import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/pemesanan_providers.dart';
import '../widgets/service_icon.dart';
import 'p6_rincian_tagihan_screen.dart';

/// P5 — Form Pemesanan (Gambar TA 3.15 & 4.2). Input kuantitas, jadwal
/// (kalender + slot; slot terisi disabled + gembok — wujud visual Atomic
/// Locking), alamat + GPS, catatan. Estimasi tarif real-time di sheet bawah.
class P5FormPemesananScreen extends ConsumerStatefulWidget {
  const P5FormPemesananScreen({super.key});

  static const route = '/p5';

  @override
  ConsumerState<P5FormPemesananScreen> createState() =>
      _P5FormPemesananScreenState();
}

class _P5FormPemesananScreenState
    extends ConsumerState<P5FormPemesananScreen> {
  num _kuantitas = 1;
  late DateTime _bulanTampil;
  DateTime? _tanggalPilih;
  int? _jamPilih;
  GeoPoint? _lokasi;
  var _mencariLokasi = false;
  var _cobaSubmit = false; // tandai field wajib yang belum diisi
  final _alamat = TextEditingController();
  final _catatan = TextEditingController();

  @override
  void initState() {
    super.initState();
    final kini = DateTime.now();
    _bulanTampil = DateTime(kini.year, kini.month);
    // Pulihkan draft (mis. saat kembali dari P6 untuk mengedit).
    final draft = ref.read(draftPesananProvider);
    if (draft != null) {
      _kuantitas = draft.kuantitas;
      _tanggalPilih = draft.tanggal;
      _jamPilih = draft.jam;
      _lokasi = draft.lokasi;
      _alamat.text = draft.alamat;
      _catatan.text = draft.catatan;
      if (draft.tanggal != null) {
        _bulanTampil = DateTime(draft.tanggal!.year, draft.tanggal!.month);
      }
    }
  }

  @override
  void dispose() {
    _alamat.dispose();
    _catatan.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  DateTime? get _jadwal => _tanggalPilih == null || _jamPilih == null
      ? null
      : DateTime(_tanggalPilih!.year, _tanggalPilih!.month,
          _tanggalPilih!.day, _jamPilih!);

  void _snack(String pesan) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));

  final _mapCtrl = MapController();
  static const _pusatSampit = LatLng(-2.5329, 112.9508);

  void _pilihTitikPeta(LatLng titik) {
    if (!Validators.isDalamWilayahSampit(titik.latitude, titik.longitude)) {
      _snack('Titik di luar area layanan Kota Sampit (Out of Delivery '
          'Range). Pilih titik dalam kota.');
      return;
    }
    setState(() => _lokasi = GeoPoint(titik.latitude, titik.longitude));
  }

  Future<void> _ambilLokasi() async {
    setState(() => _mencariLokasi = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('Aktifkan layanan lokasi (GPS) perangkat Anda, atau ketuk '
            'peta untuk memilih titik manual.');
        return;
      }
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.deniedForever) {
        _snack('Izin lokasi diblokir permanen. Buka Pengaturan aplikasi, '
            'atau ketuk peta untuk memilih titik manual.');
        return;
      }
      if (izin == LocationPermission.denied) {
        _snack('Izin lokasi ditolak. Ketuk peta untuk memilih titik '
            'manual.');
        return;
      }
      final posisi = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      final titik = LatLng(posisi.latitude, posisi.longitude);
      if (!Validators.isDalamWilayahSampit(titik.latitude, titik.longitude)) {
        _snack('Lokasi Anda di luar area layanan Kota Sampit '
            '(Out of Delivery Range).');
        return;
      }
      setState(() => _lokasi = GeoPoint(titik.latitude, titik.longitude));
      _mapCtrl.move(titik, 16);
    } catch (_) {
      _snack('Gagal mendapatkan lokasi GPS. Ketuk peta untuk memilih titik '
          'manual.');
    } finally {
      if (mounted) setState(() => _mencariLokasi = false);
    }
  }

  void _simpanDraft(ServiceModel layanan) {
    ref.read(draftPesananProvider.notifier).state = DraftPesanan(
      layanan: layanan,
      kuantitas: _kuantitas,
      tanggal: _tanggalPilih,
      jam: _jamPilih,
      alamat: _alamat.text.trim(),
      lokasi: _lokasi,
      catatan: _catatan.text.trim(),
    );
  }

  Future<void> _submit(ServiceModel layanan) async {
    setState(() => _cobaSubmit = true);
    if (_jadwal == null) {
      _snack('Pilih tanggal dan slot waktu terlebih dahulu.');
      return;
    }
    if (_alamat.text.trim().isEmpty) {
      _snack('Isi alamat layanan terlebih dahulu.');
      return;
    }
    if (_lokasi == null) {
      _snack('Tandai titik lokasi di peta ("Lokasi Saya" atau ketuk peta).');
      return;
    }
    final errCatatan = Validators.teksBebas(_catatan.text);
    if (errCatatan != null) {
      _snack(errCatatan);
      return;
    }
    // Simpan draft dan lanjut ke Rincian Tagihan (order belum dibuat —
    // kunci slot terjadi saat konfirmasi pembayaran di P7).
    _simpanDraft(layanan);
    Navigator.of(context).pushNamed(P6RincianTagihanScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final layanan =
        ModalRoute.of(context)!.settings.arguments as ServiceModel;
    final satuan = satuanSingkat(layanan.satuan);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(subjudul: layanan.namaLayanan),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                children: [
                  _Stepper(
                    label: 'Jumlah ${_labelSatuan(satuan)}',
                    sub: '${PriceBadge.formatRupiah(layanan.harga)} '
                        'per $satuan',
                    nilai: _kuantitas,
                    onUbah: (v) => setState(() => _kuantitas = v),
                  ),
                  const SizedBox(height: 22),
                  _JudulBagian('Pilih Tanggal'),
                  const SizedBox(height: 12),
                  _Kalender(
                    bulan: _bulanTampil,
                    terpilih: _tanggalPilih,
                    onBulan: (b) => setState(() => _bulanTampil = b),
                    onPilih: (t) => setState(() {
                      _tanggalPilih = t;
                      _jamPilih = null;
                    }),
                  ),
                  const SizedBox(height: 22),
                  if (_tanggalPilih != null) ...[
                    _JudulSlot(),
                    const SizedBox(height: 12),
                    _GridSlot(
                      hari: _tanggalPilih!,
                      terpilih: _jamPilih,
                      onPilih: (jam) => setState(() => _jamPilih = jam),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Row(children: [
                    _JudulBagian('Alamat Layanan'),
                    Text(' *',
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TkColors.error)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Ketuk peta untuk menandai titik, atau gunakan '
                      '"Lokasi Saya".',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                  const SizedBox(height: 12),
                  _KartuAlamatPeta(
                    mapCtrl: _mapCtrl,
                    pusatAwal: _lokasi != null
                        ? LatLng(_lokasi!.latitude, _lokasi!.longitude)
                        : _pusatSampit,
                    controller: _alamat,
                    lokasi: _lokasi,
                    mencari: _mencariLokasi,
                    wajibBelumDiisi: _cobaSubmit && _lokasi == null,
                    alamatBelumDiisi:
                        _cobaSubmit && _alamat.text.trim().isEmpty,
                    onLokasiSaya: _ambilLokasi,
                    onKetukPeta: _pilihTitikPeta,
                    onAlamatUbah: () => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _JudulBagian('Catatan Khusus'),
                      const SizedBox(width: 6),
                      Text('(opsional)',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: const Color(0xFFA6AEA9))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _catatan,
                    maxLines: 3,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: Validators.teksBebas,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: TkColors.inkSoft, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Contoh: rumah 2 lantai, ada hewan '
                          'peliharaan, fokus dapur & kamar mandi…',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: TkColors.textPlaceholder,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            _SheetEstimasi(
              layanan: layanan,
              kuantitas: _kuantitas,
              satuan: satuan,
              loading: false,
              onLanjut: () => _submit(layanan),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelSatuan(String satuan) => switch (satuan) {
        'ruang' => 'Ruangan',
        'jam' => 'Jam',
        'm²' => 'Meter Persegi',
        _ => satuan[0].toUpperCase() + satuan.substring(1),
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.subjudul});

  final String subjudul;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: Navigator.of(context).pop,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: TkColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: TkColors.inkSoft),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Form Pemesanan',
                  style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              Text(subjudul,
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: TkColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Text(teks,
      style: GoogleFonts.montserrat(
          fontSize: 15, fontWeight: FontWeight.w600, color: TkColors.inkSoft));
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.sub,
    required this.nilai,
    required this.onUbah,
  });

  final String label;
  final String sub;
  final num nilai;
  final ValueChanged<num> onUbah;

  @override
  Widget build(BuildContext context) {
    Widget tombol(IconData ikon, bool utama, VoidCallback? onTap) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: onTap == null
                  ? const Color(0xFFF0F2EF)
                  : utama
                      ? TkColors.primary
                      : TkColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(ikon,
                size: 18,
                color: onTap == null
                    ? const Color(0xFFB4BBB6)
                    : utama
                        ? TkColors.surface
                        : TkColors.primary),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JudulBagian(label),
            const SizedBox(height: 2),
            Text(sub,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textMuted)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: TkColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              tombol(Icons.remove, false,
                  nilai <= 1 ? null : () => onUbah(nilai - 1)),
              SizedBox(
                width: 48,
                child: Text('${nilai.round()}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
              ),
              tombol(Icons.add, true, () => onUbah(nilai + 1)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Format tanggal/jadwal berbahasa Indonesia — dipakai P5, P6, dan
/// layar-layar berikutnya (tanpa dependensi intl).
class JudulHariID {
  static const hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  static const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
    'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// "Sabtu, 11 Juli 2026"
  static String tanggal(DateTime t) =>
      '${hari[t.weekday - 1]}, ${t.day} ${bulan[t.month - 1]} ${t.year}';

  /// "Sabtu, 11 Juli 2026 10.00"
  static String format(DateTime t) =>
      '${tanggal(t)} ${t.hour.toString().padLeft(2, '0')}.00';
}

class _Kalender extends StatelessWidget {
  const _Kalender({
    required this.bulan,
    required this.terpilih,
    required this.onBulan,
    required this.onPilih,
  });

  final DateTime bulan;
  final DateTime? terpilih;
  final ValueChanged<DateTime> onBulan;
  final ValueChanged<DateTime> onPilih;

  @override
  Widget build(BuildContext context) {
    final kini = DateTime.now();
    final hariIni = DateTime(kini.year, kini.month, kini.day);
    final bulanIni = DateTime(kini.year, kini.month);
    final bisaMundur = bulan.isAfter(bulanIni);

    final awalBulan = DateTime(bulan.year, bulan.month, 1);
    // Grid mulai Senin (S S R K J S M).
    final mulaiGrid =
        awalBulan.subtract(Duration(days: awalBulan.weekday - 1));
    final jumlahMinggu =
        ((DateTime(bulan.year, bulan.month + 1, 0).day +
                    awalBulan.weekday -
                    1) /
                7)
            .ceil();

    Widget navBtn(IconData ikon, VoidCallback? onTap) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: TkColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ikon,
                size: 15,
                color: onTap == null
                    ? const Color(0xFFC4CBC6)
                    : TkColors.textSecondary),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x140F281C)),
        borderRadius: BorderRadius.circular(TkRadius.card),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${JudulHariID.bulan[bulan.month - 1]} ${bulan.year}',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft),
              ),
              Row(children: [
                navBtn(
                    Icons.chevron_left_rounded,
                    bisaMundur
                        ? () =>
                            onBulan(DateTime(bulan.year, bulan.month - 1))
                        : null),
                const SizedBox(width: 8),
                navBtn(Icons.chevron_right_rounded,
                    () => onBulan(DateTime(bulan.year, bulan.month + 1))),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final h in ['S', 'S', 'R', 'K', 'J', 'S', 'M'])
                Expanded(
                  child: Text(h,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA6AEA9))),
                ),
            ],
          ),
          for (var m = 0; m < jumlahMinggu; m++)
            Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: _sel(
                      mulaiGrid.add(Duration(days: m * 7 + d)),
                      hariIni,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sel(DateTime tanggal, DateTime hariIni) {
    final diBulanIni =
        tanggal.month == bulan.month && tanggal.year == bulan.year;
    final lampau = tanggal.isBefore(hariIni);
    final aktif = diBulanIni && !lampau;
    final dipilih = terpilih != null &&
        tanggal.year == terpilih!.year &&
        tanggal.month == terpilih!.month &&
        tanggal.day == terpilih!.day;

    if (dipilih) {
      return Center(
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: TkColors.primary,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                  color: TkColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          alignment: Alignment.center,
          child: Text('${tanggal.day}',
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TkColors.surface)),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aktif ? () => onPilih(tanggal) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('${tanggal.day}',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    aktif ? TkColors.inkSoft : const Color(0xFFC4CBC6))),
      ),
    );
  }
}

class _JudulSlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _JudulBagian('Slot Waktu'),
        Row(children: [
          const Icon(Icons.lock_outline_rounded,
              size: 13, color: Color(0xFFA6AEA9)),
          const SizedBox(width: 5),
          Text('= sudah terisi',
              style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFA6AEA9))),
        ]),
      ],
    );
  }
}

