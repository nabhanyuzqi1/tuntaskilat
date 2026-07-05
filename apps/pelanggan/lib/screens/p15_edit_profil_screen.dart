import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/beranda_providers.dart';

/// P15 — Edit Profil. Ubah nama/telepon/alamat → `users` (updateUserProfile).
/// Catatan skema: foto profil TIDAK diimplementasikan — koleksi `users`
/// pada Kamus Data TA tidak memiliki field foto (butuh konfirmasi scope
/// sebelum menambah field baru).
class P15EditProfilScreen extends ConsumerStatefulWidget {
  const P15EditProfilScreen({super.key});

  static const route = '/p15';

  @override
  ConsumerState<P15EditProfilScreen> createState() =>
      _P15EditProfilScreenState();
}

class _P15EditProfilScreenState extends ConsumerState<P15EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _alamat = TextEditingController();
  var _terisi = false;
  var _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _alamat.dispose();
    super.dispose();
  }

  void _isiAwal(UserModel profil) {
    if (_terisi) return;
    _terisi = true;
    _nama.text = profil.nama;
    _telepon.text = profil.noTelepon;
    _alamat.text = profil.alamat;
  }

  Future<void> _simpan(UserModel profil) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      await ref.read(firestoreServiceProvider).updateUserProfile(
            profil.copyWith(
              nama: _nama.text.trim(),
              noTelepon: _telepon.text.trim(),
              alamat: _alamat.text.trim(),
            ),
          );
      ref.invalidate(profilSayaProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Perubahan belum tersimpan. Periksa koneksi Anda.')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilSayaProvider);
    final profil = profilAsync.valueOrNull;
    if (profil != null) _isiAwal(profil);

    final inisial = profil == null || profil.nama.isEmpty
        ? 'TK'
        : profil.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              decoration: const BoxDecoration(
                color: TkColors.surface,
                border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
              ),
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
                Text('Edit Profil',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
              ]),
            ),
            Expanded(
              child: profil == null
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: TkColors.primary))
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                        children: [
                          Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: TkColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.center,
                              child: Text(inisial,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: TkColors.primaryDark)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TkTextField(
                            label: 'Nama Lengkap',
                            controller: _nama,
                            validator: Validators.namaLengkap,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),
                          TkTextField(
                            label: 'No. Telepon',
                            controller: _telepon,
                            keyboardType: TextInputType.phone,
                            validator: Validators.noTelepon,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),
                          Text('Alamat',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TkColors.label)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _alamat,
                            maxLines: 3,
                            minLines: 2,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: Validators.teksBebas,
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                color: TkColors.inkSoft,
                                height: 1.5),
                            decoration: InputDecoration(
                              hintText:
                                  'Jalan, nomor, kelurahan — Kota Sampit',
                              hintStyle: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  color: TkColors.textPlaceholder),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TkButton(
                            label: 'Simpan Perubahan',
                            loading: _menyimpan,
                            onPressed: () => _simpan(profil),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
