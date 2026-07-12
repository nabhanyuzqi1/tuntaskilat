import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../screens/p2_auth_screen.dart';

/// Bottom sheet ajakan login untuk MODE TAMU — muncul saat tamu menyentuh
/// aksi yang butuh akun (pesan, riwayat, notifikasi, profil, chat).
/// Pola aplikasi marketplace umum: jelajah bebas, aksi = login dulu.
Future<void> mintaLogin(BuildContext context, {String? pesan}) =>
    showModalBottomSheet(
      context: context,
      backgroundColor: TkColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.primary.withValues(alpha: 0.10),
              ),
              child: const Icon(Icons.lock_person_outlined,
                  size: 30, color: TkColors.primary),
            ),
            const SizedBox(height: 14),
            Text('Masuk untuk melanjutkan',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft)),
            const SizedBox(height: 6),
            Text(
              pesan ??
                  'Anda sedang menjelajah sebagai tamu. Masuk atau daftar '
                      'dulu untuk memesan layanan dan mengakses akun.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  color: TkColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TkButton(
                label: 'Masuk / Daftar',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      P2AuthScreen.route, (_) => false);
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Nanti saja',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600, color: TkColors.label)),
            ),
          ]),
        ),
      ),
    );

/// Isi tab penuh untuk tamu (Riwayat/Notifikasi/Profil) — bukan blokade
/// dialog, tapi penjelasan ramah + tombol masuk.
class MasukDuluView extends StatelessWidget {
  const MasukDuluView({super.key, required this.judul, required this.pesan});

  final String judul;
  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TkColors.primary.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.lock_person_outlined,
                      size: 42, color: TkColors.primary),
                ),
              ),
              const SizedBox(height: 22),
              Text(judul,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              const SizedBox(height: 8),
              Text(pesan,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: TkColors.textSecondary,
                      height: 1.55)),
              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: TkButton(
                  label: 'Masuk / Daftar',
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                          P2AuthScreen.route, (_) => false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
