/// Konfigurasi satu metode pembayaran yang dikelola admin (settings/pembayaran).
///
/// [tipe]:
/// - `statis`  — instruksi tetap + unggah bukti manual (transfer ke rekening
///   tetap, QRIS gambar tetap). Diverifikasi admin.
/// - `dinamis` — dibuat per-order lewat gateway (Xendit): Virtual Account /
///   QRIS unik, status otomatis via webhook tanpa unggah bukti.
class MetodePembayaranKonfig {
  const MetodePembayaranKonfig({
    required this.kode,
    required this.nama,
    required this.deskripsi,
    this.aktif = true,
    this.tipe = 'statis',
  });

  /// Sama dengan `MetodeBayar.wire`: transfer_bank | qris | tunai.
  final String kode;
  final String nama;
  final String deskripsi;
  final bool aktif;
  final String tipe; // 'statis' | 'dinamis'

  bool get dinamis => tipe == 'dinamis';

  MetodePembayaranKonfig copyWith({bool? aktif, String? tipe}) =>
      MetodePembayaranKonfig(
        kode: kode,
        nama: nama,
        deskripsi: deskripsi,
        aktif: aktif ?? this.aktif,
        tipe: tipe ?? this.tipe,
      );

  factory MetodePembayaranKonfig.fromMap(Map<String, dynamic> m) =>
      MetodePembayaranKonfig(
        kode: m['kode'] as String? ?? '',
        nama: m['nama'] as String? ?? '',
        deskripsi: m['deskripsi'] as String? ?? '',
        aktif: m['aktif'] as bool? ?? true,
        tipe: m['tipe'] as String? ?? 'statis',
      );

  Map<String, dynamic> toMap() => {
        'kode': kode,
        'nama': nama,
        'deskripsi': deskripsi,
        'aktif': aktif,
        'tipe': tipe,
      };
}

/// Daftar metode pembayaran + status aktif/tipe. Disimpan di
/// `settings/pembayaran`. Bila dokumen kosong → [bawaan] (3 metode statis
/// aktif) supaya perilaku lama tetap jalan sebelum admin mengaturnya.
class KonfigPembayaran {
  const KonfigPembayaran({required this.metode});

  final List<MetodePembayaranKonfig> metode;

  static const bawaan = KonfigPembayaran(metode: [
    MetodePembayaranKonfig(
        kode: 'transfer_bank',
        nama: 'Transfer Bank',
        deskripsi: 'BCA · BRI · Mandiri'),
    MetodePembayaranKonfig(
        kode: 'qris', nama: 'QRIS', deskripsi: 'Scan dari semua e-wallet'),
    MetodePembayaranKonfig(
        kode: 'tunai', nama: 'Tunai', deskripsi: 'Bayar langsung ke kru'),
  ]);

  List<MetodePembayaranKonfig> get aktif =>
      metode.where((m) => m.aktif).toList(growable: false);

  MetodePembayaranKonfig? byKode(String kode) {
    for (final m in metode) {
      if (m.kode == kode) return m;
    }
    return null;
  }

  factory KonfigPembayaran.fromMap(Map<String, dynamic> m) {
    final raw = m['metode'] as List?;
    if (raw == null || raw.isEmpty) return bawaan;
    // Gabungkan dengan bawaan agar metode baru (mis. ditambah versi app)
    // tetap muncul walau belum ada di dokumen.
    final tersimpan = {
      for (final e in raw)
        (e as Map)['kode'] as String? ?? '':
            MetodePembayaranKonfig.fromMap(e.cast<String, dynamic>()),
    };
    return KonfigPembayaran(metode: [
      for (final def in bawaan.metode) tersimpan[def.kode] ?? def,
    ]);
  }

  Map<String, dynamic> toMap() =>
      {'metode': metode.map((m) => m.toMap()).toList()};
}
