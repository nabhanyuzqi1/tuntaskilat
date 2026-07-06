import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';

/// K4 — Form Laporan Kerja (Gambar TA 3.17 & 4.4). Foto sebelum & sesudah
/// keduanya wajib (dokumentasi objektif) → Firebase Storage →
/// `orders.fotoSebelum/fotoSesudah` + status `selesai`.
class K4LaporanKerjaScreen extends ConsumerStatefulWidget {
  const K4LaporanKerjaScreen({super.key});

  static const route = '/k4';

  @override
  ConsumerState<K4LaporanKerjaScreen> createState() =>
      _K4LaporanKerjaScreenState();
}

class _K4LaporanKerjaScreenState extends ConsumerState<K4LaporanKerjaScreen> {
  Uint8List? _fotoSebelum;
  Uint8List? _fotoSesudah;
  var _mengirim = false;
  var _terkirim = false;

  Future<void> _ambilFoto(bool sebelum) async {
    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      // Perangkat tanpa kamera (mis. emulator tertentu) → galeri.
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      if (sebelum) {
        _fotoSebelum = bytes;
      } else {
        _fotoSesudah = bytes;
      }
    });
  }

  Future<void> _kirim(OrderModel order) async {
    if (_fotoSebelum == null || _fotoSesudah == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Foto sebelum dan sesudah keduanya wajib diunggah.')));
      return;
    }
    setState(() => _mengirim = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser!.uid;
      final storage = ref.read(storageServiceProvider);
      final urlSebelum = await storage.uploadFotoLaporan(
        cleanerId: uid,
        orderId: order.orderId,
        sebelum: true,
        index: 0,
        bytes: _fotoSebelum!,
      );
      final urlSesudah = await storage.uploadFotoLaporan(
        cleanerId: uid,
        orderId: order.orderId,
        sebelum: false,
        index: 0,
        bytes: _fotoSesudah!,
      );
      await ref.read(firestoreServiceProvider).submitLaporanKerja(
            orderId: order.orderId,
            fotoSebelum: [urlSebelum],
            fotoSesudah: [urlSesudah],
          );
      if (mounted) setState(() => _terkirim = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Laporan belum terkirim. Periksa koneksi Anda lalu coba '
                'lagi.')));
      }
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _terkirim ? _sukses(order) : _form(order),
      ),
    );
  }

  Widget _form(OrderModel order) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        decoration: const BoxDecoration(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Laporan Kerja',
                  style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              Text('${order.namaLayanan} · #${order.orderId}',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TkColors.primary)),
            ],
          ),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          children: [
            Row(children: [
              Text('Bukti Foto',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
              Text(' *',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TkColors.error)),
              const SizedBox(width: 6),
              Text('keduanya wajib',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _slotFoto('Foto Sebelum', _fotoSebelum, true),
              const SizedBox(width: 12),
              _slotFoto('Foto Sesudah', _fotoSesudah, false),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 58,
              child: TkButton(
                label: 'Kirim Laporan',
                loading: _mengirim,
                onPressed: () => _kirim(order),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _slotFoto(String label, Uint8List? bytes, bool sebelum) {
    return Expanded(
      child: Column(children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _ambilFoto(sebelum),
          child: Container(
            height: 168,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: TkColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(TkRadius.card),
              border: bytes == null
                  ? Border.all(color: const Color(0xFFB7C9BF), width: 2)
                  : Border.all(color: TkColors.primary, width: 2),
            ),
            child: bytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TkColors.primary.withValues(alpha: 0.10),
                        ),
                        child: const Icon(Icons.photo_camera_outlined,
                            size: 24, color: TkColors.primary),
                      ),
                      const SizedBox(height: 10),
                      Text('Ambil foto',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TkColors.primary)),
                    ],
                  )
                : Stack(fit: StackFit.expand, children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TkColors.primary),
                        child: const Icon(Icons.check_rounded,
                            size: 15, color: TkColors.surface),
                      ),
                    ),
                  ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF33403A))),
      ]),
    );
  }

  Widget _sukses(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TkColors.primary,
                  boxShadow: [
                    BoxShadow(
                        color: TkColors.primary.withValues(alpha: 0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 42, color: TkColors.surface),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Laporan Terkirim',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Tugas ${order.namaLayanan} telah selesai dan laporan dikirim '
            'ke admin. Pelanggan akan diminta memberi ulasan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 22),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pendapatan tugas',
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
                Text('+ ${PriceBadge.formatRupiah(order.totalHarga)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: TkColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          TkButton(
            label: 'Kembali ke Daftar Tugas',
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
