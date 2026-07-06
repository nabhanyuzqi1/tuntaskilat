---
name: ta-review-docx
role: Review & edit naskah TA Tuntaskilat (.docx)
model: gemini (Antigravity)
activate_when:
  - Review/cek/audit naskah TA/skripsi (.docx)
  - Edit/perbaiki naskah, cek daftar pustaka, konsistensi, revisi dosen
  - Menjelang sidang (14 Juli 2026)
prereq: Baca AGENTS.md (konteks kode↔naskah) lebih dulu.
---

# Skill: Review & Edit TA (Antigravity mirror)

Setara dengan skill Claude `.claude/skills/ta-review-docx/` dan memakai **skrip
Python yang sama** — berjalan identik di Antigravity. Gabungan audit akademik +
editor .docx. Fokus pada temuan **mekanis & verifiable**, bukan mutu argumen.

Naskah aktif: `TA Nabhan 2026 - RevNN.docx` di folder workspace user. Sidang
14 Juli 2026 (pembimbing Lukman Bachtiar; penguji Minarni & Mustaqiem).

## Alur (jalankan berurutan)
```bash
pip install python-docx --break-system-packages -q
S=".claude/skills/ta-review-docx/scripts"
python3 "$S/extract_docx.py" "<naskah>.docx" ta     # dump paras + tabel + struktur
python3 "$S/verify_docx.py"  "<naskah>.docx"        # gambar/sitasi/SUS/italic
```
Lalu audit terarah pakai checklist:
`.claude/skills/ta-review-docx/references/review-checklist.md`.

## Yang WAJIB dicek (khas TA ini)
- **Kesetiaan kode↔naskah**: Atomic Locking (4.2.2) = `runTransaction`+slot lock;
  "tujuh koleksi" bukan "tiga"; 3 aplikasi terpisah; harga divalidasi backend;
  role ditolak di rules. Bukti ada di `packages/tk_core/`.
- **Scope**: tidak keluar Batasan Masalah tanpa catatan; deviasi sadar-skema
  (AGENTS.md §6) tidak di-overclaim.
- **SUS 87,0 = SIMULASI** (bukan 50 responden riil) — tandai jujur; cek
  aritmetika Σ item ×2,5.
- **Administratif**: Gambar 3.11 tertempel; tanggal sidang & JUDUL Lembar
  Persetujuan terisi; gelar/NIDN konsisten; penomoran gambar berurutan.

## Perbaikan aman → revisi baru
Pakai `.claude/skills/ta-review-docx/scripts/edit_helpers.py` + pola di
`references/docx-gotchas.md`. Prinsip: edit berbasis pencarian teks; insert/
delete paragraf paling akhir; sel merge = objek sama; italic sebagian = pecah
run; **jangan timpa asli** (simpan RevNN+1); **verifikasi** re-extract + grep
string lama(0)/baru(ada). Yang tak boleh ditebak (referensi yatim, tanggal
belum terjadi, gambar hilang total) → tanya user.

## Guardrails
- Jalankan verifikasi programatik sebelum bilang "aman".
- Jangan menambah klaim tak-didukung kode/data (SUS simulasi tetap disebut jujur).
- Perbaikan substansi/scope → konfirmasi user.
