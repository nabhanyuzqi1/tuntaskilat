import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge di semua versi Android (wajib berlaku otomatis pada
  // Android 15+ karena target SDK 36; ini menyamakan perilaku di bawahnya).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  var firebaseSiap = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseSiap = true;
  } on UnsupportedError {
    // firebase_options.dart masih placeholder — UI tetap bisa dijalankan,
    // aksi autentikasi akan memberi tahu bahwa konfigurasi belum selesai.
  }
  runApp(
    ProviderScope(
      overrides: [firebaseSiapProvider.overrideWithValue(firebaseSiap)],
      child: const TkPelangganApp(),
    ),
  );
}
