export const PELANGGAN = {
  eyebrow: 'Aplikasi Pelanggan',
  title: 'Panduan Pelanggan',
  description: 'Pesan jasa kebersihan profesional dalam hitungan menit — dari memilih layanan, menjadwalkan kru, membayar, hingga melacak pekerjaan secara real-time.',
  sections: [
    {
      title: 'Memulai',
      image: { src: 'images/hifi/p2.png', caption: 'P2 — Masuk / Registrasi', variant: 'phone' },
      blocks: [
        { type: 'paragraph', text: 'Anda bisa mendaftar dengan email & kata sandi, atau langsung masuk dengan akun Google. Pengguna baru wajib melengkapi profil sebelum dapat memesan layanan.' },
        { type: 'steps', items: [
          { title: 'Unduh & buka aplikasi', desc: 'Layar pembuka menampilkan pengenalan singkat (onboarding) tentang cara kerja Tuntaskilat.' },
          { title: 'Daftar atau Masuk', desc: 'Gunakan email + kata sandi (minimal 8 karakter), atau tombol "Masuk dengan Google". Punya kode referal dari teman? Masukkan saat mendaftar untuk aktivasi hadiah nanti.' },
          { title: 'Berikan izin lokasi', desc: 'Diperlukan agar aplikasi bisa menyarankan alamat & menghitung jarak layanan secara akurat.' },
          { title: 'Lengkapi profil', desc: 'Nama, nomor telepon, dan alamat wajib diisi (khusus akun Google yang baru pertama kali masuk) sebelum dapat memesan.' },
        ] },
      ],
    },
    {
      title: 'Menjelajahi Layanan',
      image: { src: 'images/hifi/p3.png', caption: 'P3 — Beranda', variant: 'phone' },
      blocks: [
        { type: 'paragraph', text: 'Beranda menampilkan katalog layanan, promo berjalan, dan pesanan aktif Anda dalam satu tampilan.' },
        { type: 'featureGrid', items: [
          { title: 'Katalog Lengkap', desc: 'Ketuk "Lihat Semua Layanan" untuk menjelajah berdasarkan kategori (rumah, umum, dsb).' },
          { title: 'Detail Layanan', desc: 'Setiap layanan menampilkan deskripsi, satuan harga, dan struktur harga (paket/per m²/mulai dari).' },
          { title: 'Banner Promo', desc: 'Ketuk banner di beranda untuk melihat detail promo dan tautan terkait.' },
          { title: 'Pesanan Aktif', desc: 'Kartu pesanan aktif muncul otomatis di beranda — ketuk untuk melacak progresnya.' },
        ] },
      ],
    },
    {
      title: 'Membuat Pesanan',
      image: { src: 'images/hifi/p5.png', caption: 'P5 — Form Pemesanan', variant: 'phone' },
      pairCount: 2,
      blocks: [
        { type: 'paragraph', text: 'Form pemesanan menyesuaikan skema harga masing-masing layanan. Tiga skema harga yang mungkin Anda temui:' },
        { type: 'featureGrid', items: [
          { title: 'Per Luas', desc: 'Pilih jenis area (mis. rumput ringan/tinggi) lalu masukkan luas dalam m².' },
          { title: 'Paket', desc: 'Pilih paket & durasi jam, tambah jam ekstra atau add-on bila perlu.' },
          { title: 'Mulai Dari', desc: 'Harga per unit dikalikan jumlah/kuantitas yang Anda pilih.' },
        ] },
        { type: 'steps', items: [
          { title: 'Pilih jadwal', desc: 'Tanggal & jam kedatangan kru. Slot yang penuh (kapasitas kru habis) otomatis dinonaktifkan.' },
          { title: 'Tentukan lokasi', desc: 'Pilih titik di peta atau gunakan "Lokasi Saya" — alamat terisi otomatis (reverse-geocoding), atau pilih dari alamat tersimpan.' },
          { title: 'Tinjau rincian tagihan', desc: 'Subtotal, potongan voucher (jika ada), dan total akhir dihitung ulang oleh server — angka yang Anda lihat selalu akurat.' },
          { title: 'Lanjut ke pembayaran', desc: 'Slot jadwal baru dikunci saat Anda menekan bayar — draf yang ditinggalkan tidak menyandera jadwal orang lain.' },
        ] },
        { type: 'callout', kind: 'info', text: 'Jika layanan yang Anda pilih sedang tidak punya kru aktif tersedia, slot jadwalnya otomatis terkunci dan tidak bisa dipesan sampai ada kru yang aktif kembali.' },
      ],
    },
    {
      title: 'Pembayaran',
      image: { src: 'images/hifi/p7.png', caption: 'P7 — Form Pembayaran', variant: 'phone' },
      pairCount: 1,
      blocks: [
        { type: 'paragraph', text: 'Tiga metode tersedia — admin dapat mengaktifkan/menonaktifkan salah satunya.' },
        { type: 'featureGrid', items: [
          { title: 'Transfer Bank', desc: 'Transfer ke rekening resmi, lalu unggah bukti transfer untuk diverifikasi admin.' },
          { title: 'QRIS', desc: 'Pindai kode QRIS yang tersedia — unggah bukti pembayaran setelahnya.' },
          { title: 'Tunai', desc: 'Bayar langsung ke kru saat pekerjaan selesai — pesanan tetap diproses tanpa unggah bukti.' },
        ] },
        { type: 'paragraph', text: 'Untuk transfer/QRIS: setelah bukti diunggah, status pesanan menjadi "Menunggu Verifikasi" hingga admin memeriksanya. Jika ditolak (mis. bukti tidak jelas), Anda dapat mengunggah ulang dari halaman Riwayat.' },
        { type: 'callout', kind: 'tip', text: 'Beberapa metode pembayaran mungkin diproses otomatis melalui payment gateway (VA/QRIS dinamis) — jika tersedia, status akan terverifikasi otomatis begitu pembayaran diterima, tanpa perlu mengunggah bukti manual.' },
      ],
    },
    {
      title: 'Melacak Pesanan',
      image: { src: 'images/hifi/p8.png', caption: 'P8 — Lacak Pesanan', variant: 'phone' },
      blocks: [
        { type: 'paragraph', text: 'Halaman Lacak Pesanan menampilkan peta dengan penanda posisi kru, status pesanan terkini (Ditugaskan -> Dalam Perjalanan -> Diproses -> Selesai), dan tombol cepat untuk menghubungi kru via chat atau CS via WhatsApp. Anda dapat membatalkan pesanan selama kru belum ditugaskan.' },
      ],
    },
    {
      title: 'Riwayat & Ulasan',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Semua transaksi tersimpan di halaman Riwayat, dapat difilter per status (Semua/Menunggu/Selesai/Dibatalkan). Setelah pesanan berstatus Selesai, beri ulasan bintang 1–5 beserta komentar — rating ini otomatis memperbarui skor rata-rata kru yang mengerjakan pesanan Anda.' },
      ],
    },
    {
      title: 'Voucher & Kode Referal',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Masukkan kode voucher saat meninjau rincian tagihan untuk mendapatkan potongan persen atau nominal tetap. Beberapa voucher memiliki syarat: minimal belanja, masa berlaku, kuota terbatas, atau khusus pelanggan baru.' },
        { type: 'callout', kind: 'tip', text: 'Kode referal Anda sendiri ada di halaman Profil (dapat disalin dengan sekali ketuk). Ajak teman mendaftar memakai kode itu — begitu pesanan pertama mereka selesai, Anda otomatis mendapat voucher hadiah.' },
      ],
    },
    {
      title: 'Chat & Asisten AI',
      image: null,
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Chat dengan Kru', desc: 'Setelah kru ditugaskan, ngobrol langsung soal detail pekerjaan dari halaman pesanan.' },
          { title: 'Asisten AI (CS)', desc: 'Tanya jam operasional, harga layanan, atau status pesanan Anda ke asisten cerdas 24 jam.' },
        ] },
      ],
    },
    {
      title: 'Notifikasi',
      image: { src: 'images/hifi/p12.png', caption: 'P12 — Notifikasi', variant: 'phone' },
      blocks: [
        { type: 'paragraph', text: 'Setiap perubahan status penting (terverifikasi, ditugaskan, dalam perjalanan, selesai) mengirim notifikasi push ke ponsel Anda dan tercatat di halaman Notifikasi — ketuk untuk langsung membuka pesanan terkait.' },
      ],
    },
    {
      title: 'Profil & Akun',
      image: { src: 'images/hifi/p11.png', caption: 'P11 — Profil', variant: 'phone' },
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Edit Profil', desc: 'Ubah nama, telepon, alamat, dan foto profil kapan saja.' },
          { title: 'Alamat Tersimpan', desc: 'Simpan beberapa alamat berlabel untuk dipilih cepat saat memesan.' },
          { title: 'Ubah Kata Sandi', desc: 'Perbarui kata sandi akun secara berkala demi keamanan.' },
          { title: 'Bantuan', desc: 'Akses FAQ, kontak CS, dan Asisten AI dari satu halaman.' },
        ] },
      ],
    },
  ],
};

