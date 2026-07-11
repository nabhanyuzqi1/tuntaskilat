import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
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
      // Draft hilang (layar lama di stack setelah bayar / dibuka langsung) —
      // langsung pulang ke Beranda, jangan tampilkan layar mati.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context)
            .popUntil((r) => r.isFirst || r.settings.name == '/p3');
      });
      return const Scaffold(
        backgroundColor: _latarLembut,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _latarLembut,
      // Kebal terhadap viewInsets basi dari transisi (akar bug "P6 blank"):
      // body TIDAK dikompres keyboard; field voucher berada dalam scroll
      // sehingga tetap dapat dijangkau saat mengetik.
      resizeToAvoidBottomInset: false,
      // SafeArea dipindah KE DALAM header putih agar warna header naik
      // sampai belakang status bar (sinkron system bar ↔ header).
      body: Column(
          children: [
            _header(context),
            Expanded(
              // Bug9 fix: SingleChildScrollView+Column menggantikan ListView
              // — di perangkat tertentu konten sliver P6 tidak ter-paint
              // (body tampak blank) meski dibangun & layout normal.
              // Overscroll stretch M3 (StretchingOverscrollIndicator →
              // ImageFiltered) menghentikan layout scrollable ini di
              // perangkat tertentu (render tree "size: MISSING" tanpa
              // exception) → body P6 tak pernah ter-paint. Matikan efeknya.
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context)
                    .copyWith(overscroll: false),
                child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        for (final r in draft.hasil.rincian) ...[
                          _barisBiaya(r.label, '',
                              PriceBadge.formatRupiah(r.jumlah)),
                          const SizedBox(height: 14),
                        ],
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
                            Text(PriceBadge.formatRupiah(draft.subtotal),
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                          ],
                        ),
                        if (draft.potongan > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Voucher ${draft.voucherKode}',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: TkColors.primary)),
                              Text(
                                  '- ${PriceBadge.formatRupiah(draft.potongan)}',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: TkColors.primary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _KartuVoucher(draft: draft),
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
              ),
            ),
            _sheetTotal(context, draft),
          ],
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
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
          Text('Rincian Tagihan',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
        ]),
          ),
        ),
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

/// Garis putus-putus via CustomPaint — tanpa LayoutBuilder (LayoutBuilder di
/// dalam list P6 ikut tersangka bug paint-blank di perangkat tertentu).
class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1.5,
      width: double.infinity,
      child: CustomPaint(painter: _GarisPutusPainter()),
    );
  }
}

class _GarisPutusPainter extends CustomPainter {
  const _GarisPutusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cat = Paint()
      ..color = TkColors.border
      ..strokeWidth = size.height;
    const dash = 6.0;
    const gap = 4.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dash).clamp(0.0, size.width), y), cat);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kartu input voucher (kode → potongan). Validasi pratinjau di klien;
/// backend memvalidasi ulang (kuota/berlaku) di dalam transaction saat bayar.
class _KartuVoucher extends ConsumerStatefulWidget {
  const _KartuVoucher({required this.draft});
  final DraftPesanan draft;

  @override
  ConsumerState<_KartuVoucher> createState() => _KartuVoucherState();
}

class _KartuVoucherState extends ConsumerState<_KartuVoucher> {
  late final TextEditingController _kode =
      TextEditingController(text: widget.draft.voucherKode);
  bool _loading = false;
  String? _pesan;

  @override
  void dispose() {
    _kode.dispose();
    super.dispose();
  }

  String _alasan(VoucherTolak t) => switch (t) {
        VoucherTolak.tidakAda => 'Kode voucher tidak ditemukan',
        VoucherTolak.nonaktif => 'Voucher tidak aktif',
        VoucherTolak.kadaluarsa => 'Voucher sudah kedaluwarsa',
        VoucherTolak.kuotaHabis => 'Kuota voucher habis',
        VoucherTolak.minimalBelanja =>
          'Minimal belanja belum terpenuhi',
        VoucherTolak.hanyaPenggunaBaru =>
          'Khusus pelanggan baru (belum pernah memesan)',
        VoucherTolak.sudahDipakaiNomor =>
          'Sudah pernah dipakai pada nomor Anda',
      };

  Future<void> _terapkan() async {
    final kode = _kode.text.trim().toUpperCase();
    if (kode.isEmpty) return;
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final v = await ref.read(firestoreServiceProvider).cariVoucher(kode);
      if (v == null) {
        setState(() => _pesan = 'Kode voucher tidak ditemukan');
        return;
      }
      final r = v.hitungPotongan(widget.draft.subtotal, DateTime.now());
      if (r.tolak != null) {
        setState(() => _pesan = _alasan(r.tolak!));
        return;
      }
      ref.read(draftPesananProvider.notifier).state =
          widget.draft.salin(voucherKode: v.kode, voucher: v);
      setState(() => _pesan = null);
    } catch (_) {
      setState(() => _pesan = 'Gagal memeriksa voucher. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _hapus() {
    _kode.clear();
    ref.read(draftPesananProvider.notifier).state =
        widget.draft.salin(hapusVoucher: true);
    setState(() => _pesan = null);
  }

  @override
  Widget build(BuildContext context) {
    final terpasang = widget.draft.voucher != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(TkRadius.card),
        border: Border.all(color: const Color(0x0D0F281C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined,
                size: 18, color: TkColors.primary),
            const SizedBox(width: 8),
            Text('Voucher',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ]),
          const SizedBox(height: 12),
          if (terpasang)
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: TkColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: TkColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.draft.voucherKode} · hemat '
                        '${PriceBadge.formatRupiah(widget.draft.potongan)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TkColors.primaryDark),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(onPressed: _hapus, child: const Text('Hapus')),
            ])
          else
            Row(children: [
              Expanded(
                // Tinggi eksplisit: pada beberapa perangkat, layout intrinsic
                // TextField (isDense) di rantai scroll ini tidak pernah
                // selesai (render tree "size: MISSING") sehingga SELURUH body
                // P6 gagal paint — akar bug "Rincian Tagihan blank".
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: _kode,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft),
                    decoration: const InputDecoration(
                      hintText: 'Masukkan kode voucher',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  // Theme global minimumSize = Size.fromHeight (lebar
                  // INFINITY) — di dalam Row (unbounded) memicu
                  // "BoxConstraints forces an infinite width" dan
                  // menggagalkan layout seluruh body P6 (bug blank).
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(96, 44)),
                  onPressed: _loading ? null : _terapkan,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Terapkan'),
                ),
              ),
            ]),
          if (_pesan != null) ...[
            const SizedBox(height: 8),
            Text(_pesan!,
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TkColors.error)),
          ],
        ],
      ),
    );
  }
}
