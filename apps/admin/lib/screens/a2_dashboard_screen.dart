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

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Dashboard',
        subjudul:
            '${JudulHariAdmin.format(kini)} · Ringkasan operasional',
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          // Responsif: KPI 4-kolom di layar lebar, 2-kolom di sempit;
          // grafik berdampingan di lebar, bertumpuk di sempit.
          final sempit = c.maxWidth < 720;
          final pad = c.maxWidth < 520 ? 16.0 : 32.0;
          final kpis = [
            _kpi(Icons.credit_card_outlined,
                PriceBadge.formatRupiah(pendapatanBulanIni),
                'Total pendapatan bulan ini', TkColors.primary),
            _kpi(Icons.receipt_long_outlined, '$aktif', 'Pesanan aktif',
                TkColors.accentAlt),
            _kpi(Icons.person_outline_rounded,
                '$kruOnline / ${kru.length}', 'Kru online sekarang',
                TkColors.primary),
            _kpi(Icons.schedule_rounded, '$menunggu',
                'Menunggu verifikasi bayar', const Color(0xFF8A6A00)),
          ];
          final lebarKpi = sempit
              ? (c.maxWidth - pad * 2 - 16) / 2
              : (c.maxWidth - pad * 2 - 18 * 3) / 4;
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
            children: [
              Wrap(
                spacing: sempit ? 16 : 18,
                runSpacing: 16,
                children: [
                  for (final k in kpis)
                    SizedBox(width: lebarKpi.clamp(150, 400), child: k),
                ],
              ),
              const SizedBox(height: 20),
              if (sempit) ...[
                SizedBox(height: 260, child: _grafikPendapatan(orders)),
                const SizedBox(height: 18),
                SizedBox(height: 240, child: _sebaranStatus(orders)),
              ] else
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
              const SizedBox(height: 20),
              _performaKru(orders, kru),
            ],
          );
        }),
      ),
    ]);
  }

  /// Performa kru — ranking individual dihitung dari order yang sudah dimuat
  /// (tanpa query tambahan): jumlah tugas selesai, rating, dan total nilai
  /// order yang dikerjakan. Membantu admin melihat kru paling produktif.
  Widget _performaKru(List<OrderModel> orders, List<KruModel> kru) {
    // Kumpulkan statistik per cleanerId dari order selesai.
    final tugasSelesai = <String, int>{};
    final nilaiDikerjakan = <String, num>{};
    for (final o in orders) {
      if (!_selesai(o.status)) continue;
      // Kru yang dikreditkan: seluruh penugasan bila ada, jika tidak
      // fallback ke cleanerId tunggal.
      final ids = o.penugasan.isNotEmpty
          ? o.penugasan.map((p) => p.cleanerId).toSet()
          : (o.cleanerId.isEmpty ? <String>{} : {o.cleanerId});
      for (final id in ids) {
        tugasSelesai[id] = (tugasSelesai[id] ?? 0) + 1;
        nilaiDikerjakan[id] = (nilaiDikerjakan[id] ?? 0) + o.totalHarga;
      }
    }
    // Urutkan kru berdasar tugas selesai terbanyak, lalu rating.
    final baris = [...kru]..sort((a, b) {
        final ta = tugasSelesai[a.cleanerId] ?? 0;
        final tb = tugasSelesai[b.cleanerId] ?? 0;
        if (tb != ta) return tb.compareTo(ta);
        return b.rataRating.compareTo(a.rataRating);
      });

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(children: [
            Text('Performa Kru',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
            const SizedBox(width: 8),
            Text('· bulan berjalan & lampau',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textMuted)),
          ]),
        ),
        AdminUi.judulTabel(const [
          ('KRU', 22),
          ('TUGAS SELESAI', 14),
          ('RATING', 12),
          ('NILAI DIKERJAKAN', 16),
        ]),
        if (baris.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text('Belum ada kru.',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.textMuted)),
          )
        else
          for (final k in baris)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: Row(children: [
                Expanded(flex: 22, child: AdminUi.teksSel(k.nama, tebal: true)),
                Expanded(
                    flex: 14,
                    child: AdminUi.teksSel(
                        '${tugasSelesai[k.cleanerId] ?? 0}')),
                Expanded(
                  flex: 12,
                  child: Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 15, color: TkColors.accent),
                    const SizedBox(width: 4),
                    AdminUi.teksSel(
                        '${k.rataRating.toStringAsFixed(1).replaceAll('.', ',')} '
                        '(${k.jumlahUlasan.round()})'),
                  ]),
                ),
                Expanded(
                    flex: 16,
                    child: AdminUi.teksSel(
                        PriceBadge.formatRupiah(
                            nilaiDikerjakan[k.cleanerId] ?? 0),
                        tebal: true)),
              ]),
            ),
      ]),
    );
  }

  Widget _kpi(IconData ikon, String nilai, String label, Color warna) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminUi.kartu(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              alignment: Alignment.centerLeft,
              child: Text(nilai,
                  style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TkColors.textMuted)),
          ],
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
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            // width:infinity + maxWidth memicu assertion
                            // "BoxConstraints forces an infinite width" pada
                            // parent unbounded — pakai lebar tetap saja.
                            width: 40,
                            height: maks == 0
                                ? 4
                                : math.max(
                                    4, 170 * (nilai[i] / maks).toDouble()),
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
    // Empat kelompok berwarna BEDA — sebelumnya hampir semua status jatuh ke
    // satu ember "lainnya" sehingga donut tampak kuning semua.
    const biru = Color(0xFF2D9CDB);
    final selesai = orders.where((o) => _selesai(o.status)).length;
    final berjalan = orders
        .where((o) =>
            o.status == OrderStatus.ditugaskan ||
            o.status == OrderStatus.dalamPerjalanan ||
            o.status == OrderStatus.diproses)
        .length;
    final ditolak =
        orders.where((o) => o.status == OrderStatus.ditolak).length;
    final menunggu = orders.length - selesai - berjalan - ditolak;
    final total = orders.length;

    Widget legenda(Color warna, String label, int jumlah) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                    color: warna, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF33403A))),
            ),
            const SizedBox(width: 8),
            Text(total == 0 ? '0%' : '${(jumlah * 100 / total).round()}%',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft)),
          ]),
        );

    final donut = SizedBox(
      width: 116,
      height: 116,
      child: CustomPaint(
        painter: _DonutPainter(
          bagian: total == 0
              ? const [(1, Color(0xFFE3E8E4))]
              : [
                  (selesai / total, TkColors.primary),
                  (berjalan / total, biru),
                  (menunggu / total, TkColors.accent),
                  (ditolak / total, TkColors.error),
                ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
    );

    final legenda3 = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        legenda(TkColors.primary, 'Selesai', selesai),
        legenda(biru, 'Berjalan', berjalan),
        legenda(TkColors.accent, 'Menunggu', menunggu),
        legenda(TkColors.error, 'Dibatalkan', ditolak),
      ],
    );

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
            child: LayoutBuilder(builder: (context, c) {
              // Sempit → donut di atas legenda; lebar → berdampingan.
              if (c.maxWidth < 280) {
                return SingleChildScrollView(
                  child: Column(children: [
                    donut,
                    const SizedBox(height: 16),
                    legenda3,
                  ]),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  donut,
                  const SizedBox(width: 18),
                  Expanded(child: legenda3),
                ],
              );
            }),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                    return AdminUi.chipSel(label, warna);
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
