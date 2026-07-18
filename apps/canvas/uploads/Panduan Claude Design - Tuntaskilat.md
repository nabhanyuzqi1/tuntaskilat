# Panduan & Konteks Desain Tuntaskilat — untuk Claude Design

Paste **System Context** di bawah sekali di awal project Claude Design Anda (atau sebagai pesan pertama). Setelah itu, paste **prompt per halaman** satu-satu untuk generate tiap screen. Semua konten di sini ditarik langsung dari Brand Guidelines resmi PT Tuntas Kilat Group + TA (metodologi HCD, kaidah desain I/O Bab III/IV).

---

## 1. System Context (paste sekali di awal)

```
Saya mendesain aplikasi "Tuntaskilat" — layanan kebersihan on-demand untuk Sampit,
Kalimantan Tengah. Flutter (Android untuk Pelanggan & Kru, Flutter Web untuk Admin).
Metodologi: Human-Centered Design.

STYLE DIRECTION — ikuti persis, jangan menyimpang:
- Clean, modern, hijau-putih. Putih adalah base dominan, hijau adalah aksen brand
  (bukan hijau tebal menutupi seluruh layar).
- Glassmorphism HANYA pada elemen mengambang: bottom nav bar, app bar saat scroll,
  kartu status yang melayang di atas peta, floating action button.
  JANGAN pakai glass effect di form input atau tabel data (turunkan keterbacaan).
- Radius: 16px kartu, 24px bottom sheet/modal, 12px tombol.
- Shadow lembut/tipis saja, hindari shadow gelap/keras.
- Font: Montserrat untuk semua teks (H1 Bold 28-32sp, H2 Bold 22sp, H3 SemiBold 18sp,
  Body Regular 14-16sp, Caption Medium 12sp). Tombol: Montserrat SemiBold, Title Case
  (bukan ALL CAPS).
- Touch target minimum 48x48dp, terutama di antarmuka Kru (dipakai di lapangan).

WARNA (hex, jangan diubah):
- Primary/Hijau utama: #0A874D — tombol aksi, elemen aktif
- Primary Dark/Hijau tua: #006542 — header, status "selesai"
- Accent/Kuning: #FBCC14 — badge harga, highlight (dari petir logo)
- Accent Alt/Oranye: #F9A22B — aksen sekunder, warning ringan
- Ink/Hitam: #000000 — teks utama
- Surface/Putih: #FFFFFF — latar dominan
- Surface Muted: hijau #0A874D @ 6% opacity di atas putih — kartu non-aktif
- Error: #D32F2F (merah standar Material, brand tidak punya warna error sendiri)
- Success: sama dengan Primary (#0A874D)

LOGO: bentuk "TK" hijau + petir kuning/oranye (brandmark). Untuk app icon pakai
brandmark petir saja, bukan logo lengkap. Jangan gepengkan/ubah proporsi logo.

TONE OF VOICE: Profesional, Efisien, Ramah, Berorientasi Solusi. Hindari bahasa
gaul/tidak formal, janji berlebihan, nada negatif.
Contoh: "Kru sedang menuju lokasi Anda, estimasi tiba 12 menit." bukan
"Sabar ya, kru masih di jalan nih 😅"

KAIDAH DESAIN I/O (HCD, wajib terlihat di setiap screen):
1. Kejelasan — hierarki visual tegas, elemen terpenting paling menonjol.
2. Validasi/Pencegahan kesalahan — error inline real-time, slot/aksi tak-valid
   ditampilkan disabled (abu + ikon gembok), bukan disembunyikan.
3. Umpan balik segera — setiap aksi (submit, upload, dsb) langsung ada respons visual
   (loading state, konfirmasi, toast).
4. Konsistensi — pola kartu, warna status, dan komponen sama di semua halaman sejenis.
5. Transparansi harga — tarif selalu terlihat jelas sebelum konfirmasi, tanpa biaya
   tersembunyi.
6. Aksesibilitas — kontras tinggi, target sentuh besar, terutama untuk peran Kru.

STATUS PESANAN — satu warna konsisten per tahap di SEMUA halaman:
kuning = menunggu, hijau = aktif/selesai, merah = ditolak/dibatalkan.

Saya akan minta Anda generate satu per satu halaman aplikasi ini. Ingat style
direction di atas untuk setiap halaman berikutnya.
```

---

## 2. Prompt per Halaman

Total 22 halaman: 12 Pelanggan (P1-P12), 5 Kru (K1-K5), 5 Admin (A1-A5, Flutter Web/desktop layout).

### Pelanggan (Android, mobile)

**P1 — Splash**
```
Desain screen Splash (P1). Baca-saja, tanpa input. Logo Tuntaskilat besar di tengah
(placeholder: lingkaran hijau dengan huruf "TK" + ikon petir kuning), nama app di
bawah logo, tagline singkat 1 baris. Latar putih bersih atau gradient hijau lembut
ke putih. Tidak ada tombol — auto-navigasi tersirat lewat catatan "auto-navigate ~2s".
```

