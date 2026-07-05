import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// P3 — Beranda (Gambar TA 3.14 & 4.1). PLACEHOLDER milestone berikutnya:
/// katalog layanan dari koleksi `services`, Pesan Ulang, bottom nav glass.
/// Layar ini hanya penanda tujuan navigasi setelah autentikasi berhasil.
class P3BerandaScreen extends StatelessWidget {
  const P3BerandaScreen({super.key});

  static const route = '/p3';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/brand/logo-color.png', width: 96),
              const SizedBox(height: 24),
              Text(
                'P3 — Beranda',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Autentikasi berhasil. Katalog layanan dibangun pada '
                'milestone berikutnya.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: TkColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
