// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this Firebase project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS is not configured for this Firebase project.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBm3H9Ve9kRIw2R1YQby6OaFaFxd5zWR7s',
    appId: '1:422910325457:android:2021589141174f76facbf0',
    messagingSenderId: '422910325457',
    projectId: 'splitzy-83bdd',
    storageBucket: 'splitzy-83bdd.firebasestorage.app',
  );
}