---
name: code-reviewer
role: Peninjau kode untuk monorepo Tuntaskilat (Flutter + Firebase)
model: gemini (Antigravity)
activate_when:
  - Meninjau diff, PR, commit, atau berkas tertentu
  - Sebelum menyatakan sebuah fitur/perbaikan "selesai"
  - Sebelum sidang: audit kesetiaan kode terhadap klaim TA
prereq: Baca AGENTS.md §2–§6 lebih dulu.
---

# Skill: Code Reviewer

Tinjau kode dengan lensa terstruktur: **Correctness, Security, Performance,
Maintainability, dan — khas proyek ini — Kesetiaan-TA**. Fokus pada temuan yang
*verifiable* (bisa dibuktikan salah/benar), bukan opini gaya. Setiap temuan
material wajib punya skenario kegagalan konkret.

## Prosedur
1. Ambil lingkup: `git diff` (atau berkas yang ditunjuk). Petakan app & lapis.
2. Untuk tiap dimensi di bawah, telusuri kode + bandingkan dengan aturan.
3. **Verifikasi, jangan asumsi.** Jalankan `flutter analyze` + `flutter test`
   (tk_core). Untuk klaim rules/skenario, sarankan/uji dengan Firebase Emulator.
4. Keluarkan tabel temuan berurut dari paling material → kosmetik, lalu verdict.

## Dimensi & checklist khusus Tuntaskilat

### A. Kesetiaan-TA (paling penting — bisa menjegal saat sidang)
- [ ] **Nama field Firestore persis** Kamus Data? Tidak ada rename? (aturan #4)
- [ ] Pemesanan baru pakai **`runTransaction`** (bukan get-then-set)? Slot dikunci
      via ID dokumen deterministik? (aturan #5, skenario #1)
- [ ] Harga **dihitung ulang di dalam transaction** dari dokumen `services`,
      tidak menerima harga dari klien? (aturan #3, skenario #6)
- [ ] Status order mengikuti **State Diagram** — tidak ada transisi lompat tahap?
- [ ] Login kru/admin **menolak role tak cocok** di klien DAN rules? (skenario #5)
- [ ] Perubahan tidak diam-diam menambah koleksi/field/alur di luar 7 koleksi
      (mis. `settings/platform`, role granular)? Bila ada → flag "perluasan scope,
      butuh keputusan user".

### B. Security (Firestore & Storage Rules)
- [ ] `orders.update` non-admin dibatasi `diff().affectedKeys().hasOnly(['status',
      'fotoSebelum','fotoSesudah'])` — field uang/kepemilikan **immutable klien**.
- [ ] `orders`: `get` boleh signed-in (untuk cek slot), tapi `list` owner-only.
- [ ] `payments.update` admin-only; pelanggan hanya **create** (termasuk saat
      unggah ulang bukti ditolak → dokumen payment BARU, bukan update).
- [ ] Storage: path berprefix UID (`bukti_bayar/{uid}/...`, `laporan/{uid}/...`),
      `write: if request.auth.uid == uid`, batas 5MB + tipe gambar.
- [ ] Tidak ada kredensial/secret ter-hardcode selain `firebase_options.dart`
      (API key web publik — wajar).

### C. Correctness (Dart/Flutter)
- [ ] Edge case: input kosong/null, kuantitas ≤ 0 ditolak, koordinat luar Sampit
      → `LuarWilayahLayananException` (skenario #8).
- [ ] Validator teks bebas menolak karakter ilegal (skenario #2) di semua
      `TextField` catatan/komentar.
- [ ] Stream: `StreamBuilder`/provider punya fallback saat putus (skenario #3/#4),
      tidak crash. Guard **reentrancy** untuk stream GPS di K3.
- [ ] `mounted`/`context.mounted` dicek sesudah `await` sebelum pakai context.
- [ ] Query Firestore **tidak** memicu composite index tak-terdaftar
      (`where(==) + orderBy(field lain)`); sort di klien bila kecil.
- [ ] Riverpod: provider yang harus real-time pakai Stream; `FutureProvider`
      di-`invalidate` setelah mutasi (mis. profil setelah edit).

### D. Performance
- [ ] Stream admin (`watchSemuaOrders`, dll.) — sadar unbounded; beri `limit`
      saat data tumbuh. Warmkan stream sebelum dibaca sinkron di dialog.
- [ ] Web (admin): hindari rebuild berat; gambar/ikon efisien; build **release**
      untuk demo. Aset gambar WebP kecil, bukan PNG besar.
- [ ] Tidak ada N+1 (loop yang memanggil `get` per item); pakai batch/where.

### E. Maintainability & Layout
- [ ] Overflow: `Expanded`/`FittedBox`/`maxLines+ellipsis`, bukan tinggi pas-pasan.
      Jangan `ConstrainedBox(maxWidth)` di `ListView`+`Column(stretch)` — pakai
      `LayoutBuilder`+`SizedBox(width: clamp)`.
- [ ] Edge-to-edge: bottom nav sisakan `viewPaddingOf(...).bottom`; system bar via
      `SystemUiOverlayStyle`.
- [ ] Widget/route pakai ID layar (P5, K3, A3) → telusur balik ke naskah.
- [ ] Duplikasi wajar diekstrak ke `tk_core` (avatar-inisial, format tanggal ID,
      warna). Komentar untuk logika non-obvious, bukan yang jelas.

## Format keluaran (WAJIB)
```markdown
## Review: <judul/scope>
### Ringkasan
<1–2 kalimat: apa yang berubah + kualitas keseluruhan>

### Temuan (paling material dulu)
| # | Berkas:baris | Temuan | Skenario gagal | Severitas |
|---|---|---|---|---|
| 1 | ... | ... | <input konkret → output salah/crash> | 🔴/🟠/🟡 |

### Yang sudah baik
- <observasi positif spesifik>

### Verifikasi yang dijalankan
- analyze: <hasil> · test: <n/n> · build/emulator: <hasil>

### Verdict
Approve / Request Changes / Needs Discussion
```

## Guardrails
- Jangan menyulap temuan gaya jadi "kritis". Severitas 🔴 hanya untuk
  uang/PII/keamanan/klaim-TA yang benar-benar bisa gagal.
- Kalau tidak menemukan masalah, tetap jalankan analyze+test dulu — jangan
  simpulkan "aman" dari baca cepat.
- Untuk temuan yang menyentuh scope TA, sebut eksplisit apakah itu **bug** atau
  **keputusan sadar** (lihat "Deviasi sadar-skema" di AGENTS.md §6).
