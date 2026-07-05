import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tk_colors.dart';

/// Skala tipografi Montserrat (design-tokens.md § Tipografi) — satu-satunya
/// font brand, dipakai untuk seluruh hierarki.
class TkTypography {
  TkTypography._();

  static TextTheme textTheme() {
    final base = GoogleFonts.montserratTextTheme();
    return base.copyWith(
      // Display/H1: Bold 28-32
      displaySmall: GoogleFonts.montserrat(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: TkColors.inkSoft,
        letterSpacing: -0.5,
      ),
      // H2 (judul halaman): Bold 22
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: TkColors.inkSoft,
        letterSpacing: -0.3,
      ),
      // H3 (judul kartu/section): SemiBold 18
      titleLarge: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: TkColors.inkSoft,
      ),
      // Body: Regular 14-16
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: TkColors.inkSoft,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TkColors.textSecondary,
      ),
      // Caption/label kecil: Medium 12
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: TkColors.textMuted,
      ),
      // Tombol: SemiBold, Title Case (bukan ALL CAPS)
      labelLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
