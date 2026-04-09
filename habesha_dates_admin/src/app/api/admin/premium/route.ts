import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebaseAdmin";
import { FieldValue } from "firebase-admin/firestore";

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

    const body = await req.json();
    const uid = String(body?.uid || "");
    const isPremium = body?.isPremium;

    if (!uid || typeof isPremium !== "boolean") {
      return NextResponse.json({ error: "Invalid payload" }, { status: 400 });
    }

    const updates: Record<string, any> = {
      isPremium,
    };

    if (isPremium) {
      updates.premiumActivatedAt = FieldValue.serverTimestamp();
    } else {
      updates.premiumActivatedAt = FieldValue.delete();
    }

    await adminDb.collection("users").doc(uid).set(updates, { merge: true });

    await adminDb.collection("audit_logs").add({
      actorId: decoded.uid,
      actorEmail: decoded.email || "unknown",
      action: "premium_toggle",
      target: uid,
      metadata: { isPremium },
      createdAt: FieldValue.serverTimestamp(),
    });

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Premium toggle error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
