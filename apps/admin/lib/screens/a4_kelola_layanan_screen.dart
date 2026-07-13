import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// A4 — Kelola Layanan (Gambar TA 3.18). CRUD katalog & tarif tetap;
/// toggle aktif per baris (baris nonaktif redup). Ikon memakai identifier
/// Material Design sesuai skema `services.ikon`.
class A4KelolaLayananScreen extends ConsumerWidget {
  const A4KelolaLayananScreen({super.key});

  static const _pilihanSatuan = [
    'per jam', 'per ruangan', 'per m2', 'per dudukan', 'per panel',
    'per unit', 'per sesi',
  ];
  static const _pilihanIkon = [
    ('cleaning_services', Icons.cleaning_services_outlined),
    ('weekend', Icons.weekend_outlined),
    ('window', Icons.window_outlined),
    ('ac_unit', Icons.ac_unit_rounded),
    ('local_laundry_service', Icons.local_laundry_service_outlined),
    ('kitchen', Icons.kitchen_outlined),
    ('bathtub', Icons.bathtub_outlined),
    ('yard', Icons.yard_outlined),
    ('pest_control', Icons.pest_control_outlined),
  ];

  static IconData ikonDari(String id) => _pilihanIkon
      .firstWhere((p) => p.$1 == id,
          orElse: () => _pilihanIkon.first)
      .$2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layanan = ref.watch(semuaLayananProvider).valueOrNull ?? const [];
    final aktifCount = layanan.where((s) => s.aktif).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Kelola Layanan',
        subjudul: '${layanan.length} layanan · $aktifCount aktif',
        aksi: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => _dialogLayanan(context, ref, null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Layanan'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: AdminUi.kartu(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AdminUi.judulTabel(const [
                  ('LAYANAN', 22),
                  ('TARIF', 10),
                  ('TIPE HARGA', 11),
                  ('SATUAN', 8),
                  ('STATUS', 8),
                  ('AKSI', 7),
                ]),
                if (layanan.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Belum ada layanan. Tambahkan yang pertama.',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: TkColors.textMuted)),
                  )
                else
                  for (final s in layanan) _baris(context, ref, s),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _baris(BuildContext context, WidgetRef ref, ServiceModel s) {
    return Opacity(
      opacity: s.aktif ? 1 : 0.62,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x0D0F281C))),
        ),
        child: Row(children: [
          Expanded(
            flex: 24,
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: s.aktif
                      ? TkColors.surfaceMuted
                      : const Color(0xFFF0F2EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(ikonDari(s.ikon),
                    size: 24,
                    color:
                        s.aktif ? TkColors.primary : TkColors.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.namaLayanan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TkColors.inkSoft)),
                    const SizedBox(height: 3),
                    Text(s.deskripsi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: TkColors.textMuted)),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
              flex: 10,
              child: AdminUi.teksSel(PriceBadge.formatRupiah(s.harga),
                  tebal: true)),
          // Kategori harga: statis (tarif tetap × qty / paket) vs dinamis
          // (tier per m²) — permintaan owner agar mudah dikelola dari tabel.
          Expanded(
            flex: 11,
            child: AdminUi.chipSel(
              switch (s.tipeHarga) {
                TipeHarga.mulaiDari => 'Statis · × qty',
                TipeHarga.paket => 'Statis · paket',
                TipeHarga.perLuas => 'Dinamis · per m²',
              },
              s.tipeHarga == TipeHarga.perLuas
                  ? TkColors.accentAlt
                  : TkColors.primary,
            ),
          ),
          Expanded(
              flex: 8,
              child:
                  AdminUi.teksSel(s.satuan.replaceFirst('per ', ''))),
          Expanded(
            flex: 8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Switch(
                value: s.aktif,
                activeTrackColor: TkColors.primary,
                onChanged: (v) => ref
                    .read(firestoreServiceProvider)
                    .setLayananAktif(s.serviceId, v),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => _dialogLayanan(context, ref, s),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: TkColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: TkColors.textSecondary),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _dialogLayanan(
      BuildContext context, WidgetRef ref, ServiceModel? awal) async {
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController(text: awal?.namaLayanan ?? '');
    final deskripsi = TextEditingController(text: awal?.deskripsi ?? '');
    final harga =
        TextEditingController(text: awal == null ? '' : '${awal.harga}');
    var satuan = awal?.satuan ?? _pilihanSatuan.first;
    var ikon = awal?.ikon ?? _pilihanIkon.first.$1;
    var aktif = awal?.aktif ?? true;
    var tipeHarga = awal?.tipeHarga ?? TipeHarga.mulaiDari;
    var kategori = awal?.kategori ?? 'umum';
    var gambarUrl = awal?.gambarUrl ?? '';
    Uint8List? gambarBaru; // dipilih admin, diunggah saat simpan

    // Salinan mutable skema harga dinamis untuk diedit di dialog. Disimpan
    // sebagai teks agar mudah dipakai TextFormField; dikonversi saat simpan.
    final tiers = [
      for (final t in awal?.tiers ?? const [])
        _TierEdit(id: t.id, nama: t.nama, harga: '${t.hargaPerM2}'),
    ];
    final pakets = [
      for (final p in awal?.paketOpsi ?? const [])
        _PaketEdit(
          id: p.id,
          nama: p.nama,
          petugas: '${p.jumlahPetugas}',
          tambahJam: '${p.hargaTambahJam}',
          durasi: [
            for (final d in p.durasi)
              _DurasiEdit(jam: '${d.jam}', harga: '${d.harga}'),
          ],
          spesifikasi: p.spesifikasi.join('\n'),
        ),
    ];
    final addOns = [
      for (final a in awal?.addOns ?? const [])
        _AddOnEdit(id: a.id, nama: a.nama, harga: '${a.harga}'),
    ];

    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(awal == null ? 'Tambah Layanan' : 'Ubah Layanan',
              style: GoogleFonts.montserrat(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TkTextField(
                      label: 'Nama Layanan',
                      controller: nama,
                      hint: 'Contoh: Bersih Taman',
                      validator: Validators.namaLengkap,
                    ),
                    const SizedBox(height: 14),
                    TkTextField(
                      label: 'Deskripsi Singkat',
                      controller: deskripsi,
                      hint: 'Ringkasan 1 baris layanan',
                      validator: Validators.teksBebas,
                    ),
                    const SizedBox(height: 14),
                    // Gambar layanan (upload) — hot-load di katalog pelanggan.
                    Text('Gambar Layanan',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TkColors.label)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        width: 64,
                        height: 64,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: TkColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: gambarBaru != null
                            ? Image.memory(gambarBaru!, fit: BoxFit.cover)
                            : gambarUrl.isNotEmpty
                                ? Image.network(gambarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                        Icons.image_outlined,
                                        color: TkColors.textMuted))
                                : const Icon(Icons.image_outlined,
                                    color: TkColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final f = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 900,
                              imageQuality: 80);
                          if (f == null) return;
                          final b = await f.readAsBytes();
                          setState(() => gambarBaru = b);
                        },
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: Text(gambarUrl.isEmpty && gambarBaru == null
                            ? 'Pilih Gambar'
                            : 'Ganti Gambar'),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<TipeHarga>(
                          initialValue: tipeHarga,
                          decoration:
                              const InputDecoration(labelText: 'Tipe Harga'),
                          items: const [
                            DropdownMenuItem(
                                value: TipeHarga.mulaiDari,
                                child: Text('Mulai dari (× qty)')),
                            DropdownMenuItem(
                                value: TipeHarga.perLuas,
                                child: Text('Per m² (tier)')),
                            DropdownMenuItem(
                                value: TipeHarga.paket,
                                child: Text('Paket + durasi')),
                          ],
                          onChanged: (v) => setState(
                              () => tipeHarga = v ?? TipeHarga.mulaiDari),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: const [
                            'umum',
                            'rumput',
                            'home_cleaning'
                          ].contains(kategori)
                              ? kategori
                              : 'umum',
                          decoration:
                              const InputDecoration(labelText: 'Kategori'),
                          items: const [
                            DropdownMenuItem(
                                value: 'umum', child: Text('Umum')),
                            DropdownMenuItem(
                                value: 'rumput', child: Text('Jasa Rumput')),
                            DropdownMenuItem(
                                value: 'home_cleaning',
                                child: Text('Home Cleaning')),
                          ],
                          onChanged: (v) =>
                              setState(() => kategori = v ?? 'umum'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    // Editor harga dinamis — muncul sesuai tipe. Tarif di
                    // bawah tetap dipakai sebagai "harga dasar / mulai dari".
                    if (tipeHarga == TipeHarga.perLuas)
                      _editorTier(setState, tiers),
                    if (tipeHarga == TipeHarga.paket) ...[
                      _editorPaket(setState, pakets),
                      const SizedBox(height: 12),
                      _editorAddOn(setState, addOns),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TkTextField(
                            label: 'Tarif (Rp)',
                            controller: harga,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final n = num.tryParse(v ?? '');
                              if (n == null || n <= 0) {
                                return 'Isi tarif dalam angka > 0.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Satuan',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: TkColors.label)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: satuan,
                                // Satuan layanan lama bisa di luar daftar
                                // (mis. 'paket') — tanpa disertakan dropdown
                                // assert dan dialog edit gagal render.
                                items: [
                                  for (final s in {satuan, ..._pilihanSatuan})
                                    DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 14))),
                                ],
                                onChanged: (v) => setState(
                                    () => satuan = v ?? satuan),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Ikon (identifier Material Design)',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: TkColors.label)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final (id, data) in _pilihanIkon)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => ikon = id),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: ikon == id
                                  ? TkColors.surfaceMuted
                                  : TkColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: ikon == id
                                      ? TkColors.primary
                                      : TkColors.border,
                                  width: ikon == id ? 1.5 : 1),
                            ),
                            child: Icon(data,
                                size: 22,
                                color: ikon == id
                                    ? TkColors.primary
                                    : TkColors.textMuted),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: TkColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktifkan langsung',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: TkColors.inkSoft)),
                              Text('Layanan tampil di katalog pelanggan',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: TkColors.textMuted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: aktif,
                          activeTrackColor: TkColors.primary,
                          onChanged: (v) => setState(() => aktif = v),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(170, 48)),
              child: const Text('Simpan Layanan'),
            ),
          ],
        ),
      ),
    );
    if (simpan != true) return;
    final svc = ref.read(firestoreServiceProvider);
    // Skema harga dinamis dikonversi dari editor sesuai tipe yang dipilih.
    // Tipe lain dipertahankan dari data awal agar tak hilang bila admin
    // berganti-ganti tipe tanpa sengaja.
    final tiersOut = tipeHarga == TipeHarga.perLuas
        ? _konversiTier(tiers)
        : (awal?.tiers ?? const <TarifTier>[]);
    final paketOut = tipeHarga == TipeHarga.paket
        ? _konversiPaket(pakets)
        : (awal?.paketOpsi ?? const <PaketOpsi>[]);
    final addOnOut = tipeHarga == TipeHarga.paket
        ? _konversiAddOn(addOns)
        : (awal?.addOns ?? const <AddOn>[]);
    var model = ServiceModel(
      serviceId: awal?.serviceId ?? '',
      namaLayanan: nama.text.trim(),
      deskripsi: deskripsi.text.trim(),
      harga: num.parse(harga.text.trim()),
      satuan: satuan,
      aktif: aktif,
      ikon: ikon,
      tipeHarga: tipeHarga,
      kategori: kategori,
      gambar: awal?.gambar ?? '',
      gambarUrl: gambarUrl,
      tiers: tiersOut,
      paketOpsi: paketOut,
      addOns: addOnOut,
    );
    // Simpan dulu untuk memastikan ada serviceId (path gambar butuh id).
    model = await svc.simpanLayanan(model);
    if (gambarBaru != null) {
      try {
        final url = await ref
            .read(storageServiceProvider)
            .uploadGambarLayanan(
                serviceId: model.serviceId, bytes: gambarBaru!);
        await svc.simpanLayanan(_gantiGambar(model, url));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gambar gagal diunggah: $e')));
        }
      }
    }
  }

  /// Salin ServiceModel dengan gambarUrl baru (ServiceModel tanpa copyWith).
  static ServiceModel _gantiGambar(ServiceModel s, String url) => ServiceModel(
        serviceId: s.serviceId,
        namaLayanan: s.namaLayanan,
        deskripsi: s.deskripsi,
        harga: s.harga,
        satuan: s.satuan,
        aktif: s.aktif,
        ikon: s.ikon,
        tipeHarga: s.tipeHarga,
        kategori: s.kategori,
        gambar: s.gambar,
        gambarUrl: url,
        tiers: s.tiers,
        paketOpsi: s.paketOpsi,
        addOns: s.addOns,
      );

  // ───────────────────────────────── konversi editor → model harga dinamis

  static num _p(String s) => num.tryParse(s.trim().replaceAll('.', '')) ?? 0;
  static int _pi(String s) => int.tryParse(s.trim()) ?? 0;

  /// Slug id stabil dari nama; fallback bila kosong.
  static String _slug(String s, String fallback) {
    final base = s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return base.isEmpty ? fallback : base;
  }

  static List<TarifTier> _konversiTier(List<_TierEdit> src) {
    final out = <TarifTier>[];
    for (var i = 0; i < src.length; i++) {
      final t = src[i];
      if (t.nama.trim().isEmpty) continue;
      out.add(TarifTier(
        id: t.id.isNotEmpty ? t.id : _slug(t.nama, 'tier${i + 1}'),
        nama: t.nama.trim(),
        hargaPerM2: _p(t.harga),
      ));
    }
    return out;
  }

  static List<PaketOpsi> _konversiPaket(List<_PaketEdit> src) {
    final out = <PaketOpsi>[];
    for (var i = 0; i < src.length; i++) {
      final p = src[i];
      if (p.nama.trim().isEmpty) continue;
      final durasi = <DurasiOpsi>[];
      for (final d in p.durasi) {
        final jam = _pi(d.jam);
        if (jam <= 0) continue;
        durasi.add(DurasiOpsi(jam: jam, harga: _p(d.harga)));
      }
      final spek = p.spesifikasi
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      out.add(PaketOpsi(
        id: p.id.isNotEmpty ? p.id : _slug(p.nama, 'paket${i + 1}'),
        nama: p.nama.trim(),
        jumlahPetugas: p.petugas.trim().isEmpty ? 1 : _pi(p.petugas),
        durasi: durasi,
        hargaTambahJam: _p(p.tambahJam),
        spesifikasi: spek,
      ));
    }
    return out;
  }

  static List<AddOn> _konversiAddOn(List<_AddOnEdit> src) {
    final out = <AddOn>[];
    for (var i = 0; i < src.length; i++) {
      final a = src[i];
      if (a.nama.trim().isEmpty) continue;
      out.add(AddOn(
        id: a.id.isNotEmpty ? a.id : _slug(a.nama, 'addon${i + 1}'),
        nama: a.nama.trim(),
        harga: _p(a.harga),
      ));
    }
    return out;
  }

  // ───────────────────────────────────────────── widget editor harga dinamis

  static Widget _labelSeksi(String judul, String bantu) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          const SizedBox(height: 2),
          Text(bantu,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: TkColors.textMuted, height: 1.3)),
        ],
      );

  static Widget _miniField({
    required Object fieldKey,
    required String label,
    required String awal,
    required ValueChanged<String> onChanged,
    bool angka = false,
    int maxLines = 1,
  }) =>
      TextFormField(
        key: ValueKey(fieldKey),
        initialValue: awal,
        onChanged: onChanged,
        keyboardType: angka ? TextInputType.number : null,
        maxLines: maxLines,
        style: GoogleFonts.montserrat(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );

  static Widget _kartuSeksi(List<Widget> anak) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TkColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: anak),
      );

  static Widget _tombolTambah(String label, VoidCallback onTap) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      );

  /// Editor tier per-m² untuk [TipeHarga.perLuas] (mis. Rapi/Sedang/Lebat).
  static Widget _editorTier(
      void Function(VoidCallback) setState, List<_TierEdit> tiers) {
    return _kartuSeksi([
      _labelSeksi('Tingkat Kondisi (tarif per m²)',
          'Pelanggan memilih salah satu; tarif × luas (m²).'),
      const SizedBox(height: 4),
      for (final t in tiers)
        Padding(
          key: ObjectKey(t),
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              flex: 3,
              child: _miniField(
                fieldKey: '${identityHashCode(t)}-nama',
                label: 'Nama tingkat',
                awal: t.nama,
                onChanged: (v) => t.nama = v,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _miniField(
                fieldKey: '${identityHashCode(t)}-harga',
                label: 'Rp/m²',
                awal: t.harga,
                angka: true,
                onChanged: (v) => t.harga = v,
              ),
            ),
            IconButton(
              tooltip: 'Hapus tingkat',
              onPressed: () => setState(() => tiers.remove(t)),
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: TkColors.error),
            ),
          ]),
        ),
      _tombolTambah(
          'Tambah tingkat', () => setState(() => tiers.add(_TierEdit()))),
    ]);
  }

  /// Editor paket (petugas × durasi + tambah jam + spesifikasi) untuk
  /// [TipeHarga.paket].
  static Widget _editorPaket(
      void Function(VoidCallback) setState, List<_PaketEdit> pakets) {
    return _kartuSeksi([
      _labelSeksi('Paket Layanan',
          'Tiap paket: jumlah petugas, opsi durasi berbayar, tarif tambah jam.'),
      for (final p in pakets)
        Container(
          key: ObjectKey(p),
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TkColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: TkColors.border),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: _miniField(
                      fieldKey: '${identityHashCode(p)}-nama',
                      label: 'Nama paket',
                      awal: p.nama,
                      onChanged: (v) => p.nama = v,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus paket',
                    onPressed: () => setState(() => pakets.remove(p)),
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: TkColors.error),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _miniField(
                      fieldKey: '${identityHashCode(p)}-petugas',
                      label: 'Jml petugas',
                      awal: p.petugas,
                      angka: true,
                      onChanged: (v) => p.petugas = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniField(
                      fieldKey: '${identityHashCode(p)}-tambah',
                      label: 'Rp/tambah jam',
                      awal: p.tambahJam,
                      angka: true,
                      onChanged: (v) => p.tambahJam = v,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text('Opsi durasi',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.label)),
                for (final d in p.durasi)
                  Padding(
                    key: ObjectKey(d),
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Expanded(
                        child: _miniField(
                          fieldKey: '${identityHashCode(d)}-jam',
                          label: 'Jam',
                          awal: d.jam,
                          angka: true,
                          onChanged: (v) => d.jam = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _miniField(
                          fieldKey: '${identityHashCode(d)}-harga',
                          label: 'Harga (Rp)',
                          awal: d.harga,
                          angka: true,
                          onChanged: (v) => d.harga = v,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus durasi',
                        onPressed: () => setState(() => p.durasi.remove(d)),
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 18, color: TkColors.error),
                      ),
                    ]),
                  ),
                _tombolTambah('Tambah durasi',
                    () => setState(() => p.durasi.add(_DurasiEdit()))),
                const SizedBox(height: 4),
                _miniField(
                  fieldKey: '${identityHashCode(p)}-spek',
                  label: 'Spesifikasi (satu per baris)',
                  awal: p.spesifikasi,
                  maxLines: 3,
                  onChanged: (v) => p.spesifikasi = v,
                ),
              ]),
        ),
      const SizedBox(height: 4),
      _tombolTambah('Tambah paket',
          () => setState(() => pakets.add(_PaketEdit(petugas: '1')))),
    ]);
  }

  /// Editor add-on (layanan tambahan berbayar) untuk [TipeHarga.paket].
  static Widget _editorAddOn(
      void Function(VoidCallback) setState, List<_AddOnEdit> addOns) {
    return _kartuSeksi([
      _labelSeksi('Layanan Tambahan (Add-on)',
          'Opsional; pelanggan boleh centang lebih dari satu.'),
      const SizedBox(height: 4),
      for (final a in addOns)
        Padding(
          key: ObjectKey(a),
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: _miniField(
                fieldKey: '${identityHashCode(a)}-nama',
                label: 'Nama add-on',
                awal: a.nama,
                onChanged: (v) => a.nama = v,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _miniField(
                fieldKey: '${identityHashCode(a)}-harga',
                label: 'Harga (Rp)',
                awal: a.harga,
                angka: true,
                onChanged: (v) => a.harga = v,
              ),
            ),
            IconButton(
              tooltip: 'Hapus add-on',
              onPressed: () => setState(() => addOns.remove(a)),
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: TkColors.error),
            ),
          ]),
        ),
      _tombolTambah(
          'Tambah add-on', () => setState(() => addOns.add(_AddOnEdit()))),
    ]);
  }
}

// ─────────────────────────────── holder mutable untuk editor harga dinamis

class _TierEdit {
  _TierEdit({this.id = '', this.nama = '', this.harga = ''});
  final String id;
  String nama;
  String harga;
}

class _DurasiEdit {
  _DurasiEdit({this.jam = '', this.harga = ''});
  String jam;
  String harga;
}

class _PaketEdit {
  _PaketEdit({
    this.id = '',
    this.nama = '',
    this.petugas = '1',
    this.tambahJam = '0',
    List<_DurasiEdit>? durasi,
    this.spesifikasi = '',
  }) : durasi = durasi ?? [];
  final String id;
  String nama;
  String petugas;
  String tambahJam;
  List<_DurasiEdit> durasi;
  String spesifikasi;
}

class _AddOnEdit {
  _AddOnEdit({this.id = '', this.nama = '', this.harga = ''});
  final String id;
  String nama;
  String harga;
}
