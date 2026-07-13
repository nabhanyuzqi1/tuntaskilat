import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// A10 — Pantau Operasional (hak admin). Dua panel:
///  • Peta Lokasi Kru: marker real-time dari `kru.posisi` (dialirkan portal
///    kru saat status `dalam_perjalanan`).
///  • Percakapan Kru–Klien: baca subkoleksi `orders/{id}/messages` pesanan
///    aktif untuk pengawasan mutu & sengketa (read-only).
class A10PantauScreen extends ConsumerStatefulWidget {
  const A10PantauScreen({super.key});

  @override
  ConsumerState<A10PantauScreen> createState() => _A10PantauScreenState();
}

class _A10PantauScreenState extends ConsumerState<A10PantauScreen> {
  int _tab = 0; // 0 = peta, 1 = percakapan

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      AdminUi.topbar(
        judul: 'Pantau Operasional',
        subjudul: 'Lokasi kru real-time & percakapan kru–klien',
        aksi: _SegmentTab(
          nilai: _tab,
          onPilih: (v) => setState(() => _tab = v),
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _tab,
          children: const [_PetaLokasi(), _PantauChat()],
        ),
      ),
    ]);
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.nilai, required this.onPilih});
  final int nilai;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    Widget seg(int i, IconData ikon, String label) {
      final aktif = nilai == i;
      return Material(
        color: aktif ? TkColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => onPilih(i),
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(children: [
              Icon(ikon,
                  size: 16,
                  color: aktif ? TkColors.surface : TkColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: aktif ? TkColors.surface : TkColors.textMuted)),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminUi.latar,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(children: [
        seg(0, Icons.map_outlined, 'Peta Lokasi'),
        const SizedBox(width: 4),
        seg(1, Icons.forum_outlined, 'Percakapan'),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────── Peta lokasi kru

/// Pusat kota Sampit (fallback bila belum ada posisi kru).
const _pusatSampit = LatLng(-2.5333, 112.9500);

class _PetaLokasi extends ConsumerStatefulWidget {
  const _PetaLokasi();

  @override
  ConsumerState<_PetaLokasi> createState() => _PetaLokasiState();
}

class _PetaLokasiState extends ConsumerState<_PetaLokasi> {
  final _peta = MapController();

  @override
  Widget build(BuildContext context) {
    final kruAsync = ref.watch(semuaKruProvider);
    final orders = ref.watch(semuaOrderProvider).valueOrNull ?? const [];

    return kruAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Gagal memuat kru: $e',
              style: GoogleFonts.montserrat(color: TkColors.error))),
      data: (kru) {
        // Kru yang punya koordinat = bisa dipetakan. Prioritas yang sedang
        // menjalankan pesanan (dalam_perjalanan/diproses).
        final kruAktif = _kruSedangBertugas(orders);
        final berkoordinat =
            kru.where((k) => k.posisi != null).toList(growable: false);

        final markers = <Marker>[
          for (final k in berkoordinat)
            Marker(
              point: LatLng(k.posisi!.latitude, k.posisi!.longitude),
              width: 132,
              height: 58,
              alignment: Alignment.topCenter,
              child: _PinKru(
                nama: k.nama,
                bertugas: kruAktif.contains(k.cleanerId),
              ),
            ),
        ];

        final pusat = berkoordinat.isNotEmpty
            ? LatLng(berkoordinat.first.posisi!.latitude,
                berkoordinat.first.posisi!.longitude)
            : _pusatSampit;

        return Row(children: [
          // Daftar kru sisi kiri.
          Container(
            width: 300,
            decoration: const BoxDecoration(
              color: TkColors.surface,
              border: Border(right: BorderSide(color: Color(0x0F0F281C))),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Kru dengan lokasi (${berkoordinat.length})',
                      style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TkColors.inkSoft)),
                ),
              ),
              if (berkoordinat.isEmpty)
                const Expanded(
                  child: _KosongPesan(
                    ikon: Icons.location_off_outlined,
                    judul: 'Belum ada lokasi kru',
                    isi: 'Lokasi muncul saat kru menekan "Dalam Perjalanan" '
                        'pada pesanannya.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: berkoordinat.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final k = berkoordinat[i];
                      final bertugas = kruAktif.contains(k.cleanerId);
                      return Material(
                        color: AdminUi.latar,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _peta.move(
                              LatLng(k.posisi!.latitude, k.posisi!.longitude),
                              16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(children: [
                              Icon(Icons.person_pin_circle_outlined,
                                  size: 20,
                                  color: bertugas
                                      ? TkColors.primary
                                      : TkColors.textMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(k.nama,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: TkColors.inkSoft)),
                                    Text(
                                        bertugas
                                            ? 'Sedang bertugas'
                                            : (k.statusKetersediaan
                                                ? 'Online'
                                                : 'Idle'),
                                        style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            color: bertugas
                                                ? TkColors.primary
                                                : TkColors.textMuted)),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ]),
          ),
          // Peta.
          Expanded(
            child: Stack(children: [
              FlutterMap(
                mapController: _peta,
                options: MapOptions(
                  initialCenter: pusat,
                  initialZoom: 13,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tuntaskilat.admin',
                    maxZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Kontrol pusatkan ulang.
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'pusatkan',
                  backgroundColor: TkColors.surface,
                  foregroundColor: TkColors.primary,
                  onPressed: () => _peta.move(pusat, 13),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  /// cleanerId semua kru yang tercantum pada pesanan berstatus aktif lapangan.
  Set<String> _kruSedangBertugas(List<OrderModel> orders) {
    final set = <String>{};
    for (final o in orders) {
      final aktif = o.status == OrderStatus.dalamPerjalanan ||
          o.status == OrderStatus.diproses;
      if (!aktif) continue;
      if (o.cleanerId.isNotEmpty) set.add(o.cleanerId);
      set.addAll(o.kruIds);
    }
    return set;
  }
}

class _PinKru extends StatelessWidget {
  const _PinKru({required this.nama, required this.bertugas});
  final String nama;
  final bool bertugas;

  @override
  Widget build(BuildContext context) {
    final warna = bertugas ? TkColors.primary : TkColors.textMuted;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: Text(nama,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: TkColors.surface)),
      ),
      Icon(Icons.location_on, color: warna, size: 30),
    ]);
  }
}

// ─────────────────────────────────────────────────────── Pantau chat

class _PantauChat extends ConsumerStatefulWidget {
  const _PantauChat();

  @override
  ConsumerState<_PantauChat> createState() => _PantauChatState();
}

class _PantauChatState extends ConsumerState<_PantauChat> {
  String? _dipilih; // orderId

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(semuaOrderProvider).valueOrNull ?? const [];
    // Pesanan yang punya kru tertugas → berpotensi ada percakapan.
    final relevan = orders
        .where((o) =>
            o.cleanerId.isNotEmpty &&
            o.status != OrderStatus.dibatalkan)
        .toList()
      ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan));

    return Row(children: [
      Container(
        width: 320,
        decoration: const BoxDecoration(
          color: TkColors.surface,
          border: Border(right: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pesanan dengan kru (${relevan.length})',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
            ),
          ),
          if (relevan.isEmpty)
            const Expanded(
              child: _KosongPesan(
                ikon: Icons.forum_outlined,
                judul: 'Belum ada percakapan',
                isi: 'Percakapan muncul setelah kru ditugaskan ke pesanan.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: relevan.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final o = relevan[i];
                  final aktif = _dipilih == o.orderId;
                  return Material(
                    color: aktif ? TkColors.primary : AdminUi.latar,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _dipilih = o.orderId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.namaPelanggan.isEmpty
                                    ? 'Pelanggan'
                                    : o.namaPelanggan,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: aktif
                                        ? TkColors.surface
                                        : TkColors.inkSoft)),
                            const SizedBox(height: 2),
                            Text(
                                '${o.namaLayanan} • ${o.namaKru ?? "Kru"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: aktif
                                        ? TkColors.surface.withValues(
                                            alpha: 0.85)
                                        : TkColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
      Expanded(
        child: _dipilih == null
            ? const _KosongPesan(
                ikon: Icons.chat_bubble_outline,
                judul: 'Pilih pesanan',
                isi: 'Pilih pesanan di kiri untuk memantau percakapannya.',
              )
            : _PanelChat(
                order: relevan.firstWhere((o) => o.orderId == _dipilih,
                    orElse: () => relevan.first),
              ),
      ),
    ]);
  }
}

class _PanelChat extends ConsumerWidget {
  const _PanelChat({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(firestoreServiceProvider);
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: TkColors.surface,
          border: Border(bottom: BorderSide(color: Color(0x0F0F281C))),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${order.namaPelanggan} ↔ ${order.namaKru ?? "Kru"}',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
                Text('${order.namaLayanan} • ${order.status.wire}',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textMuted)),
              ],
            ),
          ),
          AdminUi.chipStatus('Read-only', TkColors.textMuted),
        ]),
      ),
      Expanded(
        child: StreamBuilder<List<MessageModel>>(
          stream: svc.watchChatMessages(order.orderId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final pesan = snap.data ?? const [];
            if (pesan.isEmpty) {
              return const _KosongPesan(
                ikon: Icons.mark_chat_read_outlined,
                judul: 'Belum ada pesan',
                isi: 'Kru dan pelanggan belum bertukar pesan pada pesanan ini.',
              );
            }
            // Stream sudah descending (terbaru dulu) → reverse untuk kronologis.
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(20),
              itemCount: pesan.length,
              itemBuilder: (_, i) {
                final m = pesan[i];
                // Bedakan kiri/kanan: kru vs pelanggan.
                final dariKru = m.senderId == order.cleanerId ||
                    order.kruIds.contains(m.senderId);
                return _Gelembung(
                    teks: m.text,
                    waktu: m.timestamp,
                    dariKru: dariKru,
                    pengirim: dariKru
                        ? (order.namaKru ?? 'Kru')
                        : order.namaPelanggan);
              },
            );
          },
        ),
      ),
    ]);
  }
}

class _Gelembung extends StatelessWidget {
  const _Gelembung({
    required this.teks,
    required this.waktu,
    required this.dariKru,
    required this.pengirim,
  });
  final String teks;
  final DateTime waktu;
  final bool dariKru;
  final String pengirim;

  String _jam(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final warna = dariKru ? TkColors.primary : AdminUi.latar;
    final warnaTeks = dariKru ? TkColors.surface : TkColors.inkSoft;
    return Align(
      alignment: dariKru ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pengirim,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: warnaTeks.withValues(alpha: 0.8))),
            const SizedBox(height: 3),
            Text(teks,
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: warnaTeks, height: 1.35)),
            const SizedBox(height: 3),
            Text(_jam(waktu),
                style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: warnaTeks.withValues(alpha: 0.65))),
          ],
        ),
      ),
    );
  }
}

class _KosongPesan extends StatelessWidget {
  const _KosongPesan(
      {required this.ikon, required this.judul, required this.isi});
  final IconData ikon;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 44, color: TkColors.textMuted),
            const SizedBox(height: 12),
            Text(judul,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft)),
            const SizedBox(height: 6),
            Text(isi,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
