import {
  LayoutDashboard,
  Receipt,
  Grid3x3,
  Users,
  Ticket,
  Wallet,
  UsersRound,
  Radar,
  Settings,
  ShieldCheck,
  Percent,
  CreditCard,
  KeyRound,
  UserPlus,
  Power,
  Bot,
} from 'lucide-react'
import { GuidePage, Section, Steps, FeatureGrid, Callout } from '../components/GuideKit'

const TOC = [
  { id: 'masuk', label: 'Masuk & Keamanan' },
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'pesanan', label: 'Kelola Pesanan' },
  { id: 'layanan', label: 'Kelola Layanan' },
  { id: 'kru', label: 'Kelola Kru' },
  { id: 'voucher', label: 'Kelola Voucher' },
  { id: 'setoran', label: 'Setoran Tunai' },
  { id: 'klien', label: 'Kelola Klien' },
  { id: 'pantau', label: 'Pantau Operasional' },
  { id: 'pengaturan', label: 'Pengaturan' },
]

export default function Admin() {
  return (
    <GuidePage
      role="admin"
      eyebrow="Panel Admin (Web)"
      title="Panduan Admin"
      description="Kelola seluruh operasional Tuntaskilat dari satu panel web — pesanan, layanan, kru, keuangan, hingga konfigurasi bisnis."
      toc={TOC}
    >
      <Section id="masuk" icon={<ShieldCheck size={18} />} title="Masuk & Keamanan">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Panel Admin diakses lewat browser (desktop). Login memerlukan email
          & kata sandi; jika Autentikasi Dua Faktor (2FA) diaktifkan, Anda
          juga perlu memasukkan kode 6 digit dari aplikasi authenticator
          (Google Authenticator, dsb).
        </p>
      </Section>

      <Section
        id="dashboard"
        icon={<LayoutDashboard size={18} />}
        title="Dashboard"
        subtitle="Ringkasan performa bisnis dalam satu layar."
      >
        <FeatureGrid
          items={[
            { icon: <LayoutDashboard size={17} />, title: 'KPI Utama', desc: 'Total pesanan, omzet, dan metrik kunci lain diperbarui real-time.' },
            { icon: <Receipt size={17} />, title: 'Grafik Pendapatan', desc: 'Tren pendapatan 7 hari terakhir dalam bentuk grafik.' },
            { icon: <Grid3x3 size={17} />, title: 'Sebaran Status', desc: 'Diagram donat menunjukkan proporsi pesanan per status, berwarna per kategori.' },
            { icon: <Receipt size={17} />, title: 'Transaksi Terbaru', desc: 'Daftar transaksi terakhir untuk pemantauan cepat.' },
          ]}
        />
      </Section>

      <Section
        id="pesanan"
        icon={<Receipt size={18} />}
        title="Kelola Pesanan"
        subtitle="Verifikasi pembayaran, tugaskan kru, dan pantau seluruh siklus pesanan."
      >
        <Steps
          items={[
            { title: 'Verifikasi pembayaran', desc: 'Periksa bukti transfer/QRIS yang diunggah pelanggan, terima atau tolak dengan alasan.' },
            { title: 'Tugaskan kru', desc: 'Sistem merekomendasikan kru yang cocok (keahlian sesuai layanan & tersedia); Anda bisa menugaskan 1 atau beberapa kru (worker + helper) sekaligus.' },
            { title: 'Pantau progres', desc: 'Filter pesanan per status untuk menindaklanjuti yang butuh perhatian.' },
          ]}
        />
        <Callout type="info">
          Pesanan yang terverifikasi namun tidak kunjung mendapat kru dalam
          24 jam akan dibatalkan otomatis oleh sistem, dan pelanggan diberi
          tahu — kuota jadwalnya juga otomatis dikembalikan.
        </Callout>
      </Section>

      <Section id="layanan" icon={<Grid3x3 size={18} />} title="Kelola Layanan">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Tambah/ubah layanan lengkap dengan struktur harga dinamis: tarif
          per m² (dengan beberapa tingkatan/tier), paket (durasi + tambah jam
          + add-on), atau harga mulai-dari per unit. Kapasitas slot per jam
          untuk sebuah layanan dihitung otomatis dari jumlah kru aktif yang
          memiliki keahlian terkait — tidak perlu diatur manual.
        </p>
      </Section>

      <Section id="kru" icon={<Users size={18} />} title="Kelola Kru">
        <FeatureGrid
          items={[
            { icon: <UserPlus size={17} />, title: 'Buat Akun Kru', desc: 'Admin membuat akun kru baru langsung dari panel — tidak mengganggu sesi login admin yang aktif.' },
            { icon: <Users size={17} />, title: 'Keahlian & Tipe', desc: 'Tandai keahlian kru per kategori layanan, dan tipe hubungan kerja (kru tetap/mitra/vendor).' },
            { icon: <Power size={17} />, title: 'Status Kepegawaian', desc: 'Aktif, Nonaktif, atau Diberhentikan — hanya kru Aktif yang bisa ditugaskan.' },
          ]}
        />
      </Section>

      <Section id="voucher" icon={<Ticket size={18} />} title="Kelola Voucher">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Buat voucher persen atau nominal tetap dengan syarat opsional:
          minimal belanja, kuota, masa berlaku, khusus pelanggan baru, dan
          kunci klaim satu-per-nomor-telepon (mencegah trik akun baru-baru
          terus untuk klaim ulang).
        </p>
      </Section>

      <Section id="setoran" icon={<Wallet size={18} />} title="Setoran Tunai">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Lihat saldo kas yang wajib disetor tiap kru (dari komisi pesanan
          tunai yang mereka pegang), tandai kru yang menunggak melewati batas,
          dan catat setoran yang diterima — riwayat setoran tersimpan sebagai
          jejak audit.
        </p>
      </Section>

      <Section id="klien" icon={<UsersRound size={18} />} title="Kelola Klien">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Lihat daftar pelanggan beserta jumlah pesanan, total belanja, dan
          tanggal transaksi terakhir — diurutkan dari yang paling loyal.
          Halaman ini juga menampilkan keluhan/banding yang perlu ditinjau
          admin.
        </p>
      </Section>

      <Section id="pantau" icon={<Radar size={18} />} title="Pantau Operasional">
        <FeatureGrid
          items={[
            { icon: <Radar size={17} />, title: 'Peta Lokasi Kru', desc: 'Pantau posisi kru yang sedang dalam perjalanan secara real-time di peta.' },
            { icon: <Bot size={17} />, title: 'Percakapan Kru–Klien', desc: 'Tinjau chat antara kru dan pelanggan untuk keperluan kendali mutu, tanpa ikut membalas.' },
          ]}
        />
      </Section>

      <Section
        id="pengaturan"
        icon={<Settings size={18} />}
        title="Pengaturan"
        subtitle="Pusat konfigurasi bisnis dan keamanan panel."
      >
        <FeatureGrid
          items={[
            { icon: <Percent size={17} />, title: 'Biaya & Komisi', desc: 'Atur persentase komisi platform secara global, atau override per layanan tertentu.' },
            { icon: <CreditCard size={17} />, title: 'Rekening & Pembayaran', desc: 'Kelola rekening bank/QRIS untuk tampil ke pelanggan, dan aktifkan/nonaktifkan tiap metode bayar.' },
            { icon: <Power size={17} />, title: 'Mode Aplikasi', desc: 'Aktifkan mode pemeliharaan atau paksa update versi minimum untuk seluruh pengguna.' },
            { icon: <Bot size={17} />, title: 'Asisten AI', desc: 'Konfigurasi penyedia & kunci API untuk fitur AI (CS otomatis & analisis bisnis).' },
            { icon: <KeyRound size={17} />, title: 'Autentikasi 2FA', desc: 'Aktifkan verifikasi dua langkah untuk akun admin Anda sendiri.' },
            { icon: <UserPlus size={17} />, title: 'Manajemen Tim Admin', desc: 'Undang admin baru atau nonaktifkan akses admin lain.' },
          ]}
        />
      </Section>
    </GuidePage>
  )
}
