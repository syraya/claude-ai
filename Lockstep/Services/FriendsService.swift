import Foundation
import FirebaseFirestore
import Observation

/// Friend requests, your friends list, and the stats friends share with each other.
@Observable @MainActor
final class FriendsService {
    private(set) var friendships: [Friendship] = []
    /// Today's stats for each friend, keyed by their UID.
    private(set) var todayStats: [String: DailyStats] = [:]
    var errorMessage: String?

    @ObservationIgnored private var listener: ListenerRegistration?
    @ObservationIgnored private(set) var uid: String?
    @ObservationIgnored private var myName = ""

    private var db: Firestore { Firestore.firestore() }

    var friends: [Friendship] {
        friendships.filter(\.isAccepted).sorted { a, b in
            guard let uid else { return false }
            return (todayStats[a.otherUID(me: uid)]?.focusMinutes ?? 0) > (todayStats[b.otherUID(me: uid)]?.focusMinutes ?? 0)
        }
    }

    var incomingRequests: [Friendship] {
        friendships.filter { !$0.isAccepted && $0.requester != uid }
    }

    var outgoingRequests: [Friendship] {
        friendships.filter { !$0.isAccepted && $0.requester == uid }
    }

    func start(uid newUID: String?, name: String) {
        myName = name
        guard newUID != uid else { return }
        listener?.remove()
        listener = nil
        friendships = []
        todayStats = [:]
        uid = newUID
        guard let newUID, FirebaseBootstrap.isConfigured else { return }

        listener = db.collection("friendships").whereField("members", arrayContains: newUID)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self, let snapshot else { return }
                    self.friendships = snapshot.documents.compactMap { try? $0.data(as: Friendship.self) }
                    await self.refreshTodayStats()
                }
            }
    }

    func name(for friendUID: String) -> String {
        guard let uid else { return "Friend" }
        return friendships.first { $0.members.contains(friendUID) }?.otherName(me: uid) ?? "Friend"
    }

    // MARK: Requests

    /// Sends a friend request to whoever owns `code`. If they already sent you one,
    /// this accepts it instead.
    func addFriend(code rawCode: String) async -> Bool {
        guard let uid else { return false }
        let code = rawCode.uppercased().filter { $0.isLetter || $0.isNumber }
        guard code.count == 6 else {
            errorMessage = "Friend codes are 6 letters and numbers."
            return false
        }
        do {
            let codeDoc = try await db.collection("friendCodes").document(code).getDocument()
            guard let friendUID = codeDoc.data()?["uid"] as? String else {
                errorMessage = "No one has the code \(code). Double-check it with your friend."
                return false
            }
            guard friendUID != uid else {
                errorMessage = "That's your own code 😄"
                return false
            }
            let profile = try await db.collection("users").document(friendUID).getDocument()
            let friendName = profile.data()?["displayName"] as? String ?? "Friend"

            let ref = db.collection("friendships").document(Friendship.pairID(uid, friendUID))
            let existing = try await ref.getDocument()
            if existing.exists, let friendship = try? existing.data(as: Friendship.self) {
                if friendship.isAccepted {
                    errorMessage = "You're already friends with \(friendName)."
                    return false
                }
                if friendship.requester != uid {
                    await accept(friendship)
                    return true
                }
                errorMessage = "You already sent \(friendName) a request."
                return false
            }

            try await ref.setData([
                "members": [uid, friendUID].sorted(),
                "names": [uid: myName, friendUID: friendName],
                "requester": uid,
                "status": "pending",
                "createdAt": FieldValue.serverTimestamp(),
            ])
            return true
        } catch {
            errorMessage = "Couldn't send the request: \(error.localizedDescription)"
            return false
        }
    }

    func accept(_ friendship: Friendship) async {
        guard let uid, let id = friendship.id else { return }
        do {
            try await db.collection("friendships").document(id).updateData([
                "status": "accepted",
                "acceptedAt": FieldValue.serverTimestamp(),
                "names.\(uid)": myName,
            ])
        } catch {
            errorMessage = "Couldn't accept: \(error.localizedDescription)"
        }
    }

    /// Declines a request, cancels one you sent, or unfriends.
    func remove(_ friendship: Friendship) async {
        guard let id = friendship.id else { return }
        do {
            try await db.collection("friendships").document(id).delete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Stats

    func refreshTodayStats() async {
        guard let uid else { return }
        let today = DailyStats.key(for: Date())
        var result: [String: DailyStats] = [:]
        for friendship in friendships where friendship.isAccepted {
            let friendUID = friendship.otherUID(me: uid)
            let doc = try? await db.collection("users").document(friendUID)
                .collection("stats").document(today).getDocument()
            result[friendUID] = DailyStats(day: today, data: doc?.data() ?? [:])
        }
        todayStats = result
    }

    /// The last `days` days for one friend, oldest first, with empty days filled in.
    func recentStats(for friendUID: String, days: Int = 7) async -> [DailyStats] {
        let keys: [String] = (0..<days).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date()).map(DailyStats.key(for:))
        }
        guard let first = keys.first else { return [] }
        do {
            let snapshot = try await db.collection("users").document(friendUID).collection("stats")
                .whereField(FieldPath.documentID(), isGreaterThanOrEqualTo: first)
                .getDocuments()
            var byDay: [String: DailyStats] = [:]
            for doc in snapshot.documents {
                byDay[doc.documentID] = DailyStats(day: doc.documentID, data: doc.data())
            }
            return keys.map { byDay[$0] ?? DailyStats(day: $0) }
        } catch {
            errorMessage = "Couldn't load stats: \(error.localizedDescription)"
            return keys.map { DailyStats(day: $0) }
        }
    }
}
