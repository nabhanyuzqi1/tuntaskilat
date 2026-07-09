import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../providers/app_providers.dart';
import '../widgets/admin_ui.dart';

/// Preferensi notifikasi admin (lokal, per perangkat).
final prefNotifAdminProvider =
    FutureProvider<Map<String, bool>>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    for (final k in _A6.kunciNotif) k: prefs.getBool('a6_$k') ?? true,
  };
});

/// Pengaturan Rekening & QRIS
final pengaturanRekeningProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (!ref.watch(firebaseSiapProvider)) return Stream.value({});
  return ref
      .watch(firestoreServiceProvider)
      .watchSettings('payments');
});

class _A6 {
  static const kunciNotif = [
    'pesanan_baru',
    'pembayaran_menunggu',
    'ringkasan_mingguan',
  ];
}

/// A6 — Pengaturan. Sesuai keputusan scope: Profil Akun + Keamanan +
/// Preferensi Notifikasi diimplementasikan; section Biaya & Komisi dan
/// Manajemen Tim Admin DITUNDA (butuh koleksi di luar 7 koleksi TA yang
/// disahkan) — ditandai "Segera Hadir".
class A6PengaturanScreen extends ConsumerWidget {
  const A6PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilAdminProvider).valueOrNull;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Pengaturan',
        subjudul: 'Profil admin, keamanan, dan preferensi panel',
      ),
      Expanded(
        child: LayoutBuilder(builder: (context, c) {
          final pad = c.maxWidth < 520 ? 16.0 : 32.0;
          // Lebar konten dibatasi & bounded eksplisit (SizedBox), bukan
          // ConstrainedBox — mencegah Column(stretch) menerima lebar
          // tak-terbatas yang merusak layout profil.
          final lebar = (c.maxWidth - pad * 2).clamp(0.0, 720.0);
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
            children: [
              SizedBox(
                width: lebar,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _judul('PROFIL AKUN'),
                    _kartuProfil(context, ref, profil),
                    const SizedBox(height: 22),
                    _judul('KEAMANAN'),
                    _kartuKeamanan(context, ref),
                    const SizedBox(height: 22),
                    _judul('PREFERENSI NOTIFIKASI'),
                    _kartuNotifikasi(ref),
                    const SizedBox(height: 22),
                    _judul('REKENING & QRIS'),
                    _kartuRekening(context, ref),
                    const SizedBox(height: 22),
                    _judul('BIAYA & KOMISI'),
                    _kartuDitunda(
                      'Biaya Platform, Komisi Kru, dan Biaya Pembatalan '
                      'membutuhkan skema di luar 7 koleksi Firestore yang '
                      'disahkan TA — ditunda sesuai keputusan scope.',
                    ),
                    const SizedBox(height: 22),
                    _judul('MANAJEMEN TIM ADMIN'),
                    _kartuDitunda(
                      'Peran admin granular (Operasional/Keuangan/Super '
                      'Admin) membutuhkan perluasan field role — ditunda '
                      'sesuai keputusan scope.',
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    ]);
  }

  Widget _judul(String teks) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TkColors.textMuted,
                letterSpacing: 0.3)),
      );

  Widget _kartuProfil(
      BuildContext context, WidgetRef ref, UserModel? profil) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminUi.kartu(),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: TkColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            profil == null || profil.nama.isEmpty
                ? 'AD'
                : profil.nama
                    .trim()
                    .split(RegExp(r'\s+'))
                    .take(2)
                    .map((k) => k[0].toUpperCase())
                    .join(),
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TkColors.onAccent),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(profil?.nama ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              const SizedBox(height: 2),
              Text(profil?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: profil == null
                ? null
                : () => _dialogUbahNama(context, ref, profil),
            child: Text('Ubah Nama',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF33403A))),
          ),
        ),
      ]),
    );
  }

  Future<void> _dialogUbahNama(
      BuildContext context, WidgetRef ref, UserModel profil) async {
    final controller = TextEditingController(text: profil.nama);
    final baru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ubah Nama Admin',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: SizedBox(
          width: 380,
          child: TkTextField(label: 'Nama Lengkap', controller: controller),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            style:
                ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (baru == null || baru.isEmpty || Validators.namaLengkap(baru) != null) {
      return;
    }
    await ref
        .read(firestoreServiceProvider)
        .updateUserProfile(profil.copyWith(nama: baru));
    ref.invalidate(profilAdminProvider);
  }

  Widget _kartuKeamanan(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(
          onTap: () => _dialogUbahSandi(context, ref),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: TkColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 19, color: TkColors.primary),
          ),
          title: Text('Ubah Kata Sandi',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TkColors.inkSoft)),
          trailing: const Icon(Icons.chevron_right_rounded,
              size: 20, color: Color(0xFFC4CBC6)),
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider()),
        ListTile(
          enabled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2EF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.phonelink_lock_outlined,
                size: 19, color: TkColors.textMuted),
          ),
          title: Text('Autentikasi Dua Faktor',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: TkColors.textMuted)),
          trailing: _badgeSegera(),
        ),
      ]),
    );
  }

  Future<void> _dialogUbahSandi(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final lama = TextEditingController();
    final baru = TextEditingController();
    final konfirmasi = TextEditingController();
    var memproses = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Ubah Kata Sandi',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TkTextField(
                    label: 'Kata Sandi Lama',
                    controller: lama,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Kata sandi lama wajib diisi.'
                        : null),
                const SizedBox(height: 14),
                TkTextField(
                    label: 'Kata Sandi Baru',
                    controller: baru,
                    hint: 'Minimal 8 karakter',
                    obscureText: true,
                    validator: Validators.kataSandi),
                const SizedBox(height: 14),
                TkTextField(
                    label: 'Konfirmasi Kata Sandi Baru',
                    controller: konfirmasi,
                    obscureText: true,
                    validator: (v) =>
                        Validators.konfirmasiKataSandi(v, baru.text)),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed:
                    memproses ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: memproses
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => memproses = true);
                      try {
                        await ref
                            .read(authServiceProvider)
                            .updatePassword(
                                passwordLama: lama.text,
                                passwordBaru: baru.text);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Kata sandi berhasil diperbarui.')));
                        }
                      } on FirebaseAuthException catch (e) {
                        setState(() => memproses = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(switch (e.code) {
                            'invalid-credential' ||
                            'wrong-password' =>
                              'Kata sandi lama tidak sesuai.',
                            _ => 'Perubahan belum tersimpan. Coba lagi.',
                          })));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48)),
              child: memproses
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: TkColors.surface))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuNotifikasi(WidgetRef ref) {
    const label = {
      'pesanan_baru': 'Pesanan baru masuk',
      'pembayaran_menunggu': 'Pembayaran menunggu verifikasi',
      'ringkasan_mingguan': 'Ringkasan performa mingguan',
    };
    return Consumer(builder: (context, ref, _) {
      final prefs = ref.watch(prefNotifAdminProvider).valueOrNull ??
          {for (final k in _A6.kunciNotif) k: true};
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: AdminUi.kartu(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < _A6.kunciNotif.length; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider()),
            SwitchListTile(
              value: prefs[_A6.kunciNotif[i]] ?? true,
              activeTrackColor: TkColors.primary,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              title: Text(label[_A6.kunciNotif[i]]!,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: TkColors.inkSoft)),
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setBool('a6_${_A6.kunciNotif[i]}', v);
                ref.invalidate(prefNotifAdminProvider);
              },
            ),
          ],
        ]),
      );
    });
  }

  Widget _kartuDitunda(String penjelasan) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFA),
          borderRadius: BorderRadius.circular(TkRadius.card),
          border: Border.all(color: const Color(0x140F281C)),
        ),
        child: Row(children: [
          const Icon(Icons.lock_clock_outlined,
              size: 20, color: TkColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(penjelasan,
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: TkColors.textMuted, height: 1.5)),
          ),
          const SizedBox(width: 12),
          _badgeSegera(),
        ]),
      );

  Widget _badgeSegera() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: TkColors.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('Segera Hadir',
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8A6A00))),
      );

  Widget _kartuRekening(BuildContext context, WidgetRef ref) {
    return Consumer(builder: (context, ref, _) {
      final snap = ref.watch(pengaturanRekeningProvider);
      final data = snap.valueOrNull ?? {};
      final String namaBank = data['namaBank'] ?? 'Belum diatur';
      final String noRekening = data['noRekening'] ?? '-';
      final String atasNama = data['atasNama'] ?? '-';
      final String qrisUrl = data['qrisUrl'] ?? '';
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AdminUi.kartu(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Info Rekening Bank & QRIS',
                          style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: TkColors.inkSoft)),
                      const SizedBox(height: 4),
                      Text('Ditampilkan kepada pelanggan saat checkout non-tunai.',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: TkColors.textMuted)),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: snap.isLoading ? null : () => _dialogUbahRekening(context, ref, data),
                  child: Text('Edit',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TkColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoItem('Bank', namaBank),
                ),
                Expanded(
                  child: _infoItem('No. Rekening', noRekening),
                ),
                Expanded(
                  child: _infoItem('Atas Nama', atasNama),
                ),
                Expanded(
                  child: _infoItem('QRIS', qrisUrl.isNotEmpty ? 'Tersedia' : 'Belum diatur'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: TkColors.textMuted)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TkColors.inkSoft)),
      ],
    );
  }

  Future<void> _dialogUbahRekening(
      BuildContext context, WidgetRef ref, Map<String, dynamic> data) async {
    final tBank = TextEditingController(text: data['namaBank'] ?? '');
    final tRek = TextEditingController(text: data['noRekening'] ?? '');
    final tNama = TextEditingController(text: data['atasNama'] ?? '');
    
    Uint8List? fileBaru;
    String? namaFileBaru;
    bool memproses = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Rekening & QRIS',
              style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TkTextField(label: 'Nama Bank (contoh: BCA)', controller: tBank),
                  const SizedBox(height: 16),
                  TkTextField(label: 'Nomor Rekening', controller: tRek, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  TkTextField(label: 'Atas Nama', controller: tNama),
                  const SizedBox(height: 20),
                  Text('QRIS',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final p = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1000,
                        imageQuality: 85,
                      );
                      if (p != null) {
                        final b = await p.readAsBytes();
                        if (b.lengthInBytes >= 5 * 1024 * 1024) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Maksimal 5MB.')));
                          }
                          return;
                        }
                        setState(() {
                          fileBaru = b;
                          namaFileBaru = p.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: TkColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TkColors.primary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, color: TkColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              namaFileBaru ?? (data['qrisUrl'] != null && data['qrisUrl'].toString().isNotEmpty ? 'QRIS sudah diunggah. Ketuk untuk ubah.' : 'Pilih File QRIS (opsional)'),
                              style: GoogleFonts.montserrat(fontSize: 13, color: TkColors.primaryDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (memproses)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: memproses ? null : () => Navigator.of(ctx).pop(false),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: memproses
                  ? null
                  : () async {
                      setState(() => memproses = true);
                      try {
                        String? urlBaru = data['qrisUrl'];
                        if (fileBaru != null) {
                          final st = FirebaseStorage.instance
                              .ref()
                              .child('admin/qris_${DateTime.now().millisecondsSinceEpoch}.jpg');
                          await st.putData(
                            fileBaru!,
                            SettableMetadata(contentType: 'image/jpeg'),
                          );
                          urlBaru = await st.getDownloadURL();
                        }
                        
                        await ref.read(firestoreServiceProvider).updateSettings('payments', {
                          'namaBank': tBank.text.trim(),
                          'noRekening': tRek.text.trim(),
                          'atasNama': tNama.text.trim(),
                          'qrisUrl': urlBaru ?? '',
                        });
                        
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setState(() => memproses = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Gagal menyimpan pengaturan.')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // already saved in dialog
    }
  }
}
