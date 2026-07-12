import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'providers/app_providers.dart';
import 'screens/k1_login_screen.dart';
import 'screens/k2a_izin_screen.dart';
import 'screens/k3_detail_penugasan_screen.dart';
import 'screens/k4_laporan_kerja_screen.dart';
import 'screens/k_bantuan_screen.dart';
import 'screens/k_rekening_screen.dart';
import 'screens/k_ubah_kata_sandi_screen.dart';
import 'screens/kru_shell.dart';
import 'screens/onboarding_kru_screen.dart';
import 'screens/k7_chat_screen.dart';

/// Versi Portal Kru (untuk pengecekan update paksa settings/app).
const kVersiKru = '1.0.0';

/// Portal Kru — identitas warna hijau tua #006542
/// (design-tokens.md § Identitas warna per aplikasi).
class TkKruApp extends StatelessWidget {
  const TkKruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuntaskilat Kru',
      debugShowCheckedModeBanner: false,
      theme: TkTheme.light(identity: TkColors.identityKru),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: TkTheme.systemOverlayStyle,
        child: MaintenanceGate(
          konfigProvider: konfigAppProvider,
          versi: kVersiKru,
          child: child!,
        ),
      ),
      home: const _GerbangAwal(),
      routes: {
        OnboardingKruScreen.route: (_) => const OnboardingKruScreen(),
        K1LoginScreen.route: (_) => const K1LoginScreen(),
        K2aIzinScreen.route: (_) => const K2aIzinScreen(),
        KruShell.route: (_) => const KruShell(),
        K3DetailPenugasanScreen.route: (_) => const K3DetailPenugasanScreen(),
        K4LaporanKerjaScreen.route: (_) => const K4LaporanKerjaScreen(),
        KUbahKataSandiScreen.route: (_) => const KUbahKataSandiScreen(),
        KBantuanScreen.route: (_) => const KBantuanScreen(),
        KRekeningScreen.route: (_) => const KRekeningScreen(),
        K7ChatScreen.route: (_) => const K7ChatScreen(),
      },
    );
  }
}

/// Entry Portal Kru (page-inventory § Arsitektur): Onboarding Kru 1-3 →
/// Login Kru; sesi aktif langsung ke K2.
class _GerbangAwal extends ConsumerWidget {
  const _GerbangAwal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingKruSelesaiProvider);
    return onboarding.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: TkColors.primaryDark),
        ),
      ),
      error: (_, _) => const K1LoginScreen(),
      data: (selesai) {
        if (!selesai) return const OnboardingKruScreen();
        final sudahLogin = ref.watch(firebaseSiapProvider) &&
            ref.watch(authServiceProvider).currentUser != null;
        return sudahLogin ? const K2aIzinScreen() : const K1LoginScreen();
      },
    );
  }
}
