import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Mengaktifkan Firebase App Check — memastikan hanya build resmi aplikasi
/// (bukan skrip/emulator jahat) yang boleh memanggil Firestore/Storage/
/// Functions. Panggil SEKALI tepat setelah `Firebase.initializeApp`.
///
/// - Debug build: `AndroidProvider.debug` / `AppleProvider.debug` — token
///   debug dicetak di logcat; daftarkan token itu di Firebase Console
///   (App Check → Apps → Manage debug tokens) agar emulator/CI lolos.
/// - Release Android: Play Integrity (`AndroidProvider.playIntegrity`).
/// - Web (admin): reCAPTCHA v3 — WAJIB isi [recaptchaSiteKey] dari
///   Firebase Console (App Check → Web app → reCAPTCHA v3). Bila kosong,
///   aktivasi web dilewati agar dev lokal tidak error.
///
/// Enforcement (menolak request tanpa token) diaktifkan MANUAL & bertahap
/// di Console setelah metrik "verified" stabil — jangan paksa dari kode.
Future<void> aktifkanAppCheck({String recaptchaSiteKey = ''}) async {
  try {
    if (kIsWeb) {
      if (recaptchaSiteKey.isEmpty) return; // dev web tanpa key → lewati
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(recaptchaSiteKey),
      );
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid:
          kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
      providerApple:
          kDebugMode ? AppleDebugProvider() : AppleAppAttestProvider(),
    );
  } catch (e) {
    // App Check gagal tidak boleh mematikan aplikasi — Firestore tetap
    // jalan (sampai enforcement diaktifkan). Cukup catat.
    debugPrint('App Check gagal diaktifkan: $e');
  }
}
