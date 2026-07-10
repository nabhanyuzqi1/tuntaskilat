import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/beranda_providers.dart';
import '../providers/pemesanan_providers.dart';
import 'p5a_peta_screen.dart';
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
  PilihanHarga? _pilihan;
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
      _pilihan = draft.pilihan;
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

  /// Buka peta fullscreen (pin geser + alamat otomatis). Isi lokasi + alamat.
  Future<void> _bukaPeta() async {
    final hasil = await Navigator.of(context).push<HasilPeta>(
      MaterialPageRoute(
        builder: (_) => P5aPetaScreen(
          awal: _lokasi != null
              ? LatLng(_lokasi!.latitude, _lokasi!.longitude)
              : null,
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      _lokasi = hasil.lokasi;
      if (hasil.alamat.isNotEmpty) _alamat.text = hasil.alamat;
    });
    _mapCtrl.move(
        LatLng(hasil.lokasi.latitude, hasil.lokasi.longitude), 16);
  }

  /// Pakai alamat tersimpan pelanggan.
  void _pakaiAlamat(AlamatModel a) {
    setState(() {
      _lokasi = a.lokasi;
      _alamat.text = a.alamat;
    });
    _mapCtrl.move(LatLng(a.lokasi.latitude, a.lokasi.longitude), 16);
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
    final sebelumnya = ref.read(draftPesananProvider);
    ref.read(draftPesananProvider.notifier).state = DraftPesanan(
      layanan: layanan,
      pilihan: _pilihan ?? pilihanDefault(layanan),
      tanggal: _tanggalPilih,
      jam: _jamPilih,
      alamat: _alamat.text.trim(),
      lokasi: _lokasi,
      catatan: _catatan.text.trim(),
      // Pertahankan voucher yang mungkin sudah dipasang di P6.
      voucherKode: sebelumnya?.voucherKode ?? '',
      voucher: sebelumnya?.voucher,
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
    final pilihan = _pilihan ??= pilihanDefault(layanan);
    final hasil = layanan.hitungHarga(pilihan);

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
                  _PemilihHarga(
                    layanan: layanan,
                    pilihan: pilihan,
                    onUbah: (p) => setState(() => _pilihan = p),
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
                      serviceId: layanan.serviceId,
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
                  Text('Pilih alamat tersimpan, buka peta, atau ketuk peta '
                      'kecil di bawah.',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                  const SizedBox(height: 12),
                  // Alamat tersimpan (chip) — tak perlu ketik ulang.
                  Consumer(builder: (context, ref, _) {
                    final uid = ref
                        .watch(profilSayaProvider)
                        .valueOrNull
                        ?.userId;
                    if (uid == null) return const SizedBox.shrink();
                    final alamat = ref
                            .watch(alamatTersimpanProvider(uid))
                            .valueOrNull ??
                        const [];
                    if (alamat.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in alamat)
                            ActionChip(
                              avatar: const Icon(Icons.bookmark_border_rounded,
                                  size: 16, color: TkColors.primary),
                              label: Text(a.label),
                              labelStyle: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.primaryDark),
                              backgroundColor:
                                  TkColors.primary.withValues(alpha: 0.07),
                              side: BorderSide(
                                  color: TkColors.primary
                                      .withValues(alpha: 0.18)),
                              onPressed: () => _pakaiAlamat(a),
                            ),
                        ],
                      ),
                    );
                  }),
                  // Buka peta fullscreen (pin geser + alamat otomatis).
                  OutlinedButton.icon(
                    onPressed: _bukaPeta,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Buka Peta & Cari Alamat'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: TkColors.primary,
                      side: BorderSide(
                          color: TkColors.primary.withValues(alpha: 0.4)),
                    ),
                  ),
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
              hasil: hasil,
              loading: false,
              onLanjut: () => _submit(layanan),
            ),
          ],
        ),
      ),
    );
  }

}

/// Pilihan harga awal berdasarkan skema layanan.
PilihanHarga pilihanDefault(ServiceModel s) {
  switch (s.tipeHarga) {
    case TipeHarga.perLuas:
      return PilihanHarga(
          tierId: s.tiers.isNotEmpty ? s.tiers.first.id : null, luas: 10);
    case TipeHarga.paket:
      final p = s.paketOpsi.isNotEmpty ? s.paketOpsi.first : null;
      return PilihanHarga(
        paketId: p?.id,
        durasiJam: (p != null && p.durasi.isNotEmpty) ? p.durasi.first.jam : null,
        addOnIds: const [],
      );
    case TipeHarga.mulaiDari:
      return const PilihanHarga(kuantitas: 1);
  }
}

/// Selektor harga dinamis sesuai pricelist TK: kuantitas (mulai dari),
/// tier + luas m² (jasa rumput), atau paket + durasi + tambah jam + add-on
/// (home cleaning). Menghasilkan [PilihanHarga] via [onUbah].
class _PemilihHarga extends StatefulWidget {
  const _PemilihHarga(
      {required this.layanan, required this.pilihan, required this.onUbah});

  final ServiceModel layanan;
  final PilihanHarga pilihan;
  final ValueChanged<PilihanHarga> onUbah;

  @override
  State<_PemilihHarga> createState() => _PemilihHargaState();
}

