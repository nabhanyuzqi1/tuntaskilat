import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/pemesanan_providers.dart';
import '../widgets/masuk_dulu.dart';
import '../widgets/service_icon.dart';
import 'p5_form_pemesanan_screen.dart';

/// P4 — Detail Layanan (Gambar TA 3.15). Hero berikon, nama + kategori,
/// tarif tetap sebagai elemen menonjol kedua (kaidah Kejelasan), chip info,
/// deskripsi, cakupan layanan, dan CTA sticky "Pesan Sekarang" → P5.
class P4DetailLayananScreen extends ConsumerWidget {
  const P4DetailLayananScreen({super.key});

  static const route = '/p4';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layanan =
        ModalRoute.of(context)!.settings.arguments as ServiceModel;
    return Scaffold(
      backgroundColor: TkColors.surface,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
                bottom: 96 + MediaQuery.paddingOf(context).bottom),
            children: [
              _Hero(layanan: layanan),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip('Layanan Kebersihan'),
                    const SizedBox(height: 10),
                    Text(
                      layanan.namaLayanan,
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _KartuTarif(layanan: layanan),
                    const SizedBox(height: 16),
                    const _InfoChips(),
                    const SizedBox(height: 20),
                    _judul('Deskripsi'),
                    const SizedBox(height: 8),
                    Text(
                      layanan.deskripsi.isEmpty
                          ? 'Layanan kebersihan profesional oleh kru '
                              'terverifikasi Tuntaskilat.'
                          : layanan.deskripsi,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: TkColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _judul('Termasuk Layanan'),
                    const SizedBox(height: 10),
                    ..._cakupan.map(_barisCakupan),
                  ],
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

  static const _cakupan = [
    'Dikerjakan kru profesional terverifikasi',
    'Peralatan & cairan pembersih standar',
    'Bergaransi — ulang gratis bila kurang bersih',
  ];

  Widget _chip(String teks) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TkColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TkColors.primaryDark)),
      );

  Widget _judul(String teks) => Text(teks,
      style: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: TkColors.inkSoft));

  Widget _barisCakupan(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.primary.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 13, color: TkColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(teks,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF33403A),
                      height: 1.4)),
            ),
          ],
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F3EC), Color(0xFFF6F8F5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 108,
              height: 108,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: layanan.gambarUrl.isEmpty
                    ? serviceGradient(layanan.kategori)
                    : null,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: TkColors.primary.withValues(alpha: 0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                      spreadRadius: -6),
                ],
              ),
              child: layanan.gambarUrl.isNotEmpty
                  ? Image.network(layanan.gambarUrl,
                      width: 108,
                      height: 108,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                          serviceIcon(layanan.ikon),
                          size: 52,
                          color: TkColors.primary))
                  : Icon(serviceIcon(layanan.ikon),
                      size: 52, color: Colors.white),
            ),
          ),
        ],
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
                Text('Tarif per satuan',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TkColors.textSecondary)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      text: PriceBadge.formatRupiah(layanan.harga),
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
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
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: TkColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Tarif\nTetap',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TkColors.onAccent,
                    height: 1.3)),
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x140F281C)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(ikon, size: 20, color: TkColors.primary),
                const SizedBox(height: 6),
                Text(judul,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 2),
                Text(sub,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 10, color: TkColors.textMuted)),
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

class _BarPesan extends ConsumerWidget {
  const _BarPesan({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      radius: 0,
      opacity: 0.92,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 14, 24, 16 + MediaQuery.viewPaddingOf(context).bottom),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mulai dari',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: TkColors.textMuted)),
                const SizedBox(height: 2),
                Text(PriceBadge.formatRupiah(layanan.harga),
                    style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // MODE TAMU: memesan butuh akun — tawarkan login dulu.
                    if (ref.read(authServiceProvider).currentUser == null) {
                      mintaLogin(context,
                          pesan: 'Masuk atau daftar dulu untuk memesan '
                              '${layanan.namaLayanan}.');
                      return;
                    }
                    // Mulai draft baru untuk layanan ini.
                    ref.read(draftPesananProvider.notifier).state =
                        DraftPesanan(
                            layanan: layanan,
                            pilihan: pilihanDefault(layanan));
                    Navigator.of(context).pushNamed(
                      P5FormPemesananScreen.route,
                      arguments: layanan,
                    );
                  },
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
