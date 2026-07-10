import 'package:cloud_firestore/cloud_firestore.dart';

/// Alamat tersimpan pelanggan — subkoleksi `users/{uid}/alamat` (produk nyata,
/// di luar 7 koleksi TA). Agar tak perlu mengetik ulang alamat tiap memesan.
class AlamatModel {
  const AlamatModel({
    required this.id,
    required this.label,
    required this.alamat,
    required this.lokasi,
  });

  final String id;

  /// Label ramah: "Rumah", "Kantor", dll.
  final String label;
  final String alamat;
  final GeoPoint lokasi;

  factory AlamatModel.fromMap(String id, Map<String, dynamic> m) => AlamatModel(
        id: id,
        label: m['label'] as String? ?? 'Alamat',
        alamat: m['alamat'] as String? ?? '',
        lokasi: m['lokasi'] as GeoPoint? ?? const GeoPoint(0, 0),
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'alamat': alamat,
        'lokasi': lokasi,
      };
}
