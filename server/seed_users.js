const admin = require('firebase-admin');

// Initialize Firebase Admin (Uses your environment variables or default config)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const mockUsers = [
  // --- 5 FEMALES ---
  {
    name: 'Selamawit Tadesse',
    age: 24,
    gender: 'female',
    bio: 'Architect & Coffee lover. Looking for someone who values culture and ambition.',
    religion: 'Orthodox',
    heritage: 'Addis Ababa',
    profileImageUrl: 'https://images.unsplash.com/photo-1523438097201-51217c399a55?q=80&w=600&auto=format&fit=crop',
    latitude: 9.033, longitude: 38.750,
  },
  {
    name: 'Helen Girmay',
    age: 26,
    gender: 'female',
    bio: 'Software Engineer. Passionate about tech and traditional music.',
    religion: 'Catholic',
    heritage: 'Asmara',
    profileImageUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=600&auto=format&fit=crop',
    latitude: 9.020, longitude: 38.740,
  },
  {
    name: 'Eden Yosef',
    age: 23,
    gender: 'female',
    bio: 'Artist and traveler. Let’s explore the beauties of Ethiopia together.',
    religion: 'Orthodox',
    heritage: 'Mekelle',
    profileImageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
    latitude: 9.010, longitude: 38.730,
  },
  {
    name: 'Marta Bekele',
    age: 25,
    gender: 'female',
    bio: 'Nurse and fitness enthusiast. Kindness is the most beautiful thing.',
    religion: 'Protestant',
    heritage: 'Hawassa',
    profileImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=600&auto=format&fit=crop',
    latitude: 9.045, longitude: 38.765,
  },
  {
    name: 'Betelhem Girma',
    age: 27,
    gender: 'female',
    bio: 'Entrepreneur. Looking for a partner to build a future with.',
    religion: 'Orthodox',
    heritage: 'Bahir Dar',
    profileImageUrl: 'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?q=80&w=600&auto=format&fit=crop',
    latitude: 9.030, longitude: 38.755,
  },
  // --- 5 MALES ---
  {
    name: 'Dawit Kasaye',
    age: 28,
    gender: 'male',
    bio: 'Tech entrepreneur. I love traditional food and deep conversations.',
    religion: 'Protestant',
    heritage: 'Gonder',
    profileImageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600&auto=format&fit=crop',
    latitude: 9.040, longitude: 38.760,
  },
  {
    name: 'Yonas Haile',
    age: 30,
    gender: 'male',
    bio: 'Historian. Passionate about our roots and shared future.',
    religion: 'Muslim',
    heritage: 'Jimma',
    profileImageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600&auto=format&fit=crop',
    latitude: 9.050, longitude: 38.770,
  },
  {
    name: 'Abel Tesfaye',
    age: 29,
    gender: 'male',
    bio: 'Musician and dreamer. Music is the language of the soul.',
    religion: 'Orthodox',
    heritage: 'Dire Dawa',
    profileImageUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=600&auto=format&fit=crop',
    latitude: 9.025, longitude: 38.752,
  },
  {
    name: 'Tamiru Alemu',
    age: 32,
    gender: 'male',
    bio: 'Civil Engineer. Looking for a serious connection.',
    religion: 'Orthodox',
    heritage: 'Debre Markos',
    profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600&auto=format&fit=crop',
    latitude: 9.035, longitude: 38.745,
  },
  {
    name: 'Elias Mohammed',
    age: 31,
    gender: 'male',
    bio: 'Business owner. Family and tradition are my priorities.',
    religion: 'Muslim',
    heritage: 'Harar',
    profileImageUrl: 'https://images.unsplash.com/photo-1488161628813-04466f872be2?q=80&w=600&auto=format&fit=crop',
    latitude: 9.028, longitude: 38.758,
  }
];

async function seed() {
  const batch = db.batch();
  console.log("Seeding 10 Habesha users...");

  mockUsers.forEach((user) => {
    // Generate a random UID for mock users
    const docRef = db.collection('users').doc();
    batch.set(docRef, {
      ...user,
      uid: docRef.id,
      isVerified: true,
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  try {
    await batch.commit();
    console.log("✅ Successfully seeded 10 users into the 'users' collection.");
    process.exit(0);
  } catch (err) {
    console.error("❌ Error seeding users:", err);
    process.exit(1);
  }
}

seed();
