import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import 'k1_login_screen.dart';

/// KO1-KO3 — Onboarding Kru (tampil sekali saat install pertama).
/// Konten berbeda dari onboarding Pelanggan: peran kru sejak awal.
class OnboardingKruScreen extends StatefulWidget {
  const OnboardingKruScreen({super.key});

  static const route = '/onboarding-kru';

  @override
  State<OnboardingKruScreen> createState() => _OnboardingKruScreenState();
}

class _OnboardingKruScreenState extends State<OnboardingKruScreen> {
  final _controller = PageController();
  var _halaman = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _keLogin() async {
    await tandaiOnboardingKruSelesai();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(K1LoginScreen.route);
    }
  }

  void _lanjut() {
    if (_halaman >= 2) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 48,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _halaman < 2
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _keLogin,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Lewati',
                            style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TkColors.textMuted)),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _halaman = i),
                children: const [
                  _HalamanKO(
                    judul: 'Terima Tugas Terdekat',
                    deskripsi:
                        'Aktifkan status Online dan lihat daftar penugasan '
                        'terdekat lengkap dengan alamat, waktu, dan jarak.',
                    ilustrasi: _IlustrasiKO1(),
                  ),
                  _HalamanKO(
                    judul: 'Ikuti Rute, Update Status',
                    deskripsi:
                        'Navigasi ke lokasi pelanggan dan perbarui status '
                        'tahap demi tahap: Menuju Lokasi → Mulai Pengerjaan '
                        '→ Selesai.',
                    ilustrasi: _IlustrasiKO2(),
                  ),
                  _HalamanKO(
                    judul: 'Laporkan & Terima Bayaran',
                    deskripsi:
                        'Unggah foto sebelum & sesudah pengerjaan — '
                        'pendapatan tugas Anda langsung tercatat.',
                    ilustrasi: _IlustrasiKO3(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _halaman ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _halaman
                              ? TkColors.primaryDark
                              : TkColors.primaryDark
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                TkButton(
                  label: _halaman == 2 ? 'Mulai Bekerja' : 'Lanjut',
                  onPressed: _halaman == 2 ? _keLogin : _lanjut,
                ),
                if (_halaman == 2) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _keLogin,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text.rich(
                        TextSpan(
                          text: 'Sudah tahu caranya? ',
                          style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: TkColors.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Masuk',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _HalamanKO extends StatelessWidget {
  const _HalamanKO({
    required this.judul,
    required this.deskripsi,
    required this.ilustrasi,
  });

  final String judul;
  final String deskripsi;
  final Widget ilustrasi;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 10, 34, 0),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TkColors.primaryDark, TkColors.primary],
                ),
                boxShadow: [
                  BoxShadow(
                      color: TkColors.primary.withValues(alpha: 0.5),
                      blurRadius: 44,
                      offset: const Offset(0, 20),
                      spreadRadius: -18),
                ],
              ),
              child: ilustrasi,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 16),
        child: Column(children: [
          Text(judul,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),
          Text(deskripsi,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: TkColors.textSecondary,
                  height: 1.55)),
        ]),
      ),
    ]);
  }
}

/// Mock kartu putih di dalam ilustrasi hijau.
class _KartuMock extends StatelessWidget {
  const _KartuMock({required this.child, this.tinted = false});

  final Widget child;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tinted
            ? Colors.white.withValues(alpha: 0.14)
            : TkColors.surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: child,
    );
  }
}

class _IlustrasiKO1 extends StatelessWidget {
  const _IlustrasiKO1();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KartuMock(
          tinted: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: TkColors.accent)),
                const SizedBox(width: 9),
                Text('Online',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TkColors.surface)),
              ]),
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: TkColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(3),
                child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: TkColors.surface)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final (nama, jam, alamat) in const [
          ('Bersih Rumah · 3 ruang', '10.00', 'Jl. MT. Haryono · 2,4 km'),
          ('Cuci Sofa · 2 dudukan', '13.30', 'Jl. S. Parman · 4,1 km'),
        ]) ...[
          _KartuMock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(nama,
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                    Text(jam,
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TkColors.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(alamat,
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: TkColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _IlustrasiKO2 extends StatelessWidget {
  const _IlustrasiKO2();

  @override
  Widget build(BuildContext context) {
    Widget langkah(String label, bool selesai, bool aktif) => Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selesai || aktif
                  ? TkColors.accent
                  : Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(
                selesai ? Icons.check_rounded : Icons.circle,
                size: selesai ? 16 : 8,
                color: selesai || aktif
                    ? TkColors.onAccent
                    : Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight:
                      aktif ? FontWeight.w700 : FontWeight.w500,
                  color: TkColors.surface)),
        ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KartuMock(
          tinted: true,
          child: Row(children: [
            const Icon(Icons.near_me_rounded,
                size: 18, color: TkColors.surface),
            const SizedBox(width: 8),
            Text('Menuju Jl. MT. Haryono No. 45',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TkColors.surface)),
          ]),
        ),
        const SizedBox(height: 20),
        langkah('Menuju Lokasi', true, false),
        Container(
            margin: const EdgeInsets.only(left: 14),
            width: 2,
            height: 18,
            color: Colors.white.withValues(alpha: 0.25)),
        langkah('Mulai Pengerjaan', false, true),
        Container(
            margin: const EdgeInsets.only(left: 14),
            width: 2,
            height: 18,
            color: Colors.white.withValues(alpha: 0.25)),
        langkah('Selesai', false, false),
      ],
    );
  }
}

class _IlustrasiKO3 extends StatelessWidget {
  const _IlustrasiKO3();

  @override
  Widget build(BuildContext context) {
    Widget foto(String label) => Expanded(
          child: Column(children: [
            Container(
              height: 84,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.photo_camera_outlined,
                  size: 26, color: TkColors.surface),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TkColors.surface)),
          ]),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          foto('Foto Sebelum'),
          const SizedBox(width: 12),
          foto('Foto Sesudah'),
        ]),
        const SizedBox(height: 14),
        _KartuMock(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pendapatan tugas masuk',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
              Text('+ Rp 75.000',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TkColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
