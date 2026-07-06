import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// A2 — Dashboard (Gambar TA 3.18 & 4.5). KPI, grafik pendapatan 7 hari,
/// sebaran status pesanan, tabel transaksi terbaru — grid padat untuk
/// scan cepat.
class A2DashboardScreen extends ConsumerWidget {
  const A2DashboardScreen({super.key});

  bool _selesai(OrderStatus s) =>
      s == OrderStatus.selesai || s == OrderStatus.dinilai;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(semuaOrderProvider).valueOrNull ?? const [];
    final kru = ref.watch(semuaKruProvider).valueOrNull ?? const [];
    final menunggu = ref.watch(menungguVerifikasiProvider);

    final kini = DateTime.now();
    final pendapatanBulanIni = orders
        .where((o) =>
            _selesai(o.status) &&
            o.jadwal.year == kini.year &&
            o.jadwal.month == kini.month)
        .fold<num>(0, (t, o) => t + o.totalHarga);
    final aktif = orders
        .where((o) =>
            o.status == OrderStatus.terverifikasi ||
            o.status == OrderStatus.menungguPenugasan ||
            o.status == OrderStatus.ditugaskan ||
            o.status == OrderStatus.dalamPerjalanan ||
            o.status == OrderStatus.diproses)
        .length;
    final kruOnline = kru.where((k) => k.statusKetersediaan).length;

    return Column(children: [
      AdminUi.topbar(
        judul: 'Dashboard',
        subjudul:
            '${JudulHariAdmin.format(kini)} · Ringkasan operasional',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: [
            Row(children: [
              _kpi(Icons.credit_card_outlined,
                  PriceBadge.formatRupiah(pendapatanBulanIni),
                  'Total pendapatan bulan ini', TkColors.primary),
              const SizedBox(width: 18),
              _kpi(Icons.receipt_long_outlined, '$aktif', 'Pesanan aktif',
                  TkColors.accentAlt),
              const SizedBox(width: 18),
              _kpi(Icons.person_outline_rounded,
                  '$kruOnline / ${kru.length}', 'Kru online sekarang',
                  TkColors.primary),
              const SizedBox(width: 18),
              _kpi(Icons.schedule_rounded, '$menunggu',
                  'Menunggu verifikasi bayar', const Color(0xFF8A6A00)),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 16, child: _grafikPendapatan(orders)),
                  const SizedBox(width: 18),
                  Expanded(flex: 10, child: _sebaranStatus(orders)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _tabelTerbaru(orders),
          ],
        ),
      ),
    ]);
  }

  Widget _kpi(IconData ikon, String nilai, String label, Color warna) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AdminUi.kartu(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ikon, size: 21, color: warna),
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(nilai,
                    style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft,
                        letterSpacing: -0.5)),
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TkColors.textMuted)),
            ],
          ),
        ),
      );

  Widget _grafikPendapatan(List<OrderModel> orders) {
    const label = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final kini = DateTime.now();
    final hariIni = DateTime(kini.year, kini.month, kini.day);
    // 7 hari terakhir, hari ini paling kanan.
    final nilai = List<num>.generate(7, (i) {
      final hari = hariIni.subtract(Duration(days: 6 - i));
      return orders
          .where((o) =>
              _selesai(o.status) &&
              o.jadwal.year == hari.year &&
              o.jadwal.month == hari.month &&
              o.jadwal.day == hari.day)
          .fold<num>(0, (t, o) => t + o.totalHarga);
    });
    final maks = nilai.fold<num>(0, math.max);
    final total = nilai.fold<num>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminUi.kartu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pendapatan 7 hari terakhir',
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
              Text(PriceBadge.formatRupiah(total),
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 1,
                          child: Container(
                            height: maks == 0
                                ? 4
                                : math.max(
                                    4, 170 * (nilai[i] / maks).toDouble()),
                            constraints:
                                const BoxConstraints(maxWidth: 40),
                            decoration: BoxDecoration(
                              color: i == 6
                                  ? TkColors.primary
                                  : TkColors.primary
                                      .withValues(alpha: 0.18),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            label[hariIni
                                    .subtract(Duration(days: 6 - i))
                                    .weekday -
                                1],
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: i == 6
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == 6
                                    ? TkColors.primary
                                    : TkColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sebaranStatus(List<OrderModel> orders) {
    final selesai = orders.where((o) => _selesai(o.status)).length;
    final ditolak =
        orders.where((o) => o.status == OrderStatus.ditolak).length;
    final lainnya = orders.length - selesai - ditolak;
    final total = orders.length;

    Widget legenda(Color warna, String label, int jumlah) => Row(children: [
          Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                  color: warna, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 9),
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF33403A))),
          const Spacer(),
          Text(total == 0 ? '0%' : '${(jumlah * 100 / total).round()}%',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
        ]);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AdminUi.kartu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sebaran status pesanan',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TkColors.inkSoft)),
          const SizedBox(height: 18),
          Expanded(
            child: Row(children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _DonutPainter(
                    bagian: total == 0
                        ? const [(1, Color(0xFFE3E8E4))]
                        : [
                            (selesai / total, TkColors.primary),
                            (lainnya / total, TkColors.accent),
                            (ditolak / total, TkColors.error),
                          ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$total',
                            style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: TkColors.inkSoft)),
                        Text('total',
                            style: GoogleFonts.montserrat(
                                fontSize: 10, color: TkColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    legenda(TkColors.primary, 'Selesai', selesai),
                    const SizedBox(height: 12),
                    legenda(TkColors.accent, 'Menunggu/Aktif', lainnya),
                    const SizedBox(height: 12),
                    legenda(TkColors.error, 'Dibatalkan', ditolak),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tabelTerbaru(List<OrderModel> orders) {
    final terbaru = orders.take(5).toList(growable: false);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(children: [
            Text('Transaksi terbaru',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ]),
        ),
        AdminUi.judulTabel(const [
          ('ID PESANAN', 14),
          ('PELANGGAN', 16),
          ('LAYANAN', 14),
          ('TOTAL', 10),
          ('STATUS', 10),
        ]),
        if (terbaru.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text('Belum ada transaksi.',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.textMuted)),
          )
        else
          for (final o in terbaru)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: Row(children: [
                Expanded(
                    flex: 14,
                    child: AdminUi.teksSel('#${o.orderId}', tebal: true)),
                Expanded(flex: 16, child: AdminUi.teksSel(o.namaPelanggan)),
                Expanded(flex: 14, child: AdminUi.teksSel(o.namaLayanan)),
                Expanded(
                    flex: 10,
                    child: AdminUi.teksSel(
                        PriceBadge.formatRupiah(o.totalHarga),
                        tebal: true)),
                Expanded(
                  flex: 10,
                  child: Builder(builder: (_) {
                    final (label, warna) = AdminUi.statusRingkas(o.status);
                    return AdminUi.chipStatus(label, warna);
                  }),
                ),
              ]),
            ),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.bagian});

  final List<(double, Color)> bagian;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var mulai = -math.pi / 2;
    for (final (porsi, warna) in bagian) {
      if (porsi <= 0) continue;
      final sapu = porsi * 2 * math.pi;
      canvas.drawArc(
        rect.deflate(11),
        mulai,
        sapu,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..color = warna,
      );
      mulai += sapu;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.bagian != bagian;
}

/// Format tanggal Indonesia untuk topbar admin.
class JudulHariAdmin {
  static const _hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
    'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static String format(DateTime t) =>
      '${_hari[t.weekday - 1]}, ${t.day} ${_bulan[t.month - 1]} ${t.year}';
}
