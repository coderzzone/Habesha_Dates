import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonetizationService {
  MonetizationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const int freeSwipeLimit = 20;

  String? get _uid => _auth.currentUser?.uid;

  /// Checks if the user can swipe.
  /// If free and limit reached, returns false.
  /// If 24h passed, resets count.
  Future<bool> canSwipe() async {
    final uid = _uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return true;

    final data = doc.data()!;
    final bool isPremium = data['isPremium'] ?? false;

    // Premium users have unlimited swipes
    if (isPremium) return true;

    final int currentSwipes = data['swipeCount'] ?? 0;
    final Timestamp? lastResetTs = data['lastSwipeResetTime'] as Timestamp?;
    final DateTime now = DateTime.now();

    // Check for 24h reset
    if (lastResetTs == null ||
        now.difference(lastResetTs.toDate()).inHours >= 24) {
      await _resetSwipes(uid);
      return true;
    }

    return currentSwipes < freeSwipeLimit;
  }

  /// Increments the swipe count for the user.
  Future<void> incrementSwipe() async {
    final uid = _uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final bool isPremium = doc.data()?['isPremium'] ?? false;
    if (isPremium) return;

    await _firestore.collection('users').doc(uid).update({
      'swipeCount': FieldValue.increment(1),
    });
  }

  /// Grants extra swipes (e.g., after rewarded ad).
  Future<void> grantExtraSwipes(int amount) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'swipeCount': FieldValue.increment(-amount), // Decrementing count allows more swipes
    });
  }

  Future<void> _resetSwipes(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'swipeCount': 0,
      'lastSwipeResetTime': FieldValue.serverTimestamp(),
    });
  }

  /// Submits a Telebirr payment request.
  Future<void> submitTelebirrRequest({
    required String screenshotUrl,
    required double amount,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not logged in');

    await _firestore.collection('payment_requests').add({
      'userId': uid,
      'screenshotUrl': screenshotUrl,
      'amount': amount,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of the user's monetization data.
  Stream<DocumentSnapshot> get monetizationStream {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
