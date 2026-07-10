import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import 'providers/app_providers.dart';
import 'screens/a1_login_screen.dart';
import 'screens/admin_shell.dart';

/// Versi Panel Admin (untuk pengecekan update paksa settings/app).
const kVersiAdmin = '1.0.0';

/// Panel Admin — identitas hijau gelap keabuan #0F5C3E untuk konteks
/// web/data-padat (design-tokens.md § Identitas warna per aplikasi).
class TkAdminApp extends StatelessWidget {
  const TkAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tuntaskilat — Panel Admin',
      debugShowCheckedModeBanner: false,
      theme: TkTheme.light(identity: TkColors.identityAdmin),
      builder: (context, child) => MaintenanceGate(
        konfigProvider: konfigAppProvider,
        versi: kVersiAdmin,
        child: child!,
      ),
      home: const _GerbangAdmin(),
      routes: {
        A1LoginScreen.route: (_) => const A1LoginScreen(),
        AdminShell.route: (_) => const AdminShell(),
      },
    );
  }
}

class _GerbangAdmin extends ConsumerWidget {
  const _GerbangAdmin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sudahLogin = ref.watch(firebaseSiapProvider) &&
        ref.watch(authServiceProvider).currentUser != null;
    return sudahLogin ? const AdminShell() : const A1LoginScreen();
  }
}
