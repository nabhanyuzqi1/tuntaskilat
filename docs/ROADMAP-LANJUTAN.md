# Roadmap Lanjutan Tuntaskilat (per 13 Juli 2026)

Dokumen desain untuk item yang DIMINTA owner tetapi butuh sesi khusus
(bukan quick-win). Urut prioritas yang disepakati.

## 1. Batch teknis berikutnya (urutan owner)

1. **Firebase App Check** — Play Integrity (Android) + reCAPTCHA v3 (admin
   web). Aktifkan enforcement bertahap: monitor-only dulu 1 minggu.
2. **Tes unit Security Rules** — `@firebase/rules-unit-testing` + emulator;
   kasus: orders create (formula uang), transisi status, slots, banners,
   broadcast, kru rating-only.
3. **Firebase Crashlytics** — pelanggan + kru; sertakan `orderId` sebagai
   custom key pada alur pemesanan.
4. **Payment gateway Xendit asli** — `xenditWebhook` sudah stub. Tambah:
   koleksi `settings/pembayaran` berisi daftar metode `{kode, aktif, tipe:
   dinamis|statis}`; switcher per metode di A6; P7 membaca daftar ini
   (dinamis = VA/QRIS Xendit; statis = transfer manual + bukti).

## 2. Dashboard performa (admin) — ✅ SEBAGIAN (13 Jul)

- **Bisnis**: ✅ sudah ada di A2 (omzet bulan ini, order aktif, grafik
  pendapatan 7 hari, sebaran status, transaksi terbaru).
- **Kru (agregat) + Individual**: ✅ tabel "Performa Kru" di A2 — ranking
  tugas selesai, rating, total nilai order dikerjakan (dihitung dari orders
  yang sudah dimuat, tanpa query tambahan).
- **Belum**: agregasi harian `stats/{yyyymmdd}` via Cloud Function (untuk
  skala ribuan order), AOV & konversi batal, on-time rate (butuh timestamp
  mulai/selesai per tahap).

## 3. Superadmin: data klien & pemantauan keluhan — ✅ v1 (13 Jul)

- **Kelola klien**: ✅ menu **Klien** (A9) — tabel pelanggan (nama, telepon,
  jumlah order, selesai, batal, total belanja, terakhir aktif) diturunkan
  dari orders.
- **Keluhan**: ✅ feed `disputes` (pengaju, pesanan, alasan, status, waktu).
- **Belum**: role `superadmin` terpisah dari `admin` (kini menu tampil untuk
  semua admin; data tetap admin-gated di rules). Inbox chat agregat
  (`chatIndex/{orderId}` + flag "belum dibalas kru") — pesan chat sudah bisa
  dibaca admin lewat rules, tinggal layar inbox.

## 4. AI / Machine Learning

- **Automatic crew assignment** — ✅ FASE 1 (13 Jul): skoring kru di dialog
  Tugaskan Kru (A3) dari rating + beban tugas aktif + online + keahlian
  spesifik; kru skor tertinggi ditandai "★ Disarankan" & diurutkan atas,
  admin 1-klik setuju. **Fase 2 (belum)**: pindah skoring ke Cloud Function
  saat order terverifikasi (tulis `rekomendasiKru` ke order) + faktor jarak
  posisi GPS terakhir + auto-assign penuh opsional.
- **Business analyst AI** — ✅ v1 (13 Jul): callable `analisaBisnisAi`
  (admin-only) membaca agregat pesanan 30 hari → ringkasan naratif + anomali
  + saran aksi via Claude API; tombol "Analisa AI" di dashboard A2.
  **Belum**: job harian otomatis + notif (kini on-demand).
- **CS AI (live chat)** — ✅ v1 (13 Jul): Cloud Function `csAi` menjawab dari
  knowledge base non-rahasia (katalog+harga, jam, cara pesan/bayar); status
  hanya order MILIK penanya (diverifikasi server). Chat di app pelanggan
  (P18, entry di Bantuan). Kunci API diatur admin di Pengaturan → Asisten AI
  (`settings/ai`, admin-only). **Belum**: integrasi WhatsApp via Fonnte
  webhook (endpoint `csAi` sudah reusable untuk itu).

## 5. Sudah dikerjakan sesi 13 Juli (referensi)

- Notif bocor lintas akun: token FCM dicabut + `deleteToken()` saat logout.
- Layar izin tak muncul lagi setelah ditangani (drop cek `storage` yang
  selalu denied di Android 13+; flag SharedPreferences).
- Riwayat error pasca ganti akun: provider kini reaktif ke auth.
- Guest mode (jelajah tanpa login; aksi → ajakan masuk).
- Banner carousel Beranda + CRUD admin (koleksi `banners`, rules deployed)
  + halaman detail P17.
- K3 kru: peta full-screen + sheet draggable + tombol aksi menempel bawah.
- Rekening/e-wallet kru (model + layar + menu K6).
- Icon launcher kru inverted (latar hijau tua).
- Admin: chip label tidak lagi mentok kanan; logo login/sidebar pakai
  logo-color; dropdown satuan aman untuk nilai lama (fix error edit
  layanan); kolom TIPE HARGA (statis/dinamis) di A4; dialog Tugaskan Kru
  ber-pencarian + promosi Ketua Tim sekali klik; sortir tabel Kelola Kru;
  fix FirebaseException 2FA di `flutter run` web.
