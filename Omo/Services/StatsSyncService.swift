import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Uploads your last week of stats to `users/{uid}/stats/{day}` so friends can see them.
enum StatsSyncService {
    static func upload() async {
        guard FirebaseBootstrap.isConfigured, let uid = Auth.auth().currentUser?.uid else { return }
        let shareScreenTime = SharedStore.settings.shareScreenTimeWithFriends
        let stats = Firestore.firestore().collection("users").document(uid).collection("stats")
        for var day in SharedStore.recentStats(days: 7) {
            if !shareScreenTime { day.distractingMinutes = -1 }
            try? await stats.document(day.day).setData(day.firestoreData)
        }
    }
}
