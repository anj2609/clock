import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCivk7lWREDEuwtWzfXN_hgwoKij5Pg4hA',
    appId: '1:1043026133058:android:e20cb63138ac8b6d3baddb',
    messagingSenderId: '1043026133058',
    projectId: 'alarm-clock-app-4f091',
    storageBucket: 'alarm-clock-app-4f091.firebasestorage.app',
  );
}
