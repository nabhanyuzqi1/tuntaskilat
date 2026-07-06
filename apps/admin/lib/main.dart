import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseSiap = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseSiap = true;
  } on UnsupportedError {
    // firebase_options.dart masih placeholder.
  }
  runApp(
    ProviderScope(
      overrides: [firebaseSiapProvider.overrideWithValue(firebaseSiap)],
      child: const TkAdminApp(),
    ),
  );
}
