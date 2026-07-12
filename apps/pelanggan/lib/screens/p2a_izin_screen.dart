import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';

import 'p3_beranda_screen.dart';

/// P2a — Layar Izin. Digunakan untuk meminta izin krusial (Lokasi) secara
/// transparan sebelum masuk Beranda.
class P2aIzinScreen extends ConsumerStatefulWidget {
  const P2aIzinScreen({super.key});

  static const route = '/p2a';

  @override
  ConsumerState<P2aIzinScreen> createState() => _P2aIzinScreenState();
}

class _P2aIzinScreenState extends ConsumerState<P2aIzinScreen> {
  var _memintaIzin = false;
  var _mengecek = true;

  @override
  void initState() {
    super.initState();
    _cekIzinAwal();
  }

  static const _kunciSudahLewat = 'izin_sudah_ditangani_v1';

  Future<void> _cekIzinAwal() async {
    // JANGAN cek Permission.storage: di Android 13+ izin itu SELALU denied
    // (deprecated, image_picker pakai Photo Picker tanpa izin) sehingga
    // layar ini muncul lagi setiap relog walau izin sudah diberikan.
    // Cukup lokasi+kamera, ATAU pengguna sudah pernah menangani layar ini
    // (flag lokal) — sistem tetap meminta izin on-demand saat fitur dipakai.
    final prefs = await SharedPreferences.getInstance();
    final sudahDitangani = prefs.getBool(_kunciSudahLewat) ?? false;
    final lokasi = await Permission.location.isGranted;
    final kamera = await Permission.camera.isGranted;

    if (sudahDitangani || (lokasi && kamera)) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(P3BerandaScreen.route);
    } else {
      if (mounted) setState(() => _mengecek = false);
    }
  }

  Future<void> _tandaiSudah() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kunciSudahLewat, true);
  }

  Future<void> _mintaIzin() async {
    setState(() => _memintaIzin = true);

    await [Permission.location, Permission.camera].request();
    await _tandaiSudah();

    // Lokasi ditolak pun tetap lanjut ke P3 — peta meminta ulang on-demand.
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(P3BerandaScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    if (_mengecek) {
      return const Scaffold(
        backgroundColor: TkColors.surface,
        body: Center(child: CircularProgressIndicator(color: TkColors.primary)),
      );
    }
    
    return Scaffold(
      backgroundColor: TkColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: TkColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded,
                      size: 60, color: TkColors.primary),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Izin Aplikasi',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TkColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Untuk memberikan pengalaman pemesanan jasa terbaik, Tuntaskilat membutuhkan akses lokasi (untuk titik layanan), dan kamera/penyimpanan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TkColors.textPlaceholder,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              TkButton(
                label: 'Berikan Izin',
                loading: _memintaIzin,
                onPressed: _mintaIzin,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _tandaiSudah();
                  if (!context.mounted) return;
                  Navigator.of(context)
                      .pushReplacementNamed(P3BerandaScreen.route);
                },
                child: Text(
                  'Lewati Sementara',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: TkColors.label,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
