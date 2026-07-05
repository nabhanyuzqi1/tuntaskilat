import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/tk_colors.dart';

/// Lencana harga tetap (P3 Beranda, P4 Detail Layanan) — latar kuning accent,
/// teks tebal. Harga harus jadi elemen paling menonjol kedua setelah nama
/// layanan (kaidah Transparansi).
class PriceBadge extends StatelessWidget {
  const PriceBadge({
    super.key,
    required this.harga,
    required this.satuan,
    this.fontSize = 12,
  });

  /// Harga dalam Rupiah, tampil dengan pemisah ribuan titik.
  final num harga;

  /// Satuan tampilan singkat, mis. "ruang", "jam", "m²".
  final String satuan;
  final double fontSize;

  static String formatRupiah(num nilai) {
    final s = nilai.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: TkColors.accent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text.rich(
        TextSpan(
          text: formatRupiah(harga),
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: TkColors.onAccent,
          ),
          children: [
            TextSpan(
              text: ' /$satuan',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
