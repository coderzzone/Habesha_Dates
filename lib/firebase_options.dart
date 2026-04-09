import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyCPuNj_LvrrF5_LngQs8MosAKW0YTmKJi0',
    appId: '1:60717378999:android:7847778554bb7994bf0c32',
    messagingSenderId: '60717378999',
    projectId: 'habesha-dates',
    storageBucket: 'habesha-dates.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '60717378999',
    projectId: 'habesha-dates',
    storageBucket: 'habesha-dates.firebasestorage.app',
    iosBundleId: 'com.yafnad.habeshaDates',
  );
}
