import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../providers/pemesanan_providers.dart';
import 'p3_beranda_screen.dart';
import 'p5_form_pemesanan_screen.dart';
import 'p8_tracking_screen.dart';

/// P7 — Form Pembayaran (Gambar TA 3.16). Pilih metode (transfer/QRIS/tunai),
/// unggah bukti bayar (wajib non-tunai), lalu state "Menunggu Verifikasi"
/// badge kuning + jam (kaidah Umpan Balik Segera).
class P7FormPembayaranScreen extends ConsumerStatefulWidget {
  const P7FormPembayaranScreen({super.key});

  static const route = '/p7';

  @override
  ConsumerState<P7FormPembayaranScreen> createState() =>
      _P7FormPembayaranScreenState();
}

class _P7FormPembayaranScreenState
    extends ConsumerState<P7FormPembayaranScreen> {
  static const _latarLembut = Color(0xFFF6F8F5);

  MetodeBayar _metode = MetodeBayar.transferBank;
  Uint8List? _bukti;
  String? _namaBukti;
  var _terkirim = false;
  var _submitting = false; // guard sinkron anti double-tap Konfirmasi
  OrderModel? _order; // terisi setelah pesanan berhasil dibuat

  Future<void> _pilihBukti() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes >= 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ukuran berkas maksimal 5MB. Pilih foto lain.')));
      }
      return;
    }
    setState(() {
      _bukti = bytes;
      _namaBukti = file.name;
    });
  }

  Future<void> _konfirmasi(DraftPesanan draft) async {
    // Guard sinkron: controller baru set state loading SETELAH await profil,
    // jadi tanpa flag ini ada celah singkat untuk tap ganda → dua percobaan
    // order. Tutup celah itu di sini.
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _prosesKonfirmasi(draft);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _prosesKonfirmasi(DraftPesanan draft) async {
    final hasil =
        await ref.read(pembayaranControllerProvider.notifier).konfirmasi(
              draft: draft,
              metode: _metode,
              buktiBytes: _metode == MetodeBayar.tunai ? null : _bukti,
            );
    if (!mounted) return;

    if (hasil.jadwalPenuh) {
      // Slot keburu terisi saat konfirmasi (skenario #1). Kembali ke P5
      // agar pelanggan memilih slot lain — draft dipertahankan.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TkRadius.sheet)),
          title: Text('Jadwal Penuh',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: TkColors.inkSoft)),
          content: Text(
            'Slot waktu ini baru saja terisi pelanggan lain. Silakan pilih '
            'slot lain yang masih tersedia.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: Navigator.of(ctx).pop,
                child: const Text('Pilih Slot Lain')),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context)
            .popUntil(ModalRoute.withName(P5FormPemesananScreen.route));
      }
      return;
    }
    if (hasil.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(hasil.error!)));
      return;
    }
    // Sukses — bersihkan draft dan tampilkan state konfirmasi.
    ref.read(draftPesananProvider.notifier).state = null;
    setState(() {
      _terkirim = true;
      _order = hasil.order;
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(draftPesananProvider);
    final loading = ref.watch(pembayaranControllerProvider).isLoading;

    // Setelah sukses draft di-null-kan; pakai _order untuk layar konfirmasi.
    if (_terkirim && _order != null) {
      return Scaffold(
        backgroundColor: _latarLembut,
        body: Column(children: [
          _header(context),
          Expanded(child: _MenungguVerifikasi(order: _order!)),
        ]),
      );
    }
    if (draft == null || !draft.lengkap) {
      // Draft hilang (mis. layar lama di stack setelah bayar) —
      // langsung pulang ke Beranda, jangan tampilkan layar mati.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((r) =>
            r.isFirst || r.settings.name == P3BerandaScreen.route);
      });
      return const Scaffold(
        backgroundColor: _latarLembut,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: _latarLembut,
      // SafeArea di dalam header → warna header sinkron sampai status bar.
      body: Column(
        children: [
          _header(context),
          Expanded(child: _form(draft, loading, ref)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: TkColors.surface,
          border: Border(bottom: BorderSide(color: Color(0x0D0F281C))),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Row(children: [
          if (!_terkirim)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: Navigator.of(context).pop,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: TkColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: TkColors.inkSoft),
              ),
            ),
          Text('Pembayaran',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
        ]),
          ),
        ),
      );

  Widget _form(DraftPesanan draft, bool loading, WidgetRef ref) {
    final pengaturan = ref.watch(pengaturanRekeningProvider).valueOrNull ?? {};
    // Metode yang tampil & tipe (statis/dinamis) diatur admin.
    final konfig = ref.watch(konfigPembayaranProvider).valueOrNull ??
        KonfigPembayaran.bawaan;
    var metodeAktif = konfig.aktif.toList();

    // Sembunyikan opsi Tunai jika pengguna menggunakan Peta/Ketik Alamat.
    if (draft.isRemoteLokasi) {
      metodeAktif.removeWhere((m) => m.kode == 'tunai');
    }

    // Jika metode terpilih dinonaktifkan admin (atau karena remote), jatuh ke metode aktif pertama.
    if (metodeAktif.isNotEmpty &&
        !metodeAktif.any((m) => m.kode == _metode.wire)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _metode = MetodeBayar.fromWire(metodeAktif.first.kode));
        }
      });
    }
    final konfigTerpilih = konfig.byKode(_metode.wire);
    final dinamis = konfigTerpilih?.dinamis ?? false;
    // Tunai & metode dinamis (Xendit) tak perlu unggah bukti manual.
    final butuhBukti = _metode != MetodeBayar.tunai && !dinamis;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _kartuTotal(draft.total),
              if (_metode == MetodeBayar.tunai) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: TkColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 17, color: TkColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Pembayaran tunai dilakukan langsung ke kru saat '
                          'pengerjaan selesai. Pesanan langsung diteruskan '
                          'ke admin untuk penugasan.',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF33403A),
                              height: 1.45)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              Text('Metode Pembayaran',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
              const SizedBox(height: 12),
              for (final m in metodeAktif) ...[
                _kartuMetode(
                  MetodeBayar.fromWire(m.kode),
                  _ikonMetode(m.kode),
                  _warnaMetode(m.kode),
                  m.nama,
                  m.dinamis
                      ? '${m.deskripsi} · otomatis (Xendit)'
                      : m.deskripsi,
                ),
                const SizedBox(height: 12),
              ],
              if (dinamis) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: TkColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded,
                        size: 17, color: TkColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          'Nomor Virtual Account / QRIS unik dibuat otomatis '
                          'setelah konfirmasi. Pembayaran terverifikasi '
                          'sendiri — tanpa unggah bukti.',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: const Color(0xFF33403A),
                              height: 1.45)),
                    ),
                  ]),
                ),
              ],
              if (butuhBukti) ...[
                const SizedBox(height: 20),
                _infoRekening(pengaturan),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Row(children: [
                  Text('Upload Bukti Transfer',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  Text(' *',
                      style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: TkColors.error)),
                ]),
                const SizedBox(height: 10),
                _areaUpload(),
              ],
            ],
          ),
        ),
        GlassContainer(
          radius: 0,
          opacity: 0.94,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 16 + MediaQuery.viewPaddingOf(context).bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x0F0F281C))),
            ),
            child: TkButton(
              label: _metode == MetodeBayar.tunai
                  ? 'Konfirmasi Pesanan'
                  : 'Konfirmasi Pembayaran',
              loading: loading || _submitting,
              onPressed: () => _konfirmasi(draft),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kartuTotal(num total) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TkRadius.card),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TkColors.primaryDark, TkColors.primary],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total yang harus dibayar',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 3),
                  Text(PriceBadge.formatRupiah(total),
                      style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: TkColors.surface,
                          letterSpacing: -0.5)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.credit_card_outlined,
                  size: 22, color: TkColors.surface),
            ),
          ],
        ),
      );

  IconData _ikonMetode(String kode) => switch (kode) {
        'transfer_bank' => Icons.account_balance_outlined,
        'qris' => Icons.qr_code_2_rounded,
        'tunai' => Icons.payments_outlined,
        _ => Icons.payment_rounded,
      };

  Color _warnaMetode(String kode) =>
      kode == 'qris' ? TkColors.accentAlt : TkColors.primary;

  Widget _kartuMetode(
    MetodeBayar metode,
    IconData ikon,
    Color warnaIkon,
    String judul,
    String sub,
  ) {
    final aktif = _metode == metode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _metode = metode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: TkColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: aktif ? TkColors.primary : TkColors.border,
            width: 1.5,
          ),
          boxShadow: aktif
              ? [
                  BoxShadow(
                      color: TkColors.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: warnaIkon.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(ikon, size: 22, color: warnaIkon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: aktif ? TkColors.primary : TkColors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: aktif
                  ? Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _areaUpload() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pilihBukti,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
        decoration: BoxDecoration(
          color: TkColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(
            color: _bukti != null
                ? TkColors.primary
                : const Color(0xFFB7C9BF),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (_bukti != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _bukti!,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(_namaBukti ?? 'bukti_transfer.jpg',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primaryDark)),
              const SizedBox(height: 3),
              Text('Ketuk untuk mengganti foto',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ] else ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TkColors.primary.withValues(alpha: 0.10),
                ),
                child: const Icon(Icons.photo_camera_outlined,
                    size: 26, color: TkColors.primary),
              ),
              const SizedBox(height: 10),
              Text('Ketuk untuk unggah foto',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.primary)),
              const SizedBox(height: 3),
              Text('JPG/PNG maks 5MB',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRekening(Map<String, dynamic> pengaturan) {
    if (_metode == MetodeBayar.transferBank) {
      final namaBank = pengaturan['namaBank'] ?? 'BCA';
      final noRek = pengaturan['noRekening'] ?? '1234567890';
      final atasNama = pengaturan['atasNama'] ?? 'PT Tuntas Kilat';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TkColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TkColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Transfer ke Rekening Berikut:',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x140F281C)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance, color: TkColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(namaBank,
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TkColors.inkSoft)),
                      const SizedBox(height: 2),
                      Text('$noRek a.n $atasNama',
                          style: GoogleFonts.montserrat(
                              fontSize: 13, color: TkColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_metode == MetodeBayar.qris) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TkColors.accentAlt.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TkColors.accentAlt.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('Scan QRIS di bawah ini:',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
            const SizedBox(height: 16),
            // QR besar (lebar penuh) + ketuk untuk fullscreen — QR 180px
            // terlalu kecil untuk discan dari layar lain.
            Builder(builder: (context) {
              final qrisUrl = pengaturan['qrisUrl']?.toString() ?? '';
              // QRIS adalah artefak pembayaran per-merchant — tanpa qrisUrl
              // dari admin (A6 Rekening & QRIS) tidak ada QR yang sah untuk
              // ditampilkan. Placeholder aset lokal dilarang: file dummy
              // pernah ter-render sebagai kotak hitam yang menyesatkan.
              if (qrisUrl.isEmpty) {
                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x140F281C)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.qr_code_2,
                        size: 64, color: TkColors.textMuted),
                    const SizedBox(height: 10),
                    Text('QRIS belum tersedia',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TkColors.inkSoft)),
                    const SizedBox(height: 4),
                    Text(
                        'Silakan pilih Transfer Bank atau Tunai '
                        'untuk saat ini.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: TkColors.textMuted)),
                  ]),
                );
              }
              final qr = Image.network(qrisUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.qr_code_2,
                      size: 180, color: TkColors.inkSoft));
              return Column(children: [
                GestureDetector(
                  onTap: () => _bukaQrisPenuh(context, qr),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x140F281C)),
                    ),
                    child: AspectRatio(aspectRatio: 1, child: qr),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _bukaQrisPenuh(context, qr),
                  icon: const Icon(Icons.fullscreen_rounded, size: 20),
                  label: const Text('Perbesar QR'),
                ),
              ]);
            }),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  /// QR fullscreen dengan latar terang maksimal agar mudah discan.
  void _bukaQrisPenuh(BuildContext context, Widget qr) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.white,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded,
                      size: 28, color: TkColors.inkSoft),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20), child: qr),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Text('Scan QRIS Tuntaskilat — ketuk untuk menutup',
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: TkColors.textMuted)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MenungguVerifikasi extends StatelessWidget {
  const _MenungguVerifikasi({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    // Tunai → order langsung menunggu penugasan (tidak ada verifikasi bukti).
    final tunai = order.status == OrderStatus.menungguPenugasan;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (tunai ? TkColors.primary : TkColors.accent)
                    .withValues(alpha: 0.16),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tunai ? TkColors.primary : TkColors.accent,
                ),
                child: Icon(
                    tunai
                        ? Icons.check_rounded
                        : Icons.schedule_rounded,
                    size: 38,
                    color: tunai ? TkColors.surface : TkColors.onAccent),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (tunai ? TkColors.primary : TkColors.accent)
                    .withValues(alpha: tunai ? 0.10 : 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tunai ? TkColors.primary : TkColors.accentAlt,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(tunai ? 'PESANAN DITERIMA' : 'MENUNGGU VERIFIKASI',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tunai
                              ? TkColors.primaryDark
                              : const Color(0xFF8A6A00))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(tunai ? 'Pesanan Dibuat' : 'Pembayaran Terkirim',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            tunai
                ? 'Pesanan Anda diteruskan ke admin untuk penugasan kru. '
                    'Pembayaran tunai dilakukan langsung ke kru saat '
                    'pengerjaan selesai.'
                : 'Pembayaran Anda sedang diverifikasi admin. Kami akan '
                    'mengirim notifikasi begitu pesanan dikonfirmasi — '
                    'estimasi kurang dari 15 menit.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
                fontSize: 14, color: TkColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 22),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: TkColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0F0F281C)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor Pesanan',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: TkColors.textMuted)),
                    const SizedBox(height: 2),
                    Text('#${order.orderId}',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                  ],
                ),
                Text(PriceBadge.formatRupiah(order.totalHarga),
                    style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: TkColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 26),
          TkButton(
            label: 'Lacak Status Pesanan',
            // Bersihkan P4-P7 dari stack (draft sudah null) — back dari P8
            // mendarat di Beranda, bukan P6 fallback "Data tidak lengkap".
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              P8TrackingScreen.route,
              (r) => r.isFirst || r.settings.name == P3BerandaScreen.route,
              arguments: order.orderId,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) =>
                  r.isFirst || r.settings.name == P3BerandaScreen.route),
              child: Text('Kembali ke Beranda',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
