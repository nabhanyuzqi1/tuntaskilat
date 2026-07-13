# AGENTS.md — Konteks & Skill Agent untuk Tuntaskilat

> Berkas ini dibaca otomatis oleh Antigravity (Gemini) dan sebagian besar IDE
> agentic. Ini adalah **sumber kebenaran perilaku agent** untuk repo
> `tuntaskilat` — monorepo Tugas Akhir (TA) yang **sudah disahkan penguji**.
> Menyimpang dari aturan di sini = implementasi tidak lagi cocok dengan
> naskah akademik yang dipertanggungjawabkan saat sidang.

## 0. Cara pakai berkas ini

Repo ini memuat **3 skill/persona Gemini** di `.antigravity/skills/`. Pilih
skill sesuai tugas, muat isinya sebagai instruksi aktif, lalu kerjakan:

| Skill | Kapan dipakai | Berkas |
|---|---|---|
| **Orchestrator** | Tugas multi-langkah / lintas app; perlu dipecah & didelegasikan ke sub-agent; koordinasi + integrasi + verifikasi | [`.antigravity/skills/orchestrator.md`](.antigravity/skills/orchestrator.md) |
| **Code Reviewer** | Meninjau diff/PR/berkas untuk bug, keamanan, performa, dan **kesetiaan pada TA** | [`.antigravity/skills/code-reviewer.md`](.antigravity/skills/code-reviewer.md) |
| **Dosen Pembimbing TA** | Menilai apakah kode + naskah layak sidang; cek scope, klaim, kesiapan, dan siapkan tanya-jawab penguji | [`.antigravity/skills/dosen-pembimbing.md`](.antigravity/skills/dosen-pembimbing.md) |
| **Review & Edit TA (.docx)** | Audit naskah TA + perbaiki temuan aman → revisi baru (konsistensi angka/gambar/sitasi, kesetiaan kode↔naskah, EYD) | [`.antigravity/skills/ta-review-docx.md`](.antigravity/skills/ta-review-docx.md) · Claude: [`.claude/skills/ta-review-docx/SKILL.md`](.claude/skills/ta-review-docx/SKILL.md) |

Apa pun skill yang dipakai, **§1–§5 di bawah berlaku mutlak.**

---

## 1. Produk & arsitektur

**Tuntaskilat** — platform jasa kebersihan on-demand untuk Kota Sampit,
Kalimantan Tengah (PT Tuntas Kilat Group). Metodologi: Human-Centered Design.
Diturunkan dari TA "Rancang Bangun Platform Jasa Kebersihan On-Demand
'Tuntas Kilat' Berbasis Mobile Menggunakan Framework Flutter dan Firebase
Terintegrasi Pendekatan HCD" (Nabhan Yuzqi Al Mubarok, Universitas Darwan Ali,
2026).

**Arsitektur: 3 aplikasi Flutter terpisah + 1 backend Firebase.**

```
tuntaskilat/
  packages/tk_core/        # Dart package bersama: models, services, theme, widgets, utils
  apps/pelanggan/          # Android  — 18 layar (OB1-3, P1-P15)   — identitas #0A874D
  apps/kru/                # Android  — 9 layar  (KO1-3, K1-K6)    — identitas #006542
  apps/admin/              # Flutter Web — 6 layar (A1-A6)         — identitas #0F5C3E
  firebase/                # firestore.rules, storage.rules
```

- **Toolchain:** Flutter 3.41.9 / Dart 3.11.5, target/compile SDK 36, minSdk 24.
- **State management:** Riverpod (`flutter_riverpod ^2.6`) — konsisten semua modul.
- **Firebase project:** `tuntaskilat-homeservices` (number `429452141588`),
  Firestore `(default)` region `asia-southeast2` (Jakarta), Auth Email/Password
  + Google, Cloud Storage aktif. App id: `com.tuntaskilat.pelanggan`,
  `com.tuntaskilat.kru`, dan web admin.

## 2. LIMA ATURAN TAK-BOLEH-DILANGGAR

Kalau sebuah permintaan bertentangan dengan ini, **berhenti dan tanya user
dulu** — jangan diam-diam menyimpang.

1. **Tiga aplikasi terpisah, satu backend.** Bukan satu APK dengan routing
   `role`. Satu koleksi `users` ber-`role` dipakai bertiga; login Portal Kru
   (K1) & Panel Admin (A1) **wajib menolak** akun yang role-nya tidak cocok —
   divalidasi **di klien DAN di Firebase Security Rules**. Jangan tambah target
   iOS/Web untuk Pelanggan/Kru (itu Saran Bab V, bukan scope).
