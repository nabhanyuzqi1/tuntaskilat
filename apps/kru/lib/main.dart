import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Firebase + FCM background handler harus siap SEBELUM runApp.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    await aktifkanAppCheck();
    await pasangCrashlytics();
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  } catch (e) {
    debugPrint('Gagal init Firebase/FCM: $e');
  }

  await NotificationService().initialize();

  jalankanTerpantau(() => runApp(
        const ProviderScope(
          child: TkKruApp(),
        ),
      ));
}
