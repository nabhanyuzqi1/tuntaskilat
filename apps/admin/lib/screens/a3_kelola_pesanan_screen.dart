import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

enum FilterA3 { semua, menunggu, aktif, dibatalkan }

final filterA3Provider = StateProvider<FilterA3>((_) => FilterA3.semua);
final cariA3Provider = StateProvider<String>((_) => '');

/// A3 — Kelola Pesanan (Gambar TA 3.18 & 4.5). Verifikasi/tolak pembayaran
/// (tolak wajib alasan → dikirim ke pelanggan via notifikasi) + penugasan
/// kru manual. Konfirmasi ulang setiap aksi (kaidah HCD).
class A3KelolaPesananScreen extends ConsumerWidget {
  const A3KelolaPesananScreen({super.key});

  bool _masukFilter(OrderStatus s, FilterA3 f) => switch (f) {
        FilterA3.semua => true,
        FilterA3.menunggu =>
          s == OrderStatus.menungguVerifikasi ||
              s == OrderStatus.dibuat ||
              s == OrderStatus.menungguPembayaran,
        FilterA3.aktif => s == OrderStatus.terverifikasi ||
            s == OrderStatus.menungguPenugasan ||
            s == OrderStatus.ditugaskan ||
            s == OrderStatus.dalamPerjalanan ||
            s == OrderStatus.diproses,
        FilterA3.dibatalkan => s == OrderStatus.ditolak,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(semuaOrderProvider).valueOrNull ?? const [];
    final filter = ref.watch(filterA3Provider);
    final cari = ref.watch(cariA3Provider).trim().toLowerCase();
    final menunggu = ref.watch(menungguVerifikasiProvider);
    // Warmkan stream kru agar dialog "Tugaskan kru" tidak kosong saat admin
    // langsung membuka menu Pesanan tanpa mampir ke Dashboard.
    ref.watch(semuaKruProvider);

    final tersaring = orders
        .where((o) =>
            _masukFilter(o.status, filter) &&
            (cari.isEmpty ||
                o.orderId.toLowerCase().contains(cari) ||
                o.namaPelanggan.toLowerCase().contains(cari)))
        .toList(growable: false);

    return Column(children: [
      AdminUi.topbar(
        judul: 'Kelola Pesanan',
        subjudul:
            '${orders.length} pesanan · $menunggu menunggu verifikasi',
        aksi: SizedBox(
          width: 280,
          height: 42,
          child: TextField(
            onChanged: (v) => ref.read(cariA3Provider.notifier).state = v,
            style: GoogleFonts.montserrat(
                fontSize: 13, color: TkColors.inkSoft),
            decoration: InputDecoration(
              hintText: 'Cari ID / nama pelanggan…',
              hintStyle: GoogleFonts.montserrat(
                  fontSize: 13, color: TkColors.textPlaceholder),
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: TkColors.textMuted),
              filled: true,
              fillColor: const Color(0xFFF0F2EF),
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                      color: TkColors.primary, width: 1.5)),
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: [
            Row(children: [
              _chip(ref, FilterA3.semua, 'Semua', null, filter),
              _chip(ref, FilterA3.menunggu, 'Menunggu', TkColors.accent,
                  filter),
              _chip(ref, FilterA3.aktif, 'Aktif', TkColors.primary, filter),
              _chip(ref, FilterA3.dibatalkan, 'Dibatalkan', TkColors.error,
                  filter),
            ]),
            const SizedBox(height: 18),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: AdminUi.kartu(),
              child: Column(children: [
                AdminUi.judulTabel(const [
                  ('ID', 12),
                  ('PELANGGAN', 14),
                  ('LAYANAN', 13),
                  ('TOTAL', 9),
                  ('STATUS', 10),
                  ('AKSI', 16),
                ]),
                if (tersaring.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Tidak ada pesanan pada kategori ini.',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: TkColors.textMuted)),
                  )
                else
                  for (final o in tersaring) _baris(context, ref, o),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _chip(WidgetRef ref, FilterA3 nilai, String label, Color? dot,
      FilterA3 aktif) {
    final terpilih = nilai == aktif;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(filterA3Provider.notifier).state = nilai,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: terpilih ? TkColors.primary : TkColors.surface,
            borderRadius: BorderRadius.circular(10),
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
                    fontWeight:
                        terpilih ? FontWeight.w600 : FontWeight.w500,
                    color: terpilih
                        ? TkColors.surface
                        : const Color(0xFF33403A))),
          ]),
        ),
      ),
    );
  }