2. **100% Firebase, tanpa server terpisah.** Jangan usulkan VPS/backend custom.
   Kalau butuh logika server, pakai Cloud Functions (plan Blaze sudah aktif).
3. **Fixed pricing.** Harga = `services.harga × kuantitas`, **dihitung ulang &
   divalidasi di backend saat submit** (di dalam transaction) — jangan pernah
   percaya angka dari klien. Tanpa surge/harga dinamis.
4. **Nama field Firestore persis `firestore-schema.md` / Kamus Data Tabel 3.8.**
   Bukan gaya penulisan bebas. Jangan refactor/rename field.
5. **Pemesanan baru wajib Firestore Transaction (Atomic Locking).** Bukan
   `get()` lalu `set()`. Ini solusi spesifik yang diklaim & diuji di TA
   (Bab IV 4.2.2) untuk mencegah double-booking. Implementasi saat ini:
   ID dokumen `orders` deterministik dari slot (`slot_yyyyMMddHHmm`,
   `FirestoreService.slotOrderId`), dua transaksi memperebutkan satu dokumen,
   Firestore menjamin hanya satu menang. Kunci slot terjadi saat **konfirmasi
   pembayaran (P7)**, bukan saat mengisi form.

## 3. Model data — 7 koleksi (nama field final)

`users`, `services`, `orders`, `kru`, `payments`, `reviews`, `notifications`.
Detail tipe ada di `packages/tk_core/lib/models/` dan `firebase/firestore.rules`.
Poin yang sering keliru:

- `orders`: field uang (`totalHarga`, `hargaSatuan`, `kuantitas`) & kepemilikan
  (`userId`, `cleanerId`, `serviceId`, `jadwal`) **immutable dari klien** —
  rules `orders.update` untuk non-admin hanya izinkan `status`, `fotoSebelum`,
  `fotoSesudah` (via `diff().affectedKeys().hasOnly(...)`).
- **State Diagram status** (Gambar 3.11): `dibuat → menunggu_pembayaran →
  menunggu_verifikasi → (ditolak↩upload ulang | terverifikasi) →
  menunggu_penugasan → ditugaskan → dalam_perjalanan → diproses → selesai →
  dinilai`. Tunai → langsung `menunggu_penugasan`; non-tunai → `menunggu_verifikasi`.
- `kru.posisi` (GeoPoint) dialirkan Portal Kru (K3) via GPS saat `dalam_perjalanan`,
  jadi sumber marker real-time P8 pelanggan.
- Storage path **berprefix UID pemilik**: `bukti_bayar/{uid}/{orderId}.jpg`,
  `laporan/{uidKru}/{orderId}/...` — rules `write: if request.auth.uid == uid`.

## 4. Inventaris 33 layar (ID = nama widget/route, telusuri balik ke naskah)

- **Pelanggan (18):** OB1-3 onboarding, P1 Splash, P2 Masuk/Registrasi,
  P3 Beranda, P4 Detail Layanan, P5 Form Pemesanan (peta OSM interaktif +
  slot lock), P6 Rincian Tagihan, P7 Pembayaran, P8 Tracking (OSM + posisi
  kru real-time), P9 Riwayat, P10 Ulasan, P11 Profil, P12 Notifikasi,
  P13 Ubah Sandi, P14 Bantuan, P15 Edit Profil.
- **Kru (9):** KO1-3 onboarding, K1 Login, K2 Daftar Penugasan (toggle
  Online/Offline), K3 Detail+Navigasi (progres berurutan + stream GPS),
  K4 Laporan Kerja (foto sebelum/sesudah → Storage), K5 Riwayat+Rating,
  K6 Profil.
- **Admin/Web (6):** A1 Login, A2 Dashboard (KPI + grafik + donut),
  A3 Kelola Pesanan (verifikasi/tolak bayar + tugaskan kru), A4 Kelola Layanan
  (CRUD), A5 Kelola Kru (buat akun via Firebase app sekunder), A6 Pengaturan.

## 5. Kriteria "selesai" & verifikasi WAJIB

Sebuah perubahan belum selesai sebelum:

