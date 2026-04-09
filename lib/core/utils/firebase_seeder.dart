import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseSeeder {
  static const List<Map<String, dynamic>> _mockUsers = [
    {
      'name': 'Selamawit',
      'age': 24,
      'gender': 'female',
      'bio': 'Passionate about art and Habesha culture. Looking for someone to share coffee and conversations.',
      'religion': 'Orthodox',
      'heritage': 'Addis Ababa',
      'intent': 'Long-term',
      'profileImageUrl': 'https://images.unsplash.com/photo-1523438097201-51217c399a55?q=80&w=600&auto=format&fit=crop',
      'isOnline': true,
      'latitude': 9.033,
      'longitude': 38.750,
    },
    {
      'name': 'Dawit',
      'age': 28,
      'gender': 'male',
      'bio': 'Software engineer, traveler, and lover of traditional food. Let’s explore together.',
      'religion': 'Protestant',
      'heritage': 'Gonder',
      'intent': 'Marriage',
      'profileImageUrl': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=600&auto=format&fit=crop',
      'isOnline': false,
      'latitude': 9.040,
      'longitude': 38.760,
    },
    {
      'name': 'Helen',
      'age': 26,
      'gender': 'female',
      'bio': 'Architect and fitness enthusiast. I believe in meaningful connections and shared growth.',
      'religion': 'Catholic',
      'heritage': 'Asmara',
      'intent': 'Friendship',
      'profileImageUrl': 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=600&auto=format&fit=crop',
      'isOnline': true,
      'latitude': 9.020,
      'longitude': 38.740,
    },
    {
      'name': 'Yonas',
      'age': 30,
      'gender': 'male',
      'bio': 'Entrepreneur and history buff. Looking for a partner who values tradition and ambition.',
      'religion': 'Muslim',
      'heritage': 'Jimma',
      'intent': 'Marriage',
      'profileImageUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600&auto=format&fit=crop',
      'isOnline': true,
      'latitude': 9.050,
      'longitude': 38.770,
    },
    {
      'name': 'Eden',
      'age': 23,
      'gender': 'female',
      'bio': 'Music lover and social work student. Let’s make the world a better place together.',
      'religion': 'Orthodox',
      'heritage': 'Mekelle',
      'intent': 'Long-term',
      'profileImageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
      'isOnline': false,
      'latitude': 9.010,
      'longitude': 38.730,
    },
  ];

  static Future<void> seedMockUsers() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    try {
      for (var userData in _mockUsers) {
        final docRef = firestore.collection('users').doc();
        batch.set(docRef, {
          ...userData,
          'uid': docRef.id,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint("Successfully seeded ${_mockUsers.length} mock users.");
    } catch (e) {
      debugPrint("Error seeding mock users: $e");
      rethrow;
    }
  }
}
