import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebaseAdmin";

type MatchRow = {
  id: string;
  userAId: string;
  userBId: string;
  userAName: string;
  userBName: string;
  matchedAt?: any;
  lastMessage?: string;
};

type UserProfile = {
  name?: string;
  email?: string;
};

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

    const chatsSnap = await adminDb
      .collection("chats")
      .orderBy("timestamp", "desc")
      .limit(200)
      .get();

    const rawMatches = chatsSnap.docs
      .map((docSnap) => {
        const data = docSnap.data() as any;
        const users = (data.users || []) as string[];
        if (users.length < 2) return null;
        return {
          id: docSnap.id,
          userAId: users[0],
          userBId: users[1],
          matchedAt: data.timestamp ?? null,
          lastMessage: data.lastMessage || "",
        } as MatchRow;
      })
      .filter(Boolean) as MatchRow[];

    const userIds = Array.from(
      new Set(rawMatches.flatMap((m) => [m.userAId, m.userBId]))
    );

    const userRefs = userIds.map((uid) => adminDb.collection("users").doc(uid));
    const userSnaps = userRefs.length ? await adminDb.getAll(...userRefs) : [];
    const usersMap = new Map<string, UserProfile>();
    userSnaps.forEach((snap) => {
      const data = (snap.data() as UserProfile | undefined) ?? {};
      usersMap.set(snap.id, data);
    });

    const enriched = rawMatches.map((match) => {
      const userA = usersMap.get(match.userAId);
      const userB = usersMap.get(match.userBId);
      return {
        ...match,
        userAName: userA?.name || userA?.email || match.userAId,
        userBName: userB?.name || userB?.email || match.userBId,
      };
    });

    return NextResponse.json({ matches: enriched });
  } catch (error) {
    console.error("Admin matches list error", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}
