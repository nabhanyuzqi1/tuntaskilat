import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/auth_controller.dart';
import 'p2a_izin_screen.dart';
import 'p2b_lengkapi_profil_screen.dart';
import 'p3_beranda_screen.dart';
import 'syarat_ketentuan_screen.dart';

class P2AuthScreenArgs {
  const P2AuthScreenArgs({this.tabDaftar = false});
  final bool tabDaftar;
}

/// P2 — Masuk / Registrasi. Gambar TA 3.14.
/// Toggle Masuk/Daftar, validasi inline real-time (kaidah Pencegahan
/// Kesalahan), registrasi menulis dokumen `users` dengan role `pelanggan`.
class P2AuthScreen extends ConsumerStatefulWidget {
  const P2AuthScreen({super.key});

  static const route = '/p2';

  @override
  ConsumerState<P2AuthScreen> createState() => _P2AuthScreenState();
}

class _P2AuthScreenState extends ConsumerState<P2AuthScreen> {
  var _tabDaftar = false;
  var _argsDibaca = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsDibaca) return;
    _argsDibaca = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is P2AuthScreenArgs) _tabDaftar = args.tabDaftar;
  }

  void _keBeranda() {
    final profil = ref.read(authControllerProvider).valueOrNull;
    if (profil != null && (profil.noTelepon.isEmpty || profil.alamat.isEmpty)) {
      Navigator.of(context).pushReplacementNamed(P2bLengkapiProfilScreen.route);
    } else {
      Navigator.of(context).pushReplacementNamed(P2aIzinScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/brand/logo-color.webp', width: 64),
              const SizedBox(height: 18),
              Text(
                'Selamat Datang',
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Layanan kebersihan on-demand untuk rumah Anda.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: TkColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _ToggleMasukDaftar(
                tabDaftar: _tabDaftar,
                onChanged: (daftar) => setState(() => _tabDaftar = daftar),
              ),
              const SizedBox(height: 16),
              if (_tabDaftar)
                _FormDaftar(onSukses: _keBeranda)
              else
                _FormMasuk(
                  onSukses: _keBeranda,
                  keDaftar: () => setState(() => _tabDaftar = true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleMasukDaftar extends StatelessWidget {
  const _ToggleMasukDaftar({required this.tabDaftar, required this.onChanged});

  final bool tabDaftar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, {required bool aktif, required bool daftar}) =>
        Expanded(
          child: GestureDetector(
            // opaque: seluruh area tab (bukan hanya teksnya) menangkap tap —
            // target sentuh ≥ 48dp (kaidah Aksesibilitas).
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(daftar),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: aktif
                  ? BoxDecoration(
                      color: TkColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    )
                  : null,
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: aktif ? TkColors.primary : TkColors.textSecondary,
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TkColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab('Masuk', aktif: !tabDaftar, daftar: false),
          tab('Daftar', aktif: tabDaftar, daftar: true),
        ],
      ),
    );
  }
}

class _FormMasuk extends ConsumerStatefulWidget {
  const _FormMasuk({required this.onSukses, required this.keDaftar});

  final VoidCallback onSukses;
  final VoidCallback keDaftar;

  @override
  ConsumerState<_FormMasuk> createState() => _FormMasukState();
}

class _FormMasukState extends ConsumerState<_FormMasuk> {
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
    final sukses = await ref.read(authControllerProvider.notifier).masuk(
          email: _email.text.trim(),
          password: _sandi.text,
        );
    if (sukses && mounted) widget.onSukses();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TkTextField(
            label: 'Email',
            controller: _email,
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TkTextField(
            label: 'Kata Sandi',
            controller: _sandi,
            obscureText: _sandiTersembunyi,
            validator: Validators.kataSandi,
            textInputAction: TextInputAction.done,
            suffixIcon: _TombolLihatSandi(
              tersembunyi: _sandiTersembunyi,
              onTap: () =>
                  setState(() => _sandiTersembunyi = !_sandiTersembunyi),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Hubungi Customer Service (07.00-21.00 WIB) untuk '
                    'mengatur ulang kata sandi.',
                  ),
                ),
              ),
              child: const Text('Lupa kata sandi?'),
            ),
          ),
          TkButton(label: 'Masuk', loading: loading, onPressed: _submit),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TkColors.textMuted,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: loading
                ? null
                : () async {
                    final sukses = await ref
                        .read(authControllerProvider.notifier)
                        .masukDenganGoogle();
                    if (sukses && context.mounted) widget.onSukses();
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4285F4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Masuk dengan Google',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2933),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Belum punya akun? ',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: TkColors.textSecondary,
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.keDaftar,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Daftar',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TkColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: TextButton(
              // MODE TAMU: jelajahi katalog & promo tanpa akun; setiap aksi
              // (pesan, riwayat, profil) akan menawarkan login kembali.
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(P3BerandaScreen.route),
              child: Text(
                'Jelajahi dulu tanpa akun',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TkColors.label,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormDaftar extends ConsumerStatefulWidget {
  const _FormDaftar({required this.onSukses});

  final VoidCallback onSukses;

  @override
  ConsumerState<_FormDaftar> createState() => _FormDaftarState();
}

class _FormDaftarState extends ConsumerState<_FormDaftar> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _konfirmasi = TextEditingController();
  final _referal = TextEditingController();
  var _sandiTersembunyi = true;
  var _setuju = false;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _email.dispose();
    _sandi.dispose();
    _konfirmasi.dispose();
    _referal.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ref0 = _referal.text.trim();
    final sukses = await ref.read(authControllerProvider.notifier).daftar(
          nama: _nama.text.trim(),
          email: _email.text.trim(),
          noTelepon: _telepon.text.trim(),
          password: _sandi.text,
          kodeReferal: ref0.isEmpty ? null : ref0,
        );
    if (sukses && mounted) widget.onSukses();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TkTextField(
            label: 'Nama Lengkap',
            controller: _nama,
            hint: 'Masukkan nama lengkap',
            validator: Validators.namaLengkap,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TkTextField(
            label: 'No. Telepon',
            controller: _telepon,
            hint: '08xx-xxxx-xxxx',
            keyboardType: TextInputType.phone,
            validator: Validators.noTelepon,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TkTextField(
            label: 'Email',
            controller: _email,
            hint: 'nama@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TkTextField(
            label: 'Kata Sandi',
            controller: _sandi,
            hint: 'Minimal 8 karakter',
            obscureText: _sandiTersembunyi,
            validator: Validators.kataSandi,
            textInputAction: TextInputAction.next,
            suffixIcon: _TombolLihatSandi(
              tersembunyi: _sandiTersembunyi,
              onTap: () =>
                  setState(() => _sandiTersembunyi = !_sandiTersembunyi),
            ),
          ),
          const SizedBox(height: 14),
          TkTextField(
            label: 'Konfirmasi Kata Sandi',
            controller: _konfirmasi,
            hint: 'Ulangi kata sandi',
            obscureText: true,
            validator: (v) => Validators.konfirmasiKataSandi(v, _sandi.text),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TkTextField(
            label: 'Kode Referal (opsional)',
            controller: _referal,
            hint: 'Punya kode teman? Masukkan di sini',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 14),
          // Persetujuan S&K WAJIB dicentang sebelum mendaftar.
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: _setuju,
                onChanged: (v) => setState(() => _setuju = v ?? false),
                activeColor: TkColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text.rich(
                  TextSpan(
                    text: 'Saya menyetujui ',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: TkColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Syarat & Ketentuan',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context)
                              .pushNamed(SyaratKetentuanScreen.route),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context)
                              .pushNamed(SyaratKetentuanScreen.route),
                      ),
                      const TextSpan(text: ' Tuntaskilat.'),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TkButton(
            label: 'Daftar',
            loading: loading,
            onPressed: _setuju ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _TombolLihatSandi extends StatelessWidget {
  const _TombolLihatSandi({required this.tersembunyi, required this.onTap});

  final bool tersembunyi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        tersembunyi ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: TkColors.textMuted,
      ),
    );
  }
}
