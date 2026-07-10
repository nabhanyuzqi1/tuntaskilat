import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// Halaman statis Syarat & Ketentuan + Kebijakan Privasi Tuntaskilat.
/// Ditautkan dari checkbox persetujuan saat pendaftaran (kepatuhan izin).
class SyaratKetentuanScreen extends StatelessWidget {
  const SyaratKetentuanScreen({super.key});

  static const route = '/syarat-ketentuan';

  static const _bagian = <(String, String)>[
    (
      '1. Layanan',
      'Tuntaskilat menghubungkan pelanggan dengan kru/mitra kebersihan di '
          'wilayah Kota Sampit. Ketersediaan layanan bergantung pada jadwal '
          'dan cakupan area.'
    ),
    (
      '2. Pemesanan & Pembayaran',
      'Harga ditampilkan sebelum konfirmasi dan dihitung ulang di sistem saat '
          'pemesanan. Pembayaran tunai, transfer, atau QRIS. Bukti pembayaran '
          'non-tunai wajib diunggah untuk verifikasi.'
    ),
    (
      '3. Pembatalan',
      'Pesanan dapat dibatalkan sebelum kru mulai bekerja. Pengembalian dana '
          'untuk pembayaran yang sudah masuk dikoordinasikan melalui Customer '
          'Service.'
    ),
    (
      '4. Kewajiban Pelanggan',
      'Memberikan alamat dan titik lokasi yang benar, serta akses yang aman '
          'bagi kru saat pengerjaan.'
    ),
    (
      'Kebijakan Privasi',
      'Kami mengumpulkan nama, kontak, alamat, dan lokasi hanya untuk '
          'memproses pesanan dan menghubungkan Anda dengan kru. Data disimpan '
          'di Firebase (Google Cloud) dan tidak dibagikan ke pihak ketiga di '
          'luar keperluan layanan. Anda dapat meminta penghapusan akun melalui '
          'Customer Service.'
    ),
    (
      'Izin Aplikasi',
      'Lokasi (menentukan titik & memantau kedatangan kru), Kamera/Galeri '
          '(mengunggah bukti bayar & foto), Notifikasi (status pesanan). '
          'Izin diminta saat dibutuhkan dan dapat dicabut di pengaturan '
          'perangkat.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
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
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
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
                  Text('Syarat & Kebijakan',
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
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              children: [
                for (final (judul, isi) in _bagian) ...[
                  Text(judul,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 6),
                  Text(isi,
                      style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          height: 1.55,
                          color: TkColors.textSecondary)),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
