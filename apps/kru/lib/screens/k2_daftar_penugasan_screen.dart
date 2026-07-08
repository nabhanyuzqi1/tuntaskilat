import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import 'k3_detail_penugasan_screen.dart';

/// Filter kategori K2: Semua / Aktif / Terjadwal / Selesai.
enum FilterTugas { semua, aktif, terjadwal, selesai }

final filterTugasProvider =
    StateProvider<FilterTugas>((_) => FilterTugas.semua);

bool _aktif(OrderStatus s) =>
    s == OrderStatus.dalamPerjalanan || s == OrderStatus.diproses;
bool _terjadwal(OrderStatus s) => s == OrderStatus.ditugaskan;
bool _selesai(OrderStatus s) =>
    s == OrderStatus.selesai || s == OrderStatus.dinilai;

/// K2 — Daftar Penugasan (Gambar TA 3.17 & 4.4). Toggle ketersediaan
/// Online/Offline besar (skenario Black-Box #7), ringkasan, list tugas —
/// tombol besar kontras tinggi (kaidah Aksesibilitas lapangan).
class K2DaftarPenugasanScreen extends ConsumerWidget {
  const K2DaftarPenugasanScreen({super.key});

  static const _latarLembut = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kru = ref.watch(kruSayaProvider).valueOrNull;
    final tugas = ref.watch(tugasSayaProvider);
    final filter = ref.watch(filterTugasProvider);

    final namaDepan =
        (kru?.nama ?? '').trim().split(RegExp(r'\s+')).first;
    final inisial = kru == null || kru.nama.isEmpty
        ? 'TK'
        : kru.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();

    return Scaffold(
      backgroundColor: _latarLembut,
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
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFDCE7E0),
                      child: Text(inisial,
                          style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TkColors.primaryDark)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            namaDepan.isEmpty
                                ? 'Halo 👋'
                                : 'Halo, $namaDepan 👋',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                color: TkColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('Penugasan Hari Ini',
                            style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: TkColors.inkSoft)),
                      ],
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _ToggleKetersediaan(kru: kru),
                ),
              ]),
            ),
          ),
          Expanded(
            child: tugas.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: TkColors.primaryDark)),
                error: (_, _) => _kosong(
                    'Penugasan tidak dapat dimuat. Periksa koneksi Anda.'),
                data: (orders) {
                  final hariIni = DateTime.now();
                  final selesaiHariIni = orders
                      .where((o) =>
                          _selesai(o.status) &&
                          o.jadwal.year == hariIni.year &&
                          o.jadwal.month == hariIni.month &&
                          o.jadwal.day == hariIni.day)
                      .length;
                  final aktifCount = orders
                      .where((o) =>
                          _aktif(o.status) || _terjadwal(o.status))
                      .length;

                  final tersaring = orders.where((o) {
                    return switch (filter) {
                      FilterTugas.semua => true,
                      FilterTugas.aktif => _aktif(o.status),
                      FilterTugas.terjadwal => _terjadwal(o.status),
                      FilterTugas.selesai => _selesai(o.status),
                    };
                  }).toList(growable: false);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      Row(children: [
                        _ringkas('$aktifCount', 'Tugas aktif',
                            TkColors.primary),
                        const SizedBox(width: 12),
                        _ringkas('$selesaiHariIni', 'Selesai hari ini',
                            TkColors.inkSoft),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _chip(ref, FilterTugas.semua, 'Semua', null,
                                filter),
                            _chip(ref, FilterTugas.aktif, 'Aktif',
                                TkColors.primary, filter),
                            _chip(ref, FilterTugas.terjadwal, 'Terjadwal',
                                TkColors.accentAlt, filter),
                            _chip(ref, FilterTugas.selesai, 'Selesai',
                                TkColors.textMuted, filter),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (tersaring.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'Belum ada penugasan pada kategori ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                                fontSize: 14, color: TkColors.textMuted),
                          ),
                        )
                      else
                        for (final order in tersaring) ...[
                          _KartuTugas(order: order),
                          const SizedBox(height: 14),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _ringkas(String angka, String label, Color warna) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x0D0F281C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(angka,
                  style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: warna)),
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

  Widget _chip(WidgetRef ref, FilterTugas nilai, String label, Color? dot,
      FilterTugas aktif) {
    final terpilih = nilai == aktif;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(filterTugasProvider.notifier).state = nilai,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: terpilih ? TkColors.primary : TkColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: terpilih
                ? null
                : Border.all(color: const Color(0x1A0F281C)),
          ),
          child: Row(children: [
            if (dot != null && !terpilih) ...[
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: dot)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: terpilih
                        ? TkColors.surface
                        : const Color(0xFF33403A))),
          ]),
        ),
      ),
    );
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

