/// Model & kalkulasi harga dinamis (lapisan produk nyata — DI LUAR naskah TA
/// yang tetap memakai "fixed pricing"). Fungsi [hitungSubtotal] adalah SATU
/// sumber kebenaran yang dipakai klien (pratinjau langsung) dan backend
/// (hitung ulang di dalam `runTransaction`), sehingga angka klien tak dipercaya.
library;

/// Ragam skema harga sesuai pricelist TK.
enum TipeHarga {
  /// Jasa Rumput: tarif per m² bergantung kondisi (tier) × luas.
  perLuas('per_luas'),

  /// Home Cleaning: paket (jumlah petugas) × durasi + tambah jam + add-on.
  paket('paket'),

  /// "Mulai dari": harga dasar sebagai estimasi lantai × kuantitas.
  mulaiDari('mulai_dari');

  const TipeHarga(this.wire);
  final String wire;

  static TipeHarga fromWire(String? w) =>
      TipeHarga.values.firstWhere((e) => e.wire == w,
          orElse: () => TipeHarga.mulaiDari);
}

/// Tingkat kondisi untuk [TipeHarga.perLuas] (mis. "Ilalang tinggi": 2800/m²).
class TarifTier {
  const TarifTier(
      {required this.id, required this.nama, required this.hargaPerM2});
  final String id;
  final String nama;
  final num hargaPerM2;

  factory TarifTier.fromMap(Map<String, dynamic> m) => TarifTier(
        id: m['id'] as String? ?? '',
        nama: m['nama'] as String? ?? '',
        hargaPerM2: m['hargaPerM2'] as num? ?? 0,
      );
  Map<String, dynamic> toMap() =>
      {'id': id, 'nama': nama, 'hargaPerM2': hargaPerM2};
}

/// Opsi durasi berbayar dalam sebuah paket (mis. 2 jam → 90.000).
class DurasiOpsi {
  const DurasiOpsi({required this.jam, required this.harga});
  final int jam;
  final num harga;

  factory DurasiOpsi.fromMap(Map<String, dynamic> m) => DurasiOpsi(
        jam: (m['jam'] as num?)?.toInt() ?? 0,
        harga: m['harga'] as num? ?? 0,
      );
  Map<String, dynamic> toMap() => {'jam': jam, 'harga': harga};
}

/// Paket Home Cleaning (Reguler/Detail Bersih) — jumlah petugas, opsi durasi,
/// dan tarif tambah jam.
class PaketOpsi {
  const PaketOpsi({
    required this.id,
    required this.nama,
    required this.jumlahPetugas,
    required this.durasi,
    required this.hargaTambahJam,
    this.spesifikasi = const [],
  });
  final String id;
  final String nama;
  final int jumlahPetugas;
  final List<DurasiOpsi> durasi;
  final num hargaTambahJam;
  final List<String> spesifikasi;

  factory PaketOpsi.fromMap(Map<String, dynamic> m) => PaketOpsi(
        id: m['id'] as String? ?? '',
        nama: m['nama'] as String? ?? '',
        jumlahPetugas: (m['jumlahPetugas'] as num?)?.toInt() ?? 1,
        durasi: ((m['durasi'] as List?) ?? [])
            .map((e) => DurasiOpsi.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        hargaTambahJam: m['hargaTambahJam'] as num? ?? 0,
        spesifikasi:
            ((m['spesifikasi'] as List?) ?? []).map((e) => '$e').toList(),
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'jumlahPetugas': jumlahPetugas,
        'durasi': durasi.map((e) => e.toMap()).toList(),
        'hargaTambahJam': hargaTambahJam,
        'spesifikasi': spesifikasi,
      };
}

/// Layanan tambahan di luar paket (mis. "Vacum sofa": 30.000).
class AddOn {
  const AddOn({required this.id, required this.nama, required this.harga});
  final String id;
  final String nama;
  final num harga;

  factory AddOn.fromMap(Map<String, dynamic> m) => AddOn(
        id: m['id'] as String? ?? '',
        nama: m['nama'] as String? ?? '',
        harga: m['harga'] as num? ?? 0,
      );
  Map<String, dynamic> toMap() => {'id': id, 'nama': nama, 'harga': harga};
}

/// Pilihan pelanggan yang dikirim saat pemesanan. Backend memakai ini untuk
/// menghitung ULANG subtotal dari dokumen `services` (bukan percaya angka klien).
class PilihanHarga {
  const PilihanHarga({
    this.tierId,
    this.luas,
    this.paketId,
    this.durasiJam,
    this.tambahJam = 0,
    this.addOnIds = const [],
    this.kuantitas = 1,
  });

  final String? tierId; // perLuas
  final num? luas; // perLuas (m²)
  final String? paketId; // paket
  final int? durasiJam; // paket
  final int tambahJam; // paket
  final List<String> addOnIds; // paket
  final num kuantitas; // mulaiDari

  PilihanHarga copyWith({
    String? tierId,
    num? luas,
    String? paketId,
    int? durasiJam,
    int? tambahJam,
    List<String>? addOnIds,
    num? kuantitas,
  }) =>
      PilihanHarga(
        tierId: tierId ?? this.tierId,
        luas: luas ?? this.luas,
        paketId: paketId ?? this.paketId,
        durasiJam: durasiJam ?? this.durasiJam,
        tambahJam: tambahJam ?? this.tambahJam,
        addOnIds: addOnIds ?? this.addOnIds,
        kuantitas: kuantitas ?? this.kuantitas,
      );

  factory PilihanHarga.fromMap(Map<String, dynamic> m) => PilihanHarga(
        tierId: m['tierId'] as String?,
        luas: m['luas'] as num?,
        paketId: m['paketId'] as String?,
        durasiJam: (m['durasiJam'] as num?)?.toInt(),
        tambahJam: (m['tambahJam'] as num?)?.toInt() ?? 0,
        addOnIds: ((m['addOnIds'] as List?) ?? []).map((e) => '$e').toList(),
        kuantitas: m['kuantitas'] as num? ?? 1,
      );
  Map<String, dynamic> toMap() => {
        if (tierId != null) 'tierId': tierId,
        if (luas != null) 'luas': luas,
        if (paketId != null) 'paketId': paketId,
        if (durasiJam != null) 'durasiJam': durasiJam,
        'tambahJam': tambahJam,
        'addOnIds': addOnIds,
        'kuantitas': kuantitas,
      };
}

/// Satu baris rincian harga (untuk ditampilkan di Rincian Tagihan / order).
class BarisRincian {
  const BarisRincian(this.label, this.jumlah);
  final String label;
  final num jumlah;
  Map<String, dynamic> toMap() => {'label': label, 'jumlah': jumlah};
  factory BarisRincian.fromMap(Map<String, dynamic> m) =>
      BarisRincian(m['label'] as String? ?? '', m['jumlah'] as num? ?? 0);
}

/// Hasil kalkulasi: subtotal + rincian baris. Dipakai klien & backend.
class HasilHarga {
  const HasilHarga({required this.subtotal, required this.rincian});
  final num subtotal;
  final List<BarisRincian> rincian;
}