export const KRU = {
  eyebrow: 'Portal Kru',
  title: 'Panduan Kru',
  description: 'Terima tugas, navigasi ke lokasi pelanggan, laporkan hasil kerja, dan kelola pencairan upah — semua dari satu aplikasi kerja harian Anda.',
  sections: [
    {
      title: 'Memulai',
      image: { src: 'images/hifi/k1.png', caption: 'K1 — Login Kru', variant: 'phone' },
      // pairCount excludes the callout from the image-paired column — a
      // callout() nested inside withScreen's text column, itself inside the
      // keepTogether wrapper, triggers a pdfmake column-width bug that
      // shoves the image off the page edge. Steps are safe to pair.
      pairCount: 1,
      blocks: [
        { type: 'steps', items: [
          { title: 'Masuk dengan akun dari admin', desc: 'Gunakan email & kata sandi awal yang diberikan admin saat pendaftaran.' },
          { title: 'Selesaikan onboarding', desc: 'Layar pengenalan singkat khusus kru (cara terima tugas, laporan kerja, setoran).' },
          { title: 'Berikan izin Lokasi & Kamera', desc: 'Lokasi untuk navigasi & status "online", Kamera untuk foto laporan kerja sebelum/sesudah.' },
        ] },
        { type: 'callout', kind: 'info', text: 'Akun kru tidak bisa didaftarkan sendiri — dibuat oleh admin melalui Panel Admin. Hubungi kantor Tuntaskilat untuk aktivasi akun.' },
      ],
    },
    {
      title: 'Daftar Tugas',
      image: { src: 'images/hifi/k2.png', caption: 'K2 — Daftar Penugasan', variant: 'phone' },
      pairCount: 1,
      blocks: [
        { type: 'paragraph', text: 'Halaman utama menampilkan daftar penugasan dengan filter Semua / Aktif / Terjadwal / Selesai. Saat admin menugaskan Anda ke sebuah pesanan, notifikasi push langsung masuk beserta pengingat otomatis sekitar 2 jam sebelum jadwal.' },
        { type: 'callout', kind: 'tip', text: 'Untuk pesanan yang dibayar tunai, admin hanya bisa menugaskan Anda jika saldo setoran tunai Anda masih di bawah batas nunggak (default Rp200.000). Setor rutin agar tetap bisa menerima tugas tunai baru.' },
      ],
    },
    {
      title: 'Navigasi & Detail Tugas',
      image: { src: 'images/hifi/k3.png', caption: 'K3 — Detail Penugasan', variant: 'phone' },
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Rute Real-Time', desc: 'Peta menampilkan rute jalan nyata dari posisi Anda ke lokasi pelanggan.' },
          { title: 'Info Lengkap', desc: 'Nama pelanggan, alamat, catatan tambahan, dan detail layanan yang dipesan.' },
          { title: 'Kontak Pelanggan', desc: 'Chat langsung atau telepon via WhatsApp bila perlu konfirmasi di lapangan.' },
        ] },
        { type: 'paragraph', text: 'Perbarui status pekerjaan secara berurutan: Ditugaskan -> Dalam Perjalanan -> Diproses -> Selesai. Status tidak bisa dilompati — pastikan tiap tahap ditandai sesuai kondisi sebenarnya di lapangan.' },
      ],
    },
    {
      title: 'Laporan Kerja',
      image: { src: 'images/hifi/k4.png', caption: 'K4 — Form Laporan Kerja', variant: 'phone' },
      pairCount: 1,
      blocks: [
        { type: 'paragraph', text: 'Sebelum menandai pesanan selesai, unggah minimal satu foto sebelum dan sesudah pengerjaan. Ini jadi bukti kualitas kerja sekaligus dasar bila ada keluhan/banding dari pelanggan.' },
        { type: 'callout', kind: 'warning', text: 'Upah (payout) untuk pesanan dihitung otomatis oleh sistem begitu status berubah menjadi Selesai — pastikan laporan diunggah dengan benar karena data ini bersifat final.' },
      ],
    },
    {
      title: 'Setoran Tunai',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Untuk pesanan berbayar tunai, Anda menerima uang penuh dari pelanggan di lokasi — namun komisi platform dari transaksi tersebut tetap menjadi tanggungan yang harus disetor ke kantor. Saldo yang perlu disetor terlihat otomatis begitu pesanan tunai selesai.' },
        { type: 'steps', items: [
          { title: 'Selesaikan pesanan tunai', desc: 'Komisi platform otomatis tercatat sebagai saldo yang harus Anda setor.' },
          { title: 'Datang ke kantor / temui admin', desc: 'Admin mencatat setoran Anda langsung di sistem — riwayat setoran tersimpan permanen.' },
          { title: 'Pantau batas nunggak', desc: 'Jika saldo belum disetor melebihi batas, Anda tidak bisa menerima tugas tunai baru sampai melunasi.' },
        ] },
      ],
    },
    {
      title: 'Rekening Pencairan',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Simpan detail rekening bank atau e-wallet Anda di halaman Profil agar admin dapat mencairkan upah (payout) hasil kerja non-tunai Anda dengan lancar.' },
      ],
    },
    {
      title: 'Riwayat & Rating',
      image: null,
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Riwayat Tugas', desc: 'Semua pesanan yang pernah Anda kerjakan, dapat difilter per periode.' },
          { title: 'Rating Rata-Rata', desc: 'Skor 1–5 dari ulasan pelanggan, dihitung ulang otomatis tiap ada ulasan baru.' },
        ] },
      ],
    },
    {
      title: 'Chat dengan Pelanggan',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Gunakan fitur chat untuk mengonfirmasi detail sebelum tiba di lokasi, atau menjawab pertanyaan pelanggan seputar pekerjaan yang sedang berlangsung.' },
      ],
    },
    {
      title: 'Catatan Penting',
      image: null,
      blocks: [
        { type: 'callout', kind: 'warning', text: 'Akun kru yang dinonaktifkan admin (status Nonaktif/Diberhentikan) tidak bisa lagi menerima tugas baru. Hubungi admin bila akun Anda bermasalah.' },
      ],
    },
  ],
};

