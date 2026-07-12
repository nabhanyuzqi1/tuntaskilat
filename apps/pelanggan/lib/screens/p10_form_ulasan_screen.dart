import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/beranda_providers.dart';
import '../widgets/service_icon.dart';
import 'p5_form_pemesanan_screen.dart' show JudulHariID;

/// P10 — Form Ulasan (Gambar TA 3.17). Rating bintang besar 44px (kaidah
/// Aksesibilitas), komentar opsional (validator skenario #2). Submit memicu
/// transaction update `kru.rataRating` + `jumlahUlasan` (firestore-schema.md).
class P10FormUlasanScreen extends ConsumerStatefulWidget {
  const P10FormUlasanScreen({super.key});

  static const route = '/p10';

  @override
  ConsumerState<P10FormUlasanScreen> createState() =>
      _P10FormUlasanScreenState();
}

class _P10FormUlasanScreenState extends ConsumerState<P10FormUlasanScreen> {
  var _rating = 0;
  final _aspekTerpilih = <String>{};
  final _komentar = TextEditingController();
  var _mengirim = false;
  var _terkirim = false;

  static const _aspek = ['Tepat waktu', 'Ramah', 'Hasil bersih', 'Rapi'];
  static const _labelRating = [
    'Pilih rating Anda',
    'Kurang memuaskan',
    'Perlu perbaikan',
    'Cukup baik',
    'Memuaskan',
    'Sangat memuaskan!',
  ];

  @override
  void dispose() {
    _komentar.dispose();
    super.dispose();
  }

  Future<void> _kirim(OrderModel order) async {
    // Guard anti double-tap: cegah kirim ulasan ganda saat proses berjalan.
    if (_mengirim) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih rating bintang terlebih dahulu.')));
      return;
    }
    final errKomentar = Validators.teksBebas(_komentar.text);
    if (errKomentar != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errKomentar)));
      return;
    }
    // Set loading SINKRON sebelum await agar tombol langsung nonaktif.
    setState(() => _mengirim = true);
    try {
      final profil = await ref.read(profilSayaProvider.future);
      if (profil == null || !mounted) return;
      // Chip aspek digabung ke komentar (schema reviews hanya punya
      // `komentar` — tidak ada field aspek terpisah).
      final bagian = [
        if (_aspekTerpilih.isNotEmpty) _aspekTerpilih.join(' · '),
        if (_komentar.text.trim().isNotEmpty) _komentar.text.trim(),
      ];
      await ref.read(firestoreServiceProvider).createReview(
            orderId: order.orderId,
            pelanggan: profil,
            cleanerId: order.cleanerId,
            penilaian: _rating,
            komentar: bagian.join(' — '),
          );
      if (mounted) setState(() => _terkirim = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Ulasan belum terkirim. Periksa koneksi Anda lalu coba '
                'lagi.')));
      }
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _terkirim ? _sukses() : _form(order),
      ),
    );
  }

  Widget _form(OrderModel order) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          decoration: const BoxDecoration(
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
            Text('Beri Ulasan',
                style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: TkColors.inkSoft)),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            children: [
              Column(children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: TkColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(serviceIcon(''),
                      size: 34, color: TkColors.primary),
                ),
                const SizedBox(height: 14),
                Text('Bagaimana layanannya?',
                    style: GoogleFonts.montserrat(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: TkColors.inkSoft)),
                const SizedBox(height: 4),
                Text(
                  '${order.namaLayanan} · '
                  '${JudulHariID.tanggal(order.jadwal)}'
                  '${(order.namaKru ?? '').isEmpty ? '' : ' · oleh ${order.namaKru}'}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.textMuted),
                ),
              ]),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _rating = i),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 48,
                          color: i <= _rating
                              ? TkColors.accent
                              : const Color(0xFFE3E8E4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(_labelRating[_rating],
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _rating == 0
                            ? TkColors.textMuted
                            : TkColors.primary)),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final aspek in _aspek)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() =>
                          _aspekTerpilih.contains(aspek)
                              ? _aspekTerpilih.remove(aspek)
                              : _aspekTerpilih.add(aspek)),
                      child: Container(
                        height: 34,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _aspekTerpilih.contains(aspek)
                              ? TkColors.primary.withValues(alpha: 0.08)
                              : TkColors.surface,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: _aspekTerpilih.contains(aspek)
                                ? TkColors.primary.withValues(alpha: 0.22)
                                : const Color(0x1A0F281C),
                          ),
                        ),
                        child: Text(aspek,
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: _aspekTerpilih.contains(aspek)
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _aspekTerpilih.contains(aspek)
                                    ? TkColors.primaryDark
                                    : const Color(0xFF33403A))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(children: [
                Text('Komentar',
                    style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TkColors.inkSoft)),
                const SizedBox(width: 6),
                Text('(opsional)',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: const Color(0xFFA6AEA9))),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _komentar,
                maxLines: 4,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: Validators.teksBebas,
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: TkColors.inkSoft, height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalaman Anda — apa yang paling '
                      'memuaskan atau bisa ditingkatkan…',
                  hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: TkColors.textPlaceholder,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
        GlassContainer(
          radius: 0,
          opacity: 0.94,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 22 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x0F0F281C))),
            ),
            child: TkButton(
              label: 'Kirim Ulasan',
              loading: _mengirim,
              onPressed: () => _kirim(order),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sukses() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TkColors.primary.withValues(alpha: 0.10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TkColors.primary,
                  boxShadow: [
                    BoxShadow(
                        color: TkColors.primary.withValues(alpha: 0.35),
                        blurRadius: 26,
                        offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    size: 42, color: TkColors.surface),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Terima Kasih!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'Ulasan Anda membantu kami menjaga kualitas layanan '
            'Tuntaskilat. Masukan Anda sudah kami terima.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Icon(Icons.star_rounded,
                      size: 22,
                      color: i < _rating
                          ? TkColors.accent
                          : const Color(0xFFE3E8E4)),
                ),
            ],
          ),
          const SizedBox(height: 26),
          TkButton(
            label: 'Kembali ke Riwayat',
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}
