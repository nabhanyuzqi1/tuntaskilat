import 'package:cloud_firestore/cloud_firestore.dart';

/// Koleksi `kru` — lihat firestore-schema.md.
class KruModel {
  const KruModel({
    required this.cleanerId,
    required this.nama,
    required this.noTelepon,
    required this.statusKetersediaan,
    required this.rataRating,
    this.posisi,
    required this.jumlahUlasan,
    this.fotoUrl = '',
  });

  /// PK — sama dengan UID Firebase Auth.
  final String cleanerId;
  final String nama;
  final String noTelepon;

  /// Online/offline menerima tugas — skenario Black-Box #7: toggle ini harus
  /// langsung menghilangkan kru dari daftar tersedia di UI pelanggan.
  final bool statusKetersediaan;
  final num rataRating;

  /// Lokasi live saat dalam perjalanan.
  final GeoPoint? posisi;
  final num jumlahUlasan;

  /// URL foto profil kru ('' bila belum diunggah) — wajib bagi kru aktif.
  final String fotoUrl;

  factory KruModel.fromMap(String id, Map<String, dynamic> map) => KruModel(
        cleanerId: id,
        nama: map['nama'] as String? ?? '',
        noTelepon: map['noTelepon'] as String? ?? '',
        statusKetersediaan: map['statusKetersediaan'] as bool? ?? false,
        rataRating: map['rataRating'] as num? ?? 0,
        posisi: map['posisi'] as GeoPoint?,
        jumlahUlasan: map['jumlahUlasan'] as num? ?? 0,
        fotoUrl: map['fotoUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'cleanerId': cleanerId,
        'nama': nama,
        'noTelepon': noTelepon,
        'statusKetersediaan': statusKetersediaan,
        'rataRating': rataRating,
        'posisi': posisi,
        'jumlahUlasan': jumlahUlasan,
        'fotoUrl': fotoUrl,
      };
}
