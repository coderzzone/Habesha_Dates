import 'package:cloud_firestore/cloud_firestore.dart';

class AiAccessResult {
  const AiAccessResult({
    required this.allowed,
    this.reason,
    this.trialEndsAt,
    this.trialAiMatchesUsed = 0,
  });

  final bool allowed;
  final String? reason;
  final DateTime? trialEndsAt;
  final int trialAiMatchesUsed;
}

class AccessControlService {
  AccessControlService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> ensureUserAccessInitialized({
    required String uid,
    required bool phoneVerified,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final snapshot = await userRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final now = DateTime.now();

    final updates = <String, dynamic>{};

    updates['access.phoneVerified'] =
        phoneVerified || (data['access']?['phoneVerified'] == true);
    updates['access.pointsBalance'] = data['access']?['pointsBalance'] ?? 0;
    updates['access.subscriptionPlan'] =
        data['access']?['subscriptionPlan'] ?? 'none';
    updates['access.monthlyFreeUsed'] = data['access']?['monthlyFreeUsed'] ?? 0;
    updates['access.monthlyUsageKey'] =
        data['access']?['monthlyUsageKey'] ?? _monthKey(now);

    final hasTrialStart = data['access']?['trialStartedAt'] != null;
    if (!hasTrialStart && phoneVerified) {
      updates['access.trialStartedAt'] = Timestamp.fromDate(now);
      updates['access.trialEndsAt'] = Timestamp.fromDate(
        now.add(const Duration(days: 7)),
      );
      updates['access.trialAiMatchesUsed'] = 0;
    } else if (data['access']?['trialAiMatchesUsed'] == null) {
      updates['access.trialAiMatchesUsed'] = 0;
    }

    await userRef.set(updates, SetOptions(merge: true));
  }

  Future<AiAccessResult> requestAiAccess({
    required String uid,
    required bool phoneVerified,
  }) async {
    await ensureUserAccessInitialized(uid: uid, phoneVerified: phoneVerified);
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final data = userSnap.data() ?? <String, dynamic>{};
    final access = (data['access'] as Map<String, dynamic>?) ?? {};

    final isSubscribed = _isSubscriptionActive(access);
    if (isSubscribed) {
      return const AiAccessResult(allowed: true);
    }

    final Timestamp? trialEndsTs = access['trialEndsAt'] as Timestamp?;
    final DateTime? trialEndsAt = trialEndsTs?.toDate();
    final int used = access['trialAiMatchesUsed'] ?? 0;

    if (phoneVerified &&
        trialEndsAt != null &&
        DateTime.now().isBefore(trialEndsAt)) {
      if (used < 2) {
        await userRef.set({
          'access': {'trialAiMatchesUsed': FieldValue.increment(1)},
        }, SetOptions(merge: true));
        return AiAccessResult(
          allowed: true,
          trialEndsAt: trialEndsAt,
          trialAiMatchesUsed: used + 1,
        );
      }
      return AiAccessResult(
        allowed: false,
        reason: 'Trial AI limit reached (2/2). Upgrade or buy points.',
        trialEndsAt: trialEndsAt,
        trialAiMatchesUsed: used,
      );
    }

    if (!phoneVerified) {
      return const AiAccessResult(
        allowed: false,
        reason: 'Phone verification is required to start the 7-day AI trial.',
      );
    }

    return AiAccessResult(
      allowed: false,
      reason: 'Trial expired. Choose Pay-as-you-go or a subscription plan.',
      trialEndsAt: trialEndsAt,
      trialAiMatchesUsed: used,
    );
  }

  Future<bool> canUseCorePremiumFeatures(String uid) async {
    final userSnap = await _firestore.collection('users').doc(uid).get();
    final data = userSnap.data() ?? <String, dynamic>{};
    final access = (data['access'] as Map<String, dynamic>?) ?? {};
    if (_isSubscriptionActive(access)) return true;

    final Timestamp? trialEnds = access['trialEndsAt'] as Timestamp?;
    return trialEnds != null && DateTime.now().isBefore(trialEnds.toDate());
  }

  Future<bool> ensureChatAccess({
    required String uid,
    required String chatId,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final now = DateTime.now();

    return _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final chatSnap = await tx.get(chatRef);
      final data = userSnap.data() ?? <String, dynamic>{};
      final access = (data['access'] as Map<String, dynamic>?) ?? {};

      if (_isSubscriptionActive(access)) {
        return true;
      }

      final monthlyKey = _monthKey(now);
      int monthlyUsed = access['monthlyFreeUsed'] ?? 0;
      final String existingKey = access['monthlyUsageKey'] ?? monthlyKey;
      if (existingKey != monthlyKey) {
        monthlyUsed = 0;
      }

      final String plan = access['subscriptionPlan'] ?? 'none';
      final int freeLimit = _monthlyFreeLimit(plan);

      final chatData = chatSnap.data() ?? <String, dynamic>{};
      final entitlements =
          (chatData['connectionEntitlements'] as Map<String, dynamic>?) ?? {};
      if (entitlements[uid] == true) return true;

      if (freeLimit > 0 && monthlyUsed < freeLimit) {
        tx.set(chatRef, {
          'connectionEntitlements': {uid: true},
        }, SetOptions(merge: true));
        tx.set(userRef, {
          'access': {
            'monthlyFreeUsed': monthlyUsed + 1,
            'monthlyUsageKey': monthlyKey,
          },
        }, SetOptions(merge: true));
        return true;
      }

      final int points = access['pointsBalance'] ?? 0;
      if (points < 1) return false;

      tx.set(chatRef, {
        'connectionEntitlements': {uid: true},
      }, SetOptions(merge: true));
      tx.set(userRef, {
        'access': {'pointsBalance': points - 1, 'monthlyUsageKey': monthlyKey},
      }, SetOptions(merge: true));
      return true;
    });
  }

