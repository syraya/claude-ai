// Tests for firestore.rules. Run with `npm install && npm test` (needs Java for the
// Firestore emulator). The key promise: only your keyholder can unlock you.
import { after, before, beforeEach, describe, test } from "node:test";
import { readFileSync } from "node:fs";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  arrayRemove,
  arrayUnion,
  collection,
  deleteField,
  doc,
  documentId,
  getDoc,
  getDocs,
  limit,
  query,
  where,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from "firebase/firestore";

let env;
const db = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-omo",
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
  });
});

after(async () => env.cleanup());
beforeEach(async () => env.clearFirestore());

/** Seeds data as an admin, bypassing the rules. */
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), path), data));
}

describe("profiles and friend codes", () => {
  test("you can create your own profile but not someone else's", async () => {
    await assertSucceeds(setDoc(doc(db("alice"), "users/alice"), { displayName: "Alice", friendCode: "AAAAAA" }));
    await assertFails(setDoc(doc(db("alice"), "users/bob"), { displayName: "Bob", friendCode: "BBBBBB" }));
  });

  test("friend codes can't be taken over", async () => {
    await assertSucceeds(setDoc(doc(db("alice"), "friendCodes/AAAAAA"), { uid: "alice" }));
    await assertFails(setDoc(doc(db("bob"), "friendCodes/AAAAAA"), { uid: "bob" }));
    await assertFails(setDoc(doc(db("bob"), "friendCodes/BBBBBB"), { uid: "alice" }));
  });
});

describe("friendships and stats", () => {
  const request = { members: ["alice", "bob"], names: { alice: "Alice", bob: "Bob" }, requester: "alice", status: "pending" };

  test("only the other person can accept a request", async () => {
    await assertSucceeds(setDoc(doc(db("alice"), "friendships/alice_bob"), request));
    await assertFails(updateDoc(doc(db("alice"), "friendships/alice_bob"), { status: "accepted" }));
    await assertFails(updateDoc(doc(db("carol"), "friendships/alice_bob"), { status: "accepted" }));
    await assertSucceeds(updateDoc(doc(db("bob"), "friendships/alice_bob"), { status: "accepted", "names.bob": "Bobby" }));
  });

  test("accepting can't rename the other person", async () => {
    await seed("friendships/alice_bob", request);
    await assertFails(updateDoc(doc(db("bob"), "friendships/alice_bob"), { status: "accepted", "names.alice": "Loser" }));
  });

  test("the document ID must match the sorted members", async () => {
    await assertFails(setDoc(doc(db("alice"), "friendships/bob_alice"), request));
    await assertFails(setDoc(doc(db("alice"), "friendships/alice_bob"), { ...request, status: "accepted" }));
  });

  test("checking whether a friendship exists works before it does", async () => {
    await assertSucceeds(getDoc(doc(db("alice"), "friendships/alice_bob")));
  });

  test("stats are visible to friends only", async () => {
    await seed("users/bob/stats/2026-10-20", { focusMinutes: 50 });
    await seed("friendships/alice_bob", { ...request, status: "pending" });
    await assertFails(getDoc(doc(db("alice"), "users/bob/stats/2026-10-20")));
    await seed("friendships/alice_bob", { ...request, status: "accepted" });
    await assertSucceeds(getDoc(doc(db("alice"), "users/bob/stats/2026-10-20")));
    await assertFails(getDoc(doc(db("carol"), "users/bob/stats/2026-10-20")));
    await assertFails(setDoc(doc(db("alice"), "users/bob/stats/2026-10-20"), { focusMinutes: 0 }));
  });

  test("push tokens are private", async () => {
    await seed("users/bob/private/devices", { fcmTokens: ["t"] });
    await assertFails(getDoc(doc(db("alice"), "users/bob/private/devices")));
    await assertSucceeds(getDoc(doc(db("bob"), "users/bob/private/devices")));
  });
});

