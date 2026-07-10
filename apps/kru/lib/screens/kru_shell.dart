import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/kru_bottom_nav.dart';
import 'k2_daftar_penugasan_screen.dart';
import 'k5_riwayat_kru_screen.dart';
import 'k6_profil_kru_screen.dart';

final kruTabAktifProvider = StateProvider<KruTab>((_) => KruTab.tugas);

/// Shell 3 tab Portal Kru: Tugas (K2) / Riwayat (K5) / Profil (K6).
class KruShell extends ConsumerStatefulWidget {
  const KruShell({super.key});

  static const route = '/kru';

  @override
  ConsumerState<KruShell> createState() => _KruShellState();
}

class _KruShellState extends ConsumerState<KruShell> {
  @override
  void initState() {
    super.initState();
    // Daftarkan token FCM kru sekali saat masuk portal (push tugas realtime).
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await PushService(
        onToken: (t) =>
            ref.read(firestoreServiceProvider).simpanFcmTokenKru(uid, t),
      ).init();
    } catch (_) {
      // Izin notifikasi ditolak / device tanpa Google Play — abaikan.
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktif = ref.watch(kruTabAktifProvider);
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: KruBottomNav(
        aktif: aktif,
        onPilih: (tab) => ref.read(kruTabAktifProvider.notifier).state = tab,
      ),
      body: IndexedStack(
        index: aktif.index,
        children: const [
          K2DaftarPenugasanScreen(),
          K5RiwayatKruScreen(),
          K6ProfilKruScreen(),
        ],
      ),
    );
  }
}
