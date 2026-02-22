import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC93Xy0_ibpzzjjKa7nvtKiCorl6e9l7Vc',
    appId: '1:60717378999:android:7847778554bb7994bf0c32',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'habesha-dates',
    storageBucket: 'habesha-dates.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'habesha-dates',
    storageBucket: 'habesha-dates.appspot.com',
    iosBundleId: 'com.yafnad.habeshaDates',
  );
}