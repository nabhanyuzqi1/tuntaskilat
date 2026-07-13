import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'p18_cs_ai_screen.dart';

/// Nomor Customer Service PT Tuntas Kilat Group.
/// PLACEHOLDER — ganti dengan nomor resmi sebelum rilis.
const nomorCustomerService = '6282100000000';

/// P14 — Bantuan & Dukungan. Accordion 4 FAQ (pembatalan, estimasi kru,
/// metode bayar, komplain) + kontak CS 07.00–21.00 WIB (kaidah
/// Aksesibilitas informasi — bantuan mandiri sebelum eskalasi).
class P14BantuanScreen extends StatelessWidget {
  const P14BantuanScreen({super.key});

  static const route = '/p14';

  static const _faq = [
    (
      'Bagaimana cara membatalkan pesanan?',
      'Buka Riwayat Pesanan, pilih pesanan berstatus "Menunggu" atau '
          '"Dikonfirmasi", lalu hubungi Customer Service untuk pembatalan. '
          'Pesanan yang kru-nya sudah dalam perjalanan tidak dapat '
          'dibatalkan.',
    ),
    (
      'Berapa lama estimasi kru datang?',
      'Kru berangkat sesuai slot waktu yang Anda pilih. Posisi dan '
          'estimasi tiba dapat dipantau real-time di halaman Status '
          'Pesanan setelah kru ditugaskan.',
    ),
    (
      'Metode pembayaran apa saja yang didukung?',
      'Transfer bank (BCA, BRI, Mandiri), QRIS dari semua e-wallet, dan '
          'tunai langsung ke kru. Pembayaran non-tunai diverifikasi admin '
          'dengan estimasi kurang dari 15 menit.',
    ),
    (
      'Bagaimana jika hasil kerja tidak memuaskan?',
      'Layanan kami bergaransi. Hubungi Customer Service maksimal 1×24 '
          'jam setelah pengerjaan selesai — kru kami akan mengulang '
          'pembersihan area terkait tanpa biaya.',
    ),
  ];

  Future<void> _luncurkan(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tidak dapat membuka aplikasi terkait.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      // Header putih membungkus SafeArea — warna naik sampai belakang
      // status bar (sinkron system bar ↔ header).
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: TkColors.surface,
                border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Row(children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: Navigator.of(context).pop,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TkColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: TkColors.inkSoft),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Bantuan & Dukungan',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
              ]),
              ),
            ),
          ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  // Entry Asisten AI — jawaban instan pertanyaan umum.
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TkRadius.card),
                      onTap: () => Navigator.of(context)
                          .pushNamed(P18CsAiScreen.route),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(TkRadius.card),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [TkColors.primaryDark, TkColors.primary],
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tanya Asisten AI',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(
                                    'Jawaban instan soal layanan, harga & '
                                    'cara pesan',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.85))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('PERTANYAAN UMUM',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TkColors.textMuted,
                            letterSpacing: 0.3)),
                  ),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: TkColors.surface,
                      borderRadius: BorderRadius.circular(TkRadius.card),
                      border: Border.all(color: const Color(0x0D0F281C)),
                    ),
                    child: Column(children: [
                      for (var i = 0; i < _faq.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(),
                          ),
                        Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: i == 0,
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            iconColor: TkColors.textMuted,
                            collapsedIconColor: TkColors.textMuted,
                            title: Text(_faq[i].$1,
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(_faq[i].$2,
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color: TkColors.textSecondary,
                                        height: 1.55)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TkRadius.card),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [TkColors.primaryDark, TkColors.primary],
                      ),
                    ),
                    child: Column(children: [
                      Text('Butuh bantuan lebih lanjut?',
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TkColors.surface)),
                      const SizedBox(height: 6),
                      Text('Tim kami siap membantu setiap hari, '
                          '07.00–21.00 WIB.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5)),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _luncurkan(
                              context,
                              Uri.parse(
                                  'https://wa.me/$nomorCustomerService')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TkColors.surface,
                            foregroundColor: TkColors.primary,
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 17),
                          label: Text('Chat dengan Customer Service',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _luncurkan(context,
                              Uri(scheme: 'tel', path: '+$nomorCustomerService')),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color:
                                    Colors.white.withValues(alpha: 0.4),
                                width: 1.5),
                          ),
                          icon: const Icon(Icons.call_rounded,
                              size: 16, color: TkColors.surface),
                          label: Text('Telepon Customer Service',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.surface)),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