class _PemilihHargaState extends State<_PemilihHarga> {
  late final TextEditingController _luas =
      TextEditingController(text: widget.pilihan.luas?.toString() ?? '');

  @override
  void dispose() {
    _luas.dispose();
    super.dispose();
  }

  PilihanHarga get p => widget.pilihan;

  @override
  Widget build(BuildContext context) {
    switch (widget.layanan.tipeHarga) {
      case TipeHarga.mulaiDari:
        return _Stepper(
          label: 'Jumlah',
          sub: 'Mulai dari ${PriceBadge.formatRupiah(widget.layanan.harga)}',
          nilai: p.kuantitas,
          onUbah: (v) => widget.onUbah(p.copyWith(kuantitas: v)),
        );

      case TipeHarga.perLuas:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JudulBagian('Kondisi Lahan'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in widget.layanan.tiers)
                  _Chip(
                    label:
                        '${t.nama}  ·  ${PriceBadge.formatRupiah(t.hargaPerM2)}/m²',
                    aktif: (p.tierId ?? widget.layanan.tiers.first.id) == t.id,
                    onTap: () => widget.onUbah(p.copyWith(tierId: t.id)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _JudulBagian('Luas Area (m²)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _luas,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TkColors.inkSoft),
              decoration: const InputDecoration(
                hintText: 'mis. 60',
                suffixText: 'm²',
              ),
              onChanged: (v) {
                final luas = num.tryParse(v.replaceAll(',', '.')) ?? 0;
                widget.onUbah(p.copyWith(luas: luas));
              },
            ),
          ],
        );

      case TipeHarga.paket:
        final paket = widget.layanan.paketOpsi.firstWhere(
          (x) => x.id == p.paketId,
          orElse: () => widget.layanan.paketOpsi.isNotEmpty
              ? widget.layanan.paketOpsi.first
              : const PaketOpsi(
                  id: '', nama: '-', jumlahPetugas: 1, durasi: [], hargaTambahJam: 0),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JudulBagian('Pilih Paket'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pk in widget.layanan.paketOpsi)
                  _Chip(
                    label: '${pk.nama} · ${pk.jumlahPetugas} petugas',
                    aktif: paket.id == pk.id,
                    onTap: () => widget.onUbah(p.copyWith(
                      paketId: pk.id,
                      durasiJam:
                          pk.durasi.isNotEmpty ? pk.durasi.first.jam : null,
                    )),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _JudulBagian('Durasi'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in paket.durasi)
                  _Chip(
                    label: '${d.jam} jam · ${PriceBadge.formatRupiah(d.harga)}',
                    aktif: (p.durasiJam ??
                            (paket.durasi.isNotEmpty
                                ? paket.durasi.first.jam
                                : 0)) ==
                        d.jam,
                    onTap: () => widget.onUbah(p.copyWith(durasiJam: d.jam)),
                  ),
              ],
            ),
            if (paket.hargaTambahJam > 0) ...[
              const SizedBox(height: 16),
              _Stepper(
                label: 'Tambah Jam',
                sub: '${PriceBadge.formatRupiah(paket.hargaTambahJam)} / jam',
                nilai: p.tambahJam,
                onUbah: (v) =>
                    widget.onUbah(p.copyWith(tambahJam: v.round())),
              ),
            ],
            if (widget.layanan.addOns.isNotEmpty) ...[
              const SizedBox(height: 16),
              _JudulBagian('Layanan Tambahan'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in widget.layanan.addOns)
                    _Chip(
                      label:
                          '${a.nama}  +${PriceBadge.formatRupiah(a.harga)}',
                      aktif: p.addOnIds.contains(a.id),
                      onTap: () {
                        final baru = List<String>.from(p.addOnIds);
                        baru.contains(a.id)
                            ? baru.remove(a.id)
                            : baru.add(a.id);
                        widget.onUbah(p.copyWith(addOnIds: baru));
                      },
                    ),
                ],
              ),
            ],
          ],
        );
    }
  }
}

/// Chip pilihan (tier/paket/durasi/add-on) bergaya brand.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.aktif, required this.onTap});
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: aktif
                ? TkColors.primary
                : TkColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: aktif
                    ? TkColors.primary
                    : TkColors.primary.withValues(alpha: 0.16)),
          ),
          child: Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: aktif ? TkColors.surface : TkColors.primaryDark)),
        ),
      );
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
    required this.serviceId,
    required this.onPilih,
  });

  final DateTime hari;
  final int? terpilih;
  final String serviceId;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terisi = ref
            .watch(slotTerisiProvider((
              serviceId: serviceId,
              hari: DateTime(hari.year, hari.month, hari.day)
            )))
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
    required this.hasil,
    required this.loading,
    required this.onLanjut,
  });

  final HasilHarga hasil;
  final bool loading;
  final VoidCallback onLanjut;

  @override
  Widget build(BuildContext context) {
    // Harga dinamis: subtotal = hasil kalkulasi model (dihitung ulang backend).
    final subtotal = hasil.subtotal;

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
              Flexible(
                child: Text(
                  hasil.rincian.isEmpty ? '' : hasil.rincian.first.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: TkColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in hasil.rincian) ...[
            baris(r.label, PriceBadge.formatRupiah(r.jumlah)),
            const SizedBox(height: 5),
          ],
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
