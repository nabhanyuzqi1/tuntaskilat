import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import 'p2_auth_screen.dart';

/// OB1-OB3 — Onboarding Aplikasi Pelanggan (hanya tampil saat install
/// pertama). Konten & visual mengikuti Canvas.dc.html section Onboarding:
/// OB1 Pesan Cepat, OB2 Tarif Transparan, OB3 Tracking Real-Time.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _halaman = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// OB1/OB2 `Lewati` dan OB3 `Sudah punya akun? Masuk` → P2 tab Masuk;
  /// OB3 `Mulai Sekarang` → P2 tab Daftar.
  Future<void> _selesai({required bool keTabDaftar}) async {
    await tandaiOnboardingSelesai();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      P2AuthScreen.route,
      arguments: P2AuthScreenArgs(tabDaftar: keTabDaftar),
    );
  }

  void _lanjut() {
    if (_halaman < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _selesai(keTabDaftar: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diOB3 = _halaman == 2;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: diOB3
                    ? null
                    : TextButton(
                        onPressed: () => _selesai(keTabDaftar: false),
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TkColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _halaman = i),
                children: const [
                  _HalamanOnboarding(
                    ilustrasi: _IlustrasiOB1(),
                    judul: 'Pesan Layanan dalam Hitungan Menit',
                    deskripsi:
                        'Pilih layanan kebersihan, tentukan jadwal, dan kru '
                        'profesional kami siap datang.',
                  ),
                  _HalamanOnboarding(
                    ilustrasi: _IlustrasiOB2(),
                    judul: 'Tarif Jelas Sejak Awal',
                    deskripsi:
                        'Semua harga tampil transparan sebelum Anda membayar '
                        '— tanpa biaya tersembunyi.',
                  ),
                  _HalamanOnboarding(
                    ilustrasi: _IlustrasiOB3(),
                    judul: 'Pantau Kru Secara Real-Time',
                    deskripsi:
                        'Lihat posisi kru, estimasi tiba, dan identitas kru '
                        'terverifikasi langsung dari aplikasi.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, diOB3 ? 24 : 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final aktif = i == _halaman;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: aktif ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: aktif
                              ? TkColors.primary
                              : TkColors.primary.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: diOB3 ? 16 : 20),
                  TkButton(
                    label: diOB3 ? 'Mulai Sekarang' : 'Lanjut',
                    onPressed: _lanjut,
                  ),
                  if (diOB3) ...[
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        text: 'Sudah punya akun? ',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: TkColors.textSecondary,
                        ),
                        children: [
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => _selesai(keTabDaftar: false),
                              child: Text(
                                'Masuk',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HalamanOnboarding extends StatelessWidget {
  const _HalamanOnboarding({
    required this.ilustrasi,
    required this.judul,
    required this.deskripsi,
  });

  final Widget ilustrasi;
  final String judul;
  final String deskripsi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
          child: AspectRatio(aspectRatio: 342 / 400, child: ilustrasi),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  judul,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  deskripsi,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: TkColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ilustrasi OB1 — katalog mini + slot waktu (Hi-Fi: dua kartu layanan dengan
// lencana harga kuning, kartu pilih slot dengan slot aktif hijau).
// ---------------------------------------------------------------------------
class _IlustrasiOB1 extends StatelessWidget {
  const _IlustrasiOB1();

  @override
  Widget build(BuildContext context) {
    return _BingkaiIlustrasi(
      lingkaranAksen: Positioned(
        top: -80,
        right: -80,
        child: _lingkaran(320, TkColors.primary.withValues(alpha: 0.05)),
      ),
      child: SizedBox(
        width: 262,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _KartuLayananMini(
                    nama: 'Bersih Rumah',
                    harga: 'Rp 25rb/ruang',
                    warnaIkon: TkColors.primary.withValues(alpha: 0.10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KartuLayananMini(
                    nama: 'Cuci Sofa',
                    harga: 'Rp 60rb/dudukan',
                    warnaIkon: TkColors.accentAlt.withValues(alpha: 0.14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _dekorKartu(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih slot waktu — Hari ini',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TkColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _slot('09.00', aktif: false),
                      const SizedBox(width: 8),
                      _slot('13.00', aktif: true),
                      const SizedBox(width: 8),
                      _slot('15.00', aktif: false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slot(String jam, {required bool aktif}) => Expanded(
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? TkColors.primary : TkColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            jam,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: aktif ? TkColors.surface : TkColors.textSecondary,
            ),
          ),
        ),
      );
}

class _KartuLayananMini extends StatelessWidget {
  const _KartuLayananMini({
    required this.nama,
    required this.harga,
    required this.warnaIkon,
  });

  final String nama;
  final String harga;
  final Color warnaIkon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: _dekorKartu(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: warnaIkon),
            alignment: Alignment.center,
            child: Image.asset('assets/brand/brandmark.webp', height: 18),
          ),
          const SizedBox(height: 8),
          Text(
            nama,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TkColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: TkColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              harga,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: TkColors.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ilustrasi OB2 — kartu Rincian Tagihan (breakdown + total + badge
// "Tanpa biaya tersembunyi").
// ---------------------------------------------------------------------------
class _IlustrasiOB2 extends StatelessWidget {
  const _IlustrasiOB2();

  @override
  Widget build(BuildContext context) {
    return _BingkaiIlustrasi(
      lingkaranAksen: Positioned(
        bottom: -100,
        left: -90,
        child: _lingkaran(320, TkColors.accent.withValues(alpha: 0.10)),
      ),
      child: Container(
        width: 272,
        padding: const EdgeInsets.all(18),
        decoration: _dekorKartu(radius: 16, shadowKuat: true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Tagihan',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TkColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _baris('Bersih Rumah × 3 ruang', 'Rp 75.000'),
            const SizedBox(height: 12),
            _baris('Cuci Sofa × 1 dudukan', 'Rp 60.000'),
            const SizedBox(height: 12),
            const _GarisPutus(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft,
                  ),
                ),
                Text(
                  'Rp 135.000',
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: TkColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TkColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ Tanpa biaya tersembunyi',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TkColors.onAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baris(String kiri, String kanan) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            kiri,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: TkColors.textSecondary,
            ),
          ),
          Text(
            kanan,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TkColors.inkSoft,
            ),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// Ilustrasi OB3 — peta mock: jalan putih, rute putus-putus, marker kru
// (brandmark) & tujuan, chip ETA glass, kartu identitas kru glass.
// ---------------------------------------------------------------------------
class _IlustrasiOB3 extends StatelessWidget {
  const _IlustrasiOB3();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: const Color(0xFFE4EFE8),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            Widget jalanH(double top) => Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  child: Container(
                    height: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                );
            Widget jalanV(double? left, double? right) => Positioned(
                  top: 0,
                  bottom: 0,
                  left: left,
                  right: right,
                  child: Container(
                    width: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                );
            return Stack(
              children: [
                jalanH(h * 0.30),
                jalanH(h * 0.67),
                jalanV(w * 0.28, null),
                jalanV(null, w * 0.23),
                // Rute putus-putus dari marker kru ke tujuan.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RutePainter(
                      dari: Offset(w * 0.28, h * 0.32),
                      ke: Offset(w * 0.76, h * 0.66),
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.28,
                  left: w * 0.22,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TkColors.primary,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: TkColors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        Image.asset('assets/brand/brandmark.webp', height: 13),
                  ),
                ),
                Positioned(
                  top: h * 0.62,
                  right: w * 0.17,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TkColors.accentAlt,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: TkColors.accentAlt.withValues(alpha: 0.40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: GlassContainer(
                    radius: 10,
                    opacity: 0.70,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Text(
                      'Tiba dalam 12 menit',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GlassContainer(
                    radius: 16,
                    opacity: 0.72,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFDCE7E0),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'AR',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TkColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Andi Rahman',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TkColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  text: '★★★★★ ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: TkColors.accentAlt,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '4,9 · Kru terverifikasi',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: TkColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TkColors.primary,
                          ),
                          child: const Icon(Icons.call,
                              size: 18, color: TkColors.surface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RutePainter extends CustomPainter {
  const _RutePainter({required this.dari, required this.ke});

  final Offset dari;
  final Offset ke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TkColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const panjangDash = 8.0;
    const jarakDash = 6.0;
    final total = (ke - dari).distance;
    final arah = (ke - dari) / total;
    var jarak = 0.0;
    while (jarak < total) {
      final akhir = (jarak + panjangDash).clamp(0, total).toDouble();
      canvas.drawLine(dari + arah * jarak, dari + arah * akhir, paint);
      jarak = akhir + jarakDash;
    }
  }

  @override
  bool shouldRepaint(_RutePainter oldDelegate) =>
      dari != oldDelegate.dari || ke != oldDelegate.ke;
}

// ---------------------------------------------------------------------------
// Elemen bersama ilustrasi
// ---------------------------------------------------------------------------
class _BingkaiIlustrasi extends StatelessWidget {
  const _BingkaiIlustrasi({
    required this.child,
    required this.lingkaranAksen,
  });

  final Widget child;
  final Widget lingkaranAksen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: TkColors.primary.withValues(alpha: 0.06),
        child: Stack(
          children: [
            lingkaranAksen,
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class _GarisPutus extends StatelessWidget {
  const _GarisPutus();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const lebarDash = 6.0;
        final jumlah = (c.maxWidth / (lebarDash * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            jumlah,
            (_) => Container(
              width: lebarDash,
              height: 1.5,
              color: const Color(0xFFDCE3DE),
            ),
          ),
        );
      },
    );
  }
}

Widget _lingkaran(double diameter, Color warna) => Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
    );

BoxDecoration _dekorKartu({required double radius, bool shadowKuat = false}) =>
    BoxDecoration(
      color: TkColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: TkColors.inkSoft.withValues(alpha: shadowKuat ? 0.10 : 0.08),
          blurRadius: shadowKuat ? 28 : 20,
          offset: Offset(0, shadowKuat ? 12 : 8),
        ),
      ],
    );
