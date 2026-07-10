import 'package:cloud_functions/cloud_functions.dart';

/// Pemanggil Cloud Functions manajemen tim admin (A#2). Callable dijalankan
/// di region asia-southeast2 dan diverifikasi admin di sisi server.
class TimAdminService {
  TimAdminService()
      : _fn = FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  final FirebaseFunctions _fn;

  /// Buat akun admin baru (Auth + users role=admin) tanpa mengeluarkan admin
  /// yang sedang login. Mengembalikan uid admin baru.
  Future<String> buatAdmin({
    required String email,
    required String password,
    required String nama,
  }) async {
    final res = await _fn.httpsCallable('buatAdmin').call({
      'email': email,
      'password': password,
      'nama': nama,
    });
    return (res.data as Map)['uid'] as String;
  }

  /// Aktif/nonaktifkan akun admin lain (tak bisa diri sendiri — dijaga server).
  Future<void> setNonaktif({required String uid, required bool nonaktif}) async {
    await _fn.httpsCallable('setNonaktifAdmin').call({
      'uid': uid,
      'nonaktif': nonaktif,
    });
  }
}
