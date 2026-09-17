import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDF_4Qk7wKaHS8NUVBMSLD-K8ZKPHNvxug',
    appId: '1:1010480017931:web:9f441d9b9e8f2fae278d0e',
    messagingSenderId: '1010480017931',
    projectId: 'lottery-app-23db4',
    authDomain: 'lottery-app-23db4.firebaseapp.com',
    storageBucket: 'lottery-app-23db4.firebasestorage.app',
  );
}
