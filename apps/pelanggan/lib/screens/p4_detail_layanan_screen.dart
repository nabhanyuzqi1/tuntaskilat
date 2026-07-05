import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../widgets/service_icon.dart';
import 'p5_form_pemesanan_screen.dart';

/// P4 — Detail Layanan (Gambar TA 3.15). Deskripsi lengkap + tarif tetap per
/// satuan sebagai elemen kedua paling menonjol (kaidah Kejelasan), chip info,
/// CTA sticky "Pesan Sekarang" → P5.
class P4DetailLayananScreen extends StatelessWidget {
  const P4DetailLayananScreen({super.key});

  static const route = '/p4';

  @override
  Widget build(BuildContext context) {
    final layanan =
        ModalRoute.of(context)!.settings.arguments as ServiceModel;
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 112),
            children: [
              _Hero(layanan: layanan),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  decoration: const BoxDecoration(
                    color: TkColors.surface,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: TkColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Layanan Kebersihan',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TkColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        layanan.namaLayanan,
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _KartuTarif(layanan: layanan),
                      const SizedBox(height: 18),
                      const _InfoChips(),
                      const SizedBox(height: 18),
                      Text(
                        'Deskripsi',
                        style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        layanan.deskripsi,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: TkColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const _TombolKembali(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BarPesan(layanan: layanan),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      color: TkColors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(
        serviceIcon(layanan.ikon),
        size: 76,
        color: TkColors.primary,
      ),
    );
  }
}

class _TombolKembali extends StatelessWidget {
  const _TombolKembali();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: Navigator.of(context).pop,
          child: GlassContainer(
            radius: 13,
            opacity: 0.85,
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: TkColors.inkSoft),
            ),
          ),
        ),
      ),
    );
  }
}

class _KartuTarif extends StatelessWidget {
  const _KartuTarif({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: TkColors.surfaceMuted,
        borderRadius: BorderRadius.circular(TkRadius.card),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarif per satuan',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TkColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    text: PriceBadge.formatRupiah(layanan.harga),
                    style: GoogleFonts.montserrat(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: TkColors.primary,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: ' /${satuanSingkat(layanan.satuan)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: TkColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: TkColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tarif\nTetap',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: TkColors.onAccent,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChips extends StatelessWidget {
  const _InfoChips();

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData ikon, String judul, String sub) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x140F281C)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(ikon, size: 20, color: TkColors.primary),
                const SizedBox(height: 6),
                Text(
                  judul,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: TkColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        chip(Icons.schedule_rounded, '± 45 mnt', 'per satuan'),
        const SizedBox(width: 10),
        chip(Icons.verified_user_outlined, 'Bergaransi', 'ulang gratis'),
        const SizedBox(width: 10),
        chip(Icons.how_to_reg_outlined, 'Terverifikasi', 'kru terlatih'),
      ],
    );
  }
}

class _BarPesan extends StatelessWidget {
  const _BarPesan({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 0,
      opacity: 0.92,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 14, 24, 22 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mulai dari',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TkColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PriceBadge.formatRupiah(layanan.harga),
                  style: GoogleFonts.montserrat(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    P5FormPemesananScreen.route,
                    arguments: layanan,
                  ),
                  icon: const Text('Pesan Sekarang'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
