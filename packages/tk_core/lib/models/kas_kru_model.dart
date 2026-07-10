import 'package:cloud_firestore/cloud_firestore.dart';

/// Batas nunggak default (Rp) — kru dengan saldoTunai di atas ini tak boleh
/// menerima order tunai baru sampai menyetor.
const int kBatasNunggakDefault = 200000;

/// Koleksi `kasKru/{cleanerId}` — buku kas setoran tunai (lapisan produk nyata,
/// di luar naskah TA). `saldoTunai` = komisi platform yang saat ini dipegang
/// kru (dari order tunai selesai) dan wajib disetor. Bertambah saat order tunai
/// selesai, berkurang saat kru menyetor ke admin. Selalu ≥ 0.
class KasKru {
  const KasKru({
    required this.cleanerId,
    this.namaKru = '',
    this.saldoTunai = 0,
    this.batasNunggak = kBatasNunggakDefault,
    this.totalMasuk = 0,
    this.totalSetor = 0,
    this.updatedAt,
  });

  final String cleanerId;
  final String namaKru;

  /// Komisi tunai yang belum disetor (Rp, ≥ 0).
  final int saldoTunai;

  /// Ambang nunggak (Rp). Di atas ini → blokir order tunai.
  final int batasNunggak;

  /// Akumulasi komisi tunai sepanjang waktu (audit).
  final int totalMasuk;

  /// Akumulasi setoran diterima admin sepanjang waktu (audit).
  final int totalSetor;
  final DateTime? updatedAt;

  /// Boleh menerima order tunai baru?
  bool get bolehTerimaTunai => saldoTunai <= batasNunggak;

  /// Invarian audit: saldo = Σ masuk − Σ setor.
  bool get invarianValid => saldoTunai == totalMasuk - totalSetor;

  factory KasKru.fromMap(String id, Map<String, dynamic> m) => KasKru(
        cleanerId: id,
        namaKru: m['namaKru'] as String? ?? '',
        saldoTunai: (m['saldoTunai'] as num?)?.toInt() ?? 0,
        batasNunggak:
            (m['batasNunggak'] as num?)?.toInt() ?? kBatasNunggakDefault,
        totalMasuk: (m['totalMasuk'] as num?)?.toInt() ?? 0,
        totalSetor: (m['totalSetor'] as num?)?.toInt() ?? 0,
        updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'cleanerId': cleanerId,
        'namaKru': namaKru,
        'saldoTunai': saldoTunai,
        'batasNunggak': batasNunggak,
        'totalMasuk': totalMasuk,
        'totalSetor': totalSetor,
        'updatedAt': updatedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(updatedAt!),
      };
}

/// Koleksi `setoran/{id}` — riwayat setoran tunai kru → admin (audit imutabel).
class SetoranModel {
  const SetoranModel({
    required this.setoranId,
    required this.cleanerId,
    required this.namaKru,
    required this.jumlah,
    required this.diterimaOleh,
    required this.waktu,
    this.catatan = '',
  });

  final String setoranId;
  final String cleanerId;
  final String namaKru;
  final int jumlah;

  /// UID admin yang menerima setoran.
  final String diterimaOleh;
  final DateTime waktu;
  final String catatan;

  factory SetoranModel.fromMap(String id, Map<String, dynamic> m) =>
      SetoranModel(
        setoranId: id,
        cleanerId: m['cleanerId'] as String? ?? '',
        namaKru: m['namaKru'] as String? ?? '',
        jumlah: (m['jumlah'] as num?)?.toInt() ?? 0,
        diterimaOleh: m['diterimaOleh'] as String? ?? '',
        waktu: (m['waktu'] as Timestamp?)?.toDate() ?? DateTime(2000),
        catatan: m['catatan'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'setoranId': setoranId,
        'cleanerId': cleanerId,
        'namaKru': namaKru,
        'jumlah': jumlah,
        'diterimaOleh': diterimaOleh,
        'waktu': Timestamp.fromDate(waktu),
        'catatan': catatan,
      };
}
