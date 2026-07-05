import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/kru_bottom_nav.dart';
import 'k2_daftar_penugasan_screen.dart';
import 'k5_riwayat_kru_screen.dart';
import 'k6_profil_kru_screen.dart';

final kruTabAktifProvider = StateProvider<KruTab>((_) => KruTab.tugas);

/// Shell 3 tab Portal Kru: Tugas (K2) / Riwayat (K5) / Profil (K6).
class KruShell extends ConsumerWidget {
  const KruShell({super.key});

  static const route = '/kru';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
