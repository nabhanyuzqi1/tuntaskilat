import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/pemesanan_providers.dart';
import '../widgets/service_icon.dart';
import 'p5_form_pemesanan_screen.dart' show JudulHariID;
import 'p7_form_pembayaran_screen.dart';

/// P6 — Rincian Tagihan (Gambar TA 3.15). Baca-saja sebelum bayar:
/// breakdown hargaSatuan × kuantitas tanpa biaya tersembunyi (kaidah
/// Transparansi), ringkasan jadwal & alamat (bisa Edit → kembali ke P5),
/// total besar → P7. Order BELUM dibuat di sini — masih draft.
class P6RincianTagihanScreen extends ConsumerWidget {
  const P6RincianTagihanScreen({super.key});

  static const route = '/p6';
  static const _latarLembut = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftPesananProvider);
    if (draft == null || !draft.lengkap) {
      // Draft hilang (mis. dibuka langsung) — kembali dengan aman.
      return Scaffold(
        backgroundColor: _latarLembut,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Data pesanan tidak lengkap.',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final satuan = satuanSingkat(draft.layanan.satuan);
    return Scaffold(
      backgroundColor: _latarLembut,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _kartu(
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: TkColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(serviceIcon(draft.layanan.ikon),
                            size: 26, color: TkColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(draft.layanan.namaLayanan,
                                style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                            const SizedBox(height: 3),
                            Text('Layanan Kebersihan · Tarif tetap',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: TkColors.textMuted)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rincian Biaya',
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: TkColors.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(children: [
                                const Icon(Icons.verified_user_outlined,
                                    size: 12, color: TkColors.primary),
                                const SizedBox(width: 5),
                                Text('Tanpa biaya tersembunyi',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: TkColors.primaryDark)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 14),
                        _barisBiaya(
                          draft.layanan.namaLayanan,
                          '${PriceBadge.formatRupiah(draft.layanan.harga)} × '
                          '${draft.kuantitas.round()} $satuan',
                          PriceBadge.formatRupiah(draft.total),
                        ),
                        const SizedBox(height: 14),
                        _barisBiaya('Biaya layanan',
                            'Tanpa biaya tambahan', 'Gratis'),
                        const SizedBox(height: 14),
                        const _GarisPutus(),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: TkColors.inkSoft)),
                            Text(PriceBadge.formatRupiah(draft.total),
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _kartu(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Jadwal & Alamat',
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // Kembali ke P5 (masih di stack) untuk mengedit;
                              // draft dipertahankan, tidak membuat order baru.
                              onTap: () => Navigator.of(context).pop(),
                              child: Row(children: [
                                const Icon(Icons.edit_outlined,
                                    size: 14, color: TkColors.primary),
                                const SizedBox(width: 4),
                                Text('Edit',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: TkColors.primary)),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 14),
                        _barisInfo(
                          Icons.calendar_month_outlined,
                          JudulHariID.tanggal(draft.jadwal!),
                          'Slot waktu '
                          '${draft.jadwal!.hour.toString().padLeft(2, '0')}'
                          '.00 WIB',
                        ),
                        const SizedBox(height: 14),
                        _barisInfo(
                          Icons.location_on_outlined,
                          draft.alamat,
                          'Sampit, Kalimantan Tengah',
                        ),
                        if (draft.catatan.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _barisInfo(Icons.sticky_note_2_outlined,
                              draft.catatan, 'Catatan untuk kru'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sheetTotal(context, draft),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        decoration: const BoxDecoration(
          color: TkColors.surface,
          border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
        ),
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
          Text('Rincian Tagihan',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
        ]),
      );

  Widget _kartu({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(color: const Color(0x0D0F281C)),
        ),
        child: child,
      );

  Widget _barisBiaya(String judul, String sub, String nilai) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 3),
                Text(sub,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
          Text(nilai,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TkColors.inkSoft)),
        ],
      );

  Widget _barisInfo(IconData ikon, String judul, String sub) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TkColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, size: 17, color: TkColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 2),
                Text(sub,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
        ],
      );

  Widget _sheetTotal(BuildContext context, DraftPesanan draft) {
    return GlassContainer(
      radius: 0,
      opacity: 0.94,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 16 + MediaQuery.viewPaddingOf(context).bottom),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: TkColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(PriceBadge.formatRupiah(draft.total),
                        style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primary,
                            letterSpacing: -0.5)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Tarif tetap',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TkColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 13),
            TkButton(
              label: 'Lanjut Bayar',
              onPressed: () => Navigator.of(context)
                  .pushNamed(P7FormPembayaranScreen.route),
            ),
          ],
        ),
      ),
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => Row(
        children: [
          for (var i = 0; i < (c.maxWidth / 10).floor(); i++)
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: i.isEven ? TkColors.border : Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }
}
