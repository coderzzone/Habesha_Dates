import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebaseAdmin";
import { FieldValue } from "firebase-admin/firestore";

export async function GET(req: Request) {
  try {
    const authHeader = req.headers.get("authorization") || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!token) {
      return NextResponse.json({ error: "Missing auth token" }, { status: 401 });
    }

    const decoded = await adminAuth.verifyIdToken(token);
    const adminSnap = await adminDb.collection("users").doc(decoded.uid).get();
    if (!adminSnap.exists || adminSnap.data()?.role !== "admin") {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const snap = await adminDb
      .collection("payment_requests")
      .where("status", "==", "pending")
      .get();

    const requests = snap.docs.map((doc) => {
      const data = doc.data() as any;
      return {
        id: doc.id,
        userId: data.userId || "",
        amount: data.amount || 0,
        screenshotUrl: data.screenshotUrl || "",
        status: data.status || "pending",
        timestamp: data.timestamp?.toMillis?.() ?? null,
      };
    });

    return NextResponse.json({ requests });
  } catch (error) {
    console.error("Admin payment requests list error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const authHeader = req.headers.get("authorization") || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    if (!token) {
      return NextResponse.json({ error: "Missing auth token" }, { status: 401 });
    }

    const decoded = await adminAuth.verifyIdToken(token);
    const adminSnap = await adminDb.collection("users").doc(decoded.uid).get();
    if (!adminSnap.exists || adminSnap.data()?.role !== "admin") {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const body = await req.json().catch(() => ({}));
    const id = body?.id as string | undefined;
    const action = body?.action as string | undefined;
    const rejectionReason = (body?.rejectionReason as string | undefined) || "";
    const userId = body?.userId as string | undefined;

    if (!id || !action || !userId) {
      return NextResponse.json({ error: "Missing id, action, or userId" }, { status: 400 });
    }

    const requestRef = adminDb.collection("payment_requests").doc(id);

    if (action === "approve") {
      await adminDb.collection("users").doc(userId).set(
        {
          isPremium: true,
          premiumActivatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      await requestRef.set(
        {
          status: "approved",
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } else if (action === "reject") {
      await requestRef.set(
        {
          status: "rejected",
          rejectionReason,
          processedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } else {
      return NextResponse.json({ error: "Invalid action" }, { status: 400 });
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Admin payment request action error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
