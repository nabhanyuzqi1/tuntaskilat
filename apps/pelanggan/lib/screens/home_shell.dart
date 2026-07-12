import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/beranda_providers.dart';
import '../providers/notifikasi_providers.dart';
import '../widgets/masuk_dulu.dart';
import '../widgets/tk_bottom_nav.dart';
import 'p11_profil_screen.dart';
import 'p12_notifikasi_screen.dart';
import 'p3_beranda_screen.dart';
import 'p8_tracking_screen.dart';
import 'p9_riwayat_screen.dart';

/// Tab aktif shell — StateProvider supaya konten tab lain bisa memindah tab
/// (mis. tombol "Riwayat" di P3, lonceng notifikasi di header Beranda).
final tabAktifProvider = StateProvider<TkNavTab>((_) => TkNavTab.beranda);

/// Shell 4 tab Aplikasi Pelanggan: Beranda (P3) / Riwayat (P9) /
/// Notifikasi (P12) / Profil (P11) — bottom nav glass dari page-inventory P3.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const route = '/home';

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Daftarkan token FCM pelanggan + handler notifikasi sekali saat masuk
    // (push chat dari kru & status pesanan). Pelanggan TIDAK memakai FGS.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPush());
  }

  Future<void> _initPush() async {
    try {
      await ref.read(firebaseInitProvider.future);
      registerFcmBackgroundHandler();
      await NotificationService().ensureChannels();
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) return;
      final push = PushService(
        onToken: (t) =>
            ref.read(firestoreServiceProvider).simpanFcmTokenUser(uid, t),
      );
      await push.init();
      // Deep link: tap notifikasi (chat/status) → langsung buka P8 Lacak
      // pesanan terkait — dari background maupun terminated.
      push.onMessageOpened.listen((m) => _bukaDeepLink(deepLinkDari(m)));
      _bukaDeepLink(deepLinkDari(await push.pesanAwal()));
    } catch (_) {
      // Izin notifikasi ditolak / device tanpa Google Play — abaikan.
    }
  }

  void _bukaDeepLink(({String orderId, String tipe})? link) {
    if (link == null || !mounted) return;
    if (link.tipe == 'promo') return; // promo cukup membuka Beranda
    Navigator.of(context)
        .pushNamed(P8TrackingScreen.route, arguments: link.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final aktif = ref.watch(tabAktifProvider);
    // MODE TAMU: Beranda bebas dijelajah; tab lain menampilkan ajakan masuk
    // (pola marketplace umum — jelajah dulu, aksi = login).
    final tamu =
        ref.watch(authStateProvider).valueOrNull == null;
    return Scaffold(
      extendBody: true, // konten tampak di balik nav glass (blur berarti)
      bottomNavigationBar: TkBottomNav(
        aktif: aktif,
        adaNotifBelumDibaca: ref.watch(adaNotifBelumDibacaProvider),
        onPilih: (tab) => ref.read(tabAktifProvider.notifier).state = tab,
      ),
      body: Stack(children: [
        IndexedStack(
          index: aktif.index,
          children: [
            const P3BerandaScreen(),
            tamu
                ? const MasukDuluView(
                    judul: 'Riwayat pesanan Anda',
                    pesan: 'Masuk untuk melihat dan melacak seluruh '
                        'pesanan Anda.')
                : const P9RiwayatScreen(),
            tamu
                ? const MasukDuluView(
                    judul: 'Notifikasi',
                    pesan: 'Masuk untuk menerima info status pesanan dan '
                        'promo terbaru.')
                : const P12NotifikasiScreen(),
            tamu
                ? const MasukDuluView(
                    judul: 'Profil Anda',
                    pesan: 'Masuk atau daftar untuk mengelola akun, alamat, '
                        'dan kode referal Anda.')
                : const P11ProfilScreen(),
          ],
        ),
        // Kartu order berjalan mengambang di atas nav (pola Gojek/Grab).
        const Positioned(
          left: 12,
          right: 12,
          bottom: 92,
          child: _OrderAktifBanner(),
        ),
      ]),
    );
  }
}

/// Banner "pesanan berjalan" — tampil bila ada order aktif; tap → P8 lacak.
class _OrderAktifBanner extends ConsumerWidget {
  const _OrderAktifBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(profilSayaProvider).valueOrNull?.userId;
    if (uid == null) return const SizedBox.shrink();
    final order = ref.watch(orderAktifProvider(uid)).valueOrNull;
    if (order == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .pushNamed(P8TrackingScreen.route, arguments: order.orderId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [TkColors.primaryDark, TkColors.primary]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: TkColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(StatusBadge.labelOf(order.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(order.namaLayanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Lacak',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}
