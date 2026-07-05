import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/notifikasi_providers.dart';
import 'p8_tracking_screen.dart';

/// P12 — Notifikasi. List grouped by hari (Hari Ini/Kemarin/tanggal),
/// belum dibaca = dot hijau + latar tinted (kaidah Umpan Balik
/// berkelanjutan); item ber-orderId deep-link ke P8.
class P12NotifikasiScreen extends ConsumerWidget {
  const P12NotifikasiScreen({super.key});

  static const _latarLembut = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.watch(notifikasiProvider);

    return Scaffold(
      backgroundColor: _latarLembut,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              decoration: const BoxDecoration(
                color: TkColors.surface,
                border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: Row(children: [
                Text('Notifikasi',
                    style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft,
                        letterSpacing: -0.3)),
                const Spacer(),
                if (ref.watch(adaNotifBelumDibacaProvider))
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final semua =
                          ref.read(notifikasiProvider).valueOrNull ?? [];
                      final service = ref.read(firestoreServiceProvider);
                      for (final n in semua.where((n) => !n.dibaca)) {
                        await service
                            .markNotificationRead(n.notificationId);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('Tandai dibaca',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TkColors.primary)),
                    ),
                  ),
              ]),
            ),
            Expanded(
              child: notif.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: TkColors.primary)),
                error: (_, _) => _kosong(
                    'Notifikasi tidak dapat dimuat. Periksa koneksi Anda.'),
                data: (list) {
                  if (list.isEmpty) {
                    return _kosong('Belum ada notifikasi untuk Anda.');
                  }
                  final grup = _kelompokkan(list);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
                    children: [
                      for (final entri in grup.entries) ...[
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 4, bottom: 10),
                          child: Row(children: [
                            Text(entri.key,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TkColors.textMuted,
                                    letterSpacing: 0.3)),
                            if (entri.key == 'HARI INI' &&
                                entri.value.any((n) => !n.dibaca)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(
                                  color: TkColors.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                    '${entri.value.where((n) => !n.dibaca).length} baru',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: TkColors.surface)),
                              ),
                            ],
                          ]),
                        ),
                        for (final n in entri.value) ...[
                          _ItemNotif(notif: n),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<NotificationModel>> _kelompokkan(
      List<NotificationModel> list) {
    final kini = DateTime.now();
    final hariIni = DateTime(kini.year, kini.month, kini.day);
    final kemarin = hariIni.subtract(const Duration(days: 1));
    final grup = <String, List<NotificationModel>>{};
    for (final n in list) {
      final hari = DateTime(n.waktu.year, n.waktu.month, n.waktu.day);
      final label = hari == hariIni
          ? 'HARI INI'
          : hari == kemarin
              ? 'KEMARIN'
              : '${hari.day}/${hari.month}/${hari.year}';
      grup.putIfAbsent(label, () => []).add(n);
    }
    return grup;
  }

  Widget _kosong(String pesan) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(pesan,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: TkColors.textMuted)),
        ),
      );
}

class _ItemNotif extends ConsumerWidget {
  const _ItemNotif({required this.notif});

  final NotificationModel notif;

  String get _jam =>
      '${notif.waktu.hour.toString().padLeft(2, '0')}.'
      '${notif.waktu.minute.toString().padLeft(2, '0')} WIB';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belumDibaca = !notif.dibaca;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref
            .read(firestoreServiceProvider)
            .markNotificationRead(notif.notificationId);
        final orderId = notif.orderId;
        if (orderId != null && orderId.isNotEmpty) {
          Navigator.of(context)
              .pushNamed(P8TrackingScreen.route, arguments: orderId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: belumDibaca
              ? TkColors.primary.withValues(alpha: 0.05)
              : TkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: belumDibaca
                ? TkColors.primary.withValues(alpha: 0.12)
                : const Color(0x0D0F281C),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: TkColors.primary
                    .withValues(alpha: belumDibaca ? 0.12 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  size: 21, color: TkColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.judul,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: belumDibaca
                              ? TkColors.inkSoft
                              : const Color(0xFF33403A))),
                  const SizedBox(height: 3),
                  Text(notif.pesan,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: belumDibaca
                              ? TkColors.textSecondary
                              : TkColors.textMuted,
                          height: 1.45)),
                  const SizedBox(height: 5),
                  Text(_jam,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA6AEA9))),
                ],
              ),
            ),
            if (belumDibaca)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: TkColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
