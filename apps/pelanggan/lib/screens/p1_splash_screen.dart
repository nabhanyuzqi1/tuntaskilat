import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'onboarding_screen.dart';
import 'p2_auth_screen.dart';
import 'p2b_lengkapi_profil_screen.dart';
import 'p3_beranda_screen.dart';

/// P1 — Pembuka (Splash). Gambar TA 3.14.
/// Branding awal dengan animasi lembut (fade + scale logo); navigasi terjadi
/// segera setelah Firebase siap (minimal ~1 dtk agar branding sempat terlihat)
/// — bukan timer tetap — supaya cold start tidak terasa lama.
class P1SplashScreen extends ConsumerStatefulWidget {
  const P1SplashScreen({super.key});

  static const route = '/p1';

  @override
  ConsumerState<P1SplashScreen> createState() => _P1SplashScreenState();
}

class _P1SplashScreenState extends ConsumerState<P1SplashScreen> {
  var _sudahNavigasi = false;
  // Layar ini hanya jembatan menunggu Firebase/prefs — bukan splash kedua.
  final _minTampil = Future<void>.delayed(const Duration(milliseconds: 250));

  @override
  void initState() {
    super.initState();
    // Navigasi begitu Firebase + prefs selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) => _coba());
  }

  Future<void> _coba() async {
    // Tunggu Firebase init (non-blocking di main) + minimal durasi branding.
    // Timeout defensif: jangan pernah menyandera pengguna di splash —
    // bila init menggantung, lanjut sebagai "belum siap" (fitur mengecek
    // firebaseSiap masing-masing).
    final siap = await ref
        .read(firebaseInitProvider.future)
        .timeout(const Duration(seconds: 8), onTimeout: () => false);
    await _minTampil;
    if (!mounted || _sudahNavigasi) return;
    _sudahNavigasi = true;

    final onboardingSelesai = await ref.read(onboardingSelesaiProvider.future);
    final authUser = ref.read(authServiceProvider).currentUser;
    final sudahLogin = siap && authUser != null;
    
    var profilLengkap = true;
    if (sudahLogin) {
      final profil = await ref.read(authServiceProvider).fetchProfile(authUser.uid);
      if (profil == null || profil.noTelepon.isEmpty || profil.alamat.isEmpty) {
        profilLengkap = false;
      }
    }

    if (!mounted) return;
    
    final tujuan = !onboardingSelesai
        ? OnboardingScreen.route
        : sudahLogin
            ? (profilLengkap ? P3BerandaScreen.route : P2bLengkapiProfilScreen.route)
            : P2AuthScreen.route;
    Navigator.of(context).pushReplacementNamed(tujuan);
  }

  @override
  Widget build(BuildContext context) {
    // Clean logo only — visual identik dengan native splash (logo TK di
    // tengah, latar putih) sehingga transisi native → Flutter mulus dan
    // TIDAK terasa sebagai splash kedua.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/brand/logo_tk.png'),
          width: 120,
        ),
      ),
    );
  }
}
