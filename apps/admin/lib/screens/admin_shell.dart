import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';
import 'a1_login_screen.dart';
import 'a2_dashboard_screen.dart';
import 'a3_kelola_pesanan_screen.dart';
import 'a4_kelola_layanan_screen.dart';
import 'a5_kelola_kru_screen.dart';
import 'a6_pengaturan_screen.dart';
import 'a7_voucher_screen.dart';

enum MenuAdmin { dashboard, pesanan, layanan, kru, voucher, pengaturan }

final menuAdminProvider =
    StateProvider<MenuAdmin>((_) => MenuAdmin.dashboard);

/// Shell Panel Admin: sidebar kiri (Dashboard/Pesanan/Layanan/Kru +
/// Pengaturan & profil admin di bawah) + konten (Gambar TA 3.18 & 4.5).
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  static const route = '/admin';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuAdminProvider);
    return Scaffold(
      backgroundColor: AdminUi.latar,
      body: Row(children: [
        _Sidebar(menu: menu),
        Expanded(
          child: IndexedStack(
            index: menu.index,
            children: const [
              A2DashboardScreen(),
              A3KelolaPesananScreen(),
              A4KelolaLayananScreen(),
              A5KelolaKruScreen(),
              A7VoucherScreen(),
              A6PengaturanScreen(),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.menu});

  final MenuAdmin menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilAdminProvider).valueOrNull;
    final menunggu = ref.watch(menungguVerifikasiProvider);
    final inisial = profil == null || profil.nama.isEmpty
        ? 'AD'
        : profil.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();

    return Container(
      width: 244,
      color: AdminUi.sidebarBg,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(7),
              child: Image.asset('assets/brand/brandmark.webp'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tuntaskilat',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TkColors.surface)),
                Text('PANEL ADMIN',
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 0.5)),
              ],
            ),
          ]),
        ),
        _item(ref, MenuAdmin.dashboard, Icons.dashboard_outlined,
            'Dashboard'),
        _item(ref, MenuAdmin.pesanan, Icons.receipt_long_outlined, 'Pesanan',
            badge: menunggu),
        _item(ref, MenuAdmin.layanan, Icons.grid_view_rounded, 'Layanan'),
        _item(ref, MenuAdmin.kru, Icons.groups_outlined, 'Kru'),
        _item(ref, MenuAdmin.voucher, Icons.local_offer_outlined, 'Voucher'),
        const Spacer(),
        _item(ref, MenuAdmin.pengaturan, Icons.settings_outlined,
            'Pengaturan'),
        const SizedBox(height: 8),
        // Kartu profil admin (informasi, bukan tombol).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: TkColors.accent),
              alignment: Alignment.center,
              child: Text(inisial,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TkColors.onAccent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profil?.nama ?? 'Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TkColors.surface)),
                  Text('Super Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // Tombol Keluar khusus — jelas, ripple, warna merah lembut.
        Material(
          color: TkColors.error.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: () => _keluar(context, ref),
            borderRadius: BorderRadius.circular(11),
            hoverColor: TkColors.error.withValues(alpha: 0.12),
            splashColor: TkColors.error.withValues(alpha: 0.24),
            child: Container(
              height: 46,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 18, color: Color(0xFFFF8A80)),
                  const SizedBox(width: 8),
                  Text('Keluar',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF8A80))),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _keluar(BuildContext context, WidgetRef ref) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TkRadius.card)),
        title: Text('Keluar dari panel?',
            style: GoogleFonts.montserrat(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: Text('Anda perlu masuk kembali untuk mengelola panel.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: TkColors.error,
                minimumSize: const Size(120, 48)),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
    if (keluar != true || !context.mounted) return;
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(A1LoginScreen.route, (_) => false);
    }
  }

  Widget _item(WidgetRef ref, MenuAdmin nilai, IconData ikon, String label,
      {int badge = 0}) {
    final aktif = menu == nilai;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: aktif ? TkColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => ref.read(menuAdminProvider.notifier).state = nilai,
          borderRadius: BorderRadius.circular(11),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          splashColor: Colors.white.withValues(alpha: 0.12),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
            Icon(ikon,
                size: 19,
                color: aktif
                    ? TkColors.surface
                    : Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: aktif ? FontWeight.w600 : FontWeight.w500,
                    color: aktif
                        ? TkColors.surface
                        : Colors.white.withValues(alpha: 0.7))),
            const Spacer(),
            if (badge > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: TkColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$badge',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TkColors.onAccent)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
