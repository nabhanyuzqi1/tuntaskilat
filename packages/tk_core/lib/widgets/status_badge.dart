import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/order_model.dart';
import '../theme/tk_colors.dart';

/// Badge status pesanan — satu warna konsisten per tahap di SEMUA halaman
/// (kaidah Konsistensi, design-tokens.md): kuning = menunggu,
/// hijau = aktif/selesai, merah = ditolak.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OrderStatus status;

  static Color colorOf(OrderStatus status) => switch (status) {
        OrderStatus.dibuat ||
        OrderStatus.menungguPembayaran ||
        OrderStatus.menungguVerifikasi ||
        OrderStatus.menungguPenugasan =>
          TkColors.accentAlt,
        OrderStatus.ditolak => TkColors.error,
        OrderStatus.terverifikasi ||
        OrderStatus.ditugaskan ||
        OrderStatus.dalamPerjalanan ||
        OrderStatus.diproses =>
          TkColors.primary,
        OrderStatus.selesai || OrderStatus.dinilai => TkColors.primaryDark,
      };

  static String labelOf(OrderStatus status) => switch (status) {
        OrderStatus.dibuat => 'Dibuat',
        OrderStatus.menungguPembayaran => 'Menunggu Pembayaran',
        OrderStatus.menungguVerifikasi => 'Menunggu Verifikasi',
        OrderStatus.ditolak => 'Ditolak',
        OrderStatus.terverifikasi => 'Terverifikasi',
        OrderStatus.menungguPenugasan => 'Menunggu Penugasan',
        OrderStatus.ditugaskan => 'Ditugaskan',
        OrderStatus.dalamPerjalanan => 'Dalam Perjalanan',
        OrderStatus.diproses => 'Diproses',
        OrderStatus.selesai => 'Selesai',
        OrderStatus.dinilai => 'Dinilai',
      };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            labelOf(status),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
