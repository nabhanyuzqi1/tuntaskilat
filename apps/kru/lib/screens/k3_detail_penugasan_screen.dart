import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tk_core/tk_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_providers.dart';
import 'k4_laporan_kerja_screen.dart';

final _orderK3Provider =
    StreamProvider.autoDispose.family<OrderModel, String>((ref, orderId) {
  return ref.watch(firestoreServiceProvider).watchOrder(orderId);
});

/// K3 — Detail Penugasan & Navigasi (Gambar TA 3.17). Peta rute, alamat &
/// catatan pelanggan, tombol progres status BERURUTAN — hanya tahap
/// berikutnya yang aktif, tak bisa lompat (kaidah Pencegahan Kesalahan,
/// `OrderStatus.tahapBerikutKru`).
///
/// Saat status `dalam_perjalanan`, layar ini mengalirkan posisi GPS kru ke
/// `kru.posisi` (sumber marker real-time P8 Tracking pelanggan).
class K3DetailPenugasanScreen extends ConsumerStatefulWidget {
  const K3DetailPenugasanScreen({super.key});

  static const route = '/k3';

  @override
  ConsumerState<K3DetailPenugasanScreen> createState() =>
      _K3DetailPenugasanScreenState();
}

class _K3DetailPenugasanScreenState
    extends ConsumerState<K3DetailPenugasanScreen> {
  StreamSubscription<Position>? _posisiSub;
  var _memulaiStream = false;
  var _memproses = false;

  @override
  void dispose() {
    _posisiSub?.cancel();
    super.dispose();
  }

  /// Mulai/berhenti mengalirkan posisi sesuai status order.
  Future<void> _sinkronPosisi(OrderModel order) async {
    final harusStream = order.status == OrderStatus.dalamPerjalanan;
    if (harusStream && _posisiSub == null && !_memulaiStream) {
      // Guard reentrancy: build bisa terpanggil lagi sebelum await selesai.
      _memulaiStream = true;
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        return;
      }
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) return;
      _posisiSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((pos) {
        ref
            .read(firestoreServiceProvider)
            .updatePosisiKru(uid, GeoPoint(pos.latitude, pos.longitude));
      });
    } else if (!harusStream && _posisiSub != null) {
      await _posisiSub?.cancel();
      _posisiSub = null;
      _memulaiStream = false;
    }
  }

  Future<void> _majukanStatus(OrderModel order) async {
    final berikut = order.status.tahapBerikutKru;
    if (berikut == null) return;
    if (berikut == OrderStatus.selesai) {
      // Tahap Selesai lewat K4 (laporan foto wajib dulu).
      Navigator.of(context)
          .pushNamed(K4LaporanKerjaScreen.route, arguments: order);
      return;
    }
    setState(() => _memproses = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateOrderStatus(order.orderId, berikut);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Status belum diperbarui. Periksa koneksi Anda lalu coba '
                'lagi.')));
      }
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String;
    final orderAsync = ref.watch(_orderK3Provider(orderId));

    return Scaffold(
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: TkColors.primaryDark)),
        error: (_, _) => Center(
          child: Text('Penugasan tidak dapat dimuat.',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: TkColors.textMuted)),
        ),
        data: (order) {
          _sinkronPosisi(order);
          return _isi(order);
        },
      ),
    );
  }

  Widget _isi(OrderModel order) {
    final kru = ref.watch(kruSayaProvider).valueOrNull;
    final tujuan = order.lokasi != null
        ? LatLng(order.lokasi!.latitude, order.lokasi!.longitude)
        : const LatLng(-2.5329, 112.9508);
    final posKru = kru?.posisi != null
        ? LatLng(kru!.posisi!.latitude, kru.posisi!.longitude)
        : null;
    final jarakKm = posKru == null || order.lokasi == null
        ? null
        : Geolocator.distanceBetween(posKru.latitude, posKru.longitude,
                tujuan.latitude, tujuan.longitude) /
            1000;

    return Stack(children: [
      // Peta rute
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 300,
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(initialCenter: tujuan, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tuntaskilat.kru',
              ),
              if (posKru != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: [posKru, tujuan],
                    color: TkColors.primary,
                    strokeWidth: 4,
                    pattern: StrokePattern.dotted(spacingFactor: 3),
                  ),
                ]),
              MarkerLayer(markers: [
                Marker(
                  point: tujuan,
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on_rounded,
                      size: 32, color: TkColors.error),
                ),
                if (posKru != null)
                  Marker(
                    point: posKru,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkColors.surface,
                        border:
                            Border.all(color: TkColors.primary, width: 3),
                      ),
                      child: const Icon(Icons.local_shipping_outlined,
                          size: 20, color: TkColors.primary),
                    ),
                  ),
              ]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: Navigator.of(context).pop,
                    child: GlassContainer(
                      radius: 13,
                      opacity: 0.9,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: TkColors.inkSoft),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => launchUrl(
                      Uri.parse('geo:${tujuan.latitude},${tujuan.longitude}'
                          '?q=${tujuan.latitude},${tujuan.longitude}'
                          '(${Uri.encodeComponent(order.namaPelanggan)})'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: TkColors.primary,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  TkColors.primary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.near_me_rounded,
                            size: 18, color: TkColors.surface),
                        const SizedBox(width: 7),
                        Text('Buka Peta',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TkColors.surface)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
      // Sheet detail
      Positioned(
        top: 278, // 300 - 22
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          decoration: const BoxDecoration(
            color: TkColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: TkColors.divider,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${order.namaLayanan} · '
                              '${order.kuantitas.round()} '
                              '${order.satuan.replaceFirst('per ', '')}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: TkColors.inkSoft)),
                          const SizedBox(height: 3),
                          Text(
                              '#${order.orderId} · '
                              '${order.jadwal.hour.toString().padLeft(2, '0')}.00 WIB',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TkColors.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: TkColors.accent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(PriceBadge.formatRupiah(order.totalHarga),
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TkColors.onAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: TkColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: TkColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.location_on_outlined,
                            size: 19, color: TkColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.alamatLayanan,
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.inkSoft)),
                            const SizedBox(height: 2),
                            Text(
                                jarakKm == null
                                    ? 'Sampit, Kalimantan Tengah'
                                    : 'Sampit · '
                                        '${jarakKm.toStringAsFixed(1).replaceAll('.', ',')} km '
                                        '· ± ${(jarakKm / 30 * 60).ceil()} mnt',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: TkColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFDCE7E0),
                    child: Text(
                      order.namaPelanggan.isEmpty
                          ? 'TK'
                          : order.namaPelanggan
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((k) => k[0].toUpperCase())
                              .join(),
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.namaPelanggan,
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TkColors.inkSoft)),
                        Text('Pelanggan',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: TkColors.textMuted)),
                      ],
                    ),
                  ),
                  _tombolKontak(
                      Icons.call_rounded,
                      true,
                      () => launchUrl(Uri(
                          scheme: 'tel', path: order.teleponPelanggan))),
                  const SizedBox(width: 8),
                  _tombolKontak(
                      Icons.chat_bubble_outline_rounded,
                      false,
                      () => launchUrl(Uri(
                          scheme: 'sms', path: order.teleponPelanggan))),
                ]),
                if (order.catatan.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Catatan Pelanggan',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x140F281C)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(order.catatan,
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: TkColors.textSecondary,
                            height: 1.55)),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Progres Pengerjaan',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 14),
                _ProgresLangkah(status: order.status),
                const SizedBox(height: 20),
                if (order.status == OrderStatus.selesai ||
                    order.status == OrderStatus.dinilai)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 20, color: TkColors.primary),
                      const SizedBox(width: 8),
                      Text('Tugas selesai — laporan terkirim',
                          style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: TkColors.primaryDark)),
                    ],
                  )
                else if (order.status.tahapBerikutKru != null)
                  SizedBox(
                    height: 58,
                    child: TkButton(
                      label: switch (order.status) {
                        OrderStatus.ditugaskan => 'Mulai Menuju Lokasi',
                        OrderStatus.dalamPerjalanan => 'Mulai Pengerjaan',
                        OrderStatus.diproses => 'Selesai & Buat Laporan',
                        _ => 'Lanjut',
                      },
                      loading: _memproses,
                      onPressed: () => _majukanStatus(order),
                    ),
                  ),
              ],
          ),
        ),
      ),
    ]);
  }

  Widget _tombolKontak(IconData ikon, bool utama, VoidCallback onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: utama ? TkColors.primary : TkColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: utama
                ? null
                : Border.all(color: TkColors.border, width: 1.5),
          ),
          child: Icon(ikon,
              size: 19,
              color: utama ? TkColors.surface : TkColors.primary),
        ),
      );
}

