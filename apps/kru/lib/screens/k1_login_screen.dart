import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/auth_kru_controller.dart';
import 'k2a_izin_screen.dart';

/// K1 — Masuk (peran kru). Gambar TA 3.14. Tanpa registrasi mandiri —
/// akun kru dibuat admin via A5 (kaidah Konsistensi: satu titik masuk).
class K1LoginScreen extends ConsumerStatefulWidget {
  const K1LoginScreen({super.key});

  static const route = '/k1';

  @override
  ConsumerState<K1LoginScreen> createState() => _K1LoginScreenState();
}

class _K1LoginScreenState extends ConsumerState<K1LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  var _sandiTersembunyi = true;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sukses = await ref.read(authKruControllerProvider.notifier).masuk(
          email: _email.text.trim(),
          password: _sandi.text,
        );
    if (sukses && mounted) {
      Navigator.of(context).pushReplacementNamed(K2aIzinScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authKruControllerProvider, (_, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
    final loading = ref.watch(authKruControllerProvider).isLoading;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header hijau Portal Kru
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TkColors.primaryDark, TkColors.primary],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 26, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(11),
                      child: Image.asset('assets/brand/brandmark.webp'),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: TkColors.accent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color: TkColors.accent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: TkColors.accent)),
                          const SizedBox(width: 6),
                          Text('PORTAL KRU',
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: TkColors.accent,
                                  letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Masuk Akun Kru',
                        style: GoogleFonts.montserrat(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: TkColors.surface,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'Gunakan akun yang dibuatkan admin untuk mulai '
                      'menerima penugasan.',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                children: [
                  TkTextField(
                    label: 'Email',
                    controller: _email,
                    hint: 'kru@tuntaskilat.id',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  TkTextField(
                    label: 'Kata Sandi',
                    controller: _sandi,
                    obscureText: _sandiTersembunyi,
                    validator: Validators.kataSandi,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _sandiTersembunyi = !_sandiTersembunyi),
                      icon: Icon(
                        _sandiTersembunyi
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: TkColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TkButton(
                      label: 'Masuk', loading: loading, onPressed: _submit),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TkColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: TkColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Akun kru dibuat oleh admin. Hubungi kantor '
                            'Tuntaskilat jika belum memiliki akses.',
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: const Color(0xFF33403A),
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
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
