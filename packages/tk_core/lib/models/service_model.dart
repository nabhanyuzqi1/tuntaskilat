/// Koleksi `services` — lihat firestore-schema.md. Harga tetap (fixed pricing).
class ServiceModel {
  const ServiceModel({
    required this.serviceId,
    required this.namaLayanan,
    required this.deskripsi,
    required this.harga,
    required this.satuan,
    required this.aktif,
    required this.ikon,
  });

  final String serviceId;
  final String namaLayanan;
  final String deskripsi;

  /// Tarif dasar (Rupiah) — sumber kebenaran harga, dihitung ulang di backend
  /// saat order dibuat (jangan percaya angka dari klien).
  final num harga;

  /// `per jam` | `per ruangan` | `per m2`
  final String satuan;
  final bool aktif;

  /// Identifier ikon Material Design.
  final String ikon;

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) =>
      ServiceModel(
        serviceId: id,
        namaLayanan: map['namaLayanan'] as String? ?? '',
        deskripsi: map['deskripsi'] as String? ?? '',
        harga: map['harga'] as num? ?? 0,
        satuan: map['satuan'] as String? ?? '',
        aktif: map['aktif'] as bool? ?? false,
        ikon: map['ikon'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'namaLayanan': namaLayanan,
        'deskripsi': deskripsi,
        'harga': harga,
        'satuan': satuan,
        'aktif': aktif,
        'ikon': ikon,
      };
}
