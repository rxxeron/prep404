// File generated for Prep404 Firebase integration
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with Prep404 Flutter applications.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQusAqHenqKzmrERiOVP99UvsEr5mywzQ',
    appId: '1:508019570429:web:0e3b1014ce9147c2fbf094',
    messagingSenderId: '508019570429',
    projectId: 'prep404fcm',
    authDomain: 'prep404fcm.firebaseapp.com',
    storageBucket: 'prep404fcm.firebasestorage.app',
    measurementId: 'G-Z79M0EGXFJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBAksSyLUz0eWV6qwqGyqc9aOhOnqXw8qQ',
    appId: '1:508019570429:android:5a1c2e47e4973c62fbf094',
    messagingSenderId: '508019570429',
    projectId: 'prep404fcm',
    storageBucket: 'prep404fcm.firebasestorage.app',
  );
}
