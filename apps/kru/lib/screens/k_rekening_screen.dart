import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';

/// Rekening Pencairan — data bank/e-wallet kru untuk pencairan upah worker
/// dan setoran (dibaca admin di manajemen keuangan).
class KRekeningScreen extends ConsumerStatefulWidget {
  const KRekeningScreen({super.key});

  static const route = '/k-rekening';

  @override
  ConsumerState<KRekeningScreen> createState() => _KRekeningScreenState();
}

class _KRekeningScreenState extends ConsumerState<KRekeningScreen> {
  static const _bank = ['BCA', 'BRI', 'Mandiri', 'BNI', 'BSI', 'Lainnya'];
  static const _ewallet = ['DANA', 'OVO', 'GoPay', 'ShopeePay', 'LinkAja'];

  final _nomor = TextEditingController();
  final _atasNama = TextEditingController();
  var _jenis = 'bank';
  String _penyedia = 'BCA';
  var _terisi = false;
  var _menyimpan = false;

  @override
  void dispose() {
    _nomor.dispose();
    _atasNama.dispose();
    super.dispose();
  }

  void _isiDariKru(KruModel kru) {
    if (_terisi) return;
    _terisi = true;
    final r = kru.rekening;
    if (r.lengkap || r.penyedia.isNotEmpty) {
      _jenis = r.jenis;
      _penyedia = r.penyedia;
      _nomor.text = r.nomor;
      _atasNama.text = r.atasNama;
    }
  }

  List<String> get _pilihan => _jenis == 'bank' ? _bank : _ewallet;

  Future<void> _simpan() async {
    final nomor = _nomor.text.trim();
    final atasNama = _atasNama.text.trim();
    if (nomor.isEmpty || atasNama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nomor dan nama pemilik wajib diisi.')));
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    setState(() => _menyimpan = true);
    try {
      await ref.read(firestoreServiceProvider).simpanRekeningKru(
          uid,
          RekeningKru(
              jenis: _jenis,
              penyedia: _penyedia,
              nomor: nomor,
              atasNama: atasNama));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Rekening pencairan tersimpan.')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Gagal menyimpan. Periksa koneksi lalu coba lagi.')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kru = ref.watch(kruSayaProvider).valueOrNull;
    if (kru != null) _isiDariKru(kru);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text('Rekening Pencairan',
            style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        backgroundColor: TkColors.surface,
        foregroundColor: TkColors.inkSoft,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            'Upah dan setoran dicairkan ke rekening/e-wallet ini. Pastikan '
            'nomor dan nama pemilik sesuai — kesalahan data memperlambat '
            'pencairan.',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: TkColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(children: [
            for (final j in const [('bank', 'Bank'), ('ewallet', 'E-Wallet')])
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(j.$2,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  selected: _jenis == j.$1,
                  selectedColor: TkColors.primary.withValues(alpha: 0.14),
                  onSelected: (_) => setState(() {
                    _jenis = j.$1;
                    if (!_pilihan.contains(_penyedia)) {
                      _penyedia = _pilihan.first;
                    }
                  }),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _pilihan.contains(_penyedia)
                ? _penyedia
                : _pilihan.first,
            decoration: InputDecoration(
                labelText: _jenis == 'bank' ? 'Bank' : 'E-Wallet'),
            items: [
              for (final p in {_penyedia, ..._pilihan})
                DropdownMenuItem(
                    value: p,
                    child: Text(p,
                        style: GoogleFonts.montserrat(fontSize: 14))),
            ],
            onChanged: (v) => setState(() => _penyedia = v ?? _penyedia),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nomor,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
                labelText:
                    _jenis == 'bank' ? 'Nomor rekening' : 'Nomor e-wallet/HP'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _atasNama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Atas nama'),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: TkButton(
              label: 'Simpan',
              loading: _menyimpan,
              onPressed: _simpan,
            ),
          ),
        ],
      ),
    );
  }
}
