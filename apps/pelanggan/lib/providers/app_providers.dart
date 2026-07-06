import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';

import '../firebase_options.dart';

/// Inisialisasi Firebase non-blocking — dijalankan setelah frame pertama
/// (P1 sudah tampil) sehingga tidak ada jeda layar putih saat cold start.
/// Mengembalikan true bila berhasil, false bila firebase_options masih
/// placeholder.
final firebaseInitProvider = FutureProvider<bool>((_) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return true;
  } on UnsupportedError {
    return false;
  }
});

/// Status siap-pakai Firebase, disinkronkan dari [firebaseInitProvider].
/// Semua stream provider membaca ini; begitu init selesai mereka otomatis
/// re-evaluasi.
final firebaseSiapProvider = Provider<bool>(
    (ref) => ref.watch(firebaseInitProvider).valueOrNull ?? false);

final authServiceProvider = Provider<AuthService>((_) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((_) => FirestoreService());

final storageServiceProvider =
    Provider<StorageService>((_) => StorageService());

final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return const Stream.empty();
  return ref.watch(authServiceProvider).authStateChanges;
});

const _kOnboardingSelesai = 'onboarding_selesai';

final onboardingSelesaiProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingSelesai) ?? false;
});

Future<void> tandaiOnboardingSelesai() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingSelesai, true);
}

/// Pesan konfigurasi saat aksi Firebase dipanggil sebelum
/// `flutterfire configure` dijalankan.
const pesanFirebaseBelumSiap =
    'Konfigurasi Firebase belum selesai. Jalankan flutterfire configure '
    'lalu build ulang aplikasi.';
