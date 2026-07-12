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

## 2. Dashboard performa (admin)

- **Bisnis**: omzet per hari/minggu/bulan, order per layanan, konversi
  batal, AOV — agregasi dari `orders` selesai (Cloud Function harian menulis
  `stats/{yyyymmdd}` agar panel tidak membaca ribuan dokumen).
- **Kru (agregat)**: jumlah tugas selesai, rata-rata rating, on-time rate.
- **Individual**: riwayat tugas + rating + pendapatan per kru (join
  `orders.penugasan` × `payouts`), tab di dialog Kelola Kru A5.

## 3. Superadmin: data klien & pemantauan chat

- Role `superadmin` (field `users.role`) — admin biasa tidak melihat menu ini.
- **Kelola klien**: tabel `users role==pelanggan` (telepon, jumlah order,
  total belanja, terakhir aktif) + detail riwayat.
- **Pantau chat & keluhan**: rules `orders/*/messages` sudah mengizinkan
  admin membaca; tambah layar inbox agregat (Cloud Function menulis index
  `chatIndex/{orderId}` berisi pesan terakhir + flag "belum dibalas kru").
- Keluhan: koleksi `disputes` sudah ada — tampilkan feed + status tindak
  lanjut.

## 4. AI / Machine Learning

- **Automatic crew assignment**: Cloud Function scoring kru saat order
  terverifikasi — fitur: jarak posisi terakhir, rating, beban tugas hari
  itu, keahlian; tulis rekomendasi ke order (`rekomendasiKru`), admin
  tinggal 1-klik setuju (fase 1 semi-otomatis, fase 2 penuh).
- **Business analyst otomatis**: job harian (Claude API) membaca
  `stats/*` → ringkasan naratif + anomali → dikirim ke admin (notif +
  panel). Termasuk insight marketing (jam ramai, layanan naik/turun) & HRD
  (kru overload/underutilized).
- **CS AI (live chat & WhatsApp)**: endpoint Cloud Function `csAi` —
  knowledge base HANYA data non-rahasia (katalog + harga, jam operasional,
  kebijakan refund, status order MILIK penanya setelah verifikasi nomor).
  Data pribadi/finansial/kredensial DILARANG masuk konteks. Integrasi:
  widget chat pelanggan + Fonnte webhook WA (sudah ada `waNotifOrder`).
  Eskalasi ke manusia bila confidence rendah / permintaan sensitif.

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
