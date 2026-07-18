import {
  Rocket,
  LayoutGrid,
  CalendarCheck,
  CreditCard,
  MapPin,
  History,
  Ticket,
  MessageCircle,
  BellRing,
  UserCog,
  ShieldCheck,
  Smartphone,
} from 'lucide-react'
import { GuidePage, Section, Steps, FeatureGrid, Callout } from '../components/GuideKit'

const TOC = [
  { id: 'memulai', label: 'Memulai' },
  { id: 'jelajahi', label: 'Menjelajahi Layanan' },
  { id: 'memesan', label: 'Membuat Pesanan' },
  { id: 'pembayaran', label: 'Pembayaran' },
  { id: 'lacak', label: 'Melacak Pesanan' },
  { id: 'riwayat', label: 'Riwayat & Ulasan' },
  { id: 'voucher', label: 'Voucher & Referal' },
  { id: 'chat', label: 'Chat & Asisten AI' },
  { id: 'notifikasi', label: 'Notifikasi' },
  { id: 'profil', label: 'Profil & Akun' },
]

export default function Pelanggan() {
  return (
    <GuidePage
      role="pelanggan"
      eyebrow="Aplikasi Pelanggan"
      title="Panduan Pelanggan"
      description="Pesan jasa kebersihan profesional dalam hitungan menit — dari memilih layanan, menjadwalkan kru, membayar, hingga melacak pekerjaan secara real-time."
      toc={TOC}
    >
      <Section id="memulai" icon={<Rocket size={18} />} title="Memulai">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Anda bisa mendaftar dengan email & kata sandi, atau langsung
          masuk dengan akun Google. Pengguna baru wajib melengkapi profil
          sebelum dapat memesan layanan.
        </p>
        <div className="mt-5">
          <Steps
            items={[
              {
                title: 'Unduh & buka aplikasi',
                desc: 'Layar pembuka menampilkan pengenalan singkat (onboarding) tentang cara kerja Tuntaskilat.',
              },
              {
                title: 'Daftar atau Masuk',
                desc: 'Gunakan email + kata sandi (minimal 8 karakter), atau tombol "Masuk dengan Google". Punya kode referal dari teman? Masukkan saat mendaftar untuk aktivasi hadiah nanti.',
              },
              {
                title: 'Berikan izin lokasi',
                desc: 'Diperlukan agar aplikasi bisa menyarankan alamat & menghitung jarak layanan secara akurat.',
              },
              {
                title: 'Lengkapi profil',
                desc: 'Nama, nomor telepon, dan alamat wajib diisi (khusus akun Google yang baru pertama kali masuk) sebelum dapat memesan.',
              },
            ]}
          />
        </div>
      </Section>

      <Section
        id="jelajahi"
        icon={<LayoutGrid size={18} />}
        title="Menjelajahi Layanan"
        subtitle="Beranda menampilkan katalog layanan, promo berjalan, dan pesanan aktif Anda dalam satu tampilan."
      >
        <FeatureGrid
          items={[
            {
              icon: <LayoutGrid size={17} />,
              title: 'Katalog Lengkap',
              desc: 'Ketuk "Lihat Semua Layanan" untuk menjelajah berdasarkan kategori (rumah, umum, dsb).',
            },
            {
              icon: <MapPin size={17} />,
              title: 'Detail Layanan',
              desc: 'Setiap layanan menampilkan deskripsi, satuan harga, dan struktur harga (paket/per m²/mulai dari).',
            },
            {
              icon: <BellRing size={17} />,
              title: 'Banner Promo',
              desc: 'Ketuk banner di beranda untuk melihat detail promo dan tautan terkait.',
            },
            {
              icon: <CalendarCheck size={17} />,
              title: 'Pesanan Aktif',
              desc: 'Kartu pesanan aktif muncul otomatis di beranda — ketuk untuk melacak progresnya.',
            },
          ]}
        />
      </Section>

      <Section
        id="memesan"
        icon={<CalendarCheck size={18} />}
        title="Membuat Pesanan"
        subtitle="Form pemesanan menyesuaikan skema harga masing-masing layanan."
      >
        <div className="space-y-4">
          <p className="text-[14.5px] leading-relaxed text-text-secondary">
            Tiga skema harga yang mungkin Anda temui:
          </p>
          <ul className="grid gap-3 sm:grid-cols-3">
            <li className="rounded-xl border border-border bg-white p-4">
              <p className="text-[13px] font-bold text-ink-soft">Per Luas</p>
              <p className="mt-1 text-[12.5px] text-text-secondary">Pilih jenis area (mis. rumput ringan/tinggi) lalu masukkan luas dalam m².</p>
            </li>
            <li className="rounded-xl border border-border bg-white p-4">
              <p className="text-[13px] font-bold text-ink-soft">Paket</p>
              <p className="mt-1 text-[12.5px] text-text-secondary">Pilih paket & durasi jam, tambah jam ekstra atau add-on bila perlu.</p>
            </li>
            <li className="rounded-xl border border-border bg-white p-4">
              <p className="text-[13px] font-bold text-ink-soft">Mulai Dari</p>
              <p className="mt-1 text-[12.5px] text-text-secondary">Harga per unit dikalikan jumlah/kuantitas yang Anda pilih.</p>
            </li>
          </ul>
          <Steps
            items={[
              {
                title: 'Pilih jadwal',
                desc: 'Tanggal & jam kedatangan kru. Slot yang penuh (kapasitas kru habis) otomatis dinonaktifkan.',
              },
              {
                title: 'Tentukan lokasi',
                desc: 'Pilih titik di peta atau gunakan "Lokasi Saya" — alamat terisi otomatis (reverse-geocoding), atau pilih dari alamat tersimpan.',
              },
              {
                title: 'Tinjau rincian tagihan',
                desc: 'Subtotal, potongan voucher (jika ada), dan total akhir dihitung ulang oleh server — angka yang Anda lihat selalu akurat.',
              },
              {
                title: 'Lanjut ke pembayaran',
                desc: 'Slot jadwal baru dikunci saat Anda menekan bayar — draf yang ditinggalkan tidak menyandera jadwal orang lain.',
              },
            ]}
          />
          <Callout type="info">
            Jika layanan yang Anda pilih sedang tidak punya kru aktif tersedia,
            slot jadwalnya otomatis terkunci dan tidak bisa dipesan sampai ada
            kru yang aktif kembali.
          </Callout>
        </div>
      </Section>

      <Section
        id="pembayaran"
        icon={<CreditCard size={18} />}
        title="Pembayaran"
        subtitle="Tiga metode tersedia — admin dapat mengaktifkan/menonaktifkan salah satunya."
      >
        <FeatureGrid
          items={[
            { icon: <CreditCard size={17} />, title: 'Transfer Bank', desc: 'Transfer ke rekening resmi, lalu unggah bukti transfer untuk diverifikasi admin.' },
            { icon: <Smartphone size={17} />, title: 'QRIS', desc: 'Pindai kode QRIS yang tersedia — unggah bukti pembayaran setelahnya.' },
            { icon: <ShieldCheck size={17} />, title: 'Tunai', desc: 'Bayar langsung ke kru saat pekerjaan selesai — pesanan tetap diproses tanpa unggah bukti.' },
          ]}
        />
        <div className="mt-5 space-y-3">
          <p className="text-[14.5px] leading-relaxed text-text-secondary">
            Untuk transfer/QRIS: setelah bukti diunggah, status pesanan menjadi
            <strong className="text-ink-soft"> "Menunggu Verifikasi"</strong> hingga admin memeriksanya.
            Jika ditolak (mis. bukti tidak jelas), Anda dapat mengunggah ulang
            dari halaman Riwayat.
          </p>
          <Callout type="tip">
            Beberapa metode pembayaran mungkin diproses otomatis melalui
            payment gateway (VA/QRIS dinamis) — jika tersedia, status akan
            terverifikasi otomatis begitu pembayaran diterima, tanpa perlu
            mengunggah bukti manual.
          </Callout>
        </div>
      </Section>

      <Section
        id="lacak"
        icon={<MapPin size={18} />}
        title="Melacak Pesanan"
        subtitle="Pantau posisi kru secara real-time begitu mereka mulai perjalanan."
      >
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Halaman Lacak Pesanan menampilkan peta dengan penanda posisi kru,
          status pesanan terkini (Ditugaskan → Dalam Perjalanan → Diproses →
          Selesai), dan tombol cepat untuk menghubungi kru via chat atau CS
          via WhatsApp. Anda dapat membatalkan pesanan selama kru belum
          ditugaskan.
        </p>
      </Section>

      <Section
        id="riwayat"
        icon={<History size={18} />}
        title="Riwayat & Ulasan"
      >
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Semua transaksi tersimpan di halaman Riwayat, dapat difilter per
          status (Semua/Menunggu/Selesai/Dibatalkan). Setelah pesanan
          berstatus <strong className="text-ink-soft">Selesai</strong>, beri
          ulasan bintang 1–5 beserta komentar — rating ini otomatis
          memperbarui skor rata-rata kru yang mengerjakan pesanan Anda.
        </p>
      </Section>

      <Section
        id="voucher"
        icon={<Ticket size={18} />}
        title="Voucher & Kode Referal"
      >
        <div className="space-y-4">
          <p className="text-[14.5px] leading-relaxed text-text-secondary">
            Masukkan kode voucher saat meninjau rincian tagihan untuk
            mendapatkan potongan persen atau nominal tetap. Beberapa voucher
            memiliki syarat: minimal belanja, masa berlaku, kuota terbatas,
            atau khusus pelanggan baru.
          </p>
          <Callout type="tip">
            Kode referal Anda sendiri ada di halaman Profil (dapat disalin
            dengan sekali ketuk). Ajak teman mendaftar memakai kode itu — begitu
            pesanan pertama mereka selesai, Anda otomatis mendapat voucher hadiah.
          </Callout>
        </div>
      </Section>

      <Section id="chat" icon={<MessageCircle size={18} />} title="Chat & Asisten AI">
        <FeatureGrid
          items={[
            { icon: <MessageCircle size={17} />, title: 'Chat dengan Kru', desc: 'Setelah kru ditugaskan, ngobrol langsung soal detail pekerjaan dari halaman pesanan.' },
            { icon: <Rocket size={17} />, title: 'Asisten AI (CS)', desc: 'Tanya jam operasional, harga layanan, atau status pesanan Anda ke asisten cerdas 24 jam.' },
          ]}
        />
      </Section>

      <Section id="notifikasi" icon={<BellRing size={18} />} title="Notifikasi">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Setiap perubahan status penting (terverifikasi, ditugaskan, dalam
          perjalanan, selesai) mengirim notifikasi push ke ponsel Anda dan
          tercatat di halaman Notifikasi — ketuk untuk langsung membuka
          pesanan terkait.
        </p>
      </Section>

      <Section id="profil" icon={<UserCog size={18} />} title="Profil & Akun">
        <FeatureGrid
          items={[
            { icon: <UserCog size={17} />, title: 'Edit Profil', desc: 'Ubah nama, telepon, alamat, dan foto profil kapan saja.' },
            { icon: <MapPin size={17} />, title: 'Alamat Tersimpan', desc: 'Simpan beberapa alamat berlabel untuk dipilih cepat saat memesan.' },
            { icon: <ShieldCheck size={17} />, title: 'Ubah Kata Sandi', desc: 'Perbarui kata sandi akun secara berkala demi keamanan.' },
            { icon: <MessageCircle size={17} />, title: 'Bantuan', desc: 'Akses FAQ, kontak CS, dan Asisten AI dari satu halaman.' },
          ]}
        />
      </Section>
    </GuidePage>
  )
}