**P2 — Masuk / Registrasi**
```
Desain screen Login/Register (P2), dengan toggle tab "Masuk" / "Daftar" di atas.
Form Masuk: field Email, field Kata Sandi (dengan show/hide), tombol "Masuk" full-width
hijau primary, link "Lupa kata sandi?", divider "atau", tombol login pihak ketiga
(Google) outline. Form Daftar: tambah field Nama Lengkap, No. Telepon, Konfirmasi
Kata Sandi. Tampilkan contoh error inline di bawah satu field (mis. "Format email
tidak valid") dengan warna merah #D32F2F, kaidah Pencegahan Kesalahan.
```

**P3 — Beranda**
```
Desain screen Beranda (P3). App bar dengan sapaan nama user + ikon notifikasi.
Search bar filter di bawah app bar. Grid 2 kolom katalog layanan (kartu: foto/ikon
layanan, nama, lencana tarif tetap warna kuning accent menonjol). Section "Pesan
Ulang" berisi horizontal scroll kartu riwayat cepat. Bottom navigation bar glass
effect (blur) dengan 4 tab: Beranda, Riwayat, Notifikasi, Profil.
```

**P4 — Detail Layanan**
```
Desain screen Detail Layanan (P4). Foto/ilustrasi layanan di atas (hero image).
Nama layanan besar, deskripsi lengkap, tarif per satuan ditampilkan sangat jelas
dan besar (kaidah Kejelasan — tarif adalah elemen kedua paling menonjol setelah
nama). Tombol "Pesan Sekarang" full-width sticky di bawah, warna hijau primary.
```

**P5 — Form Pemesanan**
```
Desain screen Form Pemesanan (P5). Input: jumlah ruangan/durasi (stepper number),
kalender pilih tanggal, grid slot waktu (slot terisi ditampilkan disabled abu-abu +
ikon gembok kecil — kaidah Pencegahan Kesalahan, ini penerapan visual dari Atomic
Locking), field alamat dengan mini-map/GPS picker, catatan khusus (textarea opsional).
Kartu estimasi tarif real-time melayang (glass effect) di bawah, update saat input
berubah.
```

**P6 — Rincian Tagihan**
```
Desain screen Rincian Tagihan (P6). Baca-saja sebelum bayar. Breakdown baris per
baris: harga satuan x kuantitas = subtotal, tanpa biaya tersembunyi (kaidah
Transparansi). Ringkasan jadwal & alamat di bawah breakdown. Total besar dan jelas
di bagian bawah. Tombol "Lanjut Bayar" full-width hijau.
```

**P7 — Form Pembayaran**
```
Desain screen Form Pembayaran (P7). Pilihan metode bayar sebagai card selectable:
Transfer Bank, QRIS, Tunai. Jika non-tunai: area upload bukti transfer (drag/tap
kotak dashed dengan ikon kamera). Setelah submit tampilkan state "Menunggu
Verifikasi" dengan badge kuning dan ikon jam, kaidah Umpan Balik Segera.
```

**P8 — Status Pesanan (Tracking)**
```
Desain screen Tracking (P8). Peta full-screen di latar (posisi kru real-time).
Kartu status pesanan glass effect melayang di bagian bawah peta (blur backdrop):
badge status warna sesuai tahap, estimasi waktu tiba, kartu identitas kru
terverifikasi (foto, nama, rating bintang, tombol telepon/chat). Kaidah
Transparansi & Kepercayaan.
```

**P9 — Riwayat Pesanan**
```
Desain screen Riwayat (P9). Filter chip di atas (tanggal/status). List kartu
transaksi lalu — pola kartu identik dengan kartu di P3 (kaidah Konsistensi):
nama layanan, tanggal, status berwarna, total harga. Tombol kecil "Beri Ulasan"
di kartu yang belum direview.
```

**P10 — Form Ulasan**
```
Desain screen Form Ulasan (P10). Rating bintang besar (1-5, mudah disentuh —
kaidah Aksesibilitas), field komentar opsional (textarea), tombol "Kirim Ulasan"
full-width. State konfirmasi setelah kirim: ikon centang + pesan singkat.
```

**P11 — Profil / Akun**
```
Desain screen Profil (P11). Foto profil + nama di atas. List item edit: Nama,
No. Telepon, Alamat tersimpan. Section pengaturan lain. Tombol "Keluar" di
paling bawah, warna merah/outline, dengan catatan perlu dialog konfirmasi
(kaidah konfirmasi ulang aksi destruktif).
```

**P12 — Notifikasi**
```
Desain screen Notifikasi (P12). List notifikasi grouped by hari (Hari Ini,
Kemarin). Item belum dibaca: dot indicator hijau + latar sedikit lebih terang.
Setiap item: ikon kategori, judul singkat, timestamp.
```

### Kru (Android, mobile — kontras tinggi, tombol besar)

**K1 — Masuk (Kru)**
```
Desain screen Login Kru (K1). Sama struktur dengan P2 tapi tanpa opsi registrasi/
login pihak ketiga (akun kru dibuat admin). Field Email, Kata Sandi, tombol
"Masuk" full-width. Branding sama tapi bisa beri label kecil "Portal Kru" untuk
bedakan dari app pelanggan.
```

**K2 — Daftar Penugasan**
```
Desain screen Daftar Penugasan (K2). Toggle besar di app bar "Online/Offline"
(switch dengan warna jelas). List card tugas aktif: alamat, waktu, status,
tombol besar kontras tinggi (kaidah Aksesibilitas — dipakai di lapangan,
touch target minimum 48x48dp, idealnya lebih besar).
```

**K3 — Detail Penugasan & Navigasi**
```
Desain screen Detail Penugasan (K3). Peta rute di atas. Detail alamat & catatan
pelanggan di bawah peta. Tombol progres status besar sesuai urutan (mis. "Menuju
Lokasi" → "Mulai Pengerjaan" → "Selesai") — hanya tombol tahap berikutnya yang
aktif, tahap lain disabled (kaidah Pencegahan Kesalahan — status tak bisa lompat
tahap).
```

**K4 — Form Laporan Kerja**
```
Desain screen Form Laporan Kerja (K4). Dua slot upload foto besar bersebelahan
atau bertumpuk: "Foto Sebelum" dan "Foto Sesudah" (kotak dashed + ikon kamera,
keduanya wajib). Field catatan opsional. Tombol "Kirim Laporan" full-width besar.
```

**K5 — Riwayat & Rating Kru**
```
Desain screen Riwayat Kru (K5). Card ringkasan di atas: rata-rata rating bintang
besar + jumlah ulasan. List riwayat pekerjaan selesai di bawah, pola kartu
konsisten dengan K2/K3.
```

### Admin (Flutter Web, desktop/wide layout)

**A1 — Masuk Admin**
```
Desain screen Login Admin (A1), layout desktop/web centered card di tengah
layar lebar (bukan full-width mobile). Field Email, Kata Sandi, tombol "Masuk".
Sidebar/branding minimal di sisi kiri atau atas.
```

**A2 — Dashboard**
```
Desain screen Dashboard Admin (A2), layout web dengan sidebar navigasi kiri
(ikon+label: Dashboard, Pesanan, Layanan, Kru). Konten utama: kartu ringkasan
KPI (total pendapatan, pesanan aktif, kru online) berjajar atas, grafik sebaran
status pesanan (bar/pie chart sederhana), tabel transaksi terbaru di bawah.
Grid padat untuk scan cepat (kaidah admin butuh efisiensi baca data).
```

**A3 — Kelola Pesanan**
```
Desain screen Kelola Pesanan (A3), layout web dengan sidebar sama seperti A2.
Tabel data pesanan lengkap dengan filter/search di atas tabel (status, tanggal).
Kolom aksi per baris: tombol Verifikasi/Tolak Pembayaran (tolak butuh alasan —
tampilkan sebagai modal dialog konfirmasi), dropdown penugasan kru manual.
```

**A4 — Kelola Layanan**
```
Desain screen Kelola Layanan (A4), sidebar sama. Tabel katalog layanan (nama,
deskripsi singkat, tarif, satuan, ikon, toggle status aktif/nonaktif per baris).
Tombol "+ Tambah Layanan" di kanan atas membuka form modal (nama, deskripsi,
tarif, satuan, upload ikon). Visual konsisten dengan gaya kartu katalog di P3.
```

**A5 — Kelola Kru**
```
Desain screen Kelola Kru (A5), sidebar sama. Tabel akun kru: foto, nama, status
ketersediaan, rata-rata rating, jumlah pesanan selesai, tombol nonaktifkan.
Tombol "+ Tambah Kru" kanan atas membuka form modal data akun baru.
```

---

## 3. Urutan yang disarankan

1. Paste System Context.
2. Generate P1 → P2 dulu, cek logo/warna/font sudah konsisten sebelum lanjut.
3. Lanjut P3-P12, lalu K1-K5, lalu A1-A5 — tiap prompt tempel satu per satu di conversation yang sama supaya Claude Design mempertahankan style system dari context awal.
4. Setelah semua screen jadi, screenshot/export tiap halaman untuk disisipkan ke `TA Nabhan 2026 - Rev16.docx` di posisi Gambar 3.14-3.18 (desain) dan 4.1-4.5 (implementasi) — sesuai mapping di tabel Ringkasan Halaman.

Referensi detail input/output per halaman (field, tipe data, validasi, koleksi Firestore): lihat `page-inventory.md` di skill `tuntaskilat-dev`. Referensi lengkap warna/font/komponen: `design-tokens.md`.
