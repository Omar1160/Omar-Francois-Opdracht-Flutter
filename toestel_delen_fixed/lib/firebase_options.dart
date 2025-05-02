import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'No Web options have been provided. Please configure Firebase for Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'No iOS options have been provided. Please configure Firebase for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD44YTV0z5KOwXGY0SUX6HpTE2GfBhVszE',
    appId: '1:1060506710450:android:ca14dc63082c9b206bb4ab',
    messagingSenderId: '1060506710450',
    projectId: 'toesteldelen',
    storageBucket: 'toesteldelen.firebasestorage.app',
  );
}