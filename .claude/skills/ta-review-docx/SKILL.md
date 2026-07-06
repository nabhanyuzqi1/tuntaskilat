---
name: ta-review-docx
description: >-
  Review & edit naskah Tugas Akhir Tuntaskilat (.docx) — audit kelengkapan
  struktur, konsistensi angka/gambar/sitasi, kepatuhan revisi dosen, kesetiaan
  kode↔naskah, bahasa/EYD; lalu MEMPERBAIKI temuan yang aman dan menghasilkan
  file revisi baru (tanpa menimpa asli). Gunakan setiap kali user minta
  "review/cek/periksa/audit TA/skripsi", "edit docx", "cek daftar pustaka",
  "cek konsistensi", "perbaiki naskah", menyebut revisi dosen, atau menjelang
  sidang. Berlaku untuk naskah TA Tuntaskilat (Rev18+) dan berkas .docx lain.
---

# Skill: Review & Edit TA (Tuntaskilat)

Menggabungkan **audit akademik** (temukan yang bisa menjegal saat sidang) dan
**editor .docx** (perbaiki yang aman, hasilkan revisi baru). Fokus pada hal
**mekanis & verifiable** — bukan menilai mutu argumen ilmiah (itu domain dosen).

Konteks proyek ada di `AGENTS.md` di root repo. Naskah aktif:
`TA Nabhan 2026 - RevNN.docx` di folder workspace user
(`.../SKRIPSI TA 2026/Tuntas Kilat/`). Sidang 14 Juli 2026.

## Alur kerja

### 0. Siapkan
```bash
pip install python-docx --break-system-packages -q   # sekali saja
DIR=".claude/skills/ta-review-docx/scripts"
```
Bekerja di scratchpad, JANGAN pernah menimpa file asli.

### 1. Ekstrak + petakan
```bash
python3 "$DIR/extract_docx.py" "<naskah>.docx" ta
```
Baca `ta_paras.txt` + `ta_tables.txt`. Petakan BAB, jumlah tabel/gambar/referensi.

### 2. Audit otomatis (empat kategori yang paling sering luput)
```bash
python3 "$DIR/verify_docx.py" "<naskah>.docx"
```
Menghasilkan: gambar hilang (caption ada tapi objek gambar tidak), sitasi yatim,
kandidat salah-hitung (SUS/rata-rata — hitung ulang manual & bandingkan klaim),
dan istilah asing italic tak-konsisten. **Jangan simpulkan "aman" tanpa
menjalankan ini.**

### 3. Audit terarah — pakai checklist proyek
Jalankan `references/review-checklist.md`. Yang khas TA ini:
- **Kesetiaan kode↔naskah**: tiap klaim Bab IV punya bukti di kode? (Atomic
  Locking 4.2.2 = `runTransaction` + slot lock; "tujuh koleksi" bukan "tiga";
  3 aplikasi terpisah; harga divalidasi backend; role ditolak di rules).
- **Scope (Batasan Masalah)**: tidak keluar tanpa catatan; deviasi sadar-skema
  (biaya "Gratis", diskon tak dirender, foto profil/catatan kru, A6 Biaya&Komisi
  ditunda) tidak di-overclaim di naskah.
- **SUS 87,0 = SIMULASI**, bukan 50 responden riil — wajib ditandai; verifikasi
  aritmetika (Σ konversi item ×2,5).
- **Administratif**: Gambar 3.11 State Diagram tertempel; tanggal sidang & JUDUL
  Lembar Persetujuan terisi; gelar/NIDN konsisten; penomoran gambar berurutan.
- **Revisi dosen** (jika ada form PDF): render `pdftoppm -png -r 150` + baca
  visual (tanda tangan/anotasi tangan), cocokkan tiap item dengan naskah.

### 4. Laporkan (tabel, bukan prosa panjang)
Urut dari paling material (bisa bikin ditolak/dipermalukan) → administratif.
Sertakan status kepatuhan revisi bila ada formnya.

### 5. Perbaiki yang AMAN → file revisi baru
Kalau user minta diperbaiki, gunakan `scripts/edit_helpers.py` dan pola di
`references/docx-gotchas.md`.
- **Aman otomatis**: typo nama/gelar, angka salah-hitung (setelah dihitung
  ulang), placeholder yang jawabannya pasti dari dokumen lain, DOI salah ketik,
  penomoran gambar, italic istilah asing, sinkronisasi klaim dengan implementasi.
- **Jangan ditebak — tanya user**: referensi yatim, tanggal yang belum terjadi,
  dan **gambar/mockup yang hilang total** (harus ditempel mahasiswa dari sumber
  asli — Figma/screenshot; asisten tidak bisa "mengarang" gambar).
- Simpan sebagai **revisi baru** (`RevNN+1`), jangan timpa. Lalu **verifikasi**:
  re-extract + grep string lama (harus 0) dan string baru (harus ada). Ingatkan
  user meng-**Update Field** Daftar Isi/Gambar/Tabel di Word.

## Guardrails
- Selalu jalankan langkah 2 (verifikasi gambar/angka/pustaka/istilah) secara
  programatik sebelum menyatakan naskah aman.
- File asli tidak boleh ditimpa; setiap perbaikan → nomor revisi baru.
- Jangan menambah klaim yang tidak didukung kode/data. Kejujuran metodologis
  (mis. SUS simulasi) melindungi mahasiswa saat sidang.
- Untuk perbaikan yang menyentuh substansi/scope, konfirmasi user dulu.

## Portabilitas ke Antigravity (Gemini)
Skill ini tercermin di `.antigravity/skills/ta-review-docx.md` (isi setara,
merujuk skrip yang sama di `.claude/skills/ta-review-docx/scripts/`). Di
Antigravity: aktifkan dengan *"Pakai skill ta-review-docx: review/edit naskah"*
atau simpan sebagai Workflow. Skrip Python berjalan sama di kedua lingkungan.

## Berkas pendukung
- `references/review-checklist.md` — checklist audit lengkap (grounded TA ini).
- `references/docx-gotchas.md` — jebakan python-docx + pola edit aman.
- `scripts/extract_docx.py` · `scripts/verify_docx.py` · `scripts/edit_helpers.py`.
