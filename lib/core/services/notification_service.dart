import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermission();

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      await _registerToken(user.uid);
    });

    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _saveToken(user.uid, token);
    });
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission();
    } catch (e) {
      debugPrint("FCM permission error: $e");
    }
  }

  Future<void> _registerToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _saveToken(uid, token);
    } catch (e) {
      debugPrint("FCM token error: $e");
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("FCM save token error: $e");
    }
  }
}
