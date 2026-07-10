import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tk_core/tk_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../providers/app_providers.dart';
import '../util/totp.dart';
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
                    const SizedBox(height: 12),
                    const _Kartu2fa(),
                    const SizedBox(height: 22),
                    _judul('PREFERENSI NOTIFIKASI'),
                    _kartuNotifikasi(ref),
                    const SizedBox(height: 22),
                    _judul('REKENING & QRIS'),
                    _kartuRekening(context, ref),
                    const SizedBox(height: 22),
                    _judul('BIAYA & KOMISI'),
                    const _KartuKomisi(),
                    const SizedBox(height: 22),
                    _judul('MODE APLIKASI'),
                    const _KartuMaintenance(),
                    const SizedBox(height: 22),
                    _judul('MANAJEMEN TIM ADMIN'),
                    const _KartuTim(),
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

/// Kartu 2FA (TOTP) admin — opsional. Mengaktifkan mewajibkan verifikasi kode
/// dulu agar admin tak terkunci. Rahasia disimpan di admin2fa/{uid}.
class _Kartu2fa extends ConsumerStatefulWidget {
  const _Kartu2fa();

  @override
  ConsumerState<_Kartu2fa> createState() => _Kartu2faState();
}

class _Kartu2faState extends ConsumerState<_Kartu2fa> {
  bool _memuat = true;
  bool _aktif = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _memuat = false);
      return;
    }
    final cfg = await ref.read(firestoreServiceProvider).get2fa(uid);
    if (mounted) {
      setState(() {
        _aktif = cfg?.aktif ?? false;
        _memuat = false;
      });
    }
  }

  Future<void> _aktifkan() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    final email = ref.read(profilAdminProvider).valueOrNull?.email ?? 'admin';
    if (uid == null) return;
    final secret = Totp.secretBaru();
    final kode = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan 2FA'),
        content: SizedBox(
          width: 340,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Scan QR ini di Google Authenticator, lalu masukkan '
                '6 digit untuk mengonfirmasi.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: QrImageView(
                data: Totp.provisioningUri(secret, email),
                size: 170,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(secret,
                style: GoogleFonts.robotoMono(
                    fontSize: 12, color: TkColors.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: kode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  counterText: '', hintText: '6 digit'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, Totp.verifikasi(secret, kode.text)),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    kode.dispose();
    if (ok != true) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kode salah — 2FA belum diaktifkan.')));
      }
      return;
    }
    await ref.read(firestoreServiceProvider).set2fa(uid, secret, true);
    if (mounted) setState(() => _aktif = true);
  }

  Future<void> _nonaktifkan() async {
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).set2fa(uid, '', false);
    if (mounted) setState(() => _aktif = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AdminUi.kartu(),
      child: Row(children: [
        Icon(_aktif ? Icons.verified_user : Icons.security_outlined,
            color: _aktif ? TkColors.primary : TkColors.textMuted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Autentikasi Dua Faktor (2FA)',
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TkColors.inkSoft)),
              Text(
                  _aktif
                      ? 'Aktif — kode authenticator diminta saat login.'
                      : 'Tambah lapisan keamanan dengan Google Authenticator.',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ],
          ),
        ),
        if (_memuat)
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
        else if (_aktif)
          OutlinedButton(
              onPressed: _nonaktifkan,
              style: OutlinedButton.styleFrom(foregroundColor: TkColors.error),
              child: const Text('Nonaktifkan'))
        else
          ElevatedButton(onPressed: _aktifkan, child: const Text('Aktifkan')),
      ]),
    );
  }
}

/// Kartu Biaya & Komisi (A#6). Komisi platform global (%) + override per
/// layanan. Disimpan di settings/komisi; dibaca backend saat menghitung upah.
class _KartuKomisi extends ConsumerStatefulWidget {
  const _KartuKomisi();

  @override
  ConsumerState<_KartuKomisi> createState() => _KartuKomisiState();
}

