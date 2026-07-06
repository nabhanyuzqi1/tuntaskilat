# Jebakan python-docx + pola edit .docx yang aman

Pengalaman nyata dari menyunting naskah TA ini (Rev17→Rev18). Patuhi ini supaya
tidak merusak dokumen.

## Aturan emas
1. **Edit berbasis pencarian teks (`cari(paras, anchor)`), bukan index kaku.**
   Index paragraf bergeser setelah insert/delete.
2. **Urutan operasi:** lakukan SEMUA edit teks/format DULU; insert/delete
   paragraf (`insert_paragraph_before`) **paling akhir**. Sekali menyisip, semua
   index setelahnya tak valid.
3. **Jangan pernah menimpa file asli.** Simpan `RevNN+1` baru.
4. **Verifikasi hasil, bukan "script jalan".** Re-extract + grep: string lama
   harus 0, string baru harus ada. Cek visual halaman kunci bila perlu
   (`soffice --headless --convert-to pdf` lalu `pdftoppm`).

## Gotcha spesifik
- **Tabel terpisah dari paragraf.** `d.paragraphs` TIDAK memuat isi tabel. Untuk
  sitasi/istilah yang ada di tabel (mis. "Tinjauan Terdahulu", spesifikasi data
  `GeoPoint`/`denormalisasi`), gabungkan `body += cell.text` saat mengecek.
- **Sel merge = objek sama.** `row.cells[0]` dan `row.cells[1]` bisa merujuk
  objek Python identik. Loop `for ci in (0,1)` yang "cuma kena sekali" itu tanda
  sel ter-merge, bukan bug. Pakai `seen = set(id(c._tc))` untuk dedup.
- **Italic sebagian kata.** `run.italic = True` mengitalic SELURUH run. Untuk
  satu kata di tengah kalimat, pakai `split_italicize(run, kata)` (pecah run
  jadi tiga via deepcopy) — lihat `scripts/edit_helpers.py`.
- **Ganti teks paragraf** tanpa kehilangan format: `rebuild_p(p, teks_baru)`
  (hapus run selain pertama, set teks run pertama) — bukan `p.text = ...` (itu
  membuang format).
- **`\n` dan `<w:br>` di caption.** Caption hasil salin kadang diawali newline
  (`"\nGambar 4.3"`). Bersihkan `r.text.lstrip("\n")` dan hapus elemen `w:br`.
- **Caption ganda saat menyisip.** Kalau menyisip caption yang mungkin sudah ada
  (mis. objek gambar sebenarnya sudah punya caption di dekatnya), cek dulu agar
  tidak dobel — hapus salah satu bila kembar.
- **Deteksi gambar dekat caption bisa meleset.** `has_drawing` memeriksa jendela
  ~20 paragraf; gambar yang ditempatkan sebagai anchored object di luar jendela
  bisa lolos sebagai "hilang" padahal ada. Konfirmasi visual sebelum menyimpulkan
  gambar benar-benar hilang (user pernah mengoreksi bahwa 3.11 tidak hilang).

## Kerangka skrip perbaikan (pola yang terbukti)
```python
import docx
from edit_helpers import cari, rebuild_p, split_italicize, sisip_setelah

SRC = ".../TA Nabhan 2026 - RevNN.docx"
DST = ".../TA Nabhan 2026 - RevNN+1.docx"
d = docx.Document(SRC); paras = d.paragraphs; log = []

# 1) Edit teks/format (berbasis anchor) ...
# 2) Italic (split_italicize) ...
# 3) PALING AKHIR: insert/delete paragraf (sisip_setelah) ...

d.save(DST)
print(*log, sep="\n")
```
Setelah simpan, jalankan `verify_docx.py` pada DST + grep manual string lama/baru.
