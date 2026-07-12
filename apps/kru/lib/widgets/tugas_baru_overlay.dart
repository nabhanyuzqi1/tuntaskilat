import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';

/// Overlay layar-penuh "Tugas Baru" gaya Gojek/Grab/Maxim: muncul saat ada
/// penugasan yang belum diterima kru, dering via notifikasi channel v2,
/// countdown 30 menit, dan HANYA tombol Terima (kebijakan: tidak bisa
/// ditolak — pembatalan penugasan wewenang admin).
class TugasBaruOverlay extends ConsumerStatefulWidget {
  const TugasBaruOverlay({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<TugasBaruOverlay> createState() => _TugasBaruOverlayState();
}

class _TugasBaruOverlayState extends ConsumerState<TugasBaruOverlay> {
  static const _batas = Duration(minutes: 30);
  Timer? _ticker;
  Duration _sisa = _batas;
  var _memproses = false;

  @override
  void initState() {
    super.initState();
    _hitungSisa();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _hitungSisa());
    // Dering lokal sekali saat overlay tampil (channel v2 bersuara custom) —
    // pelengkap push FCM yang mungkin sudah berbunyi saat app di background.
    NotificationService().showLocalNotification(
      'Tugas baru menunggu konfirmasi',
      '${widget.order.namaLayanan} — konfirmasi dalam 30 menit.',
    );
  }

  void _hitungSisa() {
    final mulai = widget.order.waktuPenugasan ?? DateTime.now();
    final habis = mulai.add(_batas);
    final sisa = habis.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _sisa = sisa.isNegative ? Duration.zero : sisa);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _terima() async {
    if (_memproses) return;
    setState(() => _memproses = true);
    try {
      final uid = ref.read(authServiceProvider).currentUser?.uid;
      if (uid == null) return;
      await ref.read(firestoreServiceProvider).terimaTugas(widget.order, uid);
      // Overlay menutup sendiri: stream orders memancarkan penugasan yang
      // sudah diterima → tugasBaruProvider menjadi null.
    } catch (_) {
      if (mounted) {
        setState(() => _memproses = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Gagal mengonfirmasi. Periksa koneksi lalu coba lagi.')));
      }
    }
  }

  String get _mmss {
    final m = _sisa.inMinutes.toString().padLeft(2, '0');
    final s = (_sisa.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final telat = _sisa == Duration.zero;
    return Material(
      color: TkColors.primaryDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              // Badge countdown — merah saat waktu habis (tetap bisa terima;
              // keterlambatan tercatat untuk evaluasi admin).
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: telat
                      ? TkColors.error
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    telat ? 'Waktu konfirmasi habis' : 'Konfirmasi $_mmss',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        // ignore: deprecated_member_use
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ]),
              ),
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text('Tugas Baru untuk Anda',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${o.namaLayanan} · ${o.kuantitas} ${o.satuan}',
                        style: GoogleFonts.montserrat(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: TkColors.inkSoft)),
                    const SizedBox(height: 10),
                    _baris(Icons.event_rounded, _tanggalJam(o.jadwal)),
                    const SizedBox(height: 6),
                    _baris(Icons.location_on_outlined, o.alamatLayanan),
                    if (o.catatan.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _baris(Icons.sticky_note_2_outlined, o.catatan),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Tugas tidak dapat ditolak. Ada kendala? Hubungi kantor.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _memproses ? null : _terima,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: TkColors.primaryDark,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: _memproses
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: TkColors.primaryDark))
                      : Text('Terima Tugas',
                          style: GoogleFonts.montserrat(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _namaBulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _tanggalJam(DateTime d) =>
      '${d.day} ${_namaBulan[d.month - 1]} ${d.year} · '
      '${d.hour.toString().padLeft(2, '0')}.'
      '${d.minute.toString().padLeft(2, '0')} WIB';

  Widget _baris(IconData ikon, String teks) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 17, color: TkColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(teks,
                style: GoogleFonts.montserrat(
                    fontSize: 13.5, color: TkColors.textSecondary)),
          ),
        ],
      );
}
