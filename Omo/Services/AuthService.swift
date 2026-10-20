import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Observation

/// Sign in with Apple through Firebase, plus your public profile and friend code.
@Observable @MainActor
final class AuthService {
    private(set) var uid: String?
    private(set) var profile: UserProfile?
    private(set) var isWorking = false
    var errorMessage: String?

    @ObservationIgnored private var currentNonce: String?
    @ObservationIgnored private var authHandle: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private var profileListener: ListenerRegistration?
    @ObservationIgnored private var pendingName: String?
    @ObservationIgnored private var isCreatingProfile = false
    @ObservationIgnored var onUserChanged: ((String?, String) -> Void)?

    var isAvailable: Bool { FirebaseBootstrap.isConfigured }
    var isSignedIn: Bool { uid != nil }
    var displayName: String { profile?.displayName ?? "You" }

    private var db: Firestore { Firestore.firestore() }

    func start() {
        guard isAvailable, authHandle == nil else { return }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.userChanged(user?.uid) }
        }
    }

    private func userChanged(_ newUID: String?) {
        guard newUID != uid else { return }
        uid = newUID
        profile = nil
        profileListener?.remove()
        profileListener = nil
        onUserChanged?(newUID, displayName)
        guard let newUID else { return }

        PushService.shared.uploadToken(for: newUID)
        profileListener = db.collection("users").document(newUID).addSnapshotListener { [weak self] snapshot, _ in
            Task { @MainActor in
                guard let self, let snapshot else { return }
                if snapshot.exists {
                    self.profile = try? snapshot.data(as: UserProfile.self)
                    self.onUserChanged?(newUID, self.displayName)
                } else {
                    await self.createProfile(uid: newUID)
                }
            }
        }
    }

    // MARK: Sign in with Apple

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName]
        request.nonce = Self.sha256(nonce)
    }

    func completeSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard let credential = appleCredential(from: result),
              let firebaseCredential = firebaseCredential(from: credential) else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            pendingName = credential.fullName?.givenName
            _ = try await Auth.auth().signIn(with: firebaseCredential)
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }

    private func appleCredential(from result: Result<ASAuthorization, Error>) -> ASAuthorizationAppleIDCredential? {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
            }
            return nil
        case .success(let authorization):
            return authorization.credential as? ASAuthorizationAppleIDCredential
        }
    }

    private func firebaseCredential(from credential: ASAuthorizationAppleIDCredential) -> AuthCredential? {
        guard let nonce = currentNonce,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            errorMessage = "Sign in with Apple didn't return a valid token. Please try again."
            return nil
        }
        return OAuthProvider.appleCredential(withIDToken: token, rawNonce: nonce, fullName: credential.fullName)
    }

    func signOut() {
        if let uid { PushService.shared.removeToken(for: uid) }
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Profile

    private func createProfile(uid: String) async {
        guard !isCreatingProfile else { return }
        isCreatingProfile = true
        defer { isCreatingProfile = false }
        do {
            let code = try await reserveFriendCode(for: uid)
            let trimmed = pendingName?.trimmingCharacters(in: .whitespaces) ?? ""
            let name = trimmed.isEmpty ? "New friend" : String(trimmed.prefix(30))
            try await db.collection("users").document(uid).setData([
                "displayName": name,
                "friendCode": code,
                "createdAt": FieldValue.serverTimestamp(),
            ])
            pendingName = nil
        } catch {
            errorMessage = "Couldn't set up your profile: \(error.localizedDescription)"
        }
    }

    /// Claims a random 6-character code. The security rules only allow creating a code
    /// that doesn't exist yet, so two people can never end up with the same one.
    private func reserveFriendCode(for uid: String) async throws -> String {
        for _ in 0..<10 {
            let code = Self.makeFriendCode()
            let ref = db.collection("friendCodes").document(code)
            let existing = try await ref.getDocument()
            if existing.exists { continue }
            do {
                try await ref.setData(["uid": uid])
                return code
            } catch {
                continue
            }
        }
        throw NSError(domain: "OMO", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Couldn't find a free friend code."])
    }

    func updateDisplayName(_ name: String) async {
        guard let uid else { return }
        let trimmed = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30))
        guard !trimmed.isEmpty else { return }
        do {
            try await db.collection("users").document(uid).updateData(["displayName": trimmed])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Delete account

    /// Apple requires apps with sign-in to offer account deletion, and to revoke the
    /// Sign in with Apple token when you do. Needs a fresh Sign in with Apple first.
    func deleteAccount(_ result: Result<ASAuthorization, Error>) async -> Bool {
        guard let user = Auth.auth().currentUser,
              let credential = appleCredential(from: result),
              let firebaseCredential = firebaseCredential(from: credential) else { return false }
        isWorking = true
        defer { isWorking = false }
        do {
            _ = try await user.reauthenticate(with: firebaseCredential)
            if let codeData = credential.authorizationCode,
               let authCode = String(data: codeData, encoding: .utf8) {
                try await Auth.auth().revokeToken(withAuthorizationCode: authCode)
            }
            try await deleteData(for: user.uid)
            try await user.delete()
            return true
        } catch {
            errorMessage = "Couldn't delete your account: \(error.localizedDescription)"
            return false
        }
    }

    private func deleteData(for uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        for doc in try await userRef.collection("stats").getDocuments().documents {
            try await doc.reference.delete()
        }
        try await userRef.collection("private").document("devices").delete()
        for doc in try await db.collection("friendships").whereField("members", arrayContains: uid).getDocuments().documents {
            try await doc.reference.delete()
        }
        if let code = profile?.friendCode {
            try await db.collection("friendCodes").document(code).delete()
        }
        try await userRef.delete()
    }

    // MARK: Helpers

    private static func makeFriendCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in alphabet.randomElement()! })
    }

    private static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var generator = SystemRandomNumberGenerator()
        return String((0..<length).map { _ in charset.randomElement(using: &generator)! })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