class _GridSlot extends ConsumerWidget {
  const _GridSlot({
    required this.hari,
    required this.terpilih,
    required this.onPilih,
  });

  final DateTime hari;
  final int? terpilih;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terisi = ref
            .watch(slotTerisiProvider(
                DateTime(hari.year, hari.month, hari.day)))
            .valueOrNull ??
        const <DateTime>{};
    final kini = DateTime.now();

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        for (final jam in FirestoreService.jamSlot)
          _slot(
            jam,
            sudahTerisi: terisi.any((t) => t.hour == jam),
            lampau: DateTime(hari.year, hari.month, hari.day, jam)
                .isBefore(kini),
          ),
      ],
    );
  }

  Widget _slot(int jam, {required bool sudahTerisi, required bool lampau}) {
    final label = '${jam.toString().padLeft(2, '0')}.00';
    final nonaktif = sudahTerisi || lampau;
    final dipilih = terpilih == jam;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: nonaktif ? null : () => onPilih(jam),
      child: Container(
        decoration: BoxDecoration(
          color: nonaktif
              ? const Color(0xFFF0F2EF)
              : dipilih
                  ? TkColors.primary
                  : null,
          border: nonaktif || dipilih
              ? null
              : Border.all(color: TkColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(11),
          boxShadow: dipilih
              ? [
                  BoxShadow(
                      color: TkColors.primary.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (sudahTerisi) ...[
              const Icon(Icons.lock_outline_rounded,
                  size: 13, color: Color(0xFFB4BBB6)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: nonaktif
                    ? const Color(0xFFB4BBB6)
                    : dipilih
                        ? TkColors.surface
                        : const Color(0xFF33403A),
                decoration:
                    sudahTerisi ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuAlamatPeta extends StatelessWidget {
  const _KartuAlamatPeta({
    required this.mapCtrl,
    required this.pusatAwal,
    required this.controller,
    required this.lokasi,
    required this.mencari,
    required this.wajibBelumDiisi,
    required this.alamatBelumDiisi,
    required this.onLokasiSaya,
    required this.onKetukPeta,
    required this.onAlamatUbah,
  });

  final MapController mapCtrl;
  final LatLng pusatAwal;
  final TextEditingController controller;
  final GeoPoint? lokasi;
  final bool mencari;
  final bool wajibBelumDiisi;
  final bool alamatBelumDiisi;
  final VoidCallback onLokasiSaya;
  final ValueChanged<LatLng> onKetukPeta;
  final VoidCallback onAlamatUbah;

  @override
  Widget build(BuildContext context) {
    final titik = lokasi != null
        ? LatLng(lokasi!.latitude, lokasi!.longitude)
        : null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(
          color: wajibBelumDiisi
              ? TkColors.error
              : const Color(0x140F281C),
          width: wajibBelumDiisi ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(TkRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Peta interaktif OpenStreetMap — ketuk untuk menandai titik.
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapCtrl,
                  options: MapOptions(
                    initialCenter: titik ?? pusatAwal,
                    initialZoom: titik != null ? 16 : 13,
                    onTap: (_, p) => onKetukPeta(p),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tuntaskilat.pelanggan',
                    ),
                    if (titik != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: titik,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on_rounded,
                              size: 38, color: TkColors.error),
                        ),
                      ]),
                  ],
                ),
                if (titik == null)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: TkColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('Ketuk peta untuk pilih titik',
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TkColors.inkSoft)),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: mencari ? null : onLokasiSaya,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: TkColors.surface,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  TkColors.inkSoft.withValues(alpha: 0.16),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (mencari)
                            const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: TkColors.primary),
                            )
                          else
                            const Icon(Icons.my_location_rounded,
                                size: 16, color: TkColors.primary),
                          const SizedBox(width: 6),
                          Text('Lokasi Saya',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Icon(Icons.location_on_outlined,
                      size: 18, color: TkColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (_) => onAlamatUbah(),
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft),
                    decoration: InputDecoration(
                      hintText: alamatBelumDiisi
                          ? 'Wajib: tulis alamat lengkap'
                          : 'Tulis alamat lengkap (jalan, nomor, '
                              'kelurahan)',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: alamatBelumDiisi
                              ? TkColors.error
                              : TkColors.textPlaceholder),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (titik != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: TkColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Titik ditandai: '
                      '${titik.latitude.toStringAsFixed(4)}, '
                      '${titik.longitude.toStringAsFixed(4)} — dalam area '
                      'layanan Sampit',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: TkColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetEstimasi extends StatelessWidget {
  const _SheetEstimasi({
    required this.layanan,
    required this.kuantitas,
    required this.satuan,
    required this.loading,
    required this.onLanjut,
  });

  final ServiceModel layanan;
  final num kuantitas;
  final String satuan;
  final bool loading;
  final VoidCallback onLanjut;

  @override
  Widget build(BuildContext context) {
    // Fixed pricing: total = harga × kuantitas, tanpa biaya tambahan
    // (biaya platform ditunda bersama A6 — di luar skema TA).
    final subtotal = layanan.harga * kuantitas;

    Widget baris(String label, String nilai) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textSecondary)),
            Text(nilai,
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ],
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, 22 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(TkRadius.sheet)),
        border:
            const Border(top: BorderSide(color: Color(0x0F0F281C))),
        boxShadow: [
          BoxShadow(
              color: TkColors.inkSoft.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, -10),
              spreadRadius: -12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Estimasi Tarif',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.textSecondary)),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: TkColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('real-time',
                      style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: TkColors.primaryDark)),
                ),
              ]),
              Text(
                '${kuantitas.round()} $satuan × '
                '${PriceBadge.formatRupiah(layanan.harga)}',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TkColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          baris('Subtotal', PriceBadge.formatRupiah(subtotal)),
          const SizedBox(height: 5),
          baris('Biaya layanan', 'Gratis'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: TkColors.textMuted)),
                  Text(PriceBadge.formatRupiah(subtotal),
                      style: GoogleFonts.montserrat(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primary)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TkButton(
                  label: 'Lanjut',
                  loading: loading,
                  onPressed: onLanjut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
