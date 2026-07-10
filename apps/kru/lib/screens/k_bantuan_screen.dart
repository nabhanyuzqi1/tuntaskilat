import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Nomor kantor/CS PT Tuntas Kilat Group untuk kru.
/// PLACEHOLDER — ganti dengan nomor resmi sebelum rilis.
const nomorKantorTuntaskilat = '6282100000000';

/// Bantuan & Dukungan Portal Kru — kontak kantor untuk kendala penugasan,
/// akun, atau pembayaran (entry dari K6).
class KBantuanScreen extends StatelessWidget {
  const KBantuanScreen({super.key});

  static const route = '/k-bantuan';

  static const _faq = [
    (
      'Bagaimana jika pelanggan tidak ada di lokasi?',
      'Hubungi pelanggan lewat tombol telepon di halaman Detail '
          'Penugasan. Jika tetap tidak dapat dihubungi dalam 15 menit, '
          'laporkan ke kantor sebelum meninggalkan lokasi.',
    ),
    (
      'Kapan pendapatan tugas dibayarkan?',
      'Pendapatan tercatat otomatis setelah laporan kerja terkirim dan '
          'direkap kantor. Jadwal pencairan mengikuti kebijakan '
          'operasional PT Tuntas Kilat Group.',
    ),
    (
      'Foto laporan gagal terunggah, bagaimana?',
      'Pastikan koneksi internet aktif lalu kirim ulang laporan — foto '
          'tersimpan di perangkat sampai berhasil terkirim. Jika masih '
          'gagal, hubungi kantor.',
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
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('PERTANYAAN UMUM KRU',
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
                      Text('Butuh bantuan kantor?',
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TkColors.surface)),
                      const SizedBox(height: 6),
                      Text('Tim operasional siap membantu setiap hari, '
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
                                  'https://wa.me/$nomorKantorTuntaskilat')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TkColors.surface,
                            foregroundColor: TkColors.primary,
                            elevation: 0,
                          ),
                          icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 17),
                          label: Text('Chat Kantor',
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
                          onPressed: () => _luncurkan(
                              context,
                              Uri(
                                  scheme: 'tel',
                                  path: '+$nomorKantorTuntaskilat')),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5),
                          ),
                          icon: const Icon(Icons.call_rounded,
                              size: 16, color: TkColors.surface),
                          label: Text('Telepon Kantor',
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
