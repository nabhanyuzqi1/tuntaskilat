import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  ('LAYANAN', 24),
                  ('TARIF', 11),
                  ('SATUAN', 10),
                  ('STATUS', 9),
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
              flex: 11,
              child: AdminUi.teksSel(PriceBadge.formatRupiah(s.harga),
                  tebal: true)),
          Expanded(
              flex: 10,
              child:
                  AdminUi.teksSel(s.satuan.replaceFirst('per ', ''))),
          Expanded(
            flex: 9,
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
                                items: [
                                  for (final s in _pilihanSatuan)
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
    await ref.read(firestoreServiceProvider).simpanLayanan(ServiceModel(
          serviceId: awal?.serviceId ?? '',
          namaLayanan: nama.text.trim(),
          deskripsi: deskripsi.text.trim(),
          harga: num.parse(harga.text.trim()),
          satuan: satuan,
          aktif: aktif,
          ikon: ikon,
        ));
  }
}
