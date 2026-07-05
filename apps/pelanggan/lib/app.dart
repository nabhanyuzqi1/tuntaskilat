import 'package:flutter/material.dart';
import 'package:tk_core/tk_core.dart';

import 'screens/onboarding_screen.dart';
import 'screens/p1_splash_screen.dart';
import 'screens/p2_auth_screen.dart';
import 'screens/p3_beranda_screen.dart';

/// Aplikasi Pelanggan — identitas warna hijau utama #0A874D
/// (design-tokens.md § Identitas warna per aplikasi).
class TkPelangganApp extends StatelessWidget {
  const TkPelangganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuntaskilat',
      debugShowCheckedModeBanner: false,
      theme: TkTheme.light(identity: TkColors.identityPelanggan),
      initialRoute: P1SplashScreen.route,
      routes: {
        P1SplashScreen.route: (_) => const P1SplashScreen(),
        OnboardingScreen.route: (_) => const OnboardingScreen(),
        P2AuthScreen.route: (_) => const P2AuthScreen(),
        P3BerandaScreen.route: (_) => const P3BerandaScreen(),
      },
    );
  }
}