/// 3 langkah kru: Menuju lokasi → Pengerjaan → Selesai (subset State
/// Diagram 3.11 yang jadi tanggung jawab kru).
class _ProgresLangkah extends StatelessWidget {
  const _ProgresLangkah({required this.status});

  final OrderStatus status;

  int get _selesaiSampai => switch (status) {
        OrderStatus.ditugaskan => 0,
        OrderStatus.dalamPerjalanan => 1,
        OrderStatus.diproses => 2,
        OrderStatus.selesai || OrderStatus.dinilai => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    const label = ['Menuju\nlokasi', 'Penger-\njaan', 'Selesai'];
    return Row(children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0)
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < _selesaiSampai
                    ? TkColors.primary
                    : const Color(0xFFE3E8E4),
              ),
            ),
          ),
        SizedBox(
          width: 64,
          child: Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _selesaiSampai
                    ? TkColors.primary
                    : i == _selesaiSampai
                        ? TkColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF0F2EF),
              ),
              alignment: Alignment.center,
              child: i < _selesaiSampai
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: TkColors.surface)
                  : Text('${i + 1}',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: i == _selesaiSampai
                              ? TkColors.primary
                              : const Color(0xFFB4BBB6))),
            ),
            const SizedBox(height: 6),
            Text(label[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: i <= _selesaiSampai
                        ? TkColors.primary
                        : const Color(0xFFA6AEA9))),
          ]),
        ),
      ],
    ]);
  }
}
