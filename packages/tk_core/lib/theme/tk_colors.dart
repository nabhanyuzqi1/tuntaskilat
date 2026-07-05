import 'package:flutter/material.dart';

/// Token warna dari design-tokens.md (Brand Guidelines PT Tuntas Kilat Group).
/// Hue brand tidak boleh diganti; turunan tint/shade di bawah diambil dari
/// Hi-Fi build final (Canvas.dc.html) agar implementasi pixel-akurat.
class TkColors {
  TkColors._();

  // --- Palet resmi brand ---
  static const primary = Color(0xFF0A874D);
  static const primaryDark = Color(0xFF006542);
  static const accent = Color(0xFFFBCC14);
  static const accentAlt = Color(0xFFF9A22B);
  static const ink = Color(0xFF000000);
  static const surface = Color(0xFFFFFFFF);

  // --- Turunan wajib (design-tokens.md) ---
  /// Hijau ~6% di atas putih — latar kartu non-aktif.
  static const surfaceMuted = Color(0x0F0A874D);
  static const error = Color(0xFFD32F2F);
  static const success = primary;

  // --- Identitas per aplikasi (design-tokens.md § Identitas warna) ---
  static const identityPelanggan = primary;
  static const identityKru = primaryDark;
  static const identityAdmin = Color(0xFF0F5C3E);

  // --- Neutral turunan Hi-Fi build ---
  /// Teks judul/utama pada Hi-Fi (hitam kehijauan).
  static const inkSoft = Color(0xFF10251A);
  static const textSecondary = Color(0xFF5B665F);
  static const textMuted = Color(0xFF8A948E);
  static const textPlaceholder = Color(0xFF9AA49D);
  static const label = Color(0xFF3C463F);
  static const border = Color(0xFFDCE3DE);
  static const divider = Color(0xFFE3E8E4);

  /// Teks di atas lencana kuning accent.
  static const onAccent = Color(0xFF4A3A00);
}

/// Radius standar (design-tokens.md § Bentuk & Elevation).
class TkRadius {
  TkRadius._();

  static const double card = 16;
  static const double sheet = 24;
  static const double button = 12;
}
