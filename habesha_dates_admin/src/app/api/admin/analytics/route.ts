import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebaseAdmin";

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
      .collection("analytics_daily")
      .orderBy("date", "desc")
      .limit(14)
      .get();

    const rows = snap.docs.map((docSnap) => {
      const data = docSnap.data() as any;
      const dateVal = data.date?.toDate?.() ?? data.date;
      const dateStr =
        typeof dateVal === "string" ? dateVal : dateVal?.toISOString?.().slice(0, 10);
      return {
        id: docSnap.id,
        date: dateStr || "",
        newUsers: Number(data.newUsers || 0),
        activeUsers: Number(data.activeUsers || 0),
        matchesCreated: Number(data.matchesCreated || 0),
        messagesSent: Number(data.messagesSent || 0),
      };
    });

    return NextResponse.json({ days: rows.reverse() });
  } catch (error) {
    console.error("Admin analytics list error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
