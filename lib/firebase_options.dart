// PLACEHOLDER FILE.
//
// Run `flutterfire configure` from the project root to overwrite this file
// with your real Firebase project configuration.
//
// See README.md "Firebase Setup" section for full instructions.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform. '
          'Run `flutterfire configure` from the project root.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAuj0ABIzKGns_BuuW24svfauJts13EhcM',
    appId: '1:316060617300:web:4cde6e759d63603331fbc1',
    messagingSenderId: '316060617300',
    projectId: 'futureme-77182',
    authDomain: 'futureme-77182.firebaseapp.com',
    storageBucket: 'futureme-77182.firebasestorage.app',
    measurementId: 'G-Z76G4HJKMP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALzeHeVLrBdKF9Elnw-4JJ8OY768rxt8k',
    appId: '1:316060617300:android:17e29fa556d3f25731fbc1',
    messagingSenderId: '316060617300',
    projectId: 'futureme-77182',
    storageBucket: 'futureme-77182.firebasestorage.app',
  );
}
