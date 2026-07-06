import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// Item nav bawah Aplikasi Pelanggan: Beranda / Riwayat / Notifikasi / Profil
/// (page-inventory P3).
enum TkNavTab { beranda, riwayat, notifikasi, profil }

/// Bottom navigation glass (design-tokens.md § Glassmorphism — elemen
/// mengambang). Tinggi 84, blur, ikon aktif terisi hijau.
class TkBottomNav extends StatelessWidget {
  const TkBottomNav({
    super.key,
    required this.aktif,
    required this.onPilih,
    this.adaNotifBelumDibaca = false,
  });

  final TkNavTab aktif;
  final ValueChanged<TkNavTab> onPilih;
  final bool adaNotifBelumDibaca;

  @override
  Widget build(BuildContext context) {
    // Sisakan ruang untuk gesture/navigation bar bawaan HP supaya isi nav
    // tidak tertutup (edge-to-edge Android 15/target SDK 36).
    final insetBawah = MediaQuery.viewPaddingOf(context).bottom;
    return GlassContainer(
      radius: 0,
      opacity: 0.72,
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: insetBawah + 8),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x0F0F281C)),
          ),
        ),
        child: Row(
          children: [
            _item(TkNavTab.beranda, 'Beranda', Icons.home_outlined,
                Icons.home_rounded),
            _item(TkNavTab.riwayat, 'Riwayat', Icons.history_rounded,
                Icons.history_rounded),
            _item(TkNavTab.notifikasi, 'Notifikasi',
                Icons.notifications_outlined, Icons.notifications_rounded,
                dot: adaNotifBelumDibaca),
            _item(TkNavTab.profil, 'Profil', Icons.person_outline_rounded,
                Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _item(
    TkNavTab tab,
    String label,
    IconData ikon,
    IconData ikonAktif, {
    bool dot = false,
  }) {
    final terpilih = tab == aktif;
    final warna = terpilih ? TkColors.primary : TkColors.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPilih(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(terpilih ? ikonAktif : ikon, size: 23, color: warna),
                if (dot)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkColors.error,
                        border: Border.all(color: TkColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: terpilih ? FontWeight.w600 : FontWeight.w500,
                color: warna,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
