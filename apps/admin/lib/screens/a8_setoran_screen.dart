import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// A8 — Setoran Tunai. Saldo kas per kru (komisi tunai yang belum disetor) +
/// terima setoran + riwayat. Lapisan produk nyata (di luar 7 koleksi TA).
class A8SetoranScreen extends ConsumerWidget {
  const A8SetoranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kas = ref.watch(semuaKasProvider);
    final riwayat = ref.watch(setoranProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Setoran Tunai',
        subjudul: 'Komisi tunai yang dipegang kru & riwayat setoran',
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final pad = c.maxWidth < 520 ? 16.0 : 32.0;
          final lebar = (c.maxWidth - pad * 2).clamp(0.0, 900.0);
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
            children: [
              SizedBox(
                width: lebar,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _judul('SALDO KAS KRU'),
                    _kartuKas(context, ref, kas),
                    const SizedBox(height: 24),
                    _judul('RIWAYAT SETORAN'),
                    _kartuRiwayat(riwayat),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    ]);
  }

  Widget _judul(String teks) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TkColors.textMuted,
                letterSpacing: 0.3)),
      );

  Widget _kartuKas(
      BuildContext context, WidgetRef ref, AsyncValue<List<KasKru>> kas) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: kas.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))),
        error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Gagal memuat kas: $e',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.error))),
        data: (list) {
          final aktif = list.where((k) => k.saldoTunai > 0).toList();
          if (aktif.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Belum ada saldo tunai tertahan pada kru.',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.textMuted)),
            );
          }
          return Column(children: [
            for (var i = 0; i < aktif.length; i++) ...[
              if (i > 0)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1)),
              _barisKas(context, ref, aktif[i]),
            ],
          ]);
        },
      ),
    );
  }

  Widget _barisKas(BuildContext context, WidgetRef ref, KasKru k) {
    final nunggak = !k.bolehTerimaTunai;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                      k.namaKru.isEmpty ? k.cleanerId : k.namaKru,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                ),
                if (nunggak) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TkColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Nunggak',
                        style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: TkColors.error)),
                  ),
                ],
              ]),
              const SizedBox(height: 3),
              Text(
                  'Saldo tunai: ${_rupiah(k.saldoTunai)}  •  batas '
                  '${_rupiah(k.batasNunggak)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _dialogSetor(context, ref, k),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Terima Setoran',
              style: GoogleFonts.montserrat(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _kartuRiwayat(AsyncValue<List<SetoranModel>> riwayat) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: riwayat.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))),
        error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Gagal memuat riwayat: $e',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.error))),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Belum ada setoran tercatat.',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.textMuted)),
            );
          }
          return Column(children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0)
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            list[i].namaKru.isEmpty
                                ? list[i].cleanerId
                                : list[i].namaKru,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TkColors.inkSoft)),
                        Text(_tanggal(list[i].waktu),
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: TkColors.textMuted)),
                      ],
                    ),
                  ),
                  Text(_rupiah(list[i].jumlah),
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TkColors.primary)),
                ]),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Future<void> _dialogSetor(
      BuildContext context, WidgetRef ref, KasKru k) async {
    final ctrl = TextEditingController(text: k.saldoTunai.toString());
    final messenger = ScaffoldMessenger.of(context);
    final adminUid = ref.read(authServiceProvider).currentUser?.uid ?? '';
    var memproses = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Terima Setoran',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    '${k.namaKru.isEmpty ? k.cleanerId : k.namaKru} — saldo '
                    '${_rupiah(k.saldoTunai)}',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: TkColors.textMuted)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Jumlah Setoran (Rp)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: memproses ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: memproses
                  ? null
                  : () async {
                      final jumlah = int.tryParse(ctrl.text.trim()) ?? 0;
                      if (jumlah <= 0) {
                        messenger.showSnackBar(const SnackBar(
                            content: Text('Masukkan jumlah yang benar.')));
                        return;
                      }
                      if (jumlah > k.saldoTunai) {
                        messenger.showSnackBar(const SnackBar(
                            content: Text(
                                'Setoran melebihi saldo tunai kru.')));
                        return;
                      }
                      setState(() => memproses = true);
                      try {
                        await ref
                            .read(firestoreServiceProvider)
                            .terimaSetoran(
                              cleanerId: k.cleanerId,
                              namaKru: k.namaKru,
                              jumlah: jumlah,
                              adminUid: adminUid,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        messenger.showSnackBar(SnackBar(
                            content:
                                Text('Setoran ${_rupiah(jumlah)} dicatat.')));
                      } catch (e) {
                        setState(() => memproses = false);
                        messenger.showSnackBar(SnackBar(
                            content: Text('Gagal: ${e.toString()}')));
                      }
                    },
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(130, 48)),
              child: memproses
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: TkColors.surface))
                  : const Text('Catat Setoran'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  String _rupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp$buf';
  }

  String _tanggal(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/'
      '${d.year} ${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
