import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'config/secrets.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: AppSecrets.firebaseApiKey,
    appId: '1:1031694875467:web:ce2f532e0c5f9afe4c46ce',
    messagingSenderId: '1031694875467',
    projectId: 'findmissingperson-66b71',
    authDomain: 'findmissingperson-66b71.firebaseapp.com',
    storageBucket: 'findmissingperson-66b71.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: AppSecrets.firebaseApiKey,
    appId: '1:1031694875467:android:ce2f532e0c5f9afe4c46ce',
    messagingSenderId: '1031694875467',
    projectId: 'findmissingperson-66b71',
    storageBucket: 'findmissingperson-66b71.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: AppSecrets.firebaseApiKey,
    appId: '1:1031694875467:ios:ce2f532e0c5f9afe4c46ce',
    messagingSenderId: '1031694875467',
    projectId: 'findmissingperson-66b71',
    storageBucket: 'findmissingperson-66b71.firebasestorage.app',
    iosBundleId: 'com.example.findMissingPerson',
  );
}
