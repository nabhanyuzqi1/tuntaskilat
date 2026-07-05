/// Validator input bersama — penerapan kaidah Pencegahan Kesalahan dan
/// skenario Black-Box #2 (karakter ilegal) & #8 (batas wilayah Sampit).
/// Semua pesan error mengikuti tone of voice brand: profesional, ramah,
/// berorientasi solusi.
class Validators {
  Validators._();

  static final _emailRe =
      RegExp(r'^[\w.\-+]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+$');
  static final _teleponRe = RegExp(r'^08\d{8,12}$');

  /// Karakter yang ditolak pada teks bebas (catatan, komentar) — skenario #2.
  static final _karakterIlegalRe = RegExp(r'[<>{}\[\]$\\`;]|[\x00-\x1F]');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email wajib diisi.';
    if (!_emailRe.hasMatch(v)) return 'Format email tidak valid';
    return null;
  }

  static String? namaLengkap(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nama lengkap wajib diisi.';
    if (v.length < 3) return 'Nama minimal 3 karakter.';
    if (_karakterIlegalRe.hasMatch(v)) {
      return 'Nama mengandung karakter yang tidak diizinkan.';
    }
    return null;
  }

  static String? noTelepon(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'No. telepon wajib diisi.';
    if (!_teleponRe.hasMatch(v)) {
      return 'Gunakan format 08xx (10-14 digit angka).';
    }
    return null;
  }

  static String? kataSandi(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi.';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter.';
    return null;
  }

  static String? konfirmasiKataSandi(String? value, String kataSandi) {
    if (value == null || value.isEmpty) return 'Ulangi kata sandi Anda.';
    if (value != kataSandi) return 'Konfirmasi kata sandi tidak cocok.';
    return null;
  }

  /// Teks bebas opsional (catatan pemesanan, komentar ulasan) — skenario #2.
  static String? teksBebas(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return null;
    if (_karakterIlegalRe.hasMatch(v)) {
      return 'Teks mengandung karakter yang tidak diizinkan.';
    }
    return null;
  }

  /// Bounding box area layanan Kota Sampit, Kalimantan Tengah (skenario #8).
  /// Pusat kota ≈ (-2.5329, 112.9508); batas dibuat longgar mencakup wilayah
  /// perkotaan — sesuaikan bersama manajemen bila area layanan berubah.
  static const sampitLatMin = -2.75;
  static const sampitLatMax = -2.35;
  static const sampitLngMin = 112.75;
  static const sampitLngMax = 113.15;

  static bool isDalamWilayahSampit(double latitude, double longitude) =>
      latitude >= sampitLatMin &&
      latitude <= sampitLatMax &&
      longitude >= sampitLngMin &&
      longitude <= sampitLngMax;
}
