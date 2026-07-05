import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

/// Bottom nav Portal Kru (page-inventory K6): Tugas / Riwayat / Profil.
enum KruTab { tugas, riwayat, profil }

class KruBottomNav extends StatelessWidget {
  const KruBottomNav({
    super.key,
    required this.aktif,
    required this.onPilih,
  });

  final KruTab aktif;
  final ValueChanged<KruTab> onPilih;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 0,
      opacity: 0.85,
      child: Container(
        height: 78,
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(children: [
          _item(KruTab.tugas, 'Tugas', Icons.list_alt_rounded),
          _item(KruTab.riwayat, 'Riwayat', Icons.history_rounded),
          _item(KruTab.profil, 'Profil', Icons.person_outline_rounded),
        ]),
      ),
    );
  }

  Widget _item(KruTab tab, String label, IconData ikon) {
    final terpilih = tab == aktif;
    final warna = terpilih ? TkColors.primaryDark : TkColors.textMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onPilih(tab),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 23, color: warna),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight:
                        terpilih ? FontWeight.w600 : FontWeight.w500,
                    color: warna)),
          ],
        ),
      ),
    );
  }
}