class _ToggleKetersediaan extends ConsumerWidget {
  const _ToggleKetersediaan({required this.kru});

  final KruModel? kru;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = kru?.statusKetersediaan ?? false;
    final warna = online ? TkColors.primary : TkColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: kru == null
          ? null
          : () => ref
              .read(firestoreServiceProvider)
              .setKetersediaanKru(kru!.cleanerId, !online),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: online
              ? TkColors.primary.withValues(alpha: 0.06)
              : const Color(0xFFF0F2EF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: online
                ? TkColors.primary.withValues(alpha: 0.14)
                : const Color(0x1A0F281C),
          ),
        ),
        child: Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: warna)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(online ? 'Online' : 'Offline',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: warna)),
                Text(
                    online
                        ? 'Siap menerima tugas baru'
                        : 'Tidak menerima tugas baru',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment:
                online ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: online ? TkColors.primary : const Color(0xFFC4CBC6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.surface,
                boxShadow: [
                  BoxShadow(
                      color: TkColors.inkSoft.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _KartuTugas extends StatelessWidget {
  const _KartuTugas({required this.order});

  final OrderModel order;

  (String, Color) get _badge => switch (order.status) {
        OrderStatus.dalamPerjalanan => ('MENUJU LOKASI', TkColors.primary),
        OrderStatus.diproses => ('PENGERJAAN', TkColors.primary),
        OrderStatus.ditugaskan => ('TERJADWAL', TkColors.accentAlt),
        OrderStatus.selesai ||
        OrderStatus.dinilai =>
          ('SELESAI', TkColors.textSecondary),
        _ => (StatusBadge.labelOf(order.status).toUpperCase(),
            TkColors.accentAlt),
      };

  @override
  Widget build(BuildContext context) {
    final aktif = order.status == OrderStatus.dalamPerjalanan ||
        order.status == OrderStatus.diproses;
    final selesai = order.status == OrderStatus.selesai ||
        order.status == OrderStatus.dinilai;
    final (labelBadge, warnaBadge) = _badge;
    final jam =
        '${order.jadwal.hour.toString().padLeft(2, '0')}.'
        '${order.jadwal.minute.toString().padLeft(2, '0')}';

    return Opacity(
      opacity: selesai ? 0.75 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(
            color: aktif
                ? TkColors.primary.withValues(alpha: 0.22)
                : const Color(0x0D0F281C),
            width: aktif ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: TkColors.inkSoft.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: warnaBadge.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: warnaBadge)),
                            const SizedBox(width: 6),
                            Text(labelBadge,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: warnaBadge)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${order.namaLayanan} · '
                        '${order.kuantitas.round()} ${order.satuan.replaceFirst('per ', '')}',
                        style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(jam,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                    Text('WIB',
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: TkColors.textMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18,
                    color: aktif ? TkColors.primary : TkColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.alamatLayanan,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: TkColors.textSecondary,
                          height: 1.45)),
                ),
                if (selesai)
                  Text('+ ${PriceBadge.formatRupiah(order.totalHarga)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primary)),
              ],
            ),
            if (!selesai) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: aktif
                    ? ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                            K3DetailPenugasanScreen.route,
                            arguments: order.orderId),
                        icon: const Icon(Icons.location_on_outlined,
                            size: 20),
                        label: const Text('Lihat Detail & Navigasi'),
                      )
                    : OutlinedButton(
                        onPressed: () => Navigator.of(context).pushNamed(
                            K3DetailPenugasanScreen.route,
                            arguments: order.orderId),
                        child: Text('Lihat Detail',
                            style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF33403A))),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
