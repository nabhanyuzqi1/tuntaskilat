import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/beranda_providers.dart';
import '../widgets/service_icon.dart';

/// P3a — Katalog Semua Layanan dengan filter kategori. Dibuka dari
/// "Lihat Semua" di Beranda.
class P3aKatalogScreen extends ConsumerStatefulWidget {
  const P3aKatalogScreen({super.key});

  static const route = '/p3a';

  @override
  ConsumerState<P3aKatalogScreen> createState() => _P3aKatalogScreenState();
}

class _P3aKatalogScreenState extends ConsumerState<P3aKatalogScreen> {
  String _kategori = 'semua';

  static const _kategoriLabel = {
    'semua': 'Semua',
    'rumput': 'Jasa Rumput',
    'home_cleaning': 'Home Cleaning',
    'umum': 'Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    final semua = ref.watch(layananAktifProvider).valueOrNull ?? const [];
    final kategoriAda = {
      'semua',
      ...semua.map((s) => s.kategori),
    }.where(_kategoriLabel.containsKey).toList();
    final tersaring = _kategori == 'semua'
        ? semua
        : semua.where((s) => s.kategori == _kategori).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
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
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Row(children: [
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
                    Text('Semua Layanan',
                        style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                  ]),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    children: [
                      for (final k in kategoriAda)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_kategoriLabel[k] ?? k),
                            selected: _kategori == k,
                            labelStyle: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kategori == k
                                    ? Colors.white
                                    : TkColors.primaryDark),
                            selectedColor: TkColors.primary,
                            backgroundColor:
                                TkColors.primary.withValues(alpha: 0.07),
                            side: BorderSide(
                                color:
                                    TkColors.primary.withValues(alpha: 0.18)),
                            onSelected: (_) =>
                                setState(() => _kategori = k),
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: tersaring.isEmpty
                ? Center(
                    child: Text('Belum ada layanan pada kategori ini.',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, color: TkColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    itemCount: tersaring.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _KartuLayanan(layanan: tersaring[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuLayanan extends StatelessWidget {
  const _KartuLayanan({required this.layanan});
  final ServiceModel layanan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TkColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context).pushNamed('/p4', arguments: layanan),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x0D0F281C)),
          ),
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: serviceGradient(layanan.kategori),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(serviceIcon(layanan.ikon),
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(layanan.namaLayanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 3),
                  Text(layanan.deskripsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: TkColors.textMuted,
                          height: 1.35)),
                  const SizedBox(height: 6),
                  Text(
                      '${layanan.tipeHarga == TipeHarga.mulaiDari ? 'Mulai ' : ''}'
                      '${PriceBadge.formatRupiah(layanan.harga)}'
                      '${layanan.tipeHarga == TipeHarga.perLuas ? '/m²' : ''}',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC4CBC6)),
          ]),
        ),
      ),
    );
  }
}
