import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// Komponen bersama Panel Admin (kartu putih, chip status, header tabel) —
/// grid padat untuk scan cepat (kaidah HCD A2).
class AdminUi {
  AdminUi._();

  static const latar = Color(0xFFF6F8F5);
  static const sidebarBg = Color(0xFF0B3B29);

  static BoxDecoration kartu() => BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(TkRadius.card),
        border: Border.all(color: const Color(0x0D0F281C)),
      );

  static Widget judulTabel(List<(String, int)> kolom) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFBFA),
          border: Border(bottom: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(children: [
          for (final (label, flex) in kolom)
            Expanded(
              flex: flex,
              child: Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TkColors.textMuted,
                      letterSpacing: 0.4)),
            ),
        ]),
      );

  /// Chip status shrink-wrap (lebar mengikuti isi). Di dalam sel tabel
  /// (Expanded) bungkus dengan [chipSel] agar rata kiri & tak melebar penuh;
  /// di dalam Row biasa pakai langsung.
  static Widget chipStatus(String label, Color warna) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: warna)),
          const SizedBox(width: 5),
          Text(label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: warna)),
        ]),
      );

  /// Chip status untuk sel tabel: rata kiri, tak melebar penuh kolom.
  static Widget chipSel(String label, Color warna) => Align(
        alignment: Alignment.centerLeft,
        child: chipStatus(label, warna),
      );

  static Widget topbar({
    required String judul,
    required String subjudul,
    Widget? aksi,
  }) =>
      Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          color: TkColors.surface,
          border: Border(bottom: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 2),
                Text(subjudul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
          ?aksi,
        ]),
      );

  static Widget teksSel(String teks,
          {bool tebal = false, bool coret = false}) =>
      Text(teks,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: tebal ? FontWeight.w700 : FontWeight.w400,
              color: coret
                  ? const Color(0xFFA6AEA9)
                  : tebal
                      ? TkColors.inkSoft
                      : const Color(0xFF33403A),
              decoration: coret ? TextDecoration.lineThrough : null));

  /// Grup status admin (konsisten warna: kuning=menunggu, hijau=aktif/
  /// selesai, merah=ditolak).
  static (String, Color) statusRingkas(OrderStatus s) => switch (s) {
        OrderStatus.dibuat ||
        OrderStatus.menungguPembayaran =>
          ('Belum Bayar', TkColors.accentAlt),
        OrderStatus.menungguVerifikasi => ('Menunggu', TkColors.accentAlt),
        OrderStatus.ditolak => ('Ditolak', TkColors.error),
        OrderStatus.selesai || OrderStatus.dinilai => (
            'Selesai',
            TkColors.primaryDark
          ),
        _ => ('Aktif', TkColors.primary),
      };
}
