/// Banner hero Beranda pelanggan — promosi / pengenalan fitur, dikelola
/// admin secara realtime (koleksi `banners`). Tap banner membuka halaman
/// detail berisi gambar + isi teks; bila [tautan] diisi, tombol di detail
/// membuka URL tersebut (mis. landing page / form).
class BannerModel {
  const BannerModel({
    required this.id,
    required this.judul,
    this.subjudul = '',
    this.badge = '',
    this.gambarUrl = '',
    this.isi = '',
    this.tautan = '',
    this.urutan = 0,
    this.aktif = true,
  });

  final String id;
  final String judul;
  final String subjudul;

  /// Label kecil di pojok banner (mis. "PROMO PERDANA").
  final String badge;
  final String gambarUrl;

  /// Isi/penjelasan panjang di halaman detail (teks multi-baris).
  final String isi;

  /// URL opsional — tombol "Selengkapnya" di halaman detail.
  final String tautan;
  final num urutan;
  final bool aktif;

  factory BannerModel.fromMap(String id, Map<String, dynamic> m) =>
      BannerModel(
        id: id,
        judul: m['judul'] as String? ?? '',
        subjudul: m['subjudul'] as String? ?? '',
        badge: m['badge'] as String? ?? '',
        gambarUrl: m['gambarUrl'] as String? ?? '',
        isi: m['isi'] as String? ?? '',
        tautan: m['tautan'] as String? ?? '',
        urutan: m['urutan'] as num? ?? 0,
        aktif: m['aktif'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'judul': judul,
        'subjudul': subjudul,
        'badge': badge,
        'gambarUrl': gambarUrl,
        'isi': isi,
        'tautan': tautan,
        'urutan': urutan,
        'aktif': aktif,
      };
}
