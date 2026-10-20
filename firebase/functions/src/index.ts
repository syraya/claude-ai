/**
 * Push notifications for Lockstep.
 *
 * The app watches Firestore live while it's open. These functions cover the times
 * it isn't: they send a visible notification plus a background wake-up, so a
 * friend's phone unlocks (or locks) even if Lockstep is closed.
 */
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

initializeApp();
const db = getFirestore();

type Route = "focus" | "together" | "friends";

interface Push {
  title: string;
  body: string;
  route: Route;
  /** Wakes the app in the background so it can update the shields right away. */
  wake?: boolean;
}

async function tokensFor(uid: string): Promise<string[]> {
  const doc = await db.doc(`users/${uid}/private/devices`).get();
  const tokens = doc.get("fcmTokens");
  return Array.isArray(tokens) ? tokens.filter((t): t is string => typeof t === "string") : [];
}

async function notify(uids: string[], push: Push): Promise<void> {
  for (const uid of new Set(uids)) {
    const tokens = await tokensFor(uid);
    if (tokens.length === 0) continue;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: push.title, body: push.body },
      data: { route: push.route },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            sound: "default",
            ...(push.wake ? { "content-available": 1 } : {}),
          },
        },
      },
    });

    // Forget tokens for uninstalled apps.
    const dead = response.responses
      .map((r, i) => (r.success ? null : { code: r.error?.code, token: tokens[i] }))
      .filter((r): r is { code: string | undefined; token: string } => r !== null)
      .filter((r) =>
        r.code === "messaging/registration-token-not-registered" ||
        r.code === "messaging/invalid-registration-token")
      .map((r) => r.token);
    if (dead.length > 0) {
      await db.doc(`users/${uid}/private/devices`).set(
        { fcmTokens: FieldValue.arrayRemove(...dead) }, { merge: true });
    }
  }
}

// MARK: Friends

export const onFriendshipCreated = onDocumentCreated("friendships/{pairId}", async (event) => {
  const data = event.data?.data();
  if (!data || data.status !== "pending") return;
  const requester: string = data.requester;
  const target = (data.members as string[]).find((m) => m !== requester);
  if (!target) return;
  const name = data.names?.[requester] ?? "Someone";
  await notify([target], {
    title: "New friend request",
    body: `${name} wants to be friends on Lockstep.`,
    route: "friends",
  });
});

export const onFriendshipUpdated = onDocumentUpdated("friendships/{pairId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.status === "pending" && after.status === "accepted") {
    const accepter = (after.members as string[]).find((m) => m !== after.requester);
    const name = (accepter && after.names?.[accepter]) ?? "Your friend";
    await notify([after.requester], {
      title: "Friend request accepted",
      body: `You and ${name} are now friends. Time to study together?`,
      route: "friends",
    });
  }
});

// MARK: Study sessions

export const onGroupSessionCreated = onDocumentCreated("groupSessions/{sessionId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const invited = (data.invited as string[] | undefined) ?? [];
  if (invited.length === 0) return;
  await notify(invited, {
    title: `${data.hostName} invited you to study`,
    body: "Join the session in Lockstep before it starts.",
    route: "together",
  });
});

export const onGroupSessionUpdated = onDocumentUpdated("groupSessions/{sessionId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  if (before.status === "lobby" && after.status === "active") {
    const members = after.members as string[];
    await notify(members.filter((m) => m !== after.hostUID), {
      title: "Study session started 🔒",
      body: "Your apps are locked. A friend has your key.",
      route: "together",
      wake: true,
    });
  }
});

export const onLockUpdated = onDocumentUpdated("groupSessions/{sessionId}/locks/{lockedUid}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  const { sessionId } = event.params;

  // Unlocked.
  if (before.locked === true && after.locked === false) {
    if (after.emergencyExit === true) {
      await notify([after.keyholderUID], {
        title: `${after.lockedName} used the emergency unlock`,
        body: "Their phone is unlocked now. Maybe check in on them?",
        route: "together",
      });
    } else {
      await notify([after.lockedUID], {
        title: `${after.keyholderName} unlocked your phone 🔓`,
        body: "Your apps are back. Nice work.",
        route: "together",
        wake: true,
      });
    }
    await endSessionIfEveryoneIsFree(sessionId);
    return;
  }

  // Break requested.
  if (after.breakRequestMinutes != null && before.breakRequestMinutes == null) {
    await notify([after.keyholderUID], {
      title: `${after.lockedName} is asking for a break`,
      body: `${after.breakRequestMinutes} minutes. Open Lockstep to allow or deny.`,
      route: "together",
    });
    return;
  }

  // Break granted.
  const beforeBreak = before.breakUntil?.toMillis?.() ?? 0;
  const afterBreak = after.breakUntil?.toMillis?.() ?? 0;
  if (afterBreak > beforeBreak && afterBreak > Date.now()) {
    const minutes = Math.round((afterBreak - Date.now()) / 60000);
    await notify([after.lockedUID], {
      title: `${after.keyholderName} gave you a break ☕️`,
      body: `Your apps are open for ${minutes} minutes, then they lock again.`,
      route: "together",
      wake: true,
    });
    return;
  }

  // Break denied.
  if (before.breakRequestMinutes != null && after.breakRequestMinutes == null && after.locked === true) {
    await notify([after.lockedUID], {
      title: "Break request declined",
      body: `${after.keyholderName} says keep going. You've got this 💪`,
      route: "together",
    });
  }
});

async function endSessionIfEveryoneIsFree(sessionId: string): Promise<void> {
  const ref = db.doc(`groupSessions/${sessionId}`);
  const locks = await ref.collection("locks").get();
  if (locks.empty || locks.docs.some((d) => d.get("locked") === true)) return;
  await db.runTransaction(async (tx) => {
    const session = await tx.get(ref);
    if (session.get("status") !== "active") return;
    tx.update(ref, { status: "ended", endedAt: FieldValue.serverTimestamp() });
  });
  logger.info(`Session ${sessionId} ended: everyone is unlocked.`);
}
