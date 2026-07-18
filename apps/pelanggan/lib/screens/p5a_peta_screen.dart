import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/osrm_provider.dart';

/// Hasil pemilihan titik dari peta fullscreen.
typedef HasilPeta = ({GeoPoint lokasi, String alamat, bool isRemote});

/// P5a — Peta Fullscreen untuk memilih titik lokasi (gaya Google/Gojek):
/// pin tetap di tengah, geser peta → pin pindah, alamat terisi otomatis
/// (reverse-geocode Nominatim). Tombol "Lokasi Saya" (GPS). Kembalikan
/// [HasilPeta] via Navigator.pop.
class P5aPetaScreen extends ConsumerStatefulWidget {
  const P5aPetaScreen({super.key, this.awal});

  static const route = '/p5a';

  /// Titik awal peta (bila pelanggan sudah pernah memilih).
  final LatLng? awal;

  @override
  ConsumerState<P5aPetaScreen> createState() => _P5aPetaScreenState();
}

class _P5aPetaScreenState extends ConsumerState<P5aPetaScreen> {
  static const _pusatSampit = LatLng(-2.5329, 112.9508);
  final _mapCtrl = MapController();
  late LatLng _tengah = widget.awal ?? _pusatSampit;
  String _alamat = '';
  bool _memuatAlamat = false;
  bool _cariGps = false;
  bool _isRemote = true; // Default true (karena geser manual)
  final _searchCtrl = TextEditingController();
  bool _mencariAlamat = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _perbaruiAlamat());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapCtrl.dispose();
    super.dispose();
  }

  void _onGeser(MapCamera cam, bool selesai) {
    _tengah = cam.center;
    if (selesai) {
      _isRemote = true; // Digeser manual berarti remote
      // Debounce reverse-geocode (kebijakan Nominatim ~1 req/detik).
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), _perbaruiAlamat);
    }
  }

  Future<void> _perbaruiAlamat() async {
    if (!mounted) return;
    setState(() => _memuatAlamat = true);
    try {
      final hasil = await ref.read(reverseGeocodeProvider(
              (lat: _tengah.latitude, lng: _tengah.longitude))
          .future);
      if (mounted) setState(() => _alamat = hasil);
    } catch (_) {
      // Diamkan — user tetap bisa mengetik alamat manual di P5.
    } finally {
      if (mounted) setState(() => _memuatAlamat = false);
    }
  }

  Future<void> _lokasiSaya() async {
    setState(() => _cariGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Aktifkan GPS perangkat Anda.');
        return;
      }
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        _snack('Izin lokasi ditolak. Geser peta untuk memilih titik.');
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      _tengah = LatLng(p.latitude, p.longitude);
      _isRemote = false; // Lokasi dari GPS
      _mapCtrl.move(_tengah, 17);
      _perbaruiAlamat();
    } catch (_) {
      _snack('Gagal mendapatkan lokasi. Geser peta untuk memilih titik.');
    } finally {
      if (mounted) setState(() => _cariGps = false);
    }
  }

  Future<void> _cariAlamat() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _mencariAlamat = true);
    try {
      final hasil = await ref.read(forwardGeocodeProvider(query).future);
      if (hasil != null) {
        _tengah = hasil;
        _isRemote = true; // Hasil pencarian adalah remote
        _mapCtrl.move(_tengah, 17);
        _perbaruiAlamat();
      } else {
        _snack('Alamat tidak ditemukan.');
      }
    } catch (_) {
      _snack('Gagal mencari alamat.');
    } finally {
      if (mounted) setState(() => _mencariAlamat = false);
    }
  }

  void _snack(String s) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s)));

  void _konfirmasi() {
    if (!Validators.isDalamWilayahSampit(
        _tengah.latitude, _tengah.longitude)) {
      _snack('Titik di luar area layanan Kota Sampit (Out of Delivery Range).');
      return;
    }
    Navigator.of(context).pop<HasilPeta>((
      lokasi: GeoPoint(_tengah.latitude, _tengah.longitude),
      alamat: _alamat,
      isRemote: _isRemote,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _tengah,
            initialZoom: 16,
            onPositionChanged: _onGeser,
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tuntaskilat.pelanggan',
            ),
          ],
        ),
        // Pin tetap di tengah layar.
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 34),
              child: Icon(Icons.location_on_rounded,
                  size: 52,
                  color: TkColors.primary,
                  shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                  ]),
            ),
          ),
        ),
        // Tombol kembali.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TombolBulat(
                  ikon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: TkColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _cariAlamat(),
                              decoration: const InputDecoration(
                                hintText: 'Cari alamat / kota lain...',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ),
                          if (_mencariAlamat)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.search, color: TkColors.primary),
                              onPressed: _cariAlamat,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Panel bawah + tombol Lokasi Saya mengambang tepat di atasnya.
        // (Dulu Positioned bottom:200 tetap → ketutup panel saat alamat 2
        // baris. Kini FAB satu kolom dengan panel → selalu di atas panel.)
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _TombolBulat(
                    ikon: _cariGps ? null : Icons.my_location_rounded,
                    loading: _cariGps,
                    onTap: _cariGps ? null : _lokasiSaya,
                  ),
                ),
              ),
              Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              color: TkColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, -8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Titik lokasi layanan',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.textMuted)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.place_outlined,
                      size: 18, color: TkColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _memuatAlamat
                        ? Text('Mencari alamat…',
                            style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                color: TkColors.textSecondary))
                        : Text(
                            _alamat.isEmpty
                                ? 'Geser peta untuk menempatkan pin'
                                : _alamat,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: TkColors.inkSoft,
                                height: 1.4)),
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TkButton(
                    label: 'Gunakan Titik Ini',
                    onPressed: _konfirmasi,
                  ),
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
}

class _TombolBulat extends StatelessWidget {
  const _TombolBulat({required this.ikon, this.onTap, this.loading = false});
  final IconData? ikon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) => Material(
        color: TkColors.surface,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: TkColors.primary))
                : Icon(ikon, size: 20, color: TkColors.inkSoft),
          ),
        ),
      );
}
