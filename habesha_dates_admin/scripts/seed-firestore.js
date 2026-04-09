const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function loadEnv() {
  const envPath = path.join(__dirname, "..", ".env.local");
  if (!fs.existsSync(envPath)) return;
  const content = fs.readFileSync(envPath, "utf8");
  content.split(/\r?\n/).forEach((line) => {
    if (!line || line.trim().startsWith("#")) return;
    const idx = line.indexOf("=");
    if (idx === -1) return;
    const key = line.slice(0, idx).trim();
    let value = line.slice(idx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) process.env[key] = value;
  });
}

function initAdmin() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error("Missing Firebase Admin credentials. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.");
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
  }

  return admin.firestore();
}

function daysAgo(num) {
  const d = new Date();
  d.setDate(d.getDate() - num);
  return d;
}

async function upsert(docRef, data) {
  await docRef.set(data, { merge: true });
}

async function seed() {
  loadEnv();
  const db = initAdmin();
  const auth = admin.auth();
  const FieldValue = admin.firestore.FieldValue;
  const Timestamp = admin.firestore.Timestamp;

  const now = new Date();

  // Safety settings
  await upsert(db.collection("safety_settings").doc("default"), {
    blockedTerms: ["scam", "explicit", "harassment", "telegram", "whatsapp"],
    banReasons: ["Spam profile", "Harassment", "Impersonation", "Payment fraud"],
    autoFlags: {
      reportThreshold: 3,
      hideBlockedTerms: true,
      autoBanAfterViolations: 2,
    },
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Platform settings
  await upsert(db.collection("platform_settings").doc("default"), {
    maxDailySwipes: "50",
    defaultSearchRadius: "25",
    matchingAlgorithm: "balanced",
    requirePhotoVerification: true,
    maintenanceMode: false,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Feature flags
  const flags = [
    { id: "ai_match_suggestions", key: "ai_match_suggestions", enabled: true, description: "AI-powered match ranking" },
    { id: "super_swipe", key: "super_swipe", enabled: true, description: "Premium super swipe" },
    { id: "video_profiles", key: "video_profiles", enabled: false, description: "Short intro videos" },
    { id: "incognito_mode", key: "incognito_mode", enabled: false, description: "Browse without showing online" },
  ];
  await Promise.all(
    flags.map((flag) =>
      upsert(db.collection("feature_flags").doc(flag.id), {
        key: flag.key,
        enabled: flag.enabled,
        description: flag.description,
        updatedAt: FieldValue.serverTimestamp(),
      })
    )
  );

  // Admin roles
  await upsert(db.collection("admin_roles").doc("admin_seed"), {
    userId: process.env.SEED_ADMIN_UID || "",
    email: process.env.SEED_ADMIN_EMAIL || "admin@habesha.com",
    role: "super_admin",
    status: "active",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Reports
  await upsert(db.collection("reports").doc("report_seed_1"), {
    reportedUserId: "user_123",
    reportedUserName: "Abebe Kebede",
    reporterId: "user_456",
    reporterName: "Sara Tilahun",
    reason: "Harassment",
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Payment requests
  await upsert(db.collection("payment_requests").doc("payment_req_1"), {
    userId: "user_789",
    amount: 600,
    screenshotUrl: "https://example.com/receipt.jpg",
    status: "pending",
    timestamp: FieldValue.serverTimestamp(),
  });

  // Transactions
  await upsert(db.collection("payment_transactions").doc("tx_seed_1"), {
    userId: "user_789",
    txRef: "tx_0001",
    sku: "gold_monthly",
    amount: 600,
    currency: "ETB",
    status: "success",
    provider: "telebirr",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Subscriptions
  await upsert(db.collection("subscriptions").doc("sub_seed_1"), {
    userId: "user_789",
    plan: "monthly",
    status: "active",
    provider: "telebirr",
    startedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)),
  });

  // Monetization events
  await upsert(db.collection("monetization_events").doc("event_seed_1"), {
    userId: "user_789",
    type: "upgrade",
    amount: 600,
    currency: "ETB",
    createdAt: FieldValue.serverTimestamp(),
  });

  // Notifications
  await upsert(db.collection("notifications").doc("camp_seed_1"), {
    title: "Welcome Back",
    body: "We saved new matches for you.",
    audience: "All Users",
    status: "scheduled",
    scheduledAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });

  // Audit logs
  await upsert(db.collection("audit_logs").doc("audit_seed_1"), {
    actorId: "admin_seed",
    actorEmail: process.env.SEED_ADMIN_EMAIL || "admin@habesha.com",
    action: "seed_data",
    target: "firestore",
    metadata: { source: "seed script" },
    createdAt: FieldValue.serverTimestamp(),
  });

  // Analytics + revenue (last 7 days)
  for (let i = 6; i >= 0; i -= 1) {
    const date = daysAgo(i);
    const dateId = date.toISOString().slice(0, 10);
    const ts = Timestamp.fromDate(date);

    await upsert(db.collection("analytics_daily").doc(dateId), {
      date: ts,
      newUsers: 120 + i * 4,
      activeUsers: 800 + i * 15,
      matchesCreated: 45 + i * 2,
      messagesSent: 1200 + i * 30,
    });

    await upsert(db.collection("revenue_daily").doc(dateId), {
      date: ts,
      gross: 2400 + i * 120,
      net: 2100 + i * 90,
      refunds: 40 + i * 3,
      currency: "ETB",
    });
  }

  // Optionally create or update an auth user for the seeded admin
  if (process.env.SEED_ADMIN_EMAIL) {
    let uid = process.env.SEED_ADMIN_UID || "";
    try {
      const existing = await auth.getUserByEmail(process.env.SEED_ADMIN_EMAIL);
      uid = existing.uid;
      if (process.env.SEED_ADMIN_PASSWORD) {
        await auth.updateUser(uid, { password: process.env.SEED_ADMIN_PASSWORD });
      }
    } catch (err) {
      if (err && err.code === "auth/user-not-found") {
        if (!process.env.SEED_ADMIN_PASSWORD) {
          throw new Error("SEED_ADMIN_PASSWORD is required to create the admin auth user.");
        }
        const created = await auth.createUser({
          email: process.env.SEED_ADMIN_EMAIL,
          password: process.env.SEED_ADMIN_PASSWORD,
        });
        uid = created.uid;
      } else {
        throw err;
      }
    }

    await upsert(db.collection("users").doc(uid), {
      role: "admin",
      email: process.env.SEED_ADMIN_EMAIL,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Keep admin_roles in sync with resolved UID
    await upsert(db.collection("admin_roles").doc("admin_seed"), {
      userId: uid,
      email: process.env.SEED_ADMIN_EMAIL,
      role: "super_admin",
      status: "active",
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  console.log("Seed complete.");
}

seed().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
