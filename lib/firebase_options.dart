import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBC2OoyrRVDNsvc8ztGAfsiGRs5Sogjvu0',
    appId: '1:563839138064:web:84f2655d9f33bcec038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    authDomain: 'freshfold-86da1.firebaseapp.com',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQqE9O9Yvb3JvxOp4WZrxrpD4rd0UMDbg',
    appId: '1:563839138064:android:0d8f8fca301a832b038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:563839138064:ios:9ca47691dd8320d5038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
    iosBundleId: 'golden.freshfold',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:563839138064:ios:9ca47691dd8320d5038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
    iosBundleId: 'golden.freshfold',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBC2OoyrRVDNsvc8ztGAfsiGRs5Sogjvu0',
    appId: '1:563839138064:web:84f2655d9f33bcec038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    authDomain: 'freshfold-86da1.firebaseapp.com',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBC2OoyrRVDNsvc8ztGAfsiGRs5Sogjvu0',
    appId: '1:563839138064:web:84f2655d9f33bcec038d95',
    messagingSenderId: '563839138064',
    projectId: 'freshfold-86da1',
    authDomain: 'freshfold-86da1.firebaseapp.com',
    storageBucket: 'freshfold-86da1.firebasestorage.app',
  );
}
