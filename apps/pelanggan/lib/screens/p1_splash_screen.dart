import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import 'onboarding_screen.dart';
import 'p2_auth_screen.dart';
import 'p3_beranda_screen.dart';

/// P1 — Pembuka (Splash). Gambar TA 3.14.
/// Branding awal, auto-navigasi ~1.6 detik: install pertama → OB1;
/// sudah login → P3 Beranda; selain itu → P2 Masuk.
class P1SplashScreen extends ConsumerStatefulWidget {
  const P1SplashScreen({super.key});

  static const route = '/p1';

  @override
  ConsumerState<P1SplashScreen> createState() => _P1SplashScreenState();
}

class _P1SplashScreenState extends ConsumerState<P1SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), _navigasi);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _navigasi() async {
    final onboardingSelesai =
        await ref.read(onboardingSelesaiProvider.future);
    final firebaseSiap = ref.read(firebaseSiapProvider);
    final sudahLogin =
        firebaseSiap && ref.read(authServiceProvider).currentUser != null;
    if (!mounted) return;
    final tujuan = !onboardingSelesai
        ? OnboardingScreen.route
        : sudahLogin
            ? P3BerandaScreen.route
            : P2AuthScreen.route;
    Navigator.of(context).pushReplacementNamed(tujuan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient hijau lembut ke putih di sepertiga atas (Hi-Fi P1).
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/brand/logo-color.webp', width: 190),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 44),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(TkColors.primary),
                          const SizedBox(width: 7),
                          _dot(TkColors.primary.withValues(alpha: 0.35)),
                          const SizedBox(width: 7),
                          _dot(TkColors.primary.withValues(alpha: 0.15)),
                        ],
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

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
