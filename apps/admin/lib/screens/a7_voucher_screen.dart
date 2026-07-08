import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// A7 — Kelola Voucher (lapisan produk NYATA, di luar naskah TA). Buat/ubah/
/// hapus voucher promo + tombol isi katalog & voucher contoh sesuai pricelist.
class A7VoucherScreen extends ConsumerWidget {
  const A7VoucherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchers = ref.watch(vouchersProvider).valueOrNull ?? const [];
    final aktif = vouchers.where((v) => v.aktif).length;

    return Column(children: [
      AdminUi.topbar(
        judul: 'Kelola Voucher',
        subjudul: '${vouchers.length} voucher · $aktif aktif',
        aksi: Row(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            onPressed: () => _isiKatalog(context, ref),
            icon: const Icon(Icons.auto_awesome_motion_outlined, size: 18),
            label: const Text('Isi Katalog Pricelist'),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => _dialogVoucher(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Voucher'),
          ),
        ]),
      ),
      Expanded(
        child: vouchers.isEmpty
            ? Center(
                child: Text('Belum ada voucher. Tambah atau isi contoh.',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: TkColors.textSecondary)),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: vouchers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _kartuVoucher(context, ref, vouchers[i]),
              ),
      ),
    ]);
  }

  Widget _kartuVoucher(
      BuildContext context, WidgetRef ref, VoucherModel v) {
    final nilai = v.tipe == TipeVoucher.persen
        ? '${v.nilai.toStringAsFixed(0)}%'
        : PriceBadge.formatRupiah(v.nilai);
    final kuota = v.kuota <= 0 ? '∞' : '${v.terpakai}/${v.kuota}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminUi.kartu(),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: v.aktif
                ? TkColors.primary.withValues(alpha: 0.10)
                : const Color(0xFFEDEFEC),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.local_offer_outlined,
              color: v.aktif ? TkColors.primary : TkColors.textMuted),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(v.kode,
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
                const SizedBox(width: 8),
                _tag(nilai, TkColors.primary),
                if (!v.aktif) ...[
                  const SizedBox(width: 6),
                  _tag('Nonaktif', TkColors.textMuted),
                ],
              ]),
              const SizedBox(height: 4),
              Text(
                '${v.deskripsi.isEmpty ? 'Tanpa deskripsi' : v.deskripsi}  ·  '
                'min ${PriceBadge.formatRupiah(v.minBelanja)}  ·  '
                'kuota $kuota',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: TkColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _dialogVoucher(context, ref, awal: v),
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Ubah',
        ),
        IconButton(
          onPressed: () => _hapus(context, ref, v),
          icon: const Icon(Icons.delete_outline, size: 20),
          color: TkColors.error,
          tooltip: 'Hapus',
        ),
      ]),
    );
  }

  Widget _tag(String teks, Color warna) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 11, fontWeight: FontWeight.w700, color: warna)),
      );

  Future<void> _isiKatalog(BuildContext context, WidgetRef ref) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Isi katalog & voucher pricelist?'),
        content: const Text(
            'Menulis ulang layanan (Jasa Rumput, Home Cleaning, dll.) dan '
            '3 voucher contoh sesuai pricelist TK. Data layanan dengan ID '
            'sama akan ditimpa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Ya, Isi')),
        ],
      ),
    );
    if (ya != true) return;
    try {
      await ref.read(firestoreServiceProvider).seedKatalogDanVoucher();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Katalog & voucher pricelist berhasil diisi.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal mengisi katalog. Coba lagi.')));
      }
    }
  }

  Future<void> _hapus(
      BuildContext context, WidgetRef ref, VoucherModel v) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Hapus voucher ${v.kode}?'),
        content: const Text('Voucher tidak bisa dipakai lagi setelah dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: TkColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true) return;
    await ref.read(firestoreServiceProvider).hapusVoucher(v.kode);
  }

  Future<void> _dialogVoucher(BuildContext context, WidgetRef ref,
      {VoucherModel? awal}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogVoucher(awal: awal),
    );
  }
}

class _DialogVoucher extends ConsumerStatefulWidget {
  const _DialogVoucher({this.awal});
  final VoucherModel? awal;

  @override
  ConsumerState<_DialogVoucher> createState() => _DialogVoucherState();
}