export const ADMIN = {
  eyebrow: 'Panel Admin (Web)',
  title: 'Panduan Admin',
  description: 'Kelola seluruh operasional Tuntaskilat dari satu panel web — pesanan, layanan, kru, keuangan, hingga konfigurasi bisnis.',
  sections: [
    {
      title: 'Masuk & Keamanan',
      image: { src: 'images/hifi/a1.png', caption: 'A1 — Login Admin', variant: 'admin' },
      blocks: [
        { type: 'paragraph', text: 'Panel Admin diakses lewat browser (desktop). Login memerlukan email & kata sandi; jika Autentikasi Dua Faktor (2FA) diaktifkan, Anda juga perlu memasukkan kode 6 digit dari aplikasi authenticator (Google Authenticator, dsb).' },
      ],
    },
    {
      title: 'Dashboard',
      image: { src: 'images/hifi/a2.png', caption: 'A2 — Dashboard', variant: 'admin' },
      blocks: [
        { type: 'paragraph', text: 'Ringkasan performa bisnis dalam satu layar.' },
        { type: 'featureGrid', items: [
          { title: 'KPI Utama', desc: 'Total pesanan, omzet, dan metrik kunci lain diperbarui real-time.' },
          { title: 'Grafik Pendapatan', desc: 'Tren pendapatan 7 hari terakhir dalam bentuk grafik.' },
          { title: 'Sebaran Status', desc: 'Diagram donat menunjukkan proporsi pesanan per status, berwarna per kategori.' },
          { title: 'Transaksi Terbaru', desc: 'Daftar transaksi terakhir untuk pemantauan cepat.' },
        ] },
      ],
    },
    {
      title: 'Kelola Pesanan',
      image: { src: 'images/hifi/a3.png', caption: 'A3 — Kelola Pesanan', variant: 'admin' },
      pairCount: 2,
      blocks: [
        { type: 'paragraph', text: 'Verifikasi pembayaran, tugaskan kru, dan pantau seluruh siklus pesanan.' },
        { type: 'steps', items: [
          { title: 'Verifikasi pembayaran', desc: 'Periksa bukti transfer/QRIS yang diunggah pelanggan, terima atau tolak dengan alasan.' },
          { title: 'Tugaskan kru', desc: 'Sistem merekomendasikan kru yang cocok (keahlian sesuai layanan & tersedia); Anda bisa menugaskan 1 atau beberapa kru (worker + helper) sekaligus.' },
          { title: 'Pantau progres', desc: 'Filter pesanan per status untuk menindaklanjuti yang butuh perhatian.' },
        ] },
        { type: 'callout', kind: 'info', text: 'Pesanan yang terverifikasi namun tidak kunjung mendapat kru dalam 24 jam akan dibatalkan otomatis oleh sistem, dan pelanggan diberi tahu — kuota jadwalnya juga otomatis dikembalikan.' },
      ],
    },
    {
      title: 'Kelola Layanan',
      image: { src: 'images/hifi/a4.png', caption: 'A4 — Kelola Layanan', variant: 'admin' },
      blocks: [
        { type: 'paragraph', text: 'Tambah/ubah layanan lengkap dengan struktur harga dinamis: tarif per m² (dengan beberapa tingkatan/tier), paket (durasi + tambah jam + add-on), atau harga mulai-dari per unit. Kapasitas slot per jam untuk sebuah layanan dihitung otomatis dari jumlah kru aktif yang memiliki keahlian terkait — tidak perlu diatur manual.' },
      ],
    },
    {
      title: 'Kelola Kru',
      image: { src: 'images/hifi/a5.png', caption: 'A5 — Kelola Kru', variant: 'admin' },
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Buat Akun Kru', desc: 'Admin membuat akun kru baru langsung dari panel — tidak mengganggu sesi login admin yang aktif.' },
          { title: 'Keahlian & Tipe', desc: 'Tandai keahlian kru per kategori layanan, dan tipe hubungan kerja (kru tetap/mitra/vendor).' },
          { title: 'Status Kepegawaian', desc: 'Aktif, Nonaktif, atau Diberhentikan — hanya kru Aktif yang bisa ditugaskan.' },
        ] },
      ],
    },
    {
      title: 'Kelola Voucher',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Buat voucher persen atau nominal tetap dengan syarat opsional: minimal belanja, kuota, masa berlaku, khusus pelanggan baru, dan kunci klaim satu-per-nomor-telepon (mencegah trik akun baru-baru terus untuk klaim ulang).' },
      ],
    },
    {
      title: 'Setoran Tunai',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Lihat saldo kas yang wajib disetor tiap kru (dari komisi pesanan tunai yang mereka pegang), tandai kru yang menunggak melewati batas, dan catat setoran yang diterima — riwayat setoran tersimpan sebagai jejak audit.' },
      ],
    },
    {
      title: 'Kelola Klien',
      image: null,
      blocks: [
        { type: 'paragraph', text: 'Lihat daftar pelanggan beserta jumlah pesanan, total belanja, dan tanggal transaksi terakhir — diurutkan dari yang paling loyal. Halaman ini juga menampilkan keluhan/banding yang perlu ditinjau admin.' },
      ],
    },
    {
      title: 'Pantau Operasional',
      image: null,
      blocks: [
        { type: 'featureGrid', items: [
          { title: 'Peta Lokasi Kru', desc: 'Pantau posisi kru yang sedang dalam perjalanan secara real-time di peta.' },
          { title: 'Percakapan Kru–Klien', desc: 'Tinjau chat antara kru dan pelanggan untuk keperluan kendali mutu, tanpa ikut membalas.' },
        ] },
      ],
    },
    {
      title: 'Pengaturan',
      image: { src: 'images/hifi/a6.png', caption: 'A6 — Pengaturan', variant: 'admin' },
      blocks: [
        { type: 'paragraph', text: 'Pusat konfigurasi bisnis dan keamanan panel.' },
        { type: 'featureGrid', items: [
          { title: 'Biaya & Komisi', desc: 'Atur persentase komisi platform secara global, atau override per layanan tertentu.' },
          { title: 'Rekening & Pembayaran', desc: 'Kelola rekening bank/QRIS untuk tampil ke pelanggan, dan aktifkan/nonaktifkan tiap metode bayar.' },
          { title: 'Mode Aplikasi', desc: 'Aktifkan mode pemeliharaan atau paksa update versi minimum untuk seluruh pengguna.' },
          { title: 'Asisten AI', desc: 'Konfigurasi penyedia & kunci API untuk fitur AI (CS otomatis & analisis bisnis).' },
          { title: 'Autentikasi 2FA', desc: 'Aktifkan verifikasi dua langkah untuk akun admin Anda sendiri.' },
          { title: 'Manajemen Tim Admin', desc: 'Undang admin baru atau nonaktifkan akses admin lain.' },
        ] },
      ],
    },
  ],
};
