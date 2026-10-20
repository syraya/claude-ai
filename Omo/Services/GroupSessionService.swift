import Foundation
import FamilyControls
import FirebaseAuth
import FirebaseFirestore
import Observation

/// Study sessions with friends. Everyone joins a lobby, the host starts it, and each
/// phone gets locked with a friend holding the key. Your phone only unlocks when your
/// keyholder unlocks it (or you use the emergency exit, which tells them).
@Observable @MainActor
final class GroupSessionService {
    private(set) var current: GroupSession?
    private(set) var locks: [SessionLock] = []
    private(set) var invitations: [GroupSession] = []
    /// Set briefly after a session finishes so the UI can say "nice work".
    var justEnded: GroupSession?
    var errorMessage: String?
    private(set) var isWorking = false

    @ObservationIgnored private(set) var uid: String?
    @ObservationIgnored private var myName = ""
    @ObservationIgnored private var sessionsListener: ListenerRegistration?
    @ObservationIgnored private var invitesListener: ListenerRegistration?
    @ObservationIgnored private var locksListener: ListenerRegistration?
    @ObservationIgnored private var locksSessionID: String?
    /// Lets FocusController refresh after this service changes the shields.
    @ObservationIgnored var onLocalStateChanged: (() -> Void)?

    private var db: Firestore { Firestore.firestore() }

    var isHost: Bool { current?.hostUID == uid }
    var myLock: SessionLock? { locks.first { $0.lockedUID == uid } }
    var keysIHold: [SessionLock] { locks.filter { $0.keyholderUID == uid } }

    /// Which of your block lists gets locked during study sessions.
    nonisolated static var groupBlockListID: UUID? {
        get { UserDefaults.standard.string(forKey: "groupBlockListID").flatMap(UUID.init(uuidString:)) }
        set { UserDefaults.standard.set(newValue?.uuidString, forKey: "groupBlockListID") }
    }

    nonisolated private static func groupSelection() -> FamilyActivitySelection? {
        let lists = SharedStore.blockLists
        let chosen = lists.first { $0.id == groupBlockListID } ?? lists.first { !$0.isEmpty }
        return chosen?.selection
    }

    // MARK: Listening

