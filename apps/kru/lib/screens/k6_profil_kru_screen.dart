import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import 'k1_login_screen.dart';
import 'k_bantuan_screen.dart';
import 'k_ubah_kata_sandi_screen.dart';

/// K6 — Profil Kru. Statistik pesanan selesai & pendapatan bulan ini
/// (transparansi kinerja & insentif finansial), entry Ubah Kata Sandi &
/// Bantuan, keluar dengan dialog konfirmasi.
class K6ProfilKruScreen extends ConsumerWidget {
  const K6ProfilKruScreen({super.key});

  static const _latarLembut = Color(0xFFF6F8F5);

  Future<void> _konfirmasiKeluar(BuildContext context, WidgetRef ref) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TkRadius.card)),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TkColors.error.withValues(alpha: 0.10),
          ),
          child: const Icon(Icons.logout_rounded,
              size: 28, color: TkColors.error),
        ),
        title: Text('Keluar dari akun?',
            style: GoogleFonts.montserrat(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: Text(
          'Anda tidak akan menerima penugasan baru sampai masuk kembali.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
              fontSize: 14, color: TkColors.textSecondary, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Batal',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF33403A))),
          ),
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
          .pushNamedAndRemoveUntil(K1LoginScreen.route, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kru = ref.watch(kruSayaProvider).valueOrNull;
    final profil = ref.watch(profilSayaProvider).valueOrNull;
    final tugas = ref.watch(tugasSayaProvider).valueOrNull ?? const [];

    final selesai = tugas
        .where((o) =>
            o.status == OrderStatus.selesai ||
            o.status == OrderStatus.dinilai)
        .toList(growable: false);
    final kini = DateTime.now();
    final pendapatanBulanIni = selesai
        .where((o) =>
            o.jadwal.year == kini.year && o.jadwal.month == kini.month)
        .fold<num>(0, (total, o) => total + o.totalHarga);

    final inisial = kru == null || kru.nama.isEmpty
        ? 'TK'
        : kru.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _latarLembut,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TkColors.primaryDark, TkColors.primary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                child: Row(children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(inisial,
                        style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primaryDark)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kru?.nama ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: TkColors.surface)),
                        const SizedBox(height: 4),
                        Text(profil?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color:
                                    Colors.white.withValues(alpha: 0.85))),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 11, color: TkColors.accent),
                              const SizedBox(width: 5),
                              Text(
                                  '${(kru?.rataRating ?? 0).toStringAsFixed(1).replaceAll('.', ',')} '
                                  '· ${kru?.jumlahUlasan.round() ?? 0} ulasan',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: TkColors.surface)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Row(children: [
                  _stat('Pesanan Selesai', '${selesai.length}',
                      TkColors.inkSoft),
                  const SizedBox(width: 12),
                  _stat('Pendapatan Bulan Ini',
                      PriceBadge.formatRupiah(pendapatanBulanIni),
                      TkColors.primary),
                ]),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text('PENGATURAN',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.textMuted,
                          letterSpacing: 0.3)),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: TkColors.surface,
                    borderRadius: BorderRadius.circular(TkRadius.card),
                    border: Border.all(color: const Color(0x0D0F281C)),
                  ),
                  child: Column(children: [
                    _baris(context, Icons.lock_outline_rounded,
                        'Ubah Kata Sandi',
                        () => Navigator.of(context)
                            .pushNamed(KUbahKataSandiScreen.route)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                    _baris(context, Icons.help_outline_rounded,
                        'Bantuan & Dukungan',
                        () => Navigator.of(context)
                            .pushNamed(KBantuanScreen.route)),
                  ]),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _konfirmasiKeluar(context, ref),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: TkColors.error.withValues(alpha: 0.35),
                          width: 1.5),
                      backgroundColor:
                          TkColors.error.withValues(alpha: 0.03),
                    ),
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: TkColors.error),
                    label: Text('Keluar',
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TkColors.error)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Tuntaskilat Kru v1.0.0',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: const Color(0xFFA6AEA9))),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _stat(String label, String nilai, Color warna) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TkColors.surface,
            borderRadius: BorderRadius.circular(TkRadius.card),
            border: Border.all(color: const Color(0x0D0F281C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(nilai,
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: warna)),
              ),
            ],
          ),
        ),
      );

  Widget _baris(BuildContext context, IconData ikon, String label,
      VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: TkColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(ikon, size: 19, color: TkColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TkColors.inkSoft)),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0xFFC4CBC6)),
        ]),
      ),
    );
  }
}