class _KartuKomisiState extends ConsumerState<_KartuKomisi> {
  final _global = TextEditingController();
  final _perLayanan = <String, TextEditingController>{};
  bool _seeded = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _global.dispose();
    for (final c in _perLayanan.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(KonfigKomisi k, List<ServiceModel> layanan) {
    if (_seeded) return;
    _global.text = _fmt(k.komisiPersen);
    for (final s in layanan) {
      _perLayanan[s.serviceId] = TextEditingController(
        text: k.perLayanan.containsKey(s.serviceId)
            ? _fmt(k.perLayanan[s.serviceId]!)
            : '',
      );
    }
    _seeded = true;
  }

  String _fmt(num v) => v == v.roundToDouble() ? v.round().toString() : '$v';

  Future<void> _simpan() async {
    final messenger = ScaffoldMessenger.of(context);
    final global = num.tryParse(_global.text.trim());
    if (global == null || global < 0 || global > 100) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Komisi global harus angka 0–100.')));
      return;
    }
    final per = <String, num>{};
    for (final e in _perLayanan.entries) {
      final t = e.value.text.trim();
      if (t.isEmpty) continue;
      final v = num.tryParse(t);
      if (v == null || v < 0 || v > 100) {
        messenger.showSnackBar(SnackBar(
            content: Text('Override komisi harus angka 0–100 (cek layanan).')));
        return;
      }
      per[e.key] = v;
    }
    setState(() => _menyimpan = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .simpanKomisi(KonfigKomisi(komisiPersen: global, perLayanan: per));
      messenger.showSnackBar(
          const SnackBar(content: Text('Komisi tersimpan.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan komisi.')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final komisi = ref.watch(komisiProvider).valueOrNull;
    final layanan = ref.watch(semuaLayananProvider).valueOrNull;
    if (komisi == null || layanan == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AdminUi.kartu(),
        child: const Center(
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    _seed(komisi, layanan);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Komisi Platform',
            style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TkColors.inkSoft)),
        const SizedBox(height: 4),
        Text('Persentase potongan dari total order untuk platform. Sisanya '
            'dibagi ke kru sesuai peran. Backend menghitung ulang saat order '
            'selesai.',
            style: GoogleFonts.montserrat(
                fontSize: 12, color: TkColors.textMuted, height: 1.5)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Text('Komisi Global',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ),
          SizedBox(
            width: 110,
            child: _fieldPersen(_global),
          ),
        ]),
        if (layanan.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 6),
          Text('Override per Layanan (kosongkan = pakai global)',
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TkColors.textMuted)),
          const SizedBox(height: 8),
          for (final s in layanan)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(
                  child: Text(s.namaLayanan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: TkColors.inkSoft)),
                ),
                SizedBox(
                  width: 110,
                  child: _fieldPersen(_perLayanan[s.serviceId]!, hint: 'global'),
                ),
              ]),
            ),
        ],
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _menyimpan ? null : _simpan,
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 46)),
            child: _menyimpan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: TkColors.surface))
                : const Text('Simpan Komisi'),
          ),
        ),
      ]),
    );
  }

  Widget _fieldPersen(TextEditingController c, {String? hint}) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          suffixText: '%',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

/// Kartu Mode Aplikasi (F6 Maintenance). Admin dapat mengaktifkan mode
/// pemeliharaan atau update paksa — semua app cek settings/app saat boot.
class _KartuMaintenance extends ConsumerStatefulWidget {
  const _KartuMaintenance();

  @override
  ConsumerState<_KartuMaintenance> createState() => _KartuMaintenanceState();
}

class _KartuMaintenanceState extends ConsumerState<_KartuMaintenance> {
  final _pesan = TextEditingController();
  final _versiMin = TextEditingController();
  AppMode? _mode;
  bool _seeded = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _pesan.dispose();
    _versiMin.dispose();
    super.dispose();
  }

  void _seed(KonfigApp k) {
    if (_seeded) return;
    _mode = k.mode;
    _pesan.text = k.pesan;
    _versiMin.text = k.versiMin;
    _seeded = true;
  }

  Future<void> _simpan() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _menyimpan = true);
    try {
      await ref.read(firestoreServiceProvider).updateSettings(
            'app',
            KonfigApp(
              mode: _mode ?? AppMode.normal,
              pesan: _pesan.text.trim(),
              versiMin: _versiMin.text.trim(),
            ).toMap(),
          );
      messenger.showSnackBar(
          const SnackBar(content: Text('Mode aplikasi diperbarui.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan mode aplikasi.')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final konfig = ref.watch(konfigAppProvider).valueOrNull;
    if (konfig == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AdminUi.kartu(),
        child: const Center(
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    _seed(konfig);
    final mode = _mode ?? AppMode.normal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (mode != AppMode.normal)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TkColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: TkColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    mode == AppMode.maintenance
                        ? 'Aplikasi SEDANG DALAM MAINTENANCE untuk semua '
                            'pengguna.'
                        : 'UPDATE PAKSA aktif untuk versi di bawah '
                            '${_versiMin.text.trim().isEmpty ? '-' : _versiMin.text.trim()}.',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TkColors.error)),
              ),
            ]),
          ),
        Text('Mode',
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TkColors.inkSoft)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in AppMode.values)
              ChoiceChip(
                label: Text(switch (m) {
                  AppMode.normal => 'Normal',
                  AppMode.maintenance => 'Maintenance',
                  AppMode.updateWajib => 'Update Wajib',
                }),
                selected: mode == m,
                onSelected: (_) => setState(() => _mode = m),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pesan,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Pesan (opsional)',
            hintText: 'Pesan yang ditampilkan ke pengguna',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _versiMin,
          decoration: InputDecoration(
            labelText: 'Versi Minimum (untuk Update Wajib, mis. 1.1.0)',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _menyimpan ? null : _simpan,
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 46)),
            child: _menyimpan
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: TkColors.surface))
                : const Text('Simpan Mode'),
          ),
        ),
      ]),
    );
  }
}

