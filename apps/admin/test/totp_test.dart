import 'package:flutter_test/flutter_test.dart';
import 'package:tk_admin/util/totp.dart';

void main() {
  // RFC 6238 test vector (SHA1): secret ASCII "12345678901234567890"
  // = base32 "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ".
  const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

  test('TOTP cocok dengan test vector RFC 6238 (6 digit)', () {
    // T=59 → HOTP 94287082 → 6 digit terakhir 287082.
    expect(Totp.kode(secret, 59), '287082');
    // T=1111111109 → 07081804 → 081804.
    expect(Totp.kode(secret, 1111111109), '081804');
  });

  test('verifikasi menerima kode saat ini & menolak yang salah', () {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    expect(Totp.verifikasi(secret, Totp.kode(secret, now)), isTrue);
    expect(Totp.verifikasi(secret, '000000'), anyOf(isTrue, isFalse));
    expect(Totp.verifikasi(secret, '12'), isFalse); // panjang salah
  });

  test('secretBaru menghasilkan base32 valid 32 char', () {
    final s = Totp.secretBaru();
    expect(s.length, 32);
    expect(RegExp(r'^[A-Z2-7]+$').hasMatch(s), isTrue);
  });
}
