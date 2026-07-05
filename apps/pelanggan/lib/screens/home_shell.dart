import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifikasi_providers.dart';
import '../widgets/tk_bottom_nav.dart';
import 'p11_profil_screen.dart';
import 'p12_notifikasi_screen.dart';
import 'p3_beranda_screen.dart';
import 'p9_riwayat_screen.dart';

/// Tab aktif shell — StateProvider supaya konten tab lain bisa memindah tab
/// (mis. tombol "Riwayat" di P3, lonceng notifikasi di header Beranda).
final tabAktifProvider = StateProvider<TkNavTab>((_) => TkNavTab.beranda);

/// Shell 4 tab Aplikasi Pelanggan: Beranda (P3) / Riwayat (P9) /
/// Notifikasi (P12) / Profil (P11) — bottom nav glass dari page-inventory P3.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const route = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aktif = ref.watch(tabAktifProvider);
    return Scaffold(
      extendBody: true, // konten tampak di balik nav glass (blur berarti)
      bottomNavigationBar: TkBottomNav(
        aktif: aktif,
        adaNotifBelumDibaca: ref.watch(adaNotifBelumDibacaProvider),
        onPilih: (tab) => ref.read(tabAktifProvider.notifier).state = tab,
      ),
      body: IndexedStack(
        index: aktif.index,
        children: const [
          P3BerandaScreen(),
          P9RiwayatScreen(),
          P12NotifikasiScreen(),
          P11ProfilScreen(),
        ],
      ),
    );
  }
}
