import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_config_model.dart';
import '../theme/tk_colors.dart';
import 'tk_button.dart';

/// Gerbang maintenance/update di root aplikasi. Watch [konfigProvider]
/// (settings/app); bila [KonfigApp.blokir] untuk [versi], tampilkan
/// [MaintenanceScreen] menggantikan [child]. Dipakai identik oleh 3 app.
class MaintenanceGate extends ConsumerWidget {
  const MaintenanceGate({
    super.key,
    required this.konfigProvider,
    required this.versi,
    required this.child,
    this.onUpdate,
  });

  final ProviderListenable<AsyncValue<KonfigApp>> konfigProvider;
  final String versi;
  final Widget child;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final konfig = ref.watch(konfigProvider).valueOrNull ?? const KonfigApp();
    if (konfig.blokir(versi)) {
      return MaintenanceScreen(konfig: konfig, onUpdate: onUpdate);
    }
    return child;
  }
}

/// Layar penghalang saat aplikasi dalam maintenance atau memaksa update.
/// UI murni (tanpa dependensi jaringan) — dipakai semua app di root.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({
    super.key,
    required this.konfig,
    this.onUpdate,
  });

  final KonfigApp konfig;

  /// Aksi tombol "Perbarui" (buka toko/APK). Null → tombol disembunyikan.
  final VoidCallback? onUpdate;

  bool get _update => konfig.mode == AppMode.updateWajib;

  @override
  Widget build(BuildContext context) {
    final pesan = konfig.pesan.trim().isNotEmpty
        ? konfig.pesan.trim()
        : _update
            ? 'Versi baru tersedia. Perbarui aplikasi untuk melanjutkan.'
            : 'Aplikasi sedang dalam pemeliharaan. Silakan coba beberapa '
                'saat lagi. Terima kasih atas kesabaran Anda.';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: TkColors.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: TkColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _update
                          ? Icons.system_update_alt_rounded
                          : Icons.build_circle_outlined,
                      size: 48,
                      color: TkColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _update ? 'Perbarui Aplikasi' : 'Sedang Pemeliharaan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: TkColors.textSecondary,
                    ),
                  ),
                  if (_update && onUpdate != null) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 260,
                      child: TkButton(label: 'Perbarui Sekarang', onPressed: onUpdate),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
