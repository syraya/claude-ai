import Foundation
import FirebaseFirestore
import Observation

/// Reporting and blocking other people. Friends and Study Circles show names and
/// activity from other users, so anyone must be able to report someone and block
/// them (App Store guideline 1.2).
///
/// Blocked people are kept at `users/{uid}/private/blocked` as `people: {uid: name}`.
/// Blocking also ends the friendship, and the security rules stop a blocked person
/// sending you friend requests or joining your Study Circles. Reports go to
/// `reports/{id}`, which only the developer can read (in the Firebase console).
@Observable @MainActor
final class ModerationService {
    static let shared = ModerationService()

    /// Everyone you've blocked, by UID, with the name they had when you blocked them.
    private(set) var blocked: [String: String] = [:]
    var errorMessage: String?

    @ObservationIgnored private(set) var uid: String?
    @ObservationIgnored private var listener: ListenerRegistration?

    private var db: Firestore { Firestore.firestore() }

    private var blockedRef: DocumentReference? {
        uid.map { db.collection("users").document($0).collection("private").document("blocked") }
    }

    func isBlocked(_ otherUID: String) -> Bool { blocked[otherUID] != nil }

    func start(uid newUID: String?) {
        guard newUID != uid else { return }
        listener?.remove()
        listener = nil
        blocked = [:]
        uid = newUID
        guard newUID != nil, FirebaseBootstrap.isConfigured, let ref = blockedRef else { return }
        listener = ref.addSnapshotListener { [weak self] snapshot, _ in
            Task { @MainActor in
                self?.blocked = snapshot?.data()?["people"] as? [String: String] ?? [:]
            }
        }
    }

    /// Blocks someone: they disappear from your friends, requests, invites and
    /// Study Circles, and can't send you requests again. They aren't told.
    func block(_ otherUID: String, name: String) async {
        guard let uid, let ref = blockedRef, otherUID != uid else { return }
        do {
            try await ref.setData(["people": [otherUID: name]], merge: true)
            blocked[otherUID] = name
            // End any friendship or pending request between you.
            try? await db.collection("friendships").document(Friendship.pairID(uid, otherUID)).delete()
        } catch {
            errorMessage = "Couldn't block \(name): \(error.localizedDescription)"
        }
    }

    func unblock(_ otherUID: String) async {
        guard let ref = blockedRef else { return }
        do {
            try await ref.updateData(["people.\(otherUID)": FieldValue.delete()])
            blocked[otherUID] = nil
        } catch {
            errorMessage = "Couldn't unblock: \(error.localizedDescription)"
        }
    }

    /// Sends a report for the developer to review. Returns whether it was sent.
    func report(_ otherUID: String, name: String, reason: ReportReason,
                details: String, context: ReportContext) async -> Bool {
        guard let uid else { return false }
        do {
            try await db.collection("reports").addDocument(data: [
                "reporter": uid,
                "reportedUID": otherUID,
                "reportedName": String(name.prefix(30)),
                "reason": reason.rawValue,
                "details": String(details.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500)),
                "context": context.rawValue,
                "createdAt": FieldValue.serverTimestamp(),
            ])
            return true
        } catch {
            errorMessage = "Couldn't send the report: \(error.localizedDescription)"
            return false
        }
    }
}

enum ReportReason: String, CaseIterable, Identifiable {
    case harassment = "Harassment or bullying"
    case offensiveName = "Offensive name"
    case spam = "Spam or fake account"
    case circleAbuse = "Misusing a Study Circle"
    case other = "Something else"

    var id: String { rawValue }
}

enum ReportContext: String {
    case friend, request, studyCircle = "study_circle"
}

/// Keeps offensive words out of display names, the only free text other people see.
/// Matches whole words (after undoing number-for-letter swaps like "5h1t"), so real
/// names that merely contain a bad word, like Matsushita or Pornpimol, still pass.
enum NameFilter {
    /// Any word starting with one of these is refused ("fucker", "retarded").
    private static let prefixes = [
        "fuck", "nigg", "faggot", "retard", "rapist", "whore", "bitch", "slut", "bastard",
        "wanker", "tranny", "motherf",
    ]
    /// These are refused only as whole words, with or without a plural "s".
    private static let words: Set<String> = [
        "shit", "shitty", "cunt", "porn", "chink", "nazi", "hitler", "twat", "kike", "pussy",
        "penis", "vagina", "cock", "fag", "kys", "rape",
    ]
    /// Caught even when spaced or dotted out ("f u c k"), since they never occur
    /// inside ordinary names.
    private static let anywhere = ["fuck", "nigger", "nigga", "faggot", "motherf"]

    static func isAllowed(_ name: String) -> Bool {
        let normalized = name.lowercased()
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "4", with: "a")
            .replacingOccurrences(of: "5", with: "s")
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "$", with: "s")
        let joined = normalized.filter(\.isLetter)
        if anywhere.contains(where: joined.contains) { return false }
        let tokens = normalized.split { !$0.isLetter }.map(String.init)
        for token in tokens {
            if prefixes.contains(where: token.hasPrefix) { return false }
            let singular = token.hasSuffix("s") ? String(token.dropLast()) : token
            if words.contains(token) || words.contains(singular) { return false }
        }
        return true
    }
}
