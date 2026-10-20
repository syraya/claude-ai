import Foundation
import FirebaseFirestore

/// Public profile at `users/{uid}`. Any signed-in user can read it (it's just a name
/// and a friend code); stats live in a subcollection only friends can read.
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var friendCode: String
}

/// `friendships/{uidA_uidB}` with the two UIDs sorted, so there's only ever one
/// document per pair of people.
struct Friendship: Codable, Identifiable {
    @DocumentID var id: String?
    var members: [String]
    var names: [String: String]
    var requester: String
    var status: String

    var isAccepted: Bool { status == "accepted" }

    func otherUID(me: String) -> String { members.first { $0 != me } ?? "" }
    func otherName(me: String) -> String { names[otherUID(me: me)] ?? "Friend" }

    static func pairID(_ a: String, _ b: String) -> String { [a, b].sorted().joined(separator: "_") }
}

/// A study session at `groupSessions/{id}`. It starts in the lobby while people
/// join, then goes active when the host locks everyone in.
struct GroupSession: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var hostUID: String
    var hostName: String
    var code: String
    var status: String
    var members: [String]
    var memberNames: [String: String]
    var invited: [String]
    var startedAt: Date?

    var isLobby: Bool { status == "lobby" }
    var isActive: Bool { status == "active" }

    func name(of uid: String) -> String { memberNames[uid] ?? "Friend" }

    static let maxMembers = 8
}

/// `groupSessions/{id}/locks/{lockedUID}`: one person's phone and who holds the key.
struct SessionLock: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var lockedUID: String
    var lockedName: String
    var keyholderUID: String
    var keyholderName: String
    var locked: Bool
    var lockedAt: Date?
    var unlockedAt: Date?
    var emergencyExit: Bool?
    var breakRequestMinutes: Int?
    var breakRequestedAt: Date?
    var breakUntil: Date?

    var isOnBreak: Bool {
        guard let breakUntil else { return false }
        return breakUntil > Date()
    }

    var hasPendingBreakRequest: Bool { locked && breakRequestMinutes != nil }
}

extension DailyStats {
    /// Reads stats written by another device, tolerating missing fields.
    init(day: String, data: [String: Any]) {
        self.init(day: day)
        focusMinutes = data["focusMinutes"] as? Int ?? 0
        sessionsCompleted = data["sessionsCompleted"] as? Int ?? 0
        breaksTaken = data["breaksTaken"] as? Int ?? 0
        friendSessions = data["friendSessions"] as? Int ?? 0
        distractingMinutes = data["distractingMinutes"] as? Int ?? -1
    }

    var firestoreData: [String: Any] {
        [
            "day": day,
            "focusMinutes": focusMinutes,
            "sessionsCompleted": sessionsCompleted,
            "breaksTaken": breaksTaken,
            "friendSessions": friendSessions,
            "distractingMinutes": distractingMinutes,
        ]
    }

    /// Friends who turned off screen-time sharing upload -1.
    var sharesScreenTime: Bool { distractingMinutes >= 0 }
}
