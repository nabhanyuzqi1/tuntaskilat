import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

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

class _P1SplashScreenState extends ConsumerState<P1SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  var _sudahNavigasi = false;
  final _minTampil = Future<void>.delayed(const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    // Mulai proses siap → navigasi begitu Firebase + prefs selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) => _coba());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _coba() async {
    // Tunggu Firebase init (non-blocking di main) + minimal durasi branding.
    final siap = await ref.read(firebaseInitProvider.future);
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
    final kurva = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.38, 0.6],
                  colors: [
                    TkColors.primary.withValues(alpha: 0.10),
                    TkColors.primary.withValues(alpha: 0.02),
                    TkColors.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: kurva,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.86, end: 1.0).animate(kurva),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/brand/logo-color.webp',
                                width: 190),
                            const SizedBox(height: 20),
                            Text(
                              'Tuntaskilat',
                              style: GoogleFonts.montserrat(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: TkColors.inkSoft,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Layanan kebersihan on-demand untuk Sampit',
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 44),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: TkColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'PT Tuntas Kilat Group',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: TkColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
