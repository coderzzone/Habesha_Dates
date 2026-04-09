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

    const body = await req.json().catch(() => ({}));
    const uid = body?.uid as string | undefined;
    const isVerified = Boolean(body?.isVerified);
    if (!uid) {
      return NextResponse.json({ error: "Missing uid" }, { status: 400 });
    }

    await adminDb.collection("users").doc(uid).set(
      {
        isVerified,
        verification: isVerified
          ? {
              status: "verified",
              provider: "manual",
              verifiedAt: FieldValue.serverTimestamp(),
            }
          : {
              status: "unverified",
              provider: "manual",
              verifiedAt: null,
            },
        lastUpdated: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Admin verify user error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
