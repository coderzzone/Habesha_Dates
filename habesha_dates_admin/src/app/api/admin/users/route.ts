import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebaseAdmin";

function resolveAuthProvider(providerIds: string[] = []) {
  if (providerIds.includes("google.com")) return "google";
  if (providerIds.includes("phone")) return "phone";
  if (providerIds.includes("password")) return "password";
  if (providerIds.includes("apple.com")) return "apple";
  return providerIds.length ? "other" : "unknown";
}

async function listAllAuthUsers() {
  const users = [];
  let nextPageToken: string | undefined = undefined;
  do {
    const res = await adminAuth.listUsers(1000, nextPageToken);
    users.push(...res.users);
    nextPageToken = res.pageToken;
  } while (nextPageToken);
  return users;
}

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

    const snap = await adminDb.collection("users").get();
    const firestoreUsers = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const authUsers = await listAllAuthUsers();
    const merged = new Map<string, any>();

    for (const u of firestoreUsers) {
      merged.set(u.id, { ...u });
    }

    for (const u of authUsers) {
      const existing = merged.get(u.uid) || {};
      const providerIds = (u.providerData || []).map((p) => p.providerId).filter(Boolean);
      merged.set(u.uid, {
        id: u.uid,
        name: existing.name || u.displayName || "Unknown User",
        email: existing.email || u.email || "",
        phoneNumber: existing.phoneNumber || u.phoneNumber || "",
        photoUrl: existing.photoUrl || u.photoURL || "",
        status: existing.status,
        isPremium: existing.isPremium,
        isVerified: existing.isVerified,
        createdAt: existing.createdAt || u.metadata?.creationTime || "",
        providerIds,
        authProvider: resolveAuthProvider(providerIds),
      });
    }

    const users = Array.from(merged.values());

    return NextResponse.json({ users });
  } catch (error) {
    console.error("Admin users list error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
