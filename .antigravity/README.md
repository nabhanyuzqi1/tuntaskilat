# Skill Set Gemini untuk Tuntaskilat (Antigravity)

Kumpulan instruksi/persona agar Gemini di **Antigravity 2.0** bekerja sesuai
konteks penuh proyek TA ini (kode + Hi-Fi + naskah). Semua berpijak pada
`AGENTS.md` di root repo (dibaca otomatis oleh Antigravity dan sebagian besar
IDE agentic).

## Isi

```
AGENTS.md                         # entry point: konteks + 5 aturan + verifikasi (WAJIB dibaca)
GEMINI.md                         # penunjuk singkat untuk Gemini CLI
.antigravity/skills/
  orchestrator.md                 # pecah tugas → delegasi sub-agent → integrasi + verifikasi
  code-reviewer.md                # tinjau bug/keamanan/performa + kesetiaan TA
  dosen-pembimbing.md             # nilai kesetiaan kode↔naskah + kesiapan sidang
  ta-review-docx.md               # audit + perbaiki naskah .docx (skrip Python dipakai bersama Claude)
```

> `ta-review-docx` memakai skrip Python yang sama dengan skill Claude di
> `.claude/skills/ta-review-docx/scripts/` (extract/verify/edit) — jalan identik
> di kedua lingkungan. Aktifkan dgn *"Pakai skill ta-review-docx: review/edit naskah"*.

## Cara memakai di Antigravity

1. **Konteks global.** Antigravity membaca `AGENTS.md` di root workspace secara
   otomatis, jadi semua agent sudah mendapat 5 aturan + skema + status proyek.
   Jika Antigravity meminta "Rules"/"Knowledge" eksplisit, arahkan ke `AGENTS.md`.
2. **Aktifkan sebuah skill.** Saat memulai tugas, sebutkan personanya, mis.:
   - *"Pakai skill orchestrator: bangun fitur X"* — Gemini memuat
     `.antigravity/skills/orchestrator.md` dan mengikuti prosesnya.
   - *"Review diff ini sebagai code-reviewer"* — memuat `code-reviewer.md`.
   - *"Nilai kesiapan sidang sebagai dosen pembimbing"* — memuat
     `dosen-pembimbing.md`.
   - *"Pakai skill ta-review-docx: review/perbaiki naskah TA"* — memuat
     `ta-review-docx.md` (jalankan skrip di `.claude/skills/ta-review-docx/scripts/`).
   Atau simpan tiap berkas sebagai **Workflow** di Antigravity dan panggil
   dengan slash-command.
3. **Agent Manager (paralel).** Skill `orchestrator` dirancang untuk memakai
   beberapa sub-agent Antigravity sekaligus — ia menentukan apa yang paralel vs
   seri, lalu mengintegrasikan + memverifikasi.

## Kontrak yang berlaku untuk SEMUA skill

- 5 aturan tak-boleh-dilanggar (`AGENTS.md §2`).
- Tidak ada "selesai" tanpa `flutter analyze` bersih + `tk_core` test lolos +
  build target yang tersentuh (`AGENTS.md §5`).
- Perluasan skema/koleksi/scope → **konfirmasi user dulu**.
- Bahasa Indonesia; ringkas; pakai tabel untuk temuan.

> Catatan: berkas ini instruksi untuk agent, bukan kode aplikasi. Aman diedit
> tanpa memengaruhi build. Perbarui bagian "Status & konteks aktif" di
> `AGENTS.md` bila ada fakta proyek yang berubah.
