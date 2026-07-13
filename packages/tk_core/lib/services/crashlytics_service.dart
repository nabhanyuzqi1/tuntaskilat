import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Memasang Firebase Crashlytics sebagai penangkap error global. Panggil
/// SETELAH `Firebase.initializeApp` dan bungkus `runApp` dengan
/// [jalankanTerpantau] agar error zona ikut tercatat.
///
/// - Error framework Flutter → `recordFlutterFatalError`.
/// - Error asinkron di luar Flutter (`PlatformDispatcher.onError`) → record.
/// - Nonaktif otomatis di debug (biar log lokal tak terkirim ke dashboard).
Future<void> pasangCrashlytics() async {
  // Web belum didukung firebase_crashlytics — lewati.
  if (kIsWeb) return;
  final cr = FirebaseCrashlytics.instance;
  await cr.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = cr.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    cr.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Menjalankan [body] (biasanya `runApp(...)`) dalam guarded zone sehingga
/// error asinkron yang lolos dari handler global tetap tercatat.
void jalankanTerpantau(void Function() body) {
  if (kIsWeb) {
    body();
    return;
  }
  runZonedGuarded(body, (error, stack) {
    try {
      // Bisa terpicu sebelum Firebase siap (init lazy di app pelanggan) —
      // jangan biarkan handler-nya sendiri melempar.
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      debugPrint('Crashlytics belum siap: $error');
    }
  });
}

/// Kunci konteks untuk mempermudah triase — mis. orderId pada alur pesan.
Future<void> setKunciCrash(String kunci, Object nilai) async {
  if (kIsWeb) return;
  try {
    await FirebaseCrashlytics.instance.setCustomKey(kunci, nilai);
  } catch (_) {
    // diamkan — jangan sampai logging merusak alur utama.
  }
}
