/// Model peran kru + pembagian upah yang ADIL & TANPA CELAH (lapisan produk
/// nyata, di luar naskah TA). Semua angka dihitung backend; jumlah payout
/// dijamin PERSIS = pool (tak ada Rupiah hilang/tercipta akibat pembulatan).
library;

/// Peran kru dalam satu order. `bobot` menentukan porsi upah.
enum PeranKru {
  worker('worker', 1.0),
  helper('helper', 0.6);

  const PeranKru(this.wire, this.bobot);
  final String wire;
  final double bobot;

  static PeranKru fromWire(String? w) =>
      w == 'helper' ? PeranKru.helper : PeranKru.worker;

  String get label => this == PeranKru.worker ? 'Worker' : 'Helper';
}

/// Satu penugasan kru pada sebuah order (disematkan di dokumen `orders`).
class Penugasan {
  const Penugasan({
    required this.cleanerId,
    required this.nama,
    required this.peran,
    this.sudahKonfirmasi = false,
    this.fotoUrl,
  });

  final String cleanerId;
  final String nama;
  final PeranKru peran;

  /// True setelah kru menekan "selesai bagian saya" + unggah foto.
  final bool sudahKonfirmasi;
  final String? fotoUrl;

  Penugasan copyWith({bool? sudahKonfirmasi, String? fotoUrl}) => Penugasan(
        cleanerId: cleanerId,
        nama: nama,
        peran: peran,
        sudahKonfirmasi: sudahKonfirmasi ?? this.sudahKonfirmasi,
        fotoUrl: fotoUrl ?? this.fotoUrl,
      );

  factory Penugasan.fromMap(Map<String, dynamic> m) => Penugasan(
        cleanerId: m['cleanerId'] as String? ?? '',
        nama: m['nama'] as String? ?? '',
        peran: PeranKru.fromWire(m['peran'] as String?),
        sudahKonfirmasi: m['sudahKonfirmasi'] as bool? ?? false,
        fotoUrl: m['fotoUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'cleanerId': cleanerId,
        'nama': nama,
        'peran': peran.wire,
        'sudahKonfirmasi': sudahKonfirmasi,
        if (fotoUrl != null) 'fotoUrl': fotoUrl,
      };
}

/// Konfigurasi upah: komisi platform (%). Sisa = pool kru.
class KonfigUpah {
  const KonfigUpah({this.komisiPersen = 20});
  final num komisiPersen; // 0–100
}

/// Hasil pembagian: komisi platform + jumlah per kru (urut sesuai input).
class HasilUpah {
  const HasilUpah({
    required this.komisi,
    required this.pool,
    required this.bagian,
  });
  final num komisi;
  final num pool;

  /// Peta cleanerId → jumlah (Rupiah, bilangan bulat).
  final Map<String, int> bagian;

  /// Invarian keadilan: komisi + Σ bagian == total penjualan.
  int get totalTerbagi =>
      komisi.round() + bagian.values.fold(0, (a, b) => a + b);
}

/// Bagi [total] (Rupiah) menjadi komisi platform + upah per kru berdasarkan
/// bobot peran. GARANSI: komisi + Σ bagian == [total] (tanpa Rupiah bocor).
///
/// - Komisi = round(total × persen/100).
/// - Pool = total − komisi.
/// - Bagian = floor(pool × bobot / Σbobot); SISA pembulatan diberikan ke kru
///   pertama (lead/worker) agar Σ bagian == pool persis.
HasilUpah bagiUpah(num total, List<Penugasan> kru, {KonfigUpah? konfig}) {
  final k = konfig ?? const KonfigUpah();
  final totalInt = total.round();
  if (kru.isEmpty) {
    return HasilUpah(komisi: totalInt, pool: 0, bagian: const {});
  }
  final komisi = (totalInt * k.komisiPersen / 100).round();
  final pool = totalInt - komisi;
  final totalBobot =
      kru.fold<double>(0, (a, p) => a + p.peran.bobot);

  final bagian = <String, int>{};
  var terbagi = 0;
  for (final p in kru) {
    final j = (pool * p.peran.bobot / totalBobot).floor();
    bagian[p.cleanerId] = j;
    terbagi += j;
  }
  // Sisa pembulatan → kru pertama (lead), supaya Σ == pool tepat.
  final sisa = pool - terbagi;
  if (sisa != 0) {
    bagian[kru.first.cleanerId] = bagian[kru.first.cleanerId]! + sisa;
  }
  return HasilUpah(komisi: komisi, pool: pool, bagian: bagian);
}
