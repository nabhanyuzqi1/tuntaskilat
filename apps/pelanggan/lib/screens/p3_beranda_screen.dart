import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/beranda_providers.dart';
import '../providers/notifikasi_providers.dart';
import '../widgets/service_icon.dart';
import '../widgets/tk_bottom_nav.dart';
import 'home_shell.dart';
import 'p3a_katalog_screen.dart';

/// P3 — Beranda (Gambar TA 3.14 & 4.1). Katalog layanan real-time dari
/// koleksi `services` + lencana tarif tetap (kaidah Transparansi harga),
/// section Pesan Ulang. Dirender sebagai tab pertama [HomeShell].
class P3BerandaScreen extends ConsumerWidget {
  const P3BerandaScreen({super.key});

  static const route = '/p3';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layanan = ref.watch(layananTersaringProvider);
    final pesanUlang = ref.watch(pesanUlangProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderBeranda(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 108),
                children: [
                  const _BannerPromo(),
                  _JudulSection(
                    'Layanan',
                    aksi: 'Lihat Semua',
                    onAksi: () => Navigator.of(context)
                        .pushNamed(P3aKatalogScreen.route),
                  ),
                  _GridLayanan(layanan: layanan),
                  pesanUlang.maybeWhen(
                    data: (orders) => orders.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _JudulSection(
                                'Pesan Ulang',
                                aksi: 'Riwayat',
                                onAksi: () => ref
                                    .read(tabAktifProvider.notifier)
                                    .state = TkNavTab.riwayat,
                              ),
                              _DeretPesanUlang(orders: orders),
                            ],
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBeranda extends ConsumerWidget {
  const _HeaderBeranda();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilSayaProvider).valueOrNull;
    final namaDepan =
        (profil?.nama ?? '').trim().split(RegExp(r'\s+')).first;
    final inisial = profil == null || profil.nama.isEmpty
        ? 'TK'
        : profil.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        color: TkColors.surface,
        border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFDCE7E0),
                  child: Text(
                    inisial,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TkColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaDepan.isEmpty ? 'Halo 👋' : 'Halo, $namaDepan 👋',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: TkColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: TkColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Sampit, Kalteng',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TkColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _TombolNotifikasi(
                  onTap: () => ref.read(tabAktifProvider.notifier).state =
                      TkNavTab.notifikasi,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _KolomPencarian(
              onChanged: (v) =>
                  ref.read(pencarianLayananProvider.notifier).state = v,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _TombolNotifikasi extends ConsumerWidget {
  const _TombolNotifikasi({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adaBaru = ref.watch(adaNotifBelumDibacaProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: TkColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 21, color: TkColors.inkSoft),
          ),
          if (adaBaru)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: TkColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KolomPencarian extends StatelessWidget {
  const _KolomPencarian({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.montserrat(fontSize: 14, color: TkColors.inkSoft),
        decoration: InputDecoration(
          hintText: 'Cari layanan kebersihan…',
          hintStyle: GoogleFonts.montserrat(
              fontSize: 14, color: TkColors.textPlaceholder),
          prefixIcon:
              const Icon(Icons.search, size: 20, color: TkColors.textMuted),
          filled: true,
          fillColor: TkColors.surfaceMuted,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: TkColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _BannerPromo extends StatelessWidget {
  const _BannerPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TkRadius.card),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TkColors.primaryDark, TkColors.primary],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -34,
            child: _lingkaran(150, TkColors.accent.withValues(alpha: 0.16)),
          ),
          Positioned(
            bottom: -30,
            right: 60,
            child: _lingkaran(90, Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: TkColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PROMO PERDANA',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TkColors.onAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Diskon 20% pesanan\npertama Anda',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TkColors.surface,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lingkaran(double d, Color warna) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
      );
}

class _JudulSection extends StatelessWidget {
  const _JudulSection(this.judul, {required this.aksi, required this.onAksi});

  final String judul;
  final String aksi;
  final VoidCallback onAksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            judul,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: TkColors.inkSoft,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAksi,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                aksi,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TkColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridLayanan extends ConsumerWidget {
  const _GridLayanan({required this.layanan});

  final AsyncValue<List<ServiceModel>> layanan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseSiap = ref.watch(firebaseSiapProvider);
    return layanan.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: TkColors.primary),
        ),
      ),
      error: (_, _) => _pesanKosong(
        'Katalog tidak dapat dimuat. Periksa koneksi Anda lalu coba lagi.',
      ),
      data: (list) {
        if (list.isEmpty) {
          return _pesanKosong(
            firebaseSiap
                ? 'Belum ada layanan tersedia. Silakan cek kembali nanti.'
                : 'Katalog layanan tampil setelah aplikasi terhubung.',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            mainAxisExtent: 184,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => _KartuLayanan(layanan: list[i]),
        );
      },
    );
  }

  Widget _pesanKosong(String pesan) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
        child: Text(
          pesan,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: TkColors.textMuted,
          ),
        ),
      );
}

class _KartuLayanan extends StatelessWidget {
  const _KartuLayanan({required this.layanan});

  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context)
          .pushNamed('/p4', arguments: layanan),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(color: const Color(0x0F0F281C)),
          boxShadow: [
            BoxShadow(
              color: TkColors.inkSoft.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -8,
            ),
          ],
        ),
        // Expanded pada area ikon menyerap sisa tinggi kartu apa pun, jadi
        // konten tak pernah overflow (fix "BOTTOM OVERFLOWED").
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration:
                    BoxDecoration(gradient: serviceGradient(layanan.kategori)),
                child: Icon(
                  serviceIcon(layanan.ikon),
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    layanan.namaLayanan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: PriceBadge(
                        harga: layanan.harga,
                        satuan: satuanSingkat(layanan.satuan),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeretPesanUlang extends StatelessWidget {
  const _DeretPesanUlang({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _KartuPesanUlang(order: orders[i]),
      ),
    );
  }
}

class _KartuPesanUlang extends StatelessWidget {
  const _KartuPesanUlang({required this.order});

  final OrderModel order;

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final t = order.tanggalPesan;
    final tanggal = '${t.day} ${_bulan[t.month - 1]} ${t.year}';
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(TkRadius.card),
        border: Border.all(color: const Color(0x0F0F281C)),
        boxShadow: [
          BoxShadow(
            color: TkColors.inkSoft.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.namaLayanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$tanggal · ${order.kuantitas.round()} '
                      '${satuanSingkat(order.satuan)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: TkColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PriceBadge.formatRupiah(order.totalHarga),
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                // → P5 Form Pemesanan pre-filled (milestone berikutnya).
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Halaman ini segera hadir.'),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: TkColors.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'Pesan Ulang',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TkColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
