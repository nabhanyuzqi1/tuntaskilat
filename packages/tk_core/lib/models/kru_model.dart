import 'package:cloud_firestore/cloud_firestore.dart';

/// Jenis kru — membedakan pegawai internal vs mitra/vendor eksternal.
enum KruTipe {
  kru('kru', 'Kru Internal'),
  mitra('mitra', 'Mitra Resmi'),
  vendor('vendor', 'Vendor');

  const KruTipe(this.wire, this.label);
  final String wire;
  final String label;
  static KruTipe fromWire(String? w) =>
      KruTipe.values.firstWhere((e) => e.wire == w, orElse: () => KruTipe.kru);
}

/// Status kepegawaian kru (siklus hidup) — beda dari online/offline.
enum StatusKru {
  aktif('aktif', 'Aktif'),
  nonaktif('nonaktif', 'Nonaktif'),
  diberhentikan('diberhentikan', 'Diberhentikan');

  const StatusKru(this.wire, this.label);
  final String wire;
  final String label;
  static StatusKru fromWire(String? w) => StatusKru.values
      .firstWhere((e) => e.wire == w, orElse: () => StatusKru.aktif);

  /// Hanya kru berstatus aktif yang boleh ditugaskan.
  bool get bisaDitugaskan => this == StatusKru.aktif;
}

/// Koleksi `kru` — lihat firestore-schema.md.
/// Rekening pencairan upah kru — bank atau e-wallet. Disimpan sebagai map
/// `rekening` pada dokumen kru; dipakai admin (manajemen keuangan) saat
/// mencairkan upah worker & menagih setoran.
class RekeningKru {
  const RekeningKru({
    this.jenis = 'bank',
    this.penyedia = '',
    this.nomor = '',
    this.atasNama = '',
  });

  /// 'bank' | 'ewallet'.
  final String jenis;

  /// Nama bank (BCA/BRI/...) atau e-wallet (DANA/OVO/GoPay/...).
  final String penyedia;
  final String nomor;
  final String atasNama;

  bool get lengkap =>
      penyedia.isNotEmpty && nomor.isNotEmpty && atasNama.isNotEmpty;

  factory RekeningKru.fromMap(Map<String, dynamic>? m) => m == null
      ? const RekeningKru()
      : RekeningKru(
          jenis: m['jenis'] as String? ?? 'bank',
          penyedia: m['penyedia'] as String? ?? '',
          nomor: m['nomor'] as String? ?? '',
          atasNama: m['atasNama'] as String? ?? '',
        );

  Map<String, dynamic> toMap() => {
        'jenis': jenis,
        'penyedia': penyedia,
        'nomor': nomor,
        'atasNama': atasNama,
      };
}

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
    this.fcmTokens = const [],
    this.keahlian = const [],
    this.tipe = KruTipe.kru,
    this.status = StatusKru.aktif,
    this.rekening = const RekeningKru(),
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

  /// Token FCM perangkat kru (multi-device) — target push notifikasi tugas.
  final List<String> fcmTokens;

  /// Keahlian kru (serviceId atau kategori yang bisa dikerjakan) — dipakai
  /// A3 untuk mencocokkan kru dengan jenis layanan (mis. cuci AC ≠ rumput).
  final List<String> keahlian;

  /// Jenis kru: internal / mitra / vendor.
  final KruTipe tipe;

  /// Status kepegawaian (aktif/nonaktif/diberhentikan). Nonaktif &
  /// diberhentikan tidak muncul di daftar penugasan.
  final StatusKru status;

  /// Rekening/e-wallet pencairan upah — kosong bila belum diisi kru.
  final RekeningKru rekening;

  factory KruModel.fromMap(String id, Map<String, dynamic> map) => KruModel(
        cleanerId: id,
        nama: map['nama'] as String? ?? '',
        noTelepon: map['noTelepon'] as String? ?? '',
        statusKetersediaan: map['statusKetersediaan'] as bool? ?? false,
        rataRating: map['rataRating'] as num? ?? 0,
        posisi: map['posisi'] as GeoPoint?,
        jumlahUlasan: map['jumlahUlasan'] as num? ?? 0,
        fotoUrl: map['fotoUrl'] as String? ?? '',
        fcmTokens: (map['fcmTokens'] as List?)?.cast<String>() ?? const [],
        keahlian: (map['keahlian'] as List?)?.cast<String>() ?? const [],
        tipe: KruTipe.fromWire(map['tipe'] as String?),
        status: StatusKru.fromWire(map['status'] as String?),
        rekening: RekeningKru.fromMap(
            (map['rekening'] as Map?)?.cast<String, dynamic>()),
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
        'fcmTokens': fcmTokens,
        'keahlian': keahlian,
        'tipe': tipe.wire,
        'status': status.wire,
        'rekening': rekening.toMap(),
      };
}
