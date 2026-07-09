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
import '../providers/osrm_provider.dart';

/// Order yang sedang dilacak.
final orderDilacakProvider =
    StreamProvider.autoDispose.family<OrderModel, String>((ref, orderId) {
  return ref.watch(firestoreServiceProvider).watchOrder(orderId);
});

/// Kru yang ditugaskan (posisi live).
final kruDilacakProvider =
    StreamProvider.autoDispose.family<KruModel, String>((ref, cleanerId) {
  return ref.watch(firestoreServiceProvider).watchKru(cleanerId);
});

/// P8 — Status Pesanan / Tracking (Gambar TA 3.16 & 4.3). Peta OSM
/// full-screen, posisi kru real-time, kartu status GLASS melayang +
/// identitas kru terverifikasi (kaidah Transparansi & Kepercayaan).
///
/// Graceful degradation (skenario Black-Box #3/#4): saat stream posisi
/// terputus, marker bertahan di titik Firestore terakhir (bukan crash);
/// saat pulih, marker melompat ke posisi terkini.
class P8TrackingScreen extends ConsumerStatefulWidget {
  const P8TrackingScreen({super.key});

  static const route = '/p8';

  @override
  ConsumerState<P8TrackingScreen> createState() => _P8TrackingScreenState();
}

class _P8TrackingScreenState extends ConsumerState<P8TrackingScreen> {
  /// Posisi kru terakhir yang berhasil diterima — fallback skenario #3.
  GeoPoint? _posisiTerakhir;

  static const _pusatSampit = LatLng(-2.5329, 112.9508);

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String;
    final orderAsync = ref.watch(orderDilacakProvider(orderId));

    return Scaffold(
      body: orderAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: TkColors.primary)),
        error: (_, _) => Center(
          child: Text('Pesanan tidak dapat dimuat.',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: TkColors.textMuted)),
        ),
        data: (order) => _peta(order),
      ),
    );
  }

  Widget _peta(OrderModel order) {
    final adaKru = order.cleanerId.isNotEmpty;
    final kruAsync =
        adaKru ? ref.watch(kruDilacakProvider(order.cleanerId)) : null;
    final kru = kruAsync?.valueOrNull;
    final streamTerputus = kruAsync?.hasError ?? false;

    // Simpan posisi terakhir yang valid (graceful degradation #3/#4).
    if (kru?.posisi != null) _posisiTerakhir = kru!.posisi;
    final posisiKru = kru?.posisi ?? _posisiTerakhir;

    final tujuan = order.lokasi != null
        ? LatLng(order.lokasi!.latitude, order.lokasi!.longitude)
        : _pusatSampit;
    final titikKru = posisiKru != null
        ? LatLng(posisiKru.latitude, posisiKru.longitude)
        : null;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: titikKru ?? tujuan,
            initialZoom: 14.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tuntaskilat.pelanggan',
            ),
            if (titikKru != null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final ruteAsync = ref.watch(osrmRouteProvider(
                      (start: titikKru, end: tujuan)));
                  return ruteAsync.when(
                    data: (points) {
                      return PolylineLayer(polylines: [
                        if (points.isNotEmpty)
                          Polyline(
                            points: points,
                            color: TkColors.primary,
                            strokeWidth: 4,
                          )
                        else
                          Polyline(
                            points: [titikKru, tujuan],
                            color: TkColors.primary,
                            strokeWidth: 4,
                            pattern: const StrokePattern.dotted(spacingFactor: 3),
                          ),
                      ]);
                    },
                    loading: () => PolylineLayer(polylines: [
                      Polyline(
                        points: [titikKru, tujuan],
                        color: TkColors.primary.withValues(alpha: 0.5),
                        strokeWidth: 4,
                        pattern: const StrokePattern.dotted(spacingFactor: 3),
                      ),
                    ]),
                    error: (err, stack) => PolylineLayer(polylines: [
                      Polyline(
                        points: [titikKru, tujuan],
                        color: TkColors.primary,
                        strokeWidth: 4,
                        pattern: const StrokePattern.dotted(spacingFactor: 3),
                      ),
                    ]),
                  );
                },
              ),
            ],
            MarkerLayer(markers: [
              Marker(
                point: tujuan,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.location_on_rounded,
                    size: 36, color: TkColors.error),
              ),
              if (titikKru != null)
                Marker(
                  point: titikKru,
                  width: 46,
                  height: 46,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TkColors.surface,
                      border: Border.all(color: TkColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: TkColors.inkSoft.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.local_shipping_outlined,
                        size: 22, color: TkColors.primary),
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
                    opacity: 0.85,
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: TkColors.inkSoft),
                    ),
                  ),
                ),
                GlassContainer(
                  radius: 13,
                  opacity: 0.85,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text('#${order.orderId}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft)),
                ),
              ],
            ),
          ),
        ),
        if (streamTerputus && posisiKru != null)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 64),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: TkColors.accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Koneksi terputus — menampilkan posisi terakhir kru.',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TkColors.onAccent),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                14, 0, 14, 20 + MediaQuery.paddingOf(context).bottom),
            child: _KartuStatus(
              order: order,
              kru: kru,
              posisiKru: posisiKru,
            ),
          ),
        ),
      ],
    );
  }
}

