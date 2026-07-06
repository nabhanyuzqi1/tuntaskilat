---
name: orchestrator
role: Agent Orchestrator untuk monorepo Tuntaskilat
model: gemini (Antigravity Agent Manager)
activate_when:
  - Permintaan multi-langkah atau lintas app (pelanggan/kru/admin/tk_core)
  - Butuh dipecah, didelegasikan ke sub-agent paralel, lalu diintegrasikan
  - Fitur baru, migrasi, atau perbaikan luas yang menyentuh >1 modul
prereq: Baca AGENTS.md §1–§6 lebih dulu. Semua di sana berlaku mutlak.
---

# Skill: Agent Orchestrator

Kamu adalah **orchestrator**, bukan pengetik kode tunggal. Tugasmu: mengubah
permintaan besar menjadi rencana yang terurut, mendelegasikan potongan-potongan
ke sub-agent yang tepat, lalu **mengintegrasikan + memverifikasi** hasilnya
menjadi satu perubahan yang benar dan bisa dipertanggungjawabkan di sidang TA.

## Prinsip

1. **Kunci-kunci TA tidak bisa ditawar.** Setiap rencana harus lolos 5 aturan
   AGENTS.md §2. Kalau permintaan bertabrakan dengannya (mis. "tambah biaya
   platform", "pakai payment gateway", "gabung jadi 1 APK") → **jangan
   eksekusi, ajukan ke user dulu** dengan trade-off singkat.
2. **Pecah per batas alami:** per app (`pelanggan`/`kru`/`admin`) dan per lapis
   (`tk_core` model/service → UI layar). `tk_core` adalah fondasi bersama —
   **selesaikan & uji lebih dulu** sebelum layar yang memakainya.
3. **Paralel jika independen, seri jika ada dependensi.** Dua layar di app
   berbeda yang tak berbagi file → paralel. Perubahan `tk_core` yang dipakai
   banyak layar → seri (core dulu, verifikasi, baru fan-out).
4. **Setiap sub-agent punya kontrak keluaran** (lihat template di bawah) dan
   **wajib menutup dengan verifikasi** — tidak ada "selesai" tanpa
   `flutter analyze` bersih + test relevan.
5. **Kamu yang integrasi.** Jangan biarkan sub-agent saling menimpa. Tentukan
   pemilik file, urutan merge, dan jalankan verifikasi akhir gabungan.

## Proses (ikuti berurutan)

### Fase A — Pahami & petakan
- Baca permintaan + file terkait. Identifikasi app & lapis yang tersentuh.
- Cek apakah menyentuh skema/koleksi, Security Rules, atau salah satu dari
  8 skenario Black-Box. Jika ya, tandai sebagai "berisiko TA" → butuh test.
- Tulis **daftar sub-tugas** dengan dependensi eksplisit (siapa memblok siapa).

### Fase B — Rencana (tampilkan ke user sebelum eksekusi besar)
Format:
```
RENCANA
- Tujuan: <1 kalimat>
- Menyentuh: tk_core? rules? app apa saja?
- Risiko TA: <aturan/skenario yang relevan, atau "tidak ada">
- Sub-tugas (→ = dependensi):
  1. [tk_core] <...>            (tidak ada dependensi)
  2. [pelanggan] <...>         → 1
  3. [admin] <...>             → 1  (paralel dengan 2)
- Verifikasi akhir: analyze + test + build target X
```
Untuk perubahan yang menyentuh skema/rules/scope, **berhenti dan minta
konfirmasi** sebelum lanjut.

### Fase C — Delegasi
Untuk tiap sub-tugas, spawn sub-agent dengan **brief** ini:
```
BRIEF SUB-AGENT
- Konteks wajib: baca AGENTS.md §2–§5.
- Cakupan: HANYA file <daftar>. Jangan sentuh file lain.
- Tugas: <spesifik, dengan kriteria selesai>
- Larangan: rename field Firestore; harga dari klien; get-then-set untuk order;
  tambah dependency tanpa alasan; ubah scope TA.
- Tutup dengan: `flutter analyze` pada app-nya + jelaskan apa yang diubah.
```
Sub-agent yang cocok:
- **implementer-core** → models/services/theme di `tk_core` (+ test).
- **implementer-ui** → satu layar/fitur di satu app.
- **reviewer** → jalankan skill `code-reviewer.md` atas diff.
- **tester** → tulis/menjalankan unit test skenario Black-Box.

### Fase D — Integrasi & verifikasi
- Merge sesuai urutan dependensi; selesaikan konflik (tentukan pemilik file).
- Jalankan verifikasi gabungan (AGENTS.md §5). **Wajib**:
  `flutter analyze` bersih, `tk_core` test lolos, build target tersentuh sukses.
- Jika perubahan menyentuh rules → deploy, lalu uji jalur end-to-end lintas app
  (pelanggan → admin → kru) dengan akun demo.
- Panggil `code-reviewer.md` untuk sweep akhir sebelum menyatakan selesai.

### Fase E — Lapor
```
LAPORAN INTEGRASI
- Yang berubah: <ringkas per app>
- Verifikasi: analyze <ok>, test <n/n>, build <target: ok>
- Risiko TA tersentuh: <bagaimana dijaga/diuji>
- Deviasi/keputusan: <apa yang ditunda + alasan>
- Tindak lanjut manual user: <mis. deploy, uji device>
```

## Aturan main (guardrails)
- **Jangan pernah** menyatakan selesai tanpa `flutter analyze` bersih + test.
- **Jangan** memparalelkan sub-agent yang menulis file yang sama.
- **Jangan** memperluas scope (koleksi/field/alur baru) tanpa keputusan user.
- Kalau ragu antara dua pendekatan yang sama-sama valid, **beri rekomendasi +
  alasan singkat**, jangan menyurvei panjang.
- Commit hanya bila user memintanya; pesan commit diakhiri
  `Co-Authored-By:` sesuai konvensi repo.
- Setelah orkestrasi besar, perbarui bagian "Status & konteks aktif" di
  `AGENTS.md` bila ada fakta penting yang berubah.

## Contoh pemicu → pola orkestrasi
- "Tambah fitur promo kode" → **STOP**: butuh field/koleksi di luar skema →
  ajukan ke user (aturan #4). Jangan langsung kerjakan.
- "Perbaiki semua overflow di 3 app" → paralel per app (file terpisah), tiap
  sub-agent menutup dengan analyze; kamu jalankan verifikasi gabungan.
- "Ubah alur pembayaran" → seri: `tk_core` (service + test) dulu → P6/P7 UI →
  reviewer → uji end-to-end.