/// Kartu Manajemen Tim Admin (A#2). Daftar akun admin + undang admin baru +
/// aktif/nonaktifkan. Operasi sensitif dijalankan lewat Cloud Function
/// (buatAdmin/setNonaktifAdmin) yang memverifikasi peran admin di server.
class _KartuTim extends ConsumerWidget {
  const _KartuTim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(daftarAdminProvider);
    final uidSaya = ref.watch(authServiceProvider).currentUser?.uid;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: AdminUi.kartu(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Akun Admin',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                  const SizedBox(height: 4),
                  Text('Undang admin baru atau nonaktifkan akses.',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: TkColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _dialogUndang(context, ref),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: Text('Undang',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1)),
        async.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)))),
          error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Gagal memuat daftar admin: $e',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: TkColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Belum ada admin.',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: TkColors.textMuted)));
            }
            return Column(children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0)
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1)),
                _barisAdmin(context, ref, list[i], list[i].userId == uidSaya),
              ],
            ]);
          },
        ),
      ]),
    );
  }

  Widget _barisAdmin(
      BuildContext context, WidgetRef ref, UserModel a, bool saya) {
    final inisial = a.nama.trim().isEmpty
        ? 'AD'
        : a.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((k) => k[0].toUpperCase())
            .join();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: a.nonaktif
                ? const Color(0xFFEDEFEC)
                : TkColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(inisial,
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: a.nonaktif ? TkColors.textMuted : TkColors.primary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(a.nama.isEmpty ? '(tanpa nama)' : a.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: TkColors.inkSoft)),
                ),
                if (saya) ...[
                  const SizedBox(width: 8),
                  _chip('Anda', TkColors.primary),
                ],
                if (a.nonaktif) ...[
                  const SizedBox(width: 8),
                  _chip('Nonaktif', TkColors.error),
                ],
              ]),
              const SizedBox(height: 2),
              Text(a.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: TkColors.textMuted)),
            ],
          ),
        ),
        if (!saya) ...[
          const SizedBox(width: 8),
          a.nonaktif
              ? OutlinedButton(
                  onPressed: () => _ubahStatus(context, ref, a, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Aktifkan',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TkColors.primary)))
              : OutlinedButton(
                  onPressed: () => _ubahStatus(context, ref, a, true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: TkColors.error,
                  ),
                  child: Text('Nonaktifkan',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ]),
    );
  }

  Widget _chip(String teks, Color warna) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(teks,
            style: GoogleFonts.montserrat(
                fontSize: 10, fontWeight: FontWeight.w700, color: warna)),
      );

  Future<void> _ubahStatus(
      BuildContext context, WidgetRef ref, UserModel a, bool nonaktif) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(nonaktif ? 'Nonaktifkan Admin?' : 'Aktifkan Admin?',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TkColors.inkSoft)),
        content: Text(
            nonaktif
                ? '${a.nama} tidak akan bisa masuk ke panel admin sampai '
                    'diaktifkan kembali.'
                : '${a.nama} akan bisa masuk kembali ke panel admin.',
            style: GoogleFonts.montserrat(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: nonaktif ? TkColors.error : TkColors.primary),
            child: Text(nonaktif ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(timAdminServiceProvider)
          .setNonaktif(uid: a.userId, nonaktif: nonaktif);
      messenger.showSnackBar(SnackBar(
          content: Text(nonaktif
              ? '${a.nama} dinonaktifkan.'
              : '${a.nama} diaktifkan kembali.')));
    } on FirebaseFunctionsException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(e.message ?? 'Gagal mengubah status admin.')));
    }
  }

  Future<void> _dialogUndang(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController();
    final email = TextEditingController();
    final sandi = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    var memproses = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Undang Admin Baru',
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
                    label: 'Nama Lengkap',
                    controller: nama,
                    validator: Validators.namaLengkap),
                const SizedBox(height: 14),
                TkTextField(
                    label: 'Email',
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email),
                const SizedBox(height: 14),
                TkTextField(
                    label: 'Kata Sandi Awal',
                    controller: sandi,
                    hint: 'Minimal 8 karakter',
                    obscureText: true,
                    validator: Validators.kataSandi),
                const SizedBox(height: 8),
                Text('Admin baru dapat mengganti kata sandi setelah masuk.',
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: TkColors.textMuted)),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: memproses ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: memproses
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => memproses = true);
                      try {
                        await ref.read(timAdminServiceProvider).buatAdmin(
                              email: email.text.trim(),
                              password: sandi.text,
                              nama: nama.text.trim(),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        messenger.showSnackBar(SnackBar(
                            content: Text(
                                'Admin ${nama.text.trim()} berhasil dibuat.')));
                      } on FirebaseFunctionsException catch (e) {
                        setState(() => memproses = false);
                        messenger.showSnackBar(SnackBar(
                            content: Text(switch (e.code) {
                          'already-exists' => 'Email sudah terdaftar.',
                          'permission-denied' =>
                            'Hanya admin yang dapat menambah admin.',
                          _ => e.message ?? 'Gagal membuat admin.',
                        })));
                      }
                    },
              style:
                  ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
              child: memproses
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: TkColors.surface))
                  : const Text('Buat Admin'),
            ),
          ],
        ),
      ),
    );
    nama.dispose();
    email.dispose();
    sandi.dispose();
  }
}
