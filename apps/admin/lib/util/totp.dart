import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Utilitas TOTP (RFC 6238, Google Authenticator-compatible) untuk 2FA admin.
/// Implementasi mandiri (HMAC-SHA1) agar tak bergantung paket dengan konflik
/// versi timezone.
class Totp {
  static const _b32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Buat rahasia base32 acak (160-bit) untuk provisioning authenticator.
  static String secretBaru() {
    final r = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < 32; i++) {
      sb.write(_b32[r.nextInt(32)]);
    }
    return sb.toString();
  }

  /// URI provisioning (otpauth://) untuk QR yang discan pengguna.
  static String provisioningUri(String secret, String email) {
    final label = Uri.encodeComponent('Tuntaskilat:$email');
    return 'otpauth://totp/$label?secret=$secret&issuer=Tuntaskilat'
        '&algorithm=SHA1&digits=6&period=30';
  }

  /// Kode 6 digit TOTP untuk [secret] pada [detik] Unix (default: sekarang).
  static String kode(String secret, [int? detik]) {
    final t = (detik ?? DateTime.now().millisecondsSinceEpoch ~/ 1000) ~/ 30;
    final key = _base32Decode(secret);
    final msg = Uint8List(8);
    var v = t;
    for (var i = 7; i >= 0; i--) {
      msg[i] = v & 0xff;
      v >>= 8;
    }
    final hmac = Hmac(sha1, key).convert(msg).bytes;
    final offset = hmac[hmac.length - 1] & 0x0f;
    final bin = ((hmac[offset] & 0x7f) << 24) |
        ((hmac[offset + 1] & 0xff) << 16) |
        ((hmac[offset + 2] & 0xff) << 8) |
        (hmac[offset + 3] & 0xff);
    return (bin % 1000000).toString().padLeft(6, '0');
  }

  /// Verifikasi [input] terhadap [secret], toleransi ±1 langkah (30 dtk).
  static bool verifikasi(String secret, String input) {
    final k = input.trim();
    if (k.length != 6) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final geser in [0, -30, 30]) {
      if (kode(secret, now + geser) == k) return true;
    }
    return false;
  }

  static Uint8List _base32Decode(String s) {
    final clean = s.toUpperCase().replaceAll('=', '').replaceAll(' ', '');
    var bits = 0;
    var value = 0;
    final out = <int>[];
    for (final ch in clean.split('')) {
      final idx = _b32.indexOf(ch);
      if (idx < 0) continue;
      value = (value << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        out.add((value >> (bits - 8)) & 0xff);
        bits -= 8;
      }
    }
    return Uint8List.fromList(out);
  }
}
