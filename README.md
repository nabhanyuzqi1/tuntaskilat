# Tuntaskilat — Monorepo

Implementasi aplikasi dari Tugas Akhir "Rancang Bangun Platform Jasa Kebersihan
On-Demand 'Tuntas Kilat'" (Nabhan Yuzqi Al Mubarok, Universitas Darwan Ali,
2026). Spesifikasi lengkap ada di skill `tuntaskilat-dev` (PRD, skema Firestore,
design tokens, inventaris 33 halaman, skenario pengujian) — jangan menyimpang
tanpa konfirmasi.

## Arsitektur

**3 aplikasi Flutter terpisah, 1 backend Firebase** (bukan satu APK dengan
role-routing):

| Direktori | Aplikasi | Target | Layar |
|---|---|---|---|
| `apps/pelanggan` | Aplikasi Pelanggan | Android | OB1-OB3, P1-P15 |
| `apps/kru` | Portal Kru | Android | KO1-KO3, K1-K6 |
| `apps/admin` | Panel Admin | Flutter Web | A1-A6 |
| `packages/tk_core` | Package bersama | - | models, services, theme, widgets |

Satu Firebase project untuk ketiganya; login Portal Kru/Panel Admin menolak
akun dengan `role` yang tidak cocok (validasi klien + Security Rules di
`firebase/firestore.rules`).

ID layar (P3, K2, A1, ...) dipakai sebagai nama file/widget/route agar bisa
ditelusuri balik ke `page-inventory.md` dan Gambar naskah TA.

## Aturan implementasi inti

1. Nama field Firestore persis `firestore-schema.md` (Kamus Data Tabel 3.8 TA).
2. Pemesanan baru wajib Firestore Transaction / Atomic Locking (TA Bab IV
   4.2.2) — lihat `FirestoreService.createOrder`.
3. Fixed pricing: `services.harga × kuantitas`, dihitung ulang di backend.
4. 100% Firebase, tanpa server terpisah.
5. State management: Riverpod, konsisten di semua modul.

## Perintah

```bash
flutter pub get                      # resolve seluruh workspace dari root
cd packages/tk_core && flutter test  # unit test (skenario Black-Box #1/#2/#6/#7/#8)
cd apps/pelanggan && flutter run     # Aplikasi Pelanggan (emulator Android)
cd apps/admin && flutter run -d chrome
```

Firebase: `flutterfire configure` per app (satu project, app id
`com.tuntaskilat.pelanggan` / `com.tuntaskilat.kru` / web admin), lalu ganti
`lib/firebase_options.dart` placeholder.

Referensi visual: `Hi-Fi Tuntaskilat App/Canvas.dc.html` (33 layar, sinkron
`page-inventory.md` v2).
