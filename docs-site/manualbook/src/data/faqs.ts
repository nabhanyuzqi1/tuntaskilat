import type { Role } from '../components/GuideKit'

export type FaqItem = { q: string; a: string; role: Role | 'semua' }

export const FAQS: FaqItem[] = [
  {
    role: 'pelanggan',
    q: 'Bagaimana cara membatalkan pesanan?',
    a: 'Buka halaman Lacak Pesanan lalu ketuk "Batalkan". Pembatalan hanya bisa dilakukan sebelum kru ditugaskan ke pesanan Anda.',
  },
  {
    role: 'pelanggan',
    q: 'Kenapa jadwal yang saya pilih tidak bisa dipesan?',
    a: 'Kemungkinan kapasitas kru untuk layanan tersebut pada jam itu sudah penuh, atau layanan sedang tidak punya kru aktif tersedia sama sekali.',
  },
  {
    role: 'pelanggan',
    q: 'Voucher saya ditolak, kenapa?',
    a: 'Periksa syaratnya: mungkin sudah kedaluwarsa, kuota habis, belanja Anda belum memenuhi minimal, voucher khusus pelanggan baru (Anda sudah pernah memesan), atau kode itu sudah pernah dipakai dengan nomor telepon yang sama.',
  },
  {
    role: 'pelanggan',
    q: 'Apakah bisa membayar tunai langsung ke kru?',
    a: 'Bisa, jika metode Tunai diaktifkan admin untuk layanan tersebut. Anda membayar penuh ke kru di lokasi; komisi platform dari transaksi itu menjadi tanggung jawab kru untuk disetor ke kantor.',
  },
  {
    role: 'kru',
    q: 'Kenapa saya tidak bisa menerima tugas pesanan tunai baru?',
    a: 'Saldo komisi tunai Anda yang belum disetor mungkin sudah melewati batas nunggak. Setor ke admin terlebih dahulu untuk kembali bisa menerima tugas tunai.',
  },
  {
    role: 'kru',
    q: 'Kapan upah saya dibayarkan?',
    a: 'Upah dihitung otomatis begitu status pesanan menjadi Selesai (setelah laporan kerja dengan foto sebelum/sesudah diunggah). Pencairan dilakukan admin ke rekening yang Anda daftarkan di Profil.',
  },
  {
    role: 'kru',
    q: 'Bagaimana jika saya mengerjakan pesanan bersama rekan (worker + helper)?',
    a: 'Upah dibagi proporsional berdasarkan peran — worker mendapat porsi penuh, helper mendapat sebagian — dijamin totalnya selalu tepat tanpa kekurangan/kelebihan pembulatan.',
  },
  {
    role: 'admin',
    q: 'Bagaimana cara mengubah persentase komisi platform?',
    a: 'Buka Pengaturan → Biaya & Komisi. Anda bisa mengatur persentase global, atau override khusus untuk layanan tertentu.',
  },
  {
    role: 'admin',
    q: 'Kapan sebaiknya mengaktifkan Mode Pemeliharaan?',
    a: 'Saat melakukan migrasi data besar atau perbaikan darurat yang berisiko jika pengguna tetap bertransaksi. Semua pengguna akan melihat layar pemberitahuan hingga mode dinonaktifkan kembali.',
  },
  {
    role: 'admin',
    q: 'Apa yang terjadi jika saya menonaktifkan akun kru?',
    a: 'Kru berstatus Nonaktif/Diberhentikan tidak akan muncul lagi di daftar rekomendasi penugasan dan tidak bisa menerima tugas baru — riwayat kerja sebelumnya tetap tersimpan.',
  },
  {
    role: 'semua',
    q: 'Apakah data pembayaran saya aman?',
    a: 'Ya. Seluruh perhitungan uang (harga, komisi, upah, potongan voucher) divalidasi ulang di server — aplikasi klien tidak pernah dipercaya untuk menentukan angka akhir.',
  },
]
