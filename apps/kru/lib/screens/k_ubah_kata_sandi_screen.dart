import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';

/// Ubah Kata Sandi Portal Kru — form yang sama dengan P13 Aplikasi
/// Pelanggan (page-inventory: "form sama, dipakai lintas app").
class KUbahKataSandiScreen extends ConsumerStatefulWidget {
  const KUbahKataSandiScreen({super.key});

  static const route = '/k-ubah-sandi';

  @override
  ConsumerState<KUbahKataSandiScreen> createState() =>
      _KUbahKataSandiScreenState();
}

class _KUbahKataSandiScreenState
    extends ConsumerState<KUbahKataSandiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _konfirmasi = TextEditingController();
  var _menyimpan = false;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      await ref.read(authServiceProvider).updatePassword(
            passwordLama: _lama.text,
            passwordBaru: _baru.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kata sandi berhasil diperbarui.')));
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final pesan = switch (e.code) {
        'invalid-credential' ||
        'wrong-password' =>
          'Kata sandi lama tidak sesuai. Periksa kembali.',
        'weak-password' =>
          'Kata sandi baru terlalu lemah. Gunakan minimal 8 karakter.',
        _ => 'Perubahan belum tersimpan. Coba lagi.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pesan)));
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      // Header putih membungkus SafeArea — warna naik sampai belakang
      // status bar (sinkron system bar ↔ header).
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
                child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
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
                Text('Ubah Kata Sandi',
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
              ]),
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
                      label: 'Kata Sandi Lama',
                      controller: _lama,
                      hint: 'Kata sandi saat ini',
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Kata sandi lama wajib diisi.'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    TkTextField(
                      label: 'Kata Sandi Baru',
                      controller: _baru,
                      hint: 'Minimal 8 karakter',
                      obscureText: true,
                      validator: Validators.kataSandi,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    TkTextField(
                      label: 'Konfirmasi Kata Sandi Baru',
                      controller: _konfirmasi,
                      hint: 'Ulangi kata sandi baru',
                      obscureText: true,
                      validator: (v) =>
                          Validators.konfirmasiKataSandi(v, _baru.text),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    TkButton(
                      label: 'Simpan Perubahan',
                      loading: _menyimpan,
                      onPressed: _simpan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