class _KartuStatus extends StatelessWidget {
  const _KartuStatus({
    required this.order,
    required this.kru,
    required this.posisiKru,
  });

  final OrderModel order;
  final KruModel? kru;
  final GeoPoint? posisiKru;

  /// 4 tahap progres (Hi-Fi): Dikonfirmasi → Menuju lokasi → Pengerjaan →
  /// Selesai, dipetakan dari State Diagram 3.11.
  int get _tahapAktif => switch (order.status) {
        OrderStatus.terverifikasi ||
        OrderStatus.menungguPenugasan ||
        OrderStatus.ditugaskan =>
          1,
        OrderStatus.dalamPerjalanan => 2,
        OrderStatus.diproses => 3,
        OrderStatus.selesai || OrderStatus.dinilai => 4,
        _ => 0,
      };

  String get _judulStatus => switch (order.status) {
        OrderStatus.dalamPerjalanan => 'KRU DALAM PERJALANAN',
        OrderStatus.diproses => 'PENGERJAAN BERLANGSUNG',
        OrderStatus.selesai || OrderStatus.dinilai => 'PESANAN SELESAI',
        OrderStatus.ditugaskan => 'KRU DITUGASKAN',
        _ => StatusBadge.labelOf(order.status).toUpperCase(),
      };

  double? get _jarakKm {
    if (posisiKru == null || order.lokasi == null) return null;
    return Geolocator.distanceBetween(
          posisiKru!.latitude,
          posisiKru!.longitude,
          order.lokasi!.latitude,
          order.lokasi!.longitude,
        ) /
        1000;
  }

  Future<void> _luncurkan(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tidak dapat membuka aplikasi telepon.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jarak = _jarakKm;
    // Estimasi sederhana: kecepatan rata-rata dalam kota ~30 km/jam.
    final etaMenit = jarak == null ? null : (jarak / 30 * 60).ceil();

    return GlassContainer(
      radius: TkRadius.sheet,
      opacity: 0.72,
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TkColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: TkColors.primary)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(_judulStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: TkColors.primaryDark,
                                    letterSpacing: 0.3)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      order.status == OrderStatus.dalamPerjalanan &&
                              etaMenit != null
                          ? 'Tiba dalam ± $etaMenit menit'
                          : StatusBadge.labelOf(order.status),
                      style: GoogleFonts.montserrat(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft),
                    ),
                  ],
                ),
              ),
              if (jarak != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: TkColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: TkColors.inkSoft.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(children: [
                    Text(jarak.toStringAsFixed(1).replaceAll('.', ','),
                        style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primary,
                            height: 1)),
                    Text('km',
                        style: GoogleFonts.montserrat(
                            fontSize: 10, color: TkColors.textMuted)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i < _tahapAktif
                        ? TkColors.primary
                        : TkColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (i, label) in const [
                (0, 'Dikonfirmasi'),
                (1, 'Menuju lokasi'),
                (2, 'Pengerjaan'),
                (3, 'Selesai'),
              ])
                Text(label,
                    style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: i < _tahapAktif
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: i < _tahapAktif
                            ? TkColors.primary
                            : const Color(0xFFA6AEA9))),
            ],
          ),
          if (kru != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: TkColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      kru!.nama.isEmpty
                          ? 'TK'
                          : kru!.nama
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((k) => k[0].toUpperCase())
                              .join(),
                      style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primaryDark),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkColors.primary,
                        border: Border.all(
                            color: TkColors.surface, width: 2.5),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 12, color: TkColors.surface),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kru!.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: TkColors.accent),
                      const SizedBox(width: 3),
                      Text(
                          kru!.rataRating
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TkColors.inkSoft)),
                      const SizedBox(width: 8),
                      Text('${kru!.jumlahUlasan.round()} ulasan',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: TkColors.textMuted)),
                      const SizedBox(width: 8),
                      Text('Kru terverifikasi',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TkColors.primaryDark)),
                    ]),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pushNamed('/p16', arguments: {
                    'orderId': order.orderId,
                    'namaKru': kru!.nama,
                    'noTelpKru': kru!.noTelepon,
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: TkColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: TkColors.border, width: 1.5),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: TkColors.primary),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final phone = kru!.noTelepon.startsWith('0') 
                      ? kru!.noTelepon.substring(1) 
                      : kru!.noTelepon;
                  final url = Uri.parse('https://wa.me/62$phone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    if (context.mounted) {
                      _luncurkan(context, Uri(scheme: 'tel', path: kru!.noTelepon));
                    }
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: TkColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color:
                              TkColors.primary.withValues(alpha: 0.26),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.call_rounded,
                      size: 20, color: TkColors.surface),
                ),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Kru akan ditampilkan di sini setelah admin menugaskan.',
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: TkColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
