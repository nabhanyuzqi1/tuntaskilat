import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tk_core/tk_core.dart';

import '../providers/app_providers.dart';
import '../services/akun_kru_service.dart';
import '../widgets/admin_ui.dart';

/// Kriteria sortir tabel Kelola Kru.
final _sortKruProvider = StateProvider<String>((_) => 'nama');

/// A5 — Kelola Kru (Gambar TA 3.18). Tabel akun kru: status ketersediaan,
/// rating, jumlah ulasan; tambah akun kru baru (dibuat admin — K1 tanpa
/// registrasi mandiri); nonaktifkan kru.
class A5KelolaKruScreen extends ConsumerWidget {
  const A5KelolaKruScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortir = ref.watch(_sortKruProvider);
    final kru = [...ref.watch(semuaKruProvider).valueOrNull ?? const []];
    kru.sort((a, b) => switch (sortir) {
          'rating' => b.rataRating.compareTo(a.rataRating),
          'online' => (b.statusKetersediaan ? 1 : 0)
              .compareTo(a.statusKetersediaan ? 1 : 0),
          _ => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        });
    final online = kru.where((k) => k.statusKetersediaan).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AdminUi.topbar(
        judul: 'Kelola Kru',
        subjudul: '${kru.length} kru · $online online',
        aksi: Row(mainAxisSize: MainAxisSize.min, children: [
          // Sortir tabel — nama / rating / online dulu.
          DropdownButton<String>(
            value: sortir,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TkColors.inkSoft),
            items: const [
              DropdownMenuItem(value: 'nama', child: Text('Urut: Nama')),
              DropdownMenuItem(
                  value: 'rating', child: Text('Urut: Rating tertinggi')),
              DropdownMenuItem(
                  value: 'online', child: Text('Urut: Online dulu')),
            ],
            onChanged: (v) =>
                ref.read(_sortKruProvider.notifier).state = v ?? 'nama',
          ),
          const SizedBox(width: 14),
          SizedBox(
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
        ]),
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _dialogKelolaKru(context, ref, k),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: k.status.bisaDitugaskan
                    ? const Color(0xFFDCE7E0)
                    : const Color(0xFFEDEFEC),
                // foregroundImage (bukan background) menimpa inisial hanya bila
                // foto berhasil dimuat; bila gagal (mis. CORS bucket di web
                // admin) inisial tetap tampil — bukan lingkaran kosong.
                foregroundImage:
                    k.fotoUrl.isNotEmpty ? NetworkImage(k.fotoUrl) : null,
                onForegroundImageError:
                    k.fotoUrl.isNotEmpty ? (_, _) {} : null,
                child: Text(inisial,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TkColors.primaryDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TkColors.inkSoft)),
                    Text(
                        '${k.tipe.label}'
                        '${k.status.bisaDitugaskan ? '' : ' · ${k.status.label}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: k.status.bisaDitugaskan
                                ? TkColors.textMuted
                                : TkColors.error)),
                  ],
                ),
              ),
            ]),
          ),
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

  /// Kelola siklus hidup kru: keahlian (layanan yang bisa dikerjakan), jenis
  /// (kru/mitra/vendor), dan status (aktif/nonaktif/diberhentikan).
  Future<void> _dialogKelolaKru(
      BuildContext context, WidgetRef ref, KruModel k) async {
    final layanan = ref.read(semuaLayananProvider).valueOrNull ?? const [];
    final keahlian = {...k.keahlian};
    var tipe = k.tipe;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Text('Kelola ${k.nama}',
              style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jenis Kru',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final t in KruTipe.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: tipe == t,
                        onSelected: (_) => setLocal(() => tipe = t),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Text('Keahlian (layanan yang bisa dikerjakan)',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Kosong = generalis (bisa semua layanan).',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: TkColors.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final s in layanan)
                      FilterChip(
                        label: Text(s.namaLayanan),
                        selected: keahlian.contains(s.serviceId),
                        onSelected: (v) => setLocal(() => v
                            ? keahlian.add(s.serviceId)
                            : keahlian.remove(s.serviceId)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Text('Status Kepegawaian',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final st in StatusKru.values)
                      OutlinedButton(
                        onPressed: () async {
                          if (st == StatusKru.diberhentikan) {
                            final ya = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                title: const Text('Berhentikan kru?'),
                                content: Text(
                                    '${k.nama} tak bisa lagi menerima tugas.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: TkColors.error),
                                    child: const Text('Berhentikan'),
                                  ),
                                ],
                              ),
                            );
                            if (ya != true) return;
                          }
                          await ref
                              .read(firestoreServiceProvider)
                              .setStatusKru(k.cleanerId, st);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: st == StatusKru.diberhentikan
                              ? TkColors.error
                              : k.status == st
                                  ? TkColors.primary
                                  : TkColors.inkSoft,
                        ),
                        child: Text(st.label),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(firestoreServiceProvider).updateProfilKru(
                      k.cleanerId,
                      keahlian: keahlian.toList(),
                      tipe: tipe,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