describe("study sessions", () => {
  const lobby = {
    hostUID: "alice", hostName: "Alice", code: "123456", status: "lobby",
    members: ["alice"], memberNames: { alice: "Alice" }, invited: ["bob"],
  };

  /** A started session where Alice holds Bob's key and Bob holds Alice's. */
  async function seedActive() {
    await seed("groupSessions/s1", { ...lobby, status: "active", members: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" } });
    await seed("groupSessions/s1/locks/bob", { lockedUID: "bob", lockedName: "Bob", keyholderUID: "alice", keyholderName: "Alice", locked: true });
    await seed("groupSessions/s1/locks/alice", { lockedUID: "alice", lockedName: "Alice", keyholderUID: "bob", keyholderName: "Bob", locked: true });
  }

  test("joining adds only yourself", async () => {
    await seed("groupSessions/s1", lobby);
    await assertSucceeds(updateDoc(doc(db("bob"), "groupSessions/s1"), { members: arrayUnion("bob"), "memberNames.bob": "Bob" }));
    await assertFails(updateDoc(doc(db("carol"), "groupSessions/s1"), { members: ["alice", "bob", "carol", "dave"], "memberNames.carol": "Carol" }));
  });

  test("a guest can leave the lobby", async () => {
    await seed("groupSessions/s1", { ...lobby, members: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" } });
    await assertSucceeds(updateDoc(doc(db("bob"), "groupSessions/s1"), { members: arrayRemove("bob"), "memberNames.bob": deleteField() }));
  });

  test("only the host starts, and the host creates the locks in one batch", async () => {
    await seed("groupSessions/s1", { ...lobby, members: ["alice", "bob"], memberNames: { alice: "Alice", bob: "Bob" } });

    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1"), { status: "active" }));

    const alice = db("alice");
    const batch = writeBatch(alice);
    batch.update(doc(alice, "groupSessions/s1"), { status: "active", startedAt: serverTimestamp() });
    batch.set(doc(alice, "groupSessions/s1/locks/alice"), { lockedUID: "alice", lockedName: "Alice", keyholderUID: "bob", keyholderName: "Bob", locked: true });
    batch.set(doc(alice, "groupSessions/s1/locks/bob"), { lockedUID: "bob", lockedName: "Bob", keyholderUID: "alice", keyholderName: "Alice", locked: true });
    await assertSucceeds(batch.commit());
  });

  test("you can't hold your own key", async () => {
    await seed("groupSessions/s1", { ...lobby, members: ["alice", "bob"] });
    const alice = db("alice");
    const batch = writeBatch(alice);
    batch.update(doc(alice, "groupSessions/s1"), { status: "active" });
    batch.set(doc(alice, "groupSessions/s1/locks/alice"), { lockedUID: "alice", keyholderUID: "alice", locked: true });
    await assertFails(batch.commit());
  });

  test("you can't unlock yourself", async () => {
    await seedActive();
    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { locked: false }));
    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { keyholderUID: "bob" }));
    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { breakUntil: new Date(Date.now() + 3600e3) }));
  });

  test("outsiders can't unlock you or even see the locks", async () => {
    await seedActive();
    await assertFails(updateDoc(doc(db("carol"), "groupSessions/s1/locks/bob"), { locked: false }));
    await assertFails(getDoc(doc(db("carol"), "groupSessions/s1/locks/bob")));
  });

  test("your keyholder can unlock you, but never re-lock you", async () => {
    await seedActive();
    await assertSucceeds(updateDoc(doc(db("alice"), "groupSessions/s1/locks/bob"), { locked: false, unlockedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db("alice"), "groupSessions/s1/locks/bob"), { locked: true }));
  });

  test("break requests: you ask, your keyholder answers", async () => {
    await seedActive();
    await assertSucceeds(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { breakRequestMinutes: 5, breakRequestedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { breakRequestMinutes: 600 }));
    await assertSucceeds(updateDoc(doc(db("alice"), "groupSessions/s1/locks/bob"), {
      breakUntil: new Date(Date.now() + 5 * 60e3),
      breakRequestMinutes: deleteField(),
      breakRequestedAt: deleteField(),
    }));
  });

  test("the emergency exit works but is always flagged", async () => {
    await seedActive();
    await assertFails(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { locked: false, emergencyExit: false }));
    await assertSucceeds(updateDoc(doc(db("bob"), "groupSessions/s1/locks/bob"), { locked: false, emergencyExit: true, unlockedAt: serverTimestamp() }));
  });

  test("ending a session doesn't unlock anyone", async () => {
    await seedActive();
    await assertSucceeds(updateDoc(doc(db("bob"), "groupSessions/s1"), { status: "ended", endedAt: serverTimestamp() }));
    let locked;
    await env.withSecurityRulesDisabled(async (ctx) => {
      locked = (await getDoc(doc(ctx.firestore(), "groupSessions/s1/locks/bob"))).get("locked");
    });
    if (locked !== true) throw new Error("lock should still be on");
  });

  test("every query the app makes is allowed", async () => {
    await seedActive();
    await seed("groupSessions/s2", { ...lobby, code: "654321" });
    await seed("friendships/alice_bob", { members: ["alice", "bob"], names: {}, requester: "alice", status: "accepted" });
    await seed("users/alice/stats/2026-10-20", { focusMinutes: 5 });
    const bob = db("bob");
    const sessions = collection(bob, "groupSessions");
    await assertSucceeds(getDocs(query(sessions, where("members", "array-contains", "bob"), where("status", "in", ["lobby", "active"]))));
    await assertSucceeds(getDocs(query(sessions, where("invited", "array-contains", "bob"), where("status", "==", "lobby"))));
    await assertSucceeds(getDocs(query(sessions, where("code", "==", "654321"), where("status", "==", "lobby"), limit(1))));
    await assertSucceeds(getDocs(collection(bob, "groupSessions/s1/locks")));
    await assertSucceeds(getDocs(query(collection(bob, "friendships"), where("members", "array-contains", "bob"))));
    await assertSucceeds(getDocs(query(collection(bob, "users/alice/stats"), where(documentId(), ">=", "2026-10-14"))));
    // Listing everyone's sessions or friendships is not.
    await assertFails(getDocs(sessions));
    await assertFails(getDocs(collection(bob, "friendships")));
  });
});
