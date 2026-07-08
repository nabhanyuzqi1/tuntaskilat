import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/beranda_providers.dart';
import 'p2a_izin_screen.dart';

/// P2b — Lengkapi Profil. Mencegat pengguna yang baru daftar atau
/// login via Google dan belum melengkapi data (No. Telepon & Alamat).
class P2bLengkapiProfilScreen extends ConsumerStatefulWidget {
  const P2bLengkapiProfilScreen({super.key});

  static const route = '/p2b';

  @override
  ConsumerState<P2bLengkapiProfilScreen> createState() =>
      _P2bLengkapiProfilScreenState();
}

class _P2bLengkapiProfilScreenState extends ConsumerState<P2bLengkapiProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telepon = TextEditingController();
  final _alamat = TextEditingController();
  var _menyimpan = false;

  @override
  void dispose() {
    _telepon.dispose();
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    setState(() => _menyimpan = true);
    try {
      final profil = await ref.read(authServiceProvider).fetchProfile(user.uid);
      if (profil != null) {
        await ref.read(firestoreServiceProvider).updateUserProfile(
              profil.copyWith(
                noTelepon: _telepon.text.trim(),
                alamat: _alamat.text.trim(),
              ),
            );
        ref.invalidate(profilSayaProvider);
      }
      if (!mounted) return;
      // Setelah sukses melengkapi profil, arahkan ke layar Izin
      Navigator.of(context).pushReplacementNamed(P2aIzinScreen.route);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Data belum tersimpan. Periksa koneksi Anda.')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Text('Lengkapi Profil',
                  style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Satu langkah lagi! Lengkapi informasi kontak Anda agar kami mudah menghubungi Anda.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TkColors.textPlaceholder,
                  height: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                  children: [
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: Validators.teksBebas,
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: TkColors.inkSoft,
                          height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Jalan, nomor, kelurahan — Kota Sampit',
                        hintStyle: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: TkColors.textPlaceholder),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TkButton(
                      label: 'Simpan',
                      loading: _menyimpan,
                      onPressed: _simpan,
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
