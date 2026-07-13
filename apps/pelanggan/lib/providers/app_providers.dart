import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';

import '../firebase_options.dart';

/// Pengaturan Rekening & QRIS
final pengaturanRekeningProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value({});
  return ref
      .watch(firestoreServiceProvider)
      .watchSettings('payments');
});

/// Konfigurasi metode pembayaran (aktif + statis/dinamis) yang dikelola
/// admin. Kosong/belum siap → bawaan (3 metode statis) supaya P7 tetap jalan.
final konfigPembayaranProvider = StreamProvider<KonfigPembayaran>((ref) {
  if (!ref.watch(firebaseSiapProvider)) {
    return Stream.value(KonfigPembayaran.bawaan);
  }
  return ref.watch(firestoreServiceProvider).watchKonfigPembayaran();
});

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
      // App Check tepat setelah init — lindungi Firestore/Storage dari
      // pemanggil non-resmi (enforcement diaktifkan bertahap di Console).
      await aktifkanAppCheck();
      await pasangCrashlytics();
      try {
        // Pelanggan HANYA butuh channel notifikasi (untuk push chat/status),
        // BUKAN Foreground Service "Online" — itu khusus kru. Memanggil
        // initialize() dulu menyalakan FGS → notifikasi persisten "online"
        // bocor di app pelanggan. ensureChannels() cukup.
        await NotificationService().ensureChannels();
      } catch (e) {
        debugPrint('Gagal menyiapkan channel notifikasi: $e');
      }
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

/// Konfigurasi runtime app (settings/app) — maintenance / update paksa.
final konfigAppProvider = StreamProvider<KonfigApp>((ref) {
  if (!ref.watch(firebaseSiapProvider)) {
    return Stream.value(const KonfigApp());
  }
  return ref.watch(firestoreServiceProvider).watchKonfigApp();
});

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
