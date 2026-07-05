import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tk_core/tk_core.dart';

import 'screens/onboarding_screen.dart';
import 'screens/p1_splash_screen.dart';
import 'screens/p2_auth_screen.dart';
import 'screens/p3_beranda_screen.dart';
import 'screens/p4_detail_layanan_screen.dart';
import 'screens/p5_form_pemesanan_screen.dart';
import 'screens/p6_rincian_tagihan_screen.dart';
import 'screens/p7_form_pembayaran_screen.dart';

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
      // P1/OB/P2 tidak memakai AppBar, jadi sinkronisasi status bar dengan
      // tema dilakukan di root — bukan per layar.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: TkTheme.systemOverlayStyle,
        child: child!,
      ),
      initialRoute: P1SplashScreen.route,
      routes: {
        P1SplashScreen.route: (_) => const P1SplashScreen(),
        OnboardingScreen.route: (_) => const OnboardingScreen(),
        P2AuthScreen.route: (_) => const P2AuthScreen(),
        P3BerandaScreen.route: (_) => const P3BerandaScreen(),
        P4DetailLayananScreen.route: (_) => const P4DetailLayananScreen(),
        P5FormPemesananScreen.route: (_) => const P5FormPemesananScreen(),
        P6RincianTagihanScreen.route: (_) => const P6RincianTagihanScreen(),
        P7FormPembayaranScreen.route: (_) => const P7FormPembayaranScreen(),
      },
    );
  }
}
