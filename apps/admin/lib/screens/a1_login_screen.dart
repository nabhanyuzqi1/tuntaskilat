import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../util/totp.dart';
import 'admin_shell.dart';

/// A1 — Masuk Admin (Gambar TA 3.18). Layout desktop: panel branding hijau
/// kiri + kartu login centered kanan. Menolak akun dengan role non-admin
/// (klien & Security Rules — skenario Black-Box #5).
class A1LoginScreen extends ConsumerStatefulWidget {
  const A1LoginScreen({super.key});

  static const route = '/a1';

  @override
  ConsumerState<A1LoginScreen> createState() => _A1LoginScreenState();
}

class _A1LoginScreenState extends ConsumerState<A1LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  var _sandiTersembunyi = true;
  var _memuat = false;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ref.read(firebaseSiapProvider)) {
      _snack(kDebugMode
          ? pesanFirebaseBelumSiap
          : 'Terjadi kendala. Coba beberapa saat lagi.');
      return;
    }
    setState(() => _memuat = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _email.text.trim(),
            password: _sandi.text,
            roleDiharapkan: UserRole.admin,
          );
      // Faktor kedua (2FA TOTP) bila diaktifkan admin ini.
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid != null) {
        final cfg = await ref.read(firestoreServiceProvider).get2fa(uid);
        if (cfg != null && cfg.aktif && cfg.secret.isNotEmpty) {
          if (!mounted) return;
          final lolos = await _minta2fa(cfg.secret);
          if (!lolos) {
            await ref.read(authServiceProvider).signOut();
            _snack('Kode 2FA salah. Login dibatalkan.');
            return;
          }
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AdminShell.route);
      }
    } on RoleTidakSesuaiException {
      _snack('Akses panel hanya untuk staf resmi Tuntaskilat.');
    } on FirebaseAuthException catch (e) {
      _snack(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email atau kata sandi tidak sesuai. Periksa kembali.',
        'too-many-requests' =>
          'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.',
        _ => 'Terjadi kendala saat autentikasi. Coba lagi.',
      });
    } catch (_) {
      _snack('Terjadi kendala. Periksa koneksi Anda lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _snack(String pesan) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));

  /// Dialog input 6 digit kode authenticator; kembalikan true bila cocok.
  Future<bool> _minta2fa(String secret) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi 2 Faktor'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Masukkan 6 digit dari aplikasi Authenticator Anda.'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            onSubmitted: (_) =>
                Navigator.pop(ctx, Totp.verifikasi(secret, ctrl.text)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, Totp.verifikasi(secret, ctrl.text)),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    final tampilkanBranding = lebar >= 980;

    return Scaffold(
      body: Row(children: [
        if (tampilkanBranding)
          Expanded(flex: 46, child: _panelBranding()),
        Expanded(
          flex: 54,
          child: Container(
            color: const Color(0xFFF6F8F5),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(40),
            child: SingleChildScrollView(child: _kartuLogin()),
          ),
        ),
      ]),
    );
  }

  Widget _panelBranding() {
    return Container(
      padding: const EdgeInsets.all(56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TkColors.primaryDark, TkColors.primary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/brand/brandmark.webp'),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tuntaskilat',
                    style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: TkColors.surface)),
                Text('PANEL ADMIN',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.5)),
              ],
            ),
          ]),
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kelola operasional dari satu tempat.',
                    style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: TkColors.surface,
                        letterSpacing: -0.8,
                        height: 1.15)),
                const SizedBox(height: 20),
                Text(
                    'Verifikasi pembayaran, tugaskan kru, dan pantau '
                    'layanan kebersihan Sampit secara real-time.',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.6)),
                const SizedBox(height: 28),
                _fitur(Icons.verified_user_outlined,
                    'Verifikasi pembayaran cepat & aman'),
                const SizedBox(height: 14),
                _fitur(Icons.how_to_reg_outlined,
                    'Penugasan kru manual & terpantau'),
              ],
            ),
          ),
          const Spacer(),
          Text('© 2026 PT Tuntas Kilat Group · Sampit, Kalteng',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _fitur(IconData ikon, String teks) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(ikon, size: 18, color: TkColors.accent),
        ),
        const SizedBox(width: 12),
        Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9))),
      ]);

  Widget _kartuLogin() {
    return Container(
      width: 420,
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 44),
      decoration: BoxDecoration(
        color: TkColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0D0F281C)),
        boxShadow: [
          BoxShadow(
              color: TkColors.inkSoft.withValues(alpha: 0.22),
              blurRadius: 44,
              offset: const Offset(0, 20),
              spreadRadius: -24),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: TkColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: TkColors.primary)),
                const SizedBox(width: 6),
                Text('AKSES ADMIN',
                    style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TkColors.primaryDark,
                        letterSpacing: 0.4)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Masuk ke Panel',
                style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft,
                    letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Gunakan kredensial admin Tuntaskilat Anda.',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: TkColors.textSecondary)),
            const SizedBox(height: 30),
            TkTextField(
              label: 'Email',
              controller: _email,
              hint: 'admin@tuntaskilat.id',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 22),
            TkButton(label: 'Masuk', loading: _memuat, onPressed: _masuk),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: TkColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: TkColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Akses panel hanya untuk staf resmi Tuntaskilat.',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: const Color(0xFF33403A))),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