    func start(uid newUID: String?, name: String) {
        myName = name
        guard newUID != uid else { return }
        stopListening()
        uid = newUID
        guard let newUID, FirebaseBootstrap.isConfigured else { return }

        let sessions = db.collection("groupSessions")
        sessionsListener = sessions
            .whereField("members", arrayContains: newUID)
            .whereField("status", in: ["lobby", "active"])
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error { self.errorMessage = error.localizedDescription }
                    guard let snapshot else { return }
                    let all = snapshot.documents.compactMap { try? $0.data(as: GroupSession.self) }
                    self.currentChanged(all.first(where: \.isActive) ?? all.first)
                }
            }

        invitesListener = sessions
            .whereField("invited", arrayContains: newUID)
            .whereField("status", isEqualTo: "lobby")
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self, let snapshot else { return }
                    self.invitations = snapshot.documents
                        .compactMap { try? $0.data(as: GroupSession.self) }
                        .filter { !$0.members.contains(newUID) }
                }
            }
    }

    private func stopListening() {
        sessionsListener?.remove()
        invitesListener?.remove()
        locksListener?.remove()
        sessionsListener = nil
        invitesListener = nil
        locksListener = nil
        locksSessionID = nil
        current = nil
        locks = []
        invitations = []
    }

    private func currentChanged(_ session: GroupSession?) {
        let previous = current
        current = session

        if session == nil, let previous, previous.isActive {
            justEnded = previous
        }

        if session?.id != locksSessionID {
            locksListener?.remove()
            locksListener = nil
            locks = []
            locksSessionID = session?.id
            if let id = session?.id {
                locksListener = db.collection("groupSessions").document(id).collection("locks")
                    .addSnapshotListener { [weak self] snapshot, _ in
                        Task { @MainActor in
                            guard let self, let snapshot else { return }
                            self.locks = snapshot.documents.compactMap { try? $0.data(as: SessionLock.self) }
                            self.applyLocalState()
                        }
                    }
            }
        }

        // Session went away while this phone still thinks it's locked: ask the server.
        if session == nil, SharedStore.friendLock != nil {
            Task {
                await Self.syncFromServer()
                self.onLocalStateChanged?()
            }
        }
    }

    /// Makes this phone's shields match the lock documents.
    private func applyLocalState() {
        guard let uid, let session = current, let sessionID = session.id else { return }

        if let mine = locks.first(where: { $0.lockedUID == uid }) {
            if mine.locked {
                let existing = SharedStore.friendLock?.sessionID == sessionID ? SharedStore.friendLock : nil
                if let selection = existing?.selection ?? Self.groupSelection() {
                    FocusEngine.applyFriendLock(FriendLockState(
                        sessionID: sessionID,
                        keyholderUID: mine.keyholderUID,
                        keyholderName: mine.keyholderName,
                        selection: selection,
                        lockedAt: existing?.lockedAt ?? mine.lockedAt ?? Date(),
                        breakEndsAt: mine.breakUntil
                    ))
                } else {
                    errorMessage = "Make a block list first so OMO knows what to lock."
                }
            } else if SharedStore.friendLock?.sessionID == sessionID {
                FocusEngine.releaseFriendLock()
            }
            onLocalStateChanged?()
        }

        // Everyone's free: close the session. The Cloud Function does this too; whoever
        // gets there first wins and the other write is a no-op.
        if session.isActive, !locks.isEmpty, locks.allSatisfy({ !$0.locked }) {
            Task { try? await db.collection("groupSessions").document(sessionID).updateData([
                "status": "ended",
                "endedAt": FieldValue.serverTimestamp(),
            ]) }
        }
    }

    // MARK: Lobby

    func createSession(inviting friendUIDs: [String]) async {
        guard let uid else { return }
        await perform("Couldn't create the session") {
            let ref = self.db.collection("groupSessions").document()
            try await ref.setData([
                "hostUID": uid,
                "hostName": self.myName,
                "code": String(format: "%06d", Int.random(in: 0...999_999)),
                "status": "lobby",
                "members": [uid],
                "memberNames": [uid: self.myName],
                "invited": friendUIDs,
                "createdAt": FieldValue.serverTimestamp(),
            ])
        }
    }

    func join(code rawCode: String) async {
        let code = rawCode.filter(\.isNumber)
        guard code.count == 6 else {
            errorMessage = "Session codes are 6 digits."
            return
        }
        do {
            let snapshot = try await db.collection("groupSessions")
                .whereField("code", isEqualTo: code)
                .whereField("status", isEqualTo: "lobby")
                .limit(to: 1)
                .getDocuments()
            guard let session = snapshot.documents.first.flatMap({ try? $0.data(as: GroupSession.self) }) else {
                errorMessage = "No open session with code \(code). It may have already started."
                return
            }
            await join(session)
        } catch {
            errorMessage = "Couldn't find that session: \(error.localizedDescription)"
        }
    }

    func join(_ session: GroupSession) async {
        guard let uid, let id = session.id else { return }
        guard session.members.count < GroupSession.maxMembers else {
            errorMessage = "That session is full (\(GroupSession.maxMembers) people max)."
            return
        }
        await perform("Couldn't join") {
            try await self.db.collection("groupSessions").document(id).updateData([
                "members": FieldValue.arrayUnion([uid]),
                "memberNames.\(uid)": self.myName,
            ])
        }
    }

    func leaveLobby() async {
        guard let uid, let session = current, let id = session.id, session.isLobby else { return }
        await perform("Couldn't leave") {
            let ref = self.db.collection("groupSessions").document(id)
            if session.hostUID == uid {
                try await ref.updateData(["status": "cancelled"])
            } else {
                try await ref.updateData([
                    "members": FieldValue.arrayRemove([uid]),
                    "memberNames.\(uid)": FieldValue.delete(),
                ])
            }
        }
    }

    /// Host only: locks every phone. Keys are passed around in a circle, so with two
    /// people you each hold the other's key.
    func beginSession() async {
        guard let session = current, let id = session.id, isHost else { return }
        guard session.members.count >= 2 else {
            errorMessage = "Wait for at least one friend to join."
            return
        }
        await perform("Couldn't start the session") {
            let ref = self.db.collection("groupSessions").document(id)
            let batch = self.db.batch()
            batch.updateData(["status": "active", "startedAt": FieldValue.serverTimestamp()], forDocument: ref)
            let members = session.members
            for (index, member) in members.enumerated() {
                let keyholder = members[(index + 1) % members.count]
                batch.setData([
                    "lockedUID": member,
                    "lockedName": session.name(of: member),
                    "keyholderUID": keyholder,
                    "keyholderName": session.name(of: keyholder),
                    "locked": true,
                    "lockedAt": FieldValue.serverTimestamp(),
                ], forDocument: ref.collection("locks").document(member))
            }
            try await batch.commit()
        }
    }

    // MARK: Keyholder actions

    func unlock(_ lock: SessionLock) async {
        await updateLock(lock, [
            "locked": false,
            "unlockedAt": FieldValue.serverTimestamp(),
            "breakRequestMinutes": FieldValue.delete(),
            "breakRequestedAt": FieldValue.delete(),
        ])
    }

    func grantBreak(_ lock: SessionLock, minutes: Int) async {
        await updateLock(lock, [
            "breakUntil": Timestamp(date: Date().addingTimeInterval(TimeInterval(minutes * 60))),
            "breakRequestMinutes": FieldValue.delete(),
            "breakRequestedAt": FieldValue.delete(),
        ])
    }

    func denyBreak(_ lock: SessionLock) async {
        await updateLock(lock, [
            "breakRequestMinutes": FieldValue.delete(),
            "breakRequestedAt": FieldValue.delete(),
        ])
    }

    // MARK: Locked-person actions

    func requestBreak(minutes: Int) async {
        guard let mine = myLock else { return }
        await updateLock(mine, [
            "breakRequestMinutes": minutes,
            "breakRequestedAt": FieldValue.serverTimestamp(),
        ])
    }

    /// The way out if your keyholder's phone dies or they leave. Your keyholder gets
    /// told, and it shows up in the session.
    func emergencyExit() async {
        guard let mine = myLock else { return }
        await updateLock(mine, [
            "locked": false,
            "emergencyExit": true,
            "unlockedAt": FieldValue.serverTimestamp(),
        ])
        FocusEngine.releaseFriendLock()
        onLocalStateChanged?()
    }

    private func updateLock(_ lock: SessionLock, _ fields: [String: Any]) async {
        guard let sessionID = current?.id, let lockID = lock.id else { return }
        await perform("That didn't go through") {
            try await self.db.collection("groupSessions").document(sessionID)
                .collection("locks").document(lockID).updateData(fields)
        }
    }

    private func perform(_ failureMessage: String, _ work: @escaping () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await work()
        } catch {
            errorMessage = "\(failureMessage): \(error.localizedDescription)"
        }
    }

    // MARK: Background sync

    /// Checks the server and fixes this phone's lock. Runs from push notifications
    /// and background refresh, when the listeners above aren't running.
    static func syncFromServer() async {
        guard FirebaseBootstrap.isConfigured, let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        if var state = SharedStore.friendLock {
            let ref = db.collection("groupSessions").document(state.sessionID).collection("locks").document(uid)
            // Server only: a stale cache must never unlock you by mistake.
            guard let doc = try? await ref.getDocument(source: .server) else { return }
            guard doc.exists, let lock = try? doc.data(as: SessionLock.self), lock.locked else {
                FocusEngine.releaseFriendLock()
                return
            }
            state.breakEndsAt = lock.breakUntil
            FocusEngine.applyFriendLock(state)
            return
        }

        // A session may have started while OMO was in the background.
        guard let selection = groupSelection(),
              let sessions = try? await db.collection("groupSessions")
                .whereField("members", arrayContains: uid)
                .whereField("status", isEqualTo: "active")
                .getDocuments(source: .server) else { return }
        for sessionDoc in sessions.documents {
            guard let lockDoc = try? await sessionDoc.reference.collection("locks").document(uid)
                    .getDocument(source: .server),
                  let lock = try? lockDoc.data(as: SessionLock.self),
                  lock.locked else { continue }
            FocusEngine.applyFriendLock(FriendLockState(
                sessionID: sessionDoc.documentID,
                keyholderUID: lock.keyholderUID,
                keyholderName: lock.keyholderName,
                selection: selection,
                lockedAt: lock.lockedAt ?? Date(),
                breakEndsAt: lock.breakUntil
            ))
            return
        }
    }
}
