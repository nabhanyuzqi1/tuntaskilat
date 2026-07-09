import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../services/akun_kru_service.dart';
import '../widgets/admin_ui.dart';

/// A5 — Kelola Kru (Gambar TA 3.18). Tabel akun kru: status ketersediaan,
/// rating, jumlah ulasan; tambah akun kru baru (dibuat admin — K1 tanpa
/// registrasi mandiri); nonaktifkan kru.
class A5KelolaKruScreen extends ConsumerWidget {
  const A5KelolaKruScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kru = ref.watch(semuaKruProvider).valueOrNull ?? const [];
    final online = kru.where((k) => k.statusKetersediaan).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Kelola Kru',
        subjudul: '${kru.length} kru · $online online',
        aksi: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => _dialogTambahKru(context, ref),
            icon: const Icon(Icons.person_add_alt_rounded, size: 18),
            label: const Text('Tambah Kru'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: AdminUi.kartu(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                AdminUi.judulTabel(const [
                  ('KRU', 20),
                  ('TELEPON', 12),
                  ('KETERSEDIAAN', 11),
                  ('RATING', 10),
                  ('AKSI', 12),
                ]),
                if (kru.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                        'Belum ada kru. Tambahkan akun kru pertama.',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: TkColors.textMuted)),
                  )
                else
                  for (final k in kru) _baris(context, ref, k),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _baris(BuildContext context, WidgetRef ref, KruModel k) {
    final inisial = k.nama.isEmpty
        ? 'TK'
        : k.nama
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((x) => x[0].toUpperCase())
            .join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0D0F281C))),
      ),
      child: Row(children: [
        Expanded(
          flex: 20,
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFDCE7E0),
              child: Text(inisial,
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TkColors.primaryDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(k.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TkColors.inkSoft)),
            ),
          ]),
        ),
        Expanded(flex: 12, child: AdminUi.teksSel(k.noTelepon)),
        Expanded(
          flex: 11,
          child: AdminUi.chipStatus(
            k.statusKetersediaan ? 'Online' : 'Offline',
            k.statusKetersediaan ? TkColors.primary : TkColors.textMuted,
          ),
        ),
        Expanded(
          flex: 10,
          child: Row(children: [
            const Icon(Icons.star_rounded,
                size: 15, color: TkColors.accent),
            const SizedBox(width: 4),
            Text(
                '${k.rataRating.toStringAsFixed(1).replaceAll('.', ',')} '
                '(${k.jumlahUlasan.round()})',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TkColors.inkSoft)),
          ]),
        ),
        Expanded(
          flex: 12,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () => ref
                    .read(firestoreServiceProvider)
                    .setKetersediaanKru(
                        k.cleanerId, !k.statusKetersediaan),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  side: BorderSide(
                      color: k.statusKetersediaan
                          ? TkColors.error.withValues(alpha: 0.4)
                          : TkColors.border,
                      width: 1.5),
                ),
                child: Text(
                    k.statusKetersediaan ? 'Nonaktifkan' : 'Aktifkan',
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: k.statusKetersediaan
                            ? TkColors.error
                            : TkColors.primaryDark)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _dialogTambahKru(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nama = TextEditingController();
    final email = TextEditingController();
    final telepon = TextEditingController();
    final sandi = TextEditingController();
    var memproses = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Tambah Akun Kru',
              style: GoogleFonts.montserrat(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: TkColors.inkSoft)),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TkTextField(
                        label: 'Nama Lengkap',
                        controller: nama,
                        hint: 'Nama kru',
                        validator: Validators.namaLengkap),
                    const SizedBox(height: 14),
                    TkTextField(
                        label: 'Email',
                        controller: email,
                        hint: 'kru@tuntaskilat.id',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email),
                    const SizedBox(height: 14),
                    TkTextField(
                        label: 'No. Telepon',
                        controller: telepon,
                        hint: '08xx-xxxx-xxxx',
                        keyboardType: TextInputType.phone,
                        validator: Validators.noTelepon),
                    const SizedBox(height: 14),
                    TkTextField(
                        label: 'Kata Sandi Awal',
                        controller: sandi,
                        hint: 'Minimal 8 karakter — minta kru menggantinya',
                        obscureText: true,
                        validator: Validators.kataSandi),
                  ],
                ),
              ),
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
                        await AkunKruService().buatAkunKru(
                          nama: nama.text.trim(),
                          email: email.text.trim(),
                          noTelepon: telepon.text.trim(),
                          password: sandi.text,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Akun kru ${nama.text.trim()} '
                                      'berhasil dibuat.')));
                        }
                      } on FirebaseAuthException catch (e) {
                        setState(() => memproses = false);
                        final pesan = switch (e.code) {
                          'email-already-in-use' =>
                            'Email sudah terdaftar. Gunakan email lain.',
                          'weak-password' =>
                            'Kata sandi terlalu lemah (min 8 karakter).',
                          _ => 'Akun belum dibuat. Coba lagi.',
                        };
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(pesan)));
                        }
                      } catch (_) {
                        setState(() => memproses = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Akun belum dibuat. Periksa koneksi '
                                      'lalu coba lagi.')));
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
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
