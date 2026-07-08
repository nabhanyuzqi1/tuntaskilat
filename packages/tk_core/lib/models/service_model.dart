import 'pricing.dart';

/// Koleksi `services` — lihat firestore-schema.md.
///
/// Naskah TA memakai "fixed pricing" (`harga × kuantitas`). Untuk operasional
/// nyata, model diperluas dengan skema harga dinamis sesuai pricelist TK
/// ([tipeHarga] + [tiers]/[paketOpsi]/[addOns]). Field lama tetap ada &
/// kompatibel; [harga] menjadi harga dasar / "mulai dari".
class ServiceModel {
  const ServiceModel({
    required this.serviceId,
    required this.namaLayanan,
    required this.deskripsi,
    required this.harga,
    required this.satuan,
    required this.aktif,
    required this.ikon,
    this.tipeHarga = TipeHarga.mulaiDari,
    this.kategori = 'umum',
    this.gambar = '',
    this.tiers = const [],
    this.paketOpsi = const [],
    this.addOns = const [],
  });

  final String serviceId;
  final String namaLayanan;
  final String deskripsi;

  /// Tarif dasar / "mulai dari" (Rupiah) — dihitung ulang di backend.
  final num harga;

  /// `per jam` | `per ruangan` | `per m2`
  final String satuan;
  final bool aktif;

  /// Identifier ikon Material Design.
  final String ikon;

  /// Skema harga: perLuas (rumput), paket (home cleaning), mulaiDari (estimasi).
  final TipeHarga tipeHarga;

  /// Kategori tampilan/ilustrasi: `rumput` | `home_cleaning` | `umum`.
  final String kategori;

  /// Kunci ilustrasi brand untuk kartu layanan (mis. `rumput`, `cleaning`).
  final String gambar;

  /// Tingkat kondisi untuk [TipeHarga.perLuas].
  final List<TarifTier> tiers;

  /// Opsi paket untuk [TipeHarga.paket].
  final List<PaketOpsi> paketOpsi;

  /// Layanan tambahan (add-on) untuk [TipeHarga.paket].
  final List<AddOn> addOns;

  /// Hitung subtotal + rincian dari [pilihan]. SATU sumber kebenaran harga
  /// (klien untuk pratinjau, backend untuk hitung ulang di transaction).
  HasilHarga hitungHarga(PilihanHarga pilihan) {
    switch (tipeHarga) {
      case TipeHarga.perLuas:
        final tier = tiers.firstWhere(
          (t) => t.id == pilihan.tierId,
          orElse: () => tiers.isNotEmpty
              ? tiers.first
              : const TarifTier(id: '', nama: '', hargaPerM2: 0),
        );
        final luas = pilihan.luas ?? 0;
        final sub = tier.hargaPerM2 * luas;
        return HasilHarga(subtotal: sub, rincian: [
          BarisRincian(
              '${tier.nama} — ${_num(luas)} m² × Rp${_num(tier.hargaPerM2)}',
              sub),
        ]);

      case TipeHarga.paket:
        final paket = paketOpsi.firstWhere(
          (p) => p.id == pilihan.paketId,
          orElse: () => paketOpsi.isNotEmpty
              ? paketOpsi.first
              : const PaketOpsi(
                  id: '',
                  nama: '',
                  jumlahPetugas: 1,
                  durasi: [],
                  hargaTambahJam: 0),
        );
        final durasi = paket.durasi.firstWhere(
          (d) => d.jam == pilihan.durasiJam,
          orElse: () => paket.durasi.isNotEmpty
              ? paket.durasi.first
              : const DurasiOpsi(jam: 0, harga: 0),
        );
        final rincian = <BarisRincian>[
          BarisRincian('${paket.nama} — ${durasi.jam} jam', durasi.harga),
        ];
        num sub = durasi.harga;
        if (pilihan.tambahJam > 0) {
          final extra = pilihan.tambahJam * paket.hargaTambahJam;
          sub += extra;
          rincian.add(BarisRincian(
              'Tambah ${pilihan.tambahJam} jam × Rp${_num(paket.hargaTambahJam)}',
              extra));
        }
        for (final id in pilihan.addOnIds) {
          final a = addOns.where((x) => x.id == id);
          if (a.isEmpty) continue;
          sub += a.first.harga;
          rincian.add(BarisRincian(a.first.nama, a.first.harga));
        }
        return HasilHarga(subtotal: sub, rincian: rincian);

      case TipeHarga.mulaiDari:
        final qty = pilihan.kuantitas <= 0 ? 1 : pilihan.kuantitas;
        final sub = harga * qty;
        return HasilHarga(subtotal: sub, rincian: [
          BarisRincian('$namaLayanan × ${_num(qty)}', sub),
        ]);
    }
  }

  static String _num(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 1);
    return s.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  }

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) =>
      ServiceModel(
        serviceId: id,
        namaLayanan: map['namaLayanan'] as String? ?? '',
        deskripsi: map['deskripsi'] as String? ?? '',
        harga: map['harga'] as num? ?? 0,
        satuan: map['satuan'] as String? ?? '',
        aktif: map['aktif'] as bool? ?? false,
        ikon: map['ikon'] as String? ?? '',
        tipeHarga: TipeHarga.fromWire(map['tipeHarga'] as String?),
        kategori: map['kategori'] as String? ?? 'umum',
        gambar: map['gambar'] as String? ?? '',
        tiers: ((map['tiers'] as List?) ?? [])
            .map((e) => TarifTier.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        paketOpsi: ((map['paketOpsi'] as List?) ?? [])
            .map((e) => PaketOpsi.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        addOns: ((map['addOns'] as List?) ?? [])
            .map((e) => AddOn.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'namaLayanan': namaLayanan,
        'deskripsi': deskripsi,
        'harga': harga,
        'satuan': satuan,
        'aktif': aktif,
        'ikon': ikon,
        'tipeHarga': tipeHarga.wire,
        'kategori': kategori,
        'gambar': gambar,
        'tiers': tiers.map((e) => e.toMap()).toList(),
        'paketOpsi': paketOpsi.map((e) => e.toMap()).toList(),
        'addOns': addOns.map((e) => e.toMap()).toList(),
      };
}
