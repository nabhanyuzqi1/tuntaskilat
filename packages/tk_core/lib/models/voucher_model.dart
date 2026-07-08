/// Koleksi `vouchers` — lapisan produk NYATA (di luar naskah TA yang memakai
/// fixed pricing tanpa promo). Dikelola Admin, divalidasi ulang di backend saat
/// pemesanan (kuota, minimal belanja, masa berlaku) di dalam `runTransaction`.
enum TipeVoucher {
  persen('persen'),
  nominal('nominal');

  const TipeVoucher(this.wire);
  final String wire;

  static TipeVoucher fromWire(String? w) =>
      w == 'persen' ? TipeVoucher.persen : TipeVoucher.nominal;
}

/// Alasan sebuah voucher ditolak (untuk pesan UI & test).
enum VoucherTolak { tidakAda, nonaktif, kadaluarsa, kuotaHabis, minimalBelanja }

class VoucherModel {
  const VoucherModel({
    required this.voucherId,
    required this.kode,
    required this.tipe,
    required this.nilai,
    this.deskripsi = '',
    this.minBelanja = 0,
    this.maxPotongan = 0,
    this.kuota = 0,
    this.terpakai = 0,
    this.berlakuHingga,
    this.aktif = true,
  });

  final String voucherId;

  /// Kode unik, disimpan UPPERCASE (mis. `HEMAT20`). Dipakai juga sebagai docId.
  final String kode;
  final TipeVoucher tipe;

  /// persen: 0–100. nominal: Rupiah.
  final num nilai;
  final String deskripsi;

  /// Minimal subtotal agar voucher berlaku.
  final num minBelanja;

  /// Batas potongan maksimum untuk tipe persen (0 = tanpa batas).
  final num maxPotongan;

  /// Kuota total; 0 dianggap tak terbatas.
  final int kuota;
  final int terpakai;
  final DateTime? berlakuHingga;
  final bool aktif;

  int get sisaKuota => kuota <= 0 ? 1 << 30 : (kuota - terpakai);

  /// Hitung potongan untuk [subtotal], atau kembalikan alasan penolakan.
  /// [sekarang] di-inject agar deterministik & mudah diuji.
  ({num potongan, VoucherTolak? tolak}) hitungPotongan(
      num subtotal, DateTime sekarang) {
    if (!aktif) return (potongan: 0, tolak: VoucherTolak.nonaktif);
    if (berlakuHingga != null && sekarang.isAfter(berlakuHingga!)) {
      return (potongan: 0, tolak: VoucherTolak.kadaluarsa);
    }
    if (sisaKuota <= 0) return (potongan: 0, tolak: VoucherTolak.kuotaHabis);
    if (subtotal < minBelanja) {
      return (potongan: 0, tolak: VoucherTolak.minimalBelanja);
    }
    num potongan =
        tipe == TipeVoucher.persen ? (subtotal * nilai / 100) : nilai;
    if (tipe == TipeVoucher.persen && maxPotongan > 0 && potongan > maxPotongan) {
      potongan = maxPotongan;
    }
    if (potongan > subtotal) potongan = subtotal; // tak boleh melebihi subtotal
    return (potongan: potongan.roundToDouble(), tolak: null);
  }

  factory VoucherModel.fromMap(String id, Map<String, dynamic> map) =>
      VoucherModel(
        voucherId: id,
        kode: (map['kode'] as String? ?? id).toUpperCase(),
        tipe: TipeVoucher.fromWire(map['tipe'] as String?),
        nilai: map['nilai'] as num? ?? 0,
        deskripsi: map['deskripsi'] as String? ?? '',
        minBelanja: map['minBelanja'] as num? ?? 0,
        maxPotongan: map['maxPotongan'] as num? ?? 0,
        kuota: (map['kuota'] as num?)?.toInt() ?? 0,
        terpakai: (map['terpakai'] as num?)?.toInt() ?? 0,
        berlakuHingga: map['berlakuHingga'] != null
            ? DateTime.tryParse(map['berlakuHingga'].toString())
            : null,
        aktif: map['aktif'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'kode': kode.toUpperCase(),
        'tipe': tipe.wire,
        'nilai': nilai,
        'deskripsi': deskripsi,
        'minBelanja': minBelanja,
        'maxPotongan': maxPotongan,
        'kuota': kuota,
        'terpakai': terpakai,
        if (berlakuHingga != null)
          'berlakuHingga': berlakuHingga!.toIso8601String(),
        'aktif': aktif,
      };

  VoucherModel copyWith({int? terpakai}) => VoucherModel(
        voucherId: voucherId,
        kode: kode,
        tipe: tipe,
        nilai: nilai,
        deskripsi: deskripsi,
        minBelanja: minBelanja,
        maxPotongan: maxPotongan,
        kuota: kuota,
        terpakai: terpakai ?? this.terpakai,
        berlakuHingga: berlakuHingga,
        aktif: aktif,
      );
}
