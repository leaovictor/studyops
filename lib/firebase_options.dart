// IMPORTANTE: Este arquivo deve ser gerado pelo FlutterFire CLI.
//
// Para gerar, execute nos seus terminais:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Isso irá sobrescrever este arquivo com os valores reais do seu projeto.
// Documentação: https://firebase.google.com/docs/flutter/setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Substitua os valores abaixo pelos valores reais do seu projeto Firebase.
/// Acesse: Firebase Console → Configurações → Web App → Configuração SDK
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQcoCctNDi3gPk94jJSz5r72gLwXwdM94',
    appId: '1:379727416390:web:da94ee56158e94e1c7ce47',
    messagingSenderId: '379727416390',
    projectId: 'studyops-dev',
    authDomain: 'studyops-dev.firebaseapp.com',
    storageBucket: 'studyops-dev.firebasestorage.app',
    measurementId: 'G-XZ5QEZXHVT',
  );

  // TODO: Substitua com os valores reais do seu Firebase Console

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKdSieJc_DlzZ6-bse2KW0eJhJa8CUAXg',
    appId: '1:379727416390:android:37e1c30faa0f4642c7ce47',
    messagingSenderId: '379727416390',
    projectId: 'studyops-dev',
    storageBucket: 'studyops-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMmpGG6HQOobktG2D7wSOGFE5hThLOg-E',
    appId: '1:379727416390:ios:3ed2735862af852dc7ce47',
    messagingSenderId: '379727416390',
    projectId: 'studyops-dev',
    storageBucket: 'studyops-dev.firebasestorage.app',
    iosClientId:
        '379727416390-0vu5m1jukfm12ol1vdjprl0ia8i3r5fr.apps.googleusercontent.com',
    iosBundleId: 'com.studyops.app',
  );
}