```bash
# 1. Analisis statis bersih di seluruh workspace
flutter analyze                       # dari root repo

# 2. Unit test tk_core lolos (saat ini 68 test, termasuk 8 skenario Black-Box)
cd packages/tk_core && flutter test

# 3. Build target yang tersentuh
cd apps/pelanggan && flutter build apk --debug
cd apps/kru       && flutter build apk --debug
cd apps/admin     && flutter build web --release

# 4. Rules yang berubah di-deploy
firebase deploy --only firestore:rules,storage --project=tuntaskilat-homeservices
```

**8 Skenario Black-Box** (Tabel 4.1 TA) yang tiap fitur terkait harus benar-benar
lolos (bukan diklaim): (1) race condition slot → abort, (2) karakter ilegal
ditolak validator, (3) koneksi kru putus → marker bertahan, (4) koneksi pulih →
marker melompat, (5) role salah → ditolak routing + rules, (6) manipulasi harga
→ dihitung ulang backend, (7) kru offline → hilang dari daftar real-time,
(8) koordinat luar Sampit → "Out of Delivery Range".

## 6. Status & konteks aktif (per Juli 2026)

- **33/33 layar selesai**, ter-commit di branch `main`. `flutter analyze` bersih,
  68/68 test lolos.
- **Naskah TA:** `TA Nabhan 2026 - Rev18.docx` (revisi terbaru). **Sidang: Selasa
  14 Juli 2026, 11.00–12.30.** Pembimbing: Lukman Bachtiar, S.Kom., M.M., M.Kom.
  (NIDN 1116108201). Penguji: Minarni, S.Kom., M.M. (1125128901, Ketua Prodi) &
  Mustaqiem, S.Kom., M.M. (1130077801).
- **Akun demo** (Firebase live): pelanggan `pelanggan@tuntaskilat.id`/`Pelanggan123`,
  kru `kru@tuntaskilat.id`/`KruTuntas123`, admin `admin@tuntaskilat.id`/`AdminTuntas123`.
- **Catatan transparansi:** skor SUS 87,0 di naskah berasal dari **simulasi**,
  bukan 50 responden riil — jangan klaim final tanpa uji ulang.

### Deviasi sadar-skema (jangan "diperbaiki" tanpa keputusan user)
Beberapa elemen Hi-Fi TIDAK diimplementasikan karena butuh field/koleksi di luar
7 koleksi TA: biaya layanan dirender "Gratis" & diskon tidak dirender
(`totalHarga` tetap murni `harga × kuantitas`); foto profil (P15) & tombol
favorit (P4); catatan kru & checklist (K4); nomor CS masih placeholder; A6 bagian
**Biaya & Komisi + Manajemen Tim Admin ditunda** (butuh `settings/platform` +
role granular). Menambah ini = perluasan skema → **wajib konfirmasi user**.

### Pelajaran teknis yang sudah mahal (jangan diulang)
- **Edge-to-edge (target SDK 36):** bottom nav wajib menyisakan
  `MediaQuery.viewPaddingOf(context).bottom`; warna status/nav bar hanya via
  `SystemUiOverlayStyle`, bukan native.
- **Overflow:** gunakan `Expanded`/`FittedBox`/`maxLines+ellipsis` untuk konten
  kartu; jangan `mainAxisExtent` yang pas-pasan. `ConstrainedBox(maxWidth)` di
  dalam `ListView` + `Column(stretch)` bisa merusak lebar — pakai
  `LayoutBuilder` + `SizedBox(width: clamp)`.
- **Firestore query:** hindari `where(==) + orderBy(field lain)` (butuh composite
  index → error runtime yang tidak muncul di `fake_cloud_firestore`). Sort di klien
  bila kecil.
- **Startup:** jangan `await Firebase.initializeApp` sebelum `runApp` (layar putih
  lama); pakai FutureProvider non-blocking.
- **A5 buat akun kru:** pakai **Firebase app sekunder** agar sesi admin tidak
  tertimpa; dokumen `users` ditulis sesi akun baru (rules `isOwner`), dokumen
  `kru` ditulis admin.

## 7. Referensi dalam repo

- `firebase/firestore.rules`, `firebase/storage.rules` — Security Rules produksi.
- `packages/tk_core/lib/services/firestore_service.dart` — semua akses data +
  transaction. `.../services/auth_service.dart` — login + validasi role.
- `packages/tk_core/test/` — 68 unit test yang membuktikan skenario Black-Box.
- `README.md` — ringkasan repo.
- Naskah TA, Hi-Fi build (`Canvas.dc.html`), dan skill `tuntaskilat-dev` (PRD,
  firestore-schema, design-tokens, page-inventory, test-scenarios) adalah sumber
  kebenaran akademik di workspace user.
