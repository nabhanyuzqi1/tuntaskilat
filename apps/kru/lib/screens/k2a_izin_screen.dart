import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tk_core/tk_core.dart';

import 'kru_shell.dart';

/// K2a — Layar Izin Kru. Meminta izin Lokasi (sangat krusial untuk streaming K3)
/// dan Kamera (untuk K4 Laporan Kerja).
class K2aIzinScreen extends ConsumerStatefulWidget {
  const K2aIzinScreen({super.key});

  static const route = '/k2a';

  @override
  ConsumerState<K2aIzinScreen> createState() => _K2aIzinScreenState();
}

class _K2aIzinScreenState extends ConsumerState<K2aIzinScreen> {
  var _memintaIzin = false;
  var _mengecek = true;

  @override
  void initState() {
    super.initState();
    _cekIzinAwal();
  }

  Future<void> _cekIzinAwal() async {
    final lokasi = await Permission.location.isGranted;
    final kamera = await Permission.camera.isGranted;
    
    if (lokasi && kamera) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(KruShell.route);
    } else {
      if (mounted) setState(() => _mengecek = false);
    }
  }

  Future<void> _mintaIzin() async {
    setState(() => _memintaIzin = true);
    
    // Kru wajib lokasi dan kamera
    await [
      Permission.location,
      Permission.camera,
    ].request();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(KruShell.route);
  }

  @override
  Widget build(BuildContext context) {
    if (_mengecek) {
      return const Scaffold(
        backgroundColor: TkColors.surface,
        body: Center(child: CircularProgressIndicator(color: TkColors.primaryDark)),
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
                  child: const Icon(Icons.share_location_rounded,
                      size: 60, color: TkColors.primaryDark),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Izin Kerja Kru',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TkColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi Kru membutuhkan akses Lokasi (untuk pelacakan pelanggan saat perjalanan) dan Kamera (untuk laporan sebelum/sesudah kerja).',
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
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(KruShell.route);
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
