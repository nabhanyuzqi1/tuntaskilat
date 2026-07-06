import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge di semua versi Android (wajib pada Android 15+ karena
  // target SDK 36; ini menyamakan perilaku di bawahnya).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Firebase TIDAK di-await di sini agar frame pertama (branding P1) langsung
  // tampil tanpa jeda layar putih; inisialisasi berjalan di firebaseInitProvider
  // sambil P1 menampilkan logo.
  runApp(const ProviderScope(child: TkPelangganApp()));
}
