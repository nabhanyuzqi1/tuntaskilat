import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/pembayaran_providers.dart';
import 'p3_beranda_screen.dart';
import 'p8_tracking_screen.dart';

/// P7 — Form Pembayaran (Gambar TA 3.16). Pilih metode (transfer/QRIS/tunai),
/// unggah bukti bayar (wajib non-tunai), lalu state "Menunggu Verifikasi"
/// badge kuning + jam (kaidah Umpan Balik Segera).
class P7FormPembayaranScreen extends ConsumerStatefulWidget {
  const P7FormPembayaranScreen({super.key});

  static const route = '/p7';

  @override
  ConsumerState<P7FormPembayaranScreen> createState() =>
      _P7FormPembayaranScreenState();
}

class _P7FormPembayaranScreenState
    extends ConsumerState<P7FormPembayaranScreen> {
  static const _latarLembut = Color(0xFFF6F8F5);

  MetodeBayar _metode = MetodeBayar.transferBank;
  Uint8List? _bukti;
  String? _namaBukti;
  var _terkirim = false;

  Future<void> _pilihBukti() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes >= 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ukuran berkas maksimal 5MB. Pilih foto lain.')));
      }
      return;
    }
    setState(() {
      _bukti = bytes;
      _namaBukti = file.name;
    });
  }

  Future<void> _konfirmasi(OrderModel order) async {
    final error =
        await ref.read(pembayaranControllerProvider.notifier).konfirmasi(
              order: order,
              metode: _metode,
              buktiBytes: _metode == MetodeBayar.tunai ? null : _bukti,
            );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _terkirim = true);
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    final loading = ref.watch(pembayaranControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: _latarLembut,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: _terkirim
                  ? _MenungguVerifikasi(order: order)
                  : _form(order, loading),
            ),
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
          if (!_terkirim)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: Navigator.of(context).pop,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: TkColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: TkColors.inkSoft),
              ),
            ),
          Text('Pembayaran',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
        ]),
      );

  Widget _form(OrderModel order, bool loading) {
    final butuhBukti = _metode != MetodeBayar.tunai;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _kartuTotal(order),
              const SizedBox(height: 20),
              Text('Metode Pembayaran',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
              const SizedBox(height: 12),
              _kartuMetode(
                MetodeBayar.transferBank,
                Icons.account_balance_outlined,
                TkColors.primary,
                'Transfer Bank',
                'BCA · BRI · Mandiri',
              ),
              const SizedBox(height: 12),
              _kartuMetode(
                MetodeBayar.qris,
                Icons.qr_code_2_rounded,
                TkColors.accentAlt,
                'QRIS',
                'Scan dari semua e-wallet',
              ),
              const SizedBox(height: 12),
              _kartuMetode(
                MetodeBayar.tunai,
                Icons.payments_outlined,
                TkColors.primary,
                'Tunai',
                'Bayar langsung ke kru',
              ),
              if (butuhBukti) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Text('Upload Bukti Transfer',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  Text(' *',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TkColors.error)),
                ]),
                const SizedBox(height: 10),
                _areaUpload(),
              ],
            ],
          ),
        ),
        GlassContainer(
          radius: 0,
          opacity: 0.94,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 22 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x0F0F281C))),
            ),
            child: TkButton(
              label: 'Konfirmasi Pembayaran',
              loading: loading,
              onPressed: () => _konfirmasi(order),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kartuTotal(OrderModel order) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TkRadius.card),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TkColors.primaryDark, TkColors.primary],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total yang harus dibayar',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 3),
                  Text(PriceBadge.formatRupiah(order.totalHarga),
                      style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: TkColors.surface,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.credit_card_outlined,
                  size: 22, color: TkColors.surface),
            ),
          ],
        ),
      );

  Widget _kartuMetode(
    MetodeBayar metode,
    IconData ikon,
    Color warnaIkon,
    String judul,
    String sub,
  ) {
    final aktif = _metode == metode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _metode = metode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: aktif ? TkColors.primary : TkColors.border,
            width: 1.5,
          ),
          boxShadow: aktif
              ? [
                  BoxShadow(
                      color: TkColors.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: warnaIkon.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(ikon, size: 22, color: warnaIkon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: aktif ? TkColors.primary : TkColors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: aktif
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaUpload() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pilihBukti,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
        decoration: BoxDecoration(
          color: TkColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(
            color: _bukti != null
                ? TkColors.primary
                : const Color(0xFFB7C9BF),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (_bukti != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _bukti!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(_namaBukti ?? 'bukti_transfer.jpg',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primaryDark)),
              const SizedBox(height: 3),
              Text('Ketuk untuk mengganti foto',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ] else ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TkColors.primary.withValues(alpha: 0.10),
                ),
                child: const Icon(Icons.photo_camera_outlined,
                    size: 26, color: TkColors.primary),
              ),
              const SizedBox(height: 10),
              Text('Ketuk untuk unggah foto',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primary)),
              const SizedBox(height: 3),
              Text('JPG/PNG maks 5MB',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenungguVerifikasi extends StatelessWidget {
  const _MenungguVerifikasi({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.accent.withValues(alpha: 0.16),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TkColors.accent,
                ),
                child: const Icon(Icons.schedule_rounded,
                    size: 38, color: TkColors.onAccent),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: TkColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TkColors.accentAlt,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('MENUNGGU VERIFIKASI',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8A6A00))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Pembayaran Terkirim',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Pembayaran Anda sedang diverifikasi admin. Kami akan mengirim '
            'notifikasi begitu pesanan dikonfirmasi — estimasi kurang dari '
            '15 menit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 22),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TkColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0F0F281C)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor Pesanan',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: TkColors.textMuted)),
                    const SizedBox(height: 2),
                    Text('#${order.orderId}',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                  ],
                ),
                Text(PriceBadge.formatRupiah(order.totalHarga),
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TkColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          TkButton(
            label: 'Lacak Status Pesanan',
            onPressed: () => Navigator.of(context).pushReplacementNamed(
              P8TrackingScreen.route,
              arguments: order.orderId,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .popUntil(ModalRoute.withName(P3BerandaScreen.route)),
              child: Text('Kembali ke Beranda',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
