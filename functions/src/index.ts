import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { createHash } from "crypto";

admin.initializeApp();

function normalizeNationalId(raw: string): string {
  return raw.replace(/[^A-Za-z0-9]/g, "").toUpperCase();
}

function buildSignature(normalized: string): string {
  return createHash("sha256").update(normalized).digest("hex");
}

export const submitVerification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const uid = context.auth.uid;
  const rawId = String(data?.nationalIdNumber || "");
  const idImageUrl = String(data?.idImageUrl || "");
  const selfieImageUrl = String(data?.selfieImageUrl || "");

  if (!rawId || rawId.length < 8 || rawId.length > 32) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid national ID number.");
  }
  if (!idImageUrl || !selfieImageUrl) {
    throw new functions.https.HttpsError("invalid-argument", "Missing image URLs.");
  }

  const normalized = normalizeNationalId(rawId);
  const signature = buildSignature(normalized);
  const last4 = normalized.length >= 4
    ? normalized.substring(normalized.length - 4)
    : normalized;

  const firestore = admin.firestore();
  const signatureRef = firestore.collection("id_signatures").doc(signature);
  const userRef = firestore.collection("users").doc(uid);

  await firestore.runTransaction(async (tx) => {
    const sigSnap = await tx.get(signatureRef);
    if (sigSnap.exists) {
      const ownerUid = sigSnap.data()?.ownerUid as string | undefined;
      if (ownerUid && ownerUid !== uid) {
        throw new functions.https.HttpsError(
          "already-exists",
          "id_already_registered"
        );
      }
    }

    tx.set(signatureRef, {
      ownerUid: uid,
      nationalIdLast4: last4,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    tx.set(userRef, {
      isVerified: true,
      verification: {
        status: "verified",
        provider: "fayda",
        idSignature: signature,
        nationalIdLast4: last4,
        idImageUrl,
        selfieImageUrl,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return {
    signature,
    status: "verified",
  };
});

export const sendNotificationOnCreate = functions.firestore
  .document("users/{uid}/notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const uid = context.params.uid as string;
    const data = snap.data() as any;
    const type = String(data?.type || "notification");
    const from = String(data?.from || "");
    const payloadData = (data?.data || {}) as Record<string, any>;

    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    if (!userSnap.exists) return;
    const userData = userSnap.data() || {};
    if (userData.notificationsEnabled === false) return;

    const tokens: string[] = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];
    if (!tokens.length) return;

    let title = "Habesha Dates";
    let body = "You have a new notification.";
    if (type === "follow") {
      title = "New follower";
      body = "Someone started following you.";
    } else if (type === "match") {
      title = "It's a match!";
      body = "You have a new match. Say hello.";
    } else if (type === "chat") {
      title = "New message";
      body = "You received a new message.";
    }

    const message = {
      notification: { title, body },
      data: {
        type,
        from,
        chatId: String(payloadData.chatId || ""),
        notifId: context.params.notifId as string,
      },
      tokens,
    };

    const res = await admin.messaging().sendEachForMulticast(message);

    const invalidTokens: string[] = [];
    res.responses.forEach((r, idx) => {
      if (r.error) {
        const code = (r.error as any).code || "";
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokens[idx]);
        }
      }
    });

    if (invalidTokens.length) {
      await admin.firestore().collection("users").doc(uid).update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  });
