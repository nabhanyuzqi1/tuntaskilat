import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

void main() {
  group('Skenario Black-Box #2 — karakter ilegal ditolak validator klien', () {
    test('teks bebas normal lolos', () {
      expect(Validators.teksBebas('Fokus di dapur dan kamar mandi, ya.'), isNull);
      expect(Validators.teksBebas(''), isNull);
      expect(Validators.teksBebas(null), isNull);
    });

    test('karakter berbahaya ditolak', () {
      for (final jahat in [
        '<script>alert(1)</script>',
        'catatan {inject}',
        r'harga $lebih murah',
        'a;b\\c',
        'tag [x]',
        '`backtick`',
        'kontrol\x01karakter',
      ]) {
        expect(Validators.teksBebas(jahat), isNotNull, reason: 'harus menolak: $jahat');
      }
    });
  });

  group('Validasi form P2 (kaidah Pencegahan Kesalahan)', () {
    test('email', () {
      expect(Validators.email('budi.gmail.com'), 'Format email tidak valid');
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('budi@gmail.com'), isNull);
    });

    test('no telepon format 08xx', () {
      expect(Validators.noTelepon('081234567890'), isNull);
      expect(Validators.noTelepon('62812345678'), isNotNull);
      expect(Validators.noTelepon('0812'), isNotNull);
      expect(Validators.noTelepon('08123abc456'), isNotNull);
    });

    test('kata sandi min 8 + konfirmasi cocok', () {
      expect(Validators.kataSandi('1234567'), isNotNull);
      expect(Validators.kataSandi('12345678'), isNull);
      expect(Validators.konfirmasiKataSandi('beda', 'sandi123'), isNotNull);
      expect(Validators.konfirmasiKataSandi('sandi123', 'sandi123'), isNull);
    });
  });

  group('Skenario Black-Box #8 — batas wilayah layanan Kota Sampit', () {
    test('pusat Sampit di dalam wilayah', () {
      expect(Validators.isDalamWilayahSampit(-2.5329, 112.9508), isTrue);
    });

    test('luar wilayah ditolak (Out of Delivery Range)', () {
      expect(Validators.isDalamWilayahSampit(-6.2, 106.8), isFalse); // Jakarta
      expect(Validators.isDalamWilayahSampit(-1.68, 113.38), isFalse); // P. Raya
      expect(Validators.isDalamWilayahSampit(-2.5, 110.0), isFalse);
    });
  });
}
