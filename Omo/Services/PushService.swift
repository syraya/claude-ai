import Foundation
import FirebaseFirestore
import FirebaseMessaging

/// Keeps this phone's push token in `users/{uid}/private/devices` so the Cloud
/// Functions can tell you when a friend unlocks you, asks for a break, etc.
final class PushService {
    static let shared = PushService()

    private var token: String?
    private var signedInUID: String?

    func tokenChanged(_ newToken: String?) {
        token = newToken
        if let signedInUID { uploadToken(for: signedInUID) }
    }

    func uploadToken(for uid: String) {
        signedInUID = uid
        guard FirebaseBootstrap.isConfigured, let token else { return }
        Firestore.firestore().collection("users").document(uid).collection("private").document("devices")
            .setData(["fcmTokens": FieldValue.arrayUnion([token])], merge: true)
    }

    func removeToken(for uid: String) {
        signedInUID = nil
        guard FirebaseBootstrap.isConfigured, let token else { return }
        Firestore.firestore().collection("users").document(uid).collection("private").document("devices")
            .setData(["fcmTokens": FieldValue.arrayRemove([token])], merge: true)
    }
}
