// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5LTx4LIRsldSrhVJnMTsm8br_mfqEKhc',
    appId: '1:999572367282:web:c00c44b2261f42f8f5e6ab',
    messagingSenderId: '999572367282',
    projectId: 'memorybox2-da467',
    authDomain: 'memorybox2-da467.firebaseapp.com',
    storageBucket: 'memorybox2-da467.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvU635MJuReaoFs-RIxCV5BRfqHxQMOig',
    appId: '1:999572367282:android:0b675e6105ab07d6f5e6ab',
    messagingSenderId: '999572367282',
    projectId: 'memorybox2-da467',
    storageBucket: 'memorybox2-da467.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDzH8HToEzRkkSkPnTDtGxr-fPbpOcBLRc',
    appId: '1:999572367282:ios:619522afc4b96997f5e6ab',
    messagingSenderId: '999572367282',
    projectId: 'memorybox2-da467',
    storageBucket: 'memorybox2-da467.appspot.com',
    iosBundleId: 'com.example.phoneAuthFirebaseTutorial',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDzH8HToEzRkkSkPnTDtGxr-fPbpOcBLRc',
    appId: '1:999572367282:ios:a28a4e575fb141c7f5e6ab',
    messagingSenderId: '999572367282',
    projectId: 'memorybox2-da467',
    storageBucket: 'memorybox2-da467.appspot.com',
    iosBundleId: 'com.example.phoneAuthFirebaseTutorial.RunnerTests',
  );
}
