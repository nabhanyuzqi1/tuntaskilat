import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Unggah bukti bayar (P7). Path diberi prefix UID pemilik supaya
  /// Storage Rules bisa menolak penimpaan oleh pengguna lain.
  /// Mengembalikan URL untuk field `payments.buktiBayar`.
  Future<String> uploadBuktiBayar({
    required String userId,
    required String orderId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) =>
      _upload('bukti_bayar/$userId/$orderId.jpg', bytes, contentType);

  /// Unggah foto laporan kerja kru (K4). Path diberi prefix UID kru.
  /// Mengembalikan URL untuk `orders.fotoSebelum` / `orders.fotoSesudah`.
  Future<String> uploadFotoLaporan({
    required String cleanerId,
    required String orderId,
    required bool sebelum,
    required int index,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) =>
      _upload(
        'laporan/$cleanerId/$orderId/'
        '${sebelum ? 'sebelum' : 'sesudah'}_$index.jpg',
        bytes,
        contentType,
      );

  /// Unggah foto profil (pelanggan P15 / kru K6). Path `profil/{uid}.jpg` —
  /// satu file per akun, unggah ulang menimpa yang lama (hemat storage).
  Future<String> uploadFotoProfil({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) =>
      _upload('profil/$uid.jpg', bytes, contentType);

  Future<String> _upload(
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