  Widget _baris(BuildContext context, WidgetRef ref, OrderModel o) {
    final (label, warna) = AdminUi.statusRingkas(o.status);
    final sorot = o.status == OrderStatus.menungguVerifikasi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: sorot ? TkColors.accent.withValues(alpha: 0.04) : null,
        border: const Border(top: BorderSide(color: Color(0x0D0F281C))),
      ),
      child: Row(children: [
        Expanded(flex: 12, child: AdminUi.teksSel('#${o.orderId}', tebal: true)),
        Expanded(flex: 14, child: AdminUi.teksSel(o.namaPelanggan)),
        Expanded(flex: 13, child: AdminUi.teksSel(o.namaLayanan)),
        Expanded(
            flex: 9,
            child: AdminUi.teksSel(PriceBadge.formatRupiah(o.totalHarga),
                tebal: true, coret: o.status == OrderStatus.ditolak)),
        Expanded(flex: 10, child: AdminUi.chipStatus(label, warna)),
        Expanded(flex: 16, child: _aksi(context, ref, o)),
      ]),
    );
  }

  Widget _aksi(BuildContext context, WidgetRef ref, OrderModel o) {
    switch (o.status) {
      case OrderStatus.menungguVerifikasi:
        return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _konfirmasiVerifikasi(context, ref, o),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  textStyle: GoogleFonts.montserrat(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              icon: const Icon(Icons.check_rounded, size: 15),
              label: const Text('Verifikasi'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _dialogTolak(context, ref, o),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                side: BorderSide(
                    color: TkColors.error.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              icon: const Icon(Icons.close_rounded,
                  size: 15, color: TkColors.error),
              label: Text('Tolak',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TkColors.error)),
            ),
          ),
        ]);
      case OrderStatus.terverifikasi || OrderStatus.menungguPenugasan:
        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => _dialogTugaskan(context, ref, o),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 13),
                side: const BorderSide(
                    color: Color(0xFFB7C9BF), width: 1.5),
              ),
              icon: const Icon(Icons.person_add_alt_outlined,
                  size: 15, color: TkColors.primary),
              label: Text('Tugaskan kru',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primary)),
            ),
          ),
        );
      case OrderStatus.ditugaskan ||
            OrderStatus.dalamPerjalanan ||
            OrderStatus.diproses:
        return Align(
          alignment: Alignment.centerRight,
          child: Text(o.namaKru ?? '—',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TkColors.inkSoft)),
        );
      default:
        return Align(
          alignment: Alignment.centerRight,
          child: Text(StatusBadge.labelOf(o.status),
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: TkColors.textMuted)),
        );
    }
  }

  Future<void> _konfirmasiVerifikasi(
      BuildContext context, WidgetRef ref, OrderModel o) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Verifikasi pembayaran?',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: Text(
            'Pesanan #${o.orderId} · ${o.namaPelanggan} · '
            '${PriceBadge.formatRupiah(o.totalHarga)}.\nPelanggan akan '
            'menerima notifikasi konfirmasi.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(130, 48)),
              child: const Text('Verifikasi')),
        ],
      ),
    );
    if (ya != true) return;
    try {
      await ref
          .read(firestoreServiceProvider)
          .verifikasiPembayaran(order: o, terima: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pembayaran #${o.orderId} diverifikasi. '
                'Silakan tugaskan kru.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memverifikasi. $e')));
      }
    }
  }

  Future<void> _dialogTolak(
      BuildContext context, WidgetRef ref, OrderModel o) async {
    final controller = TextEditingController();
    const cepat = ['Bukti tidak sesuai', 'Nominal kurang', 'Bukti buram'];
    final alasan = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: TkColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 24, color: TkColors.error),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tolak pembayaran?',
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft)),
                  Text(
                      '#${o.orderId} · ${o.namaPelanggan} · '
                      '${PriceBadge.formatRupiah(o.totalHarga)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: TkColors.textMuted)),
                ],
              ),
            ),
          ]),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Alasan penolakan',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TkColors.label)),
                  Text(' *',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.error)),
                  const SizedBox(width: 6),
                  Text('wajib — dikirim ke pelanggan',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in cepat)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => controller.text = '$c.'),
                      child: Container(
                        height: 32,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: controller.text.startsWith(c)
                              ? TkColors.error.withValues(alpha: 0.06)
                              : TkColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: controller.text.startsWith(c)
                                  ? TkColors.error.withValues(alpha: 0.28)
                                  : const Color(0x1F0F281C)),
                        ),
                        child: Text(c,
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: controller.text.startsWith(c)
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: controller.text.startsWith(c)
                                    ? TkColors.error
                                    : const Color(0xFF33403A))),
                      ),
                    ),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.inkSoft, height: 1.5),
                  decoration: InputDecoration(
                    hintText: 'Tulis alasan yang jelas untuk pelanggan…',
                    hintStyle: GoogleFonts.montserrat(
                        fontSize: 13, color: TkColors.textPlaceholder),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: TkColors.error,
                  minimumSize: const Size(170, 48)),
              child: const Text('Tolak Pembayaran'),
            ),
          ],
        ),
      ),
    );
    if (alasan == null || alasan.isEmpty) return;
    await ref
        .read(firestoreServiceProvider)
        .verifikasiPembayaran(order: o, terima: false, alasan: alasan);
  }

  Future<void> _dialogTugaskan(
      BuildContext context, WidgetRef ref, OrderModel o) async {
    // Ambil daftar kru; tunggu stream bila belum sempat termuat.
    final List<KruModel> semuaKru =
        ref.read(semuaKruProvider).valueOrNull ??
            await ref
                .read(firestoreServiceProvider)
                .watchSemuaKru()
                .first
                .timeout(const Duration(seconds: 8),
                    onTimeout: () => const []);
    if (!context.mounted) return;
    final kru = await showDialog<KruModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tugaskan kru untuk #${o.orderId}',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: SizedBox(
          width: 420,
          child: semuaKru.isEmpty
              ? Text('Belum ada kru terdaftar. Tambahkan lewat menu Kru.',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.textMuted))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final k in semuaKru)
                      ListTile(
                        onTap: k.statusKetersediaan
                            ? () => Navigator.of(ctx).pop(k)
                            : null,
                        enabled: k.statusKetersediaan,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDCE7E0),
                          child: Text(
                            k.nama.isEmpty
                                ? 'TK'
                                : k.nama
                                    .trim()
                                    .split(RegExp(r'\s+'))
                                    .take(2)
                                    .map((x) => x[0].toUpperCase())
                                    .join(),
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TkColors.primaryDark),
                          ),
                        ),
                        title: Text(k.nama,
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TkColors.inkSoft)),
                        subtitle: Text(
                            '★ ${k.rataRating.toStringAsFixed(1).replaceAll('.', ',')} · '
                            '${k.jumlahUlasan.round()} ulasan',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: TkColors.textMuted)),
                        trailing: AdminUi.chipStatus(
                          k.statusKetersediaan ? 'Online' : 'Offline',
                          k.statusKetersediaan
                              ? TkColors.primary
                              : TkColors.textMuted,
                        ),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
        ],
      ),
    );
    if (kru == null) return;
    try {
      await ref
          .read(firestoreServiceProvider)
          .tugaskanKru(order: o, kru: kru);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${kru.nama} ditugaskan ke pesanan '
                '#${o.orderId}.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menugaskan kru. $e')));
      }
    }
  }
}
