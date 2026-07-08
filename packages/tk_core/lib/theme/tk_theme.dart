import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tk_colors.dart';
import 'tk_typography.dart';

/// ThemeData bersama ketiga aplikasi. [identity] membedakan app yang sedang
/// dipakai (Pelanggan #0A874D, Kru #006542, Admin #0F5C3E) — dipakai untuk
/// nav aktif/badge, sementara warna aksi utama tetap hijau brand.
class TkTheme {
  TkTheme._();

  /// Status/navigation bar sinkron dengan latar putih app: transparan +
  /// ikon gelap. Android 15+ (target SDK 35/36) memberlakukan edge-to-edge,
  /// jadi warna bar TIDAK boleh di-set dari sisi native — hanya lewat sini.
  /// Pakai via AppBarTheme (layar ber-AppBar) dan AnnotatedRegion di root
  /// MaterialApp.builder (layar tanpa AppBar seperti P1/OB/P2).
  static const systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: TkColors.surface,
    statusBarIconBrightness: Brightness.dark, // Android: ikon gelap
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData light({Color identity = TkColors.identityPelanggan}) {
    final textTheme = TkTypography.textTheme();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: TkColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TkColors.primary,
        primary: TkColors.primary,
        secondary: identity,
        error: TkColors.error,
        surface: TkColors.surface,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: TkColors.surface,
        foregroundColor: TkColors.inkSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: systemOverlayStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TkColors.primary,
          foregroundColor: TkColors.surface,
          disabledBackgroundColor: TkColors.surfaceMuted,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TkRadius.button),
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TkColors.inkSoft,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: TkColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TkRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TkColors.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TkColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyLarge
            ?.copyWith(fontSize: 15, color: TkColors.textPlaceholder),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TkRadius.button),
          borderSide: const BorderSide(color: TkColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TkRadius.button),
          borderSide: const BorderSide(color: TkColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TkRadius.button),
          borderSide: const BorderSide(color: TkColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TkRadius.button),
          borderSide: const BorderSide(color: TkColors.error, width: 1.5),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: TkColors.error),
      ),
      cardTheme: CardThemeData(
        color: TkColors.surface,
        elevation: 2,
        shadowColor: TkColors.inkSoft.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TkRadius.card),
          side: BorderSide(color: TkColors.inkSoft.withValues(alpha: 0.06)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TkColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TkColors.inkSoft,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: TkColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TkRadius.button),
        ),
      ),
    );
  }
}
