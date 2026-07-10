/// Mode operasional aplikasi (koleksi `settings/app`) — lapisan produk nyata.
enum AppMode {
  normal('normal'),
  maintenance('maintenance'),
  updateWajib('update_wajib');

  const AppMode(this.wire);
  final String wire;

  static AppMode fromWire(String? w) =>
      AppMode.values.firstWhere((m) => m.wire == w, orElse: () => AppMode.normal);
}

/// Konfigurasi runtime aplikasi yang dicek saat boot semua app. Admin bisa
/// mengaktifkan maintenance / memaksa update tanpa rilis ulang.
class KonfigApp {
  const KonfigApp({
    this.mode = AppMode.normal,
    this.pesan = '',
    this.versiMin = '',
    this.urlUpdate = '',
  });

  final AppMode mode;

  /// Pesan yang ditampilkan pada layar maintenance/update ('' → default).
  final String pesan;

  /// Versi minimum yang wajib dipakai (semver "x.y.z"). Kosong = tak dicek.
  final String versiMin;

  /// URL toko/APK untuk tombol "Perbarui" (opsional).
  final String urlUpdate;

  /// Apakah [versiSekarang] di bawah [versiMin] (perlu update paksa).
  bool perluUpdate(String versiSekarang) {
    if (versiMin.trim().isEmpty) return false;
    return _bandingSemver(versiSekarang, versiMin) < 0;
  }

  /// Layar penghalang harus tampil? (maintenance, atau update wajib & versi
  /// klien lebih lama dari [versiMin]).
  bool blokir(String versiSekarang) =>
      mode == AppMode.maintenance ||
      (mode == AppMode.updateWajib && perluUpdate(versiSekarang));

  /// -1 bila `a` lebih lama, 0 bila sama, 1 bila `a` lebih baru. Bagian
  /// non-numerik dianggap 0.
  static int _bandingSemver(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final va = i < pa.length ? (int.tryParse(pa[i].trim()) ?? 0) : 0;
      final vb = i < pb.length ? (int.tryParse(pb[i].trim()) ?? 0) : 0;
      if (va != vb) return va < vb ? -1 : 1;
    }
    return 0;
  }

  factory KonfigApp.fromMap(Map<String, dynamic> m) => KonfigApp(
        mode: AppMode.fromWire(m['mode'] as String?),
        pesan: m['pesan'] as String? ?? '',
        versiMin: m['versiMin'] as String? ?? '',
        urlUpdate: m['urlUpdate'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'mode': mode.wire,
        'pesan': pesan,
        'versiMin': versiMin,
        'urlUpdate': urlUpdate,
      };
}
