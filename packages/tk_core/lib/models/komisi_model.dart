import 'wage.dart';

/// Konfigurasi komisi platform (koleksi `settings/komisi`) — lapisan produk
/// nyata (di luar naskah TA). Komisi global + override opsional per layanan.
/// Dibaca backend & klien; angka uang tetap dihitung ulang di backend.
class KonfigKomisi {
  const KonfigKomisi({
    this.komisiPersen = 20,
    this.perLayanan = const {},
  });

  /// Komisi default (0–100) bila layanan tak punya override.
  final num komisiPersen;

  /// Override per serviceId → persen (0–100).
  final Map<String, num> perLayanan;

  /// Persen komisi efektif untuk sebuah layanan (override → global).
  num persenUntuk(String? serviceId) {
    if (serviceId != null && perLayanan.containsKey(serviceId)) {
      return _klem(perLayanan[serviceId]!);
    }
    return _klem(komisiPersen);
  }

  /// KonfigUpah (dipakai `bagiUpah`) untuk layanan tertentu.
  KonfigUpah upahUntuk(String? serviceId) =>
      KonfigUpah(komisiPersen: persenUntuk(serviceId));

  static num _klem(num v) => v < 0
      ? 0
      : v > 100
          ? 100
          : v;

  factory KonfigKomisi.fromMap(Map<String, dynamic> m) => KonfigKomisi(
        komisiPersen: m['komisiPersen'] as num? ?? 20,
        perLayanan: ((m['perLayanan'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num?) ?? 0),
        ),
      );

  Map<String, dynamic> toMap() => {
        'komisiPersen': komisiPersen,
        'perLayanan': perLayanan.map((k, v) => MapEntry(k, v)),
      };

  KonfigKomisi copyWith({num? komisiPersen, Map<String, num>? perLayanan}) =>
      KonfigKomisi(
        komisiPersen: komisiPersen ?? this.komisiPersen,
        perLayanan: perLayanan ?? this.perLayanan,
      );
}
