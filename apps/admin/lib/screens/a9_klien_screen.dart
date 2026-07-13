import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// Ringkasan satu klien, diturunkan dari koleksi orders (tanpa query users
/// tambahan): identitas + agregat belanja & aktivitas.
class _Klien {
  _Klien(this.userId, this.nama, this.telepon);
  final String userId;
  String nama;
  String telepon;
  int jumlahOrder = 0;
  int selesai = 0;
  int dibatalkan = 0;
  num totalBelanja = 0; // hanya order selesai
  DateTime? terakhir;
}

/// A9 — Kelola Klien & Keluhan (hak superadmin). Daftar pelanggan dengan
/// agregat belanja + aktivitas, dan pemantauan keluhan/sengketa. Data klien
/// diturunkan dari orders yang sudah dimuat panel (hemat kuota).
class A9KlienScreen extends ConsumerWidget {
  const A9KlienScreen({super.key});

  bool _selesai(OrderStatus s) =>
      s == OrderStatus.selesai || s == OrderStatus.dinilai;

  List<_Klien> _rekap(List<OrderModel> orders) {
    final map = <String, _Klien>{};
    for (final o in orders) {
      if (o.userId.isEmpty) continue;
      final k = map.putIfAbsent(
          o.userId, () => _Klien(o.userId, o.namaPelanggan, o.teleponPelanggan));
      // Pakai identitas terbaru yang tak kosong.
      if (o.namaPelanggan.isNotEmpty) k.nama = o.namaPelanggan;
      if (o.teleponPelanggan.isNotEmpty) k.telepon = o.teleponPelanggan;
      k.jumlahOrder++;
      if (_selesai(o.status)) {
        k.selesai++;
        k.totalBelanja += o.totalHarga;
      }
      if (o.status == OrderStatus.dibatalkan) k.dibatalkan++;
      if (k.terakhir == null || o.tanggalPesan.isAfter(k.terakhir!)) {
        k.terakhir = o.tanggalPesan;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.totalBelanja.compareTo(a.totalBelanja));
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(semuaOrderProvider).valueOrNull ?? const [];
    final disputes = ref.watch(disputesProvider).valueOrNull ?? const [];
    final klien = _rekap(orders);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Klien & Keluhan',
        subjudul:
            '${klien.length} pelanggan · ${disputes.length} keluhan',
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: [
            _tabelKlien(klien),
            const SizedBox(height: 20),
            _tabelKeluhan(context, disputes),
          ],
        ),
      ),
    ]);
  }

  Widget _tabelKlien(List<_Klien> klien) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Text('Pelanggan',
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TkColors.inkSoft)),
        ),
        AdminUi.judulTabel(const [
          ('NAMA', 20),
          ('TELEPON', 14),
          ('ORDER', 8),
          ('SELESAI', 8),
          ('BATAL', 7),
          ('TOTAL BELANJA', 15),
          ('TERAKHIR', 12),
        ]),
        if (klien.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text('Belum ada pelanggan.',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.textMuted)),
          )
        else
          for (final k in klien)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: Row(children: [
                Expanded(flex: 20, child: AdminUi.teksSel(k.nama, tebal: true)),
                Expanded(flex: 14, child: AdminUi.teksSel(k.telepon)),
                Expanded(flex: 8, child: AdminUi.teksSel('${k.jumlahOrder}')),
                Expanded(flex: 8, child: AdminUi.teksSel('${k.selesai}')),
                Expanded(flex: 7, child: AdminUi.teksSel('${k.dibatalkan}')),
                Expanded(
                    flex: 15,
                    child: AdminUi.teksSel(
                        PriceBadge.formatRupiah(k.totalBelanja),
                        tebal: true)),
                Expanded(
                    flex: 12,
                    child: AdminUi.teksSel(k.terakhir == null
                        ? '—'
                        : _tanggal(k.terakhir!))),
              ]),
            ),
      ]),
    );
  }

  Widget _tabelKeluhan(BuildContext context, List<DisputeModel> disputes) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Row(children: [
            const Icon(Icons.report_problem_outlined,
                size: 18, color: TkColors.error),
            const SizedBox(width: 8),
            Text('Keluhan & Sengketa',
                style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ]),
        ),
        AdminUi.judulTabel(const [
          ('PENGAJU', 18),
          ('PESANAN', 18),
          ('ALASAN', 30),
          ('STATUS', 12),
          ('WAKTU', 12),
        ]),
        if (disputes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Text('Tidak ada keluhan. 🎉',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.textMuted)),
          )
        else
          for (final d in disputes)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x0D0F281C))),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    flex: 18,
                    child: AdminUi.teksSel(d.pengajuNama, tebal: true)),
                Expanded(
                    flex: 18, child: AdminUi.teksSel('#${d.orderId}')),
                Expanded(flex: 30, child: AdminUi.teksSel(d.alasan)),
                Expanded(
                  flex: 12,
                  child: AdminUi.chipSel(
                      _labelBanding(d.status), _warnaBanding(d.status)),
                ),
                Expanded(flex: 12, child: AdminUi.teksSel(_tanggal(d.waktu))),
              ]),
            ),
      ]),
    );
  }

  String _labelBanding(StatusBanding s) => switch (s) {
        StatusBanding.diajukan => 'Diajukan',
        StatusBanding.diterima => 'Diterima',
        StatusBanding.ditolak => 'Ditolak',
      };

  Color _warnaBanding(StatusBanding s) => switch (s) {
        StatusBanding.diajukan => TkColors.accentAlt,
        StatusBanding.diterima => TkColors.primary,
        StatusBanding.ditolak => TkColors.error,
      };

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _tanggal(DateTime d) =>
      '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}
