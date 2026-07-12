import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/service_icon.dart';
import 'p10_form_ulasan_screen.dart';
import 'p8_tracking_screen.dart';

/// Filter status P9: Semua / Menunggu / Selesai / Dibatalkan (chip Hi-Fi).
enum FilterRiwayat { semua, menunggu, selesai, dibatalkan }

final filterRiwayatProvider =
    StateProvider<FilterRiwayat>((_) => FilterRiwayat.semua);

/// Seluruh pesanan pengguna, terbaru dulu.
final riwayatProvider = StreamProvider<List<OrderModel>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value(const []);
  // watch(authStateProvider), BUKAN currentUser: saat ganti akun provider
  // harus rebuild — stream uid lama mati PERMISSION_DENIED ketika auth null
  // dan error-nya terkunci sampai app restart (bug riwayat "tidak dapat
  // dimuat" pasca login akun berbeda).
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchOrdersByUser(uid).map(
        (orders) => (orders.toList()
          ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan)))
            .toList(growable: false),
      );
});

bool _masukFilter(OrderStatus s, FilterRiwayat f) => switch (f) {
      FilterRiwayat.semua => true,
      FilterRiwayat.menunggu => s == OrderStatus.dibuat ||
          s == OrderStatus.menungguPembayaran ||
          s == OrderStatus.menungguVerifikasi ||
          s == OrderStatus.menungguPenugasan,
      FilterRiwayat.selesai =>
        s == OrderStatus.selesai || s == OrderStatus.dinilai,
      FilterRiwayat.dibatalkan => s == OrderStatus.ditolak,
    };

/// P9 — Riwayat Pesanan (Gambar TA 3.16). Rekap transaksi + filter status,
/// pola kartu identik P3 (kaidah Konsistensi), akses ke P10 Form Ulasan.
class P9RiwayatScreen extends ConsumerWidget {
  const P9RiwayatScreen({super.key});

  static const _latarLembut = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterRiwayatProvider);
    final riwayat = ref.watch(riwayatProvider);

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
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                    child: Text('Riwayat Pesanan',
                        style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft,
                            letterSpacing: -0.3)),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      children: [
                        _chip(ref, FilterRiwayat.semua, 'Semua', null,
                            filter),
                        _chip(ref, FilterRiwayat.menunggu, 'Menunggu',
                            TkColors.accent, filter),
                        _chip(ref, FilterRiwayat.selesai, 'Selesai',
                            TkColors.primary, filter),
                        _chip(ref, FilterRiwayat.dibatalkan, 'Dibatalkan',
                            TkColors.error, filter),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
            Expanded(
              child: riwayat.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) => Container(
                    decoration: BoxDecoration(
                      color: TkColors.surface,
                      borderRadius: BorderRadius.circular(TkRadius.card),
                      border: Border.all(color: const Color(0x0D0F281C)),
                    ),
                    child: const TkSkeletonListTile(),
                  ),
                ),
                error: (_, _) => _kosong(
                    'Riwayat tidak dapat dimuat. Periksa koneksi Anda.'),
                data: (orders) {
                  final tersaring = orders
                      .where((o) => _masukFilter(o.status, filter))
                      .toList(growable: false);
                  if (tersaring.isEmpty) {
                    return _kosong(
                        'Belum ada pesanan pada kategori ini.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
                    itemCount: tersaring.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _KartuRiwayat(order: tersaring[i]),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _chip(WidgetRef ref, FilterRiwayat nilai, String label, Color? dot,
      FilterRiwayat aktif) {
    final terpilih = nilai == aktif;
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(filterRiwayatProvider.notifier).state = nilai,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: terpilih ? TkColors.primary : TkColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: terpilih
                ? null
                : Border.all(color: const Color(0x1A0F281C)),
            boxShadow: terpilih
                ? [
                    BoxShadow(
                        color: TkColors.primary.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]
                : null,
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

class _KartuRiwayat extends ConsumerWidget {
  const _KartuRiwayat({required this.order});

  final OrderModel order;

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  bool get _berlangsung =>
      order.status == OrderStatus.terverifikasi ||
      order.status == OrderStatus.menungguPenugasan ||
      order.status == OrderStatus.ditugaskan ||
      order.status == OrderStatus.dalamPerjalanan ||
      order.status == OrderStatus.diproses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = order.jadwal;
    final batal = order.status == OrderStatus.ditolak;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(TkRadius.card),
        border: Border.all(color: const Color(0x0D0F281C)),
        boxShadow: [
          BoxShadow(
              color: TkColors.inkSoft.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: batal
                    ? TkColors.error.withValues(alpha: 0.08)
                    : TkColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(serviceIcon(''),
                  size: 24,
                  color: batal ? TkColors.error : TkColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.namaLayanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 3),
                  Text(
                      '${t.day} ${_bulan[t.month - 1]} ${t.year} · '
                      '${order.kuantitas.round()} '
                      '${satuanSingkat(order.satuan)}',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(PriceBadge.formatRupiah(order.totalHarga),
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: batal
                          ? const Color(0xFFA6AEA9)
                          : TkColors.inkSoft,
                      decoration:
                          batal ? TextDecoration.lineThrough : null)),
              _aksi(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aksi(BuildContext context, WidgetRef ref) {
    switch (order.status) {
      case OrderStatus.dibuat || OrderStatus.menungguPembayaran:
        return Text('Menunggu pembayaran',
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A6A00)));
      case OrderStatus.menungguVerifikasi:
        return Text('Menunggu verifikasi admin',
            style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A6A00)));
      case OrderStatus.ditolak:
        // State Diagram: ditolak ↩ upload ulang bukti bayar.
        return _tautan(context, 'Unggah Ulang',
            () => _unggahUlang(context, ref));
      case OrderStatus.selesai:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context)
              .pushNamed(P10FormUlasanScreen.route, arguments: order),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: TkColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded,
                  size: 14, color: TkColors.onAccent),
              const SizedBox(width: 6),
              Text('Beri Ulasan',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TkColors.onAccent)),
            ]),
          ),
        );
      case OrderStatus.dinilai:
        return Row(children: [
          const Icon(Icons.star_rounded, size: 14, color: TkColors.accent),
          const SizedBox(width: 4),
          Text('Sudah dinilai',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TkColors.textMuted)),
        ]);
      default:
        return _berlangsung
            ? _tautan(
                context,
                'Lacak',
                () => Navigator.of(context).pushNamed(
                    P8TrackingScreen.route,
                    arguments: order.orderId),
                ikon: true)
            : const SizedBox.shrink();
    }
  }

  Future<void> _unggahUlang(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes >= 5 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ukuran berkas maksimal 5MB. Pilih foto lain.')));
      }
      return;
    }
    try {
      final url = await ref.read(storageServiceProvider).uploadBuktiBayar(
            userId: order.userId,
            orderId: order.orderId,
            bytes: bytes,
          );
      await ref
          .read(firestoreServiceProvider)
          .unggahUlangBukti(order: order, buktiBayar: url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Bukti baru terkirim. Menunggu verifikasi '
                'admin kembali.')));
      }
    } on FirebaseException catch (e, stack) {
      debugPrint('FirebaseException unggah ulang: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal mengunggah: ${e.message}')));
      }
    } catch (e, stack) {
      debugPrint('Error tak terduga unggah ulang: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Gagal mengunggah. Periksa koneksi lalu coba lagi. ($e)')));
      }
    }
  }

  Widget _tautan(BuildContext context, String label, VoidCallback onTap,
      {bool ikon = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TkColors.primary)),
          if (ikon)
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: TkColors.primary),
        ]),
      ),
    );
  }
}