  Future<Map<String, dynamic>> getAccessSnapshot(String uid) async {
    final userSnap = await _firestore.collection('users').doc(uid).get();
    final data = userSnap.data() ?? <String, dynamic>{};
    return (data['access'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> applyVerifiedPurchase({
    required String uid,
    required String sku,
    required String txRef,
    String? transactionId,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final paymentRef = _firestore.collection('payment_transactions').doc(txRef);
    final now = DateTime.now();

    await _firestore.runTransaction((tx) async {
      final paymentSnap = await tx.get(paymentRef);
      if (paymentSnap.exists) {
        return;
      }

      if (sku == 'points_10' || sku == 'points_25' || sku == 'points_50') {
        final increment = sku == 'points_10'
            ? 10
            : sku == 'points_25'
            ? 25
            : 50;
        tx.set(userRef, {
          'access': {'pointsBalance': FieldValue.increment(increment)},
        }, SetOptions(merge: true));
      } else {
        Duration duration = const Duration(days: 30);
        String plan = 'silver';
        if (sku == 'gold_monthly') {
          plan = 'gold';
        } else if (sku == 'gold_quarterly') {
          plan = 'quarterly_gold';
          duration = const Duration(days: 90);
        }

        tx.set(userRef, {
          'access': {
            'subscriptionPlan': plan,
            'subscriptionStartedAt': Timestamp.fromDate(now),
            'subscriptionEndsAt': Timestamp.fromDate(now.add(duration)),
            'monthlyUsageKey': _monthKey(now),
            'monthlyFreeUsed': 0,
          },
        }, SetOptions(merge: true));
      }

      tx.set(paymentRef, {
        'uid': uid,
        'sku': sku,
        'txRef': txRef,
        'transactionId': transactionId,
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  bool _isSubscriptionActive(Map<String, dynamic> access) {
    final String plan = access['subscriptionPlan'] ?? 'none';
    if (plan == 'none') return false;
    final Timestamp? ts = access['subscriptionEndsAt'] as Timestamp?;
    if (ts == null) return false;
    return DateTime.now().isBefore(ts.toDate());
  }

  int _monthlyFreeLimit(String plan) {
    if (plan == 'silver') return 5;
    if (plan == 'gold' || plan == 'quarterly_gold') return 15;
    return 0;
  }

  String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}
