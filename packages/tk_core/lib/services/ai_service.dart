import 'package:cloud_functions/cloud_functions.dart';

/// Klien untuk fitur AI Tuntaskilat (Customer Service & analitik) via Cloud
/// Functions callable. Kunci API Anthropic disimpan & dibaca sepenuhnya di
/// sisi server (settings/ai) — TIDAK pernah menyentuh aplikasi klien.
class AiService {
  AiService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  final FirebaseFunctions _fn;

  /// Tanya asisten CS. [orderId] opsional untuk pertanyaan terkait pesanan
  /// milik penanya (diverifikasi server). Melempar [AiBelumAktif] bila admin
  /// belum mengatur kunci API.
  Future<String> tanyaCs(String pertanyaan, {String? orderId}) async {
    try {
      final res = await _fn.httpsCallable('csAi').call<Map<dynamic, dynamic>>({
        'pertanyaan': pertanyaan,
        'orderId': ?orderId,
      });
      return (res.data['jawaban'] as String?)?.trim() ?? '';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') throw const AiBelumAktif();
      rethrow;
    }
  }

  /// Analisis bisnis naratif (admin) dari agregat pesanan terkini.
  Future<String> analisaBisnis() async {
    try {
      final res = await _fn
          .httpsCallable('analisaBisnisAi')
          .call<Map<dynamic, dynamic>>({});
      return (res.data['ringkasan'] as String?)?.trim() ?? '';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') throw const AiBelumAktif();
      rethrow;
    }
  }
}

/// Dilempar saat fitur AI dipanggil tapi kunci API belum diatur admin.
class AiBelumAktif implements Exception {
  const AiBelumAktif();
  @override
  String toString() =>
      'Asisten AI belum diaktifkan. Admin perlu mengatur kunci API di '
      'Pengaturan.';
}