class _DialogVoucherState extends ConsumerState<_DialogVoucher> {
  late final _kode =
      TextEditingController(text: widget.awal?.kode ?? '');
  late final _deskripsi =
      TextEditingController(text: widget.awal?.deskripsi ?? '');
  late final _nilai =
      TextEditingController(text: widget.awal?.nilai.toStringAsFixed(0) ?? '');
  late final _minBelanja = TextEditingController(
      text: (widget.awal?.minBelanja ?? 0).toStringAsFixed(0));
  late final _maxPotongan = TextEditingController(
      text: (widget.awal?.maxPotongan ?? 0).toStringAsFixed(0));
  late final _kuota =
      TextEditingController(text: (widget.awal?.kuota ?? 0).toString());
  late TipeVoucher _tipe = widget.awal?.tipe ?? TipeVoucher.persen;
  late bool _aktif = widget.awal?.aktif ?? true;
  bool _simpan = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _kode,
      _deskripsi,
      _nilai,
      _minBelanja,
      _maxPotongan,
      _kuota
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpanVoucher() async {
    final kode = _kode.text.trim().toUpperCase();
    final nilai = num.tryParse(_nilai.text.trim()) ?? 0;
    if (kode.isEmpty || nilai <= 0) {
      setState(() => _error = 'Kode dan nilai wajib diisi (nilai > 0).');
      return;
    }
    if (_tipe == TipeVoucher.persen && nilai > 100) {
      setState(() => _error = 'Persentase maksimal 100.');
      return;
    }
    setState(() {
      _simpan = true;
      _error = null;
    });
    final v = VoucherModel(
      voucherId: kode,
      kode: kode,
      tipe: _tipe,
      nilai: nilai,
      deskripsi: _deskripsi.text.trim(),
      minBelanja: num.tryParse(_minBelanja.text.trim()) ?? 0,
      maxPotongan: num.tryParse(_maxPotongan.text.trim()) ?? 0,
      kuota: int.tryParse(_kuota.text.trim()) ?? 0,
      terpakai: widget.awal?.terpakai ?? 0,
      berlakuHingga: widget.awal?.berlakuHingga,
      aktif: _aktif,
    );
    try {
      await ref.read(firestoreServiceProvider).simpanVoucher(v);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _simpan = false;
        _error = 'Gagal menyimpan. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TkRadius.card)),
      title: Text(widget.awal == null ? 'Tambah Voucher' : 'Ubah Voucher',
          style: GoogleFonts.montserrat(
              fontSize: 19, fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_kode, 'Kode voucher (mis. HEMAT20)',
                  enabled: widget.awal == null,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  ],
                  uppercase: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<TipeVoucher>(
                    initialValue: _tipe,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: const [
                      DropdownMenuItem(
                          value: TipeVoucher.persen,
                          child: Text('Persen (%)')),
                      DropdownMenuItem(
                          value: TipeVoucher.nominal,
                          child: Text('Nominal (Rp)')),
                    ],
                    onChanged: (t) =>
                        setState(() => _tipe = t ?? TipeVoucher.persen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_nilai,
                        _tipe == TipeVoucher.persen ? 'Nilai (%)' : 'Nilai (Rp)',
                        number: true)),
              ]),
              const SizedBox(height: 12),
              _field(_deskripsi, 'Deskripsi (opsional)'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(_minBelanja, 'Min. belanja (Rp)',
                        number: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_maxPotongan, 'Maks potongan (Rp, 0=∞)',
                        number: true)),
              ]),
              const SizedBox(height: 12),
              _field(_kuota, 'Kuota (0 = tak terbatas)', number: true),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _aktif,
                onChanged: (v) => setState(() => _aktif = v),
                title: Text('Aktif',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (_error != null)
                Text(_error!,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _simpan ? null : _simpanVoucher,
          child: _simpan
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false,
      bool enabled = true,
      bool uppercase = false,
      List<TextInputFormatter> formatters = const []}) {
    return TextField(
      controller: c,
      enabled: enabled,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      textCapitalization:
          uppercase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: [
        ...formatters,
        if (number) FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(labelText: label),
      style: GoogleFonts.montserrat(fontSize: 14),
    );
  }
}
