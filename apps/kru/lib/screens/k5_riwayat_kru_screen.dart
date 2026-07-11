import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';

enum PeriodeK5 { bulanIni, mingguIni, semua }

final periodeK5Provider = StateProvider<PeriodeK5>((_) => PeriodeK5.bulanIni);

/// K5 — Riwayat & Rating Kru. Rata-rata rating + jumlah ulasan
/// (transparansi kinerja) + rekap pekerjaan selesai dengan rating per
/// pekerjaan dari koleksi `reviews`.
class K5RiwayatKruScreen extends ConsumerWidget {
  const K5RiwayatKruScreen({super.key});

  static const _latarLembut = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kru = ref.watch(kruSayaProvider).valueOrNull;
    final tugas = ref.watch(tugasSayaProvider).valueOrNull ?? const [];
    final ulasan = ref.watch(ulasanSayaProvider).valueOrNull ?? const [];
    final periode = ref.watch(periodeK5Provider);

    final selesaiSemua = tugas
        .where((o) =>
            o.status == OrderStatus.selesai ||
            o.status == OrderStatus.dinilai)
        .toList()
      ..sort((a, b) => b.jadwal.compareTo(a.jadwal));

    final kini = DateTime.now();
    final awalMinggu = DateTime(kini.year, kini.month, kini.day)
        .subtract(Duration(days: kini.weekday - 1));
    final tersaring = selesaiSemua.where((o) {
      return switch (periode) {
        PeriodeK5.semua => true,
        PeriodeK5.bulanIni =>
          o.jadwal.year == kini.year && o.jadwal.month == kini.month,
        PeriodeK5.mingguIni => !o.jadwal.isBefore(awalMinggu),
      };
    }).toList(growable: false);

    final ratingPerOrder = {
      for (final r in ulasan) r.orderId: r,
    };

    return Scaffold(
      backgroundColor: _latarLembut,
      // Header putih membungkus SafeArea — warna naik sampai belakang
      // status bar (sinkron system bar ↔ header).
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: TkColors.surface,
                border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                  child: Text('Riwayat & Rating',
                      style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft,
                          letterSpacing: -0.3)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                children: [
                  _kartuRingkasan(kru, selesaiSemua.length),
                  const SizedBox(height: 18),
                  Row(children: [
                    _chip(ref, PeriodeK5.bulanIni, 'Bulan Ini', periode),
                    _chip(ref, PeriodeK5.mingguIni, 'Minggu Ini', periode),
                    _chip(ref, PeriodeK5.semua, 'Semua', periode),
                  ]),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('PEKERJAAN SELESAI',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TkColors.textMuted,
                            letterSpacing: 0.3)),
                  ),
                  if (tersaring.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Text(
                        'Belum ada pekerjaan selesai pada periode ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 14, color: TkColors.textMuted),
                      ),
                    )
                  else
                    for (final order in tersaring) ...[
                      _kartuRiwayat(order, ratingPerOrder[order.orderId]),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _kartuRingkasan(KruModel? kru, int totalSelesai) {
    final rating = kru?.rataRating ?? 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TkColors.primaryDark, TkColors.primary],
        ),
      ),
      child: Row(children: [
        Column(children: [
          Text(rating.toStringAsFixed(1).replaceAll('.', ','),
              style: GoogleFonts.montserrat(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: TkColors.surface,
                  height: 1)),
          const SizedBox(height: 6),
          Row(children: [
            for (var i = 0; i < 5; i++)
              Icon(Icons.star_rounded,
                  size: 15,
                  color: i < rating.round()
                      ? TkColors.accent
                      : Colors.white.withValues(alpha: 0.3)),
          ]),
          const SizedBox(height: 6),
          Text('${kru?.jumlahUlasan.round() ?? 0} ulasan',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85))),
        ]),
        Container(
            width: 1,
            height: 76,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withValues(alpha: 0.18)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$totalSelesai',
                  style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: TkColors.surface)),
              Text('Tugas selesai',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 14, color: TkColors.surface),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text('Kru Terverifikasi Tuntaskilat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TkColors.surface)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(
      WidgetRef ref, PeriodeK5 nilai, String label, PeriodeK5 aktif) {
    final terpilih = nilai == aktif;
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(periodeK5Provider.notifier).state = nilai,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: terpilih ? TkColors.primary : TkColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: terpilih
                ? null
                : Border.all(color: const Color(0x1A0F281C)),
          ),
          child: Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight:
                      terpilih ? FontWeight.w600 : FontWeight.w500,
                  color: terpilih
                      ? TkColors.surface
                      : const Color(0xFF33403A))),
        ),
      ),
    );
  }

  Widget _kartuRiwayat(OrderModel order, ReviewModel? review) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final t = order.jadwal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(TkRadius.card),
        border: Border.all(color: const Color(0x0D0F281C)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: TkColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cleaning_services_outlined,
                size: 22, color: TkColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${order.namaLayanan} · '
                    '${order.kuantitas.round()} '
                    '${order.satuan.replaceFirst('per ', '')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 3),
                Text(
                    '${t.day} ${bulan[t.month - 1]} ${t.year} · '
                    '${t.hour.toString().padLeft(2, '0')}.00 WIB',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
          StatusBadge(status: order.status),
        ]),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            // Expanded + ellipsis: nama pelanggan panjang tidak lagi
            // menabrak nominal (fix overlap kartu Pekerjaan Selesai).
            Expanded(
              child: review != null
                  ? Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: TkColors.accent),
                      const SizedBox(width: 4),
                      Text(
                          review.penilaian
                              .toDouble()
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TkColors.inkSoft)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('· ${review.namaPelanggan}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: TkColors.textMuted)),
                      ),
                    ])
                  : Text('Belum dinilai pelanggan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
            ),
            const SizedBox(width: 10),
            Text('+ ${PriceBadge.formatRupiah(order.totalHarga)}',
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TkColors.primary)),
          ],
        ),
      ]),
    );
  }
}
