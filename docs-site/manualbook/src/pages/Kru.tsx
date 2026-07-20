import {
  LogIn,
  ListChecks,
  Navigation,
  Camera,
  History,
  Wallet,
  Landmark,
  MessageCircle,
  Star,
  ShieldAlert,
} from 'lucide-react'
import { GuidePage, Section, Steps, FeatureGrid, Callout, ScreenFigure, WithScreen } from '../components/GuideKit'

const TOC = [
  { id: 'memulai', label: 'Memulai' },
  { id: 'tugas', label: 'Daftar Tugas' },
  { id: 'navigasi', label: 'Navigasi & Detail' },
  { id: 'laporan', label: 'Laporan Kerja' },
  { id: 'setoran', label: 'Setoran Tunai' },
  { id: 'rekening', label: 'Rekening Pencairan' },
  { id: 'riwayat', label: 'Riwayat & Rating' },
  { id: 'chat', label: 'Chat dengan Pelanggan' },
  { id: 'keamanan', label: 'Catatan Penting' },
]

export default function Kru() {
  return (
    <GuidePage
      role="kru"
      eyebrow="Portal Kru"
      title="Panduan Kru"
      description="Terima tugas, navigasi ke lokasi pelanggan, laporkan hasil kerja, dan kelola pencairan upah — semua dari satu aplikasi kerja harian Anda."
      toc={TOC}
    >
      <Section id="memulai" icon={<LogIn size={18} />} title="Memulai">
        <WithScreen screen={<ScreenFigure src="/hifi/k1.webp" caption="K1 — Login Kru" />}>
          <Callout type="info">
            Akun kru <strong>tidak bisa didaftarkan sendiri</strong> — dibuat oleh
            admin melalui Panel Admin. Hubungi kantor Tuntaskilat untuk aktivasi akun.
          </Callout>
          <div className="mt-5">
            <Steps
              items={[
                { title: 'Masuk dengan akun dari admin', desc: 'Gunakan email & kata sandi awal yang diberikan admin saat pendaftaran.' },
                { title: 'Selesaikan onboarding', desc: 'Layar pengenalan singkat khusus kru (cara terima tugas, laporan kerja, setoran).' },
                { title: 'Berikan izin Lokasi & Kamera', desc: 'Lokasi untuk navigasi & status "online", Kamera untuk foto laporan kerja sebelum/sesudah.' },
              ]}
            />
          </div>
        </WithScreen>
      </Section>

      <Section id="tugas" icon={<ListChecks size={18} />} title="Daftar Tugas">
        <WithScreen screen={<ScreenFigure src="/hifi/k2.webp" caption="K2 — Daftar Penugasan" />}>
          <p className="text-[14.5px] leading-relaxed text-text-secondary">
            Halaman utama menampilkan daftar penugasan dengan filter Semua /
            Aktif / Terjadwal / Selesai. Saat admin menugaskan Anda ke sebuah
            pesanan, notifikasi push langsung masuk beserta pengingat otomatis
            sekitar 2 jam sebelum jadwal.
          </p>
          <Callout type="tip">
            Untuk pesanan yang dibayar <strong>tunai</strong>, admin hanya bisa
            menugaskan Anda jika saldo setoran tunai Anda masih di bawah batas
            nunggak (default Rp200.000). Setor rutin agar tetap bisa menerima
            tugas tunai baru.
          </Callout>
        </WithScreen>
      </Section>

      <Section id="navigasi" icon={<Navigation size={18} />} title="Navigasi & Detail Tugas">
        <WithScreen screen={<ScreenFigure src="/hifi/k3.webp" caption="K3 — Detail Penugasan" />}>
          <FeatureGrid
            items={[
              { icon: <Navigation size={17} />, title: 'Rute Real-Time', desc: 'Peta menampilkan rute jalan nyata dari posisi Anda ke lokasi pelanggan.' },
              { icon: <ListChecks size={17} />, title: 'Info Lengkap', desc: 'Nama pelanggan, alamat, catatan tambahan, dan detail layanan yang dipesan.' },
              { icon: <MessageCircle size={17} />, title: 'Kontak Pelanggan', desc: 'Chat langsung atau telepon via WhatsApp bila perlu konfirmasi di lapangan.' },
            ]}
          />
          <p className="mt-4 text-[14.5px] leading-relaxed text-text-secondary">
            Perbarui status pekerjaan secara berurutan: Ditugaskan → Dalam
            Perjalanan → Diproses → Selesai. Status tidak bisa dilompati —
            pastikan tiap tahap ditandai sesuai kondisi sebenarnya di lapangan.
          </p>
        </WithScreen>
      </Section>

      <Section id="laporan" icon={<Camera size={18} />} title="Laporan Kerja">
        <WithScreen screen={<ScreenFigure src="/hifi/k4.webp" caption="K4 — Form Laporan Kerja" />}>
          <p className="text-[14.5px] leading-relaxed text-text-secondary">
            Sebelum menandai pesanan selesai, unggah minimal satu foto{' '}
            <strong className="text-ink-soft">sebelum</strong> dan{' '}
            <strong className="text-ink-soft">sesudah</strong> pengerjaan. Ini
            jadi bukti kualitas kerja sekaligus dasar bila ada keluhan/banding
            dari pelanggan.
          </p>
          <Callout type="warning">
            Upah (payout) untuk pesanan dihitung otomatis oleh sistem begitu
            status berubah menjadi Selesai — pastikan laporan diunggah dengan
            benar karena data ini bersifat final.
          </Callout>
        </WithScreen>
      </Section>

      <Section id="setoran" icon={<Wallet size={18} />} title="Setoran Tunai">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Untuk pesanan berbayar tunai, Anda menerima uang penuh dari
          pelanggan di lokasi — namun komisi platform dari transaksi tersebut
          tetap menjadi tanggungan yang harus disetor ke kantor. Saldo yang
          perlu disetor terlihat otomatis begitu pesanan tunai selesai.
        </p>
        <Steps
          items={[
            { title: 'Selesaikan pesanan tunai', desc: 'Komisi platform otomatis tercatat sebagai saldo yang harus Anda setor.' },
            { title: 'Datang ke kantor / temui admin', desc: 'Admin mencatat setoran Anda langsung di sistem — riwayat setoran tersimpan permanen.' },
            { title: 'Pantau batas nunggak', desc: 'Jika saldo belum disetor melebihi batas, Anda tidak bisa menerima tugas tunai baru sampai melunasi.' },
          ]}
        />
      </Section>

      <Section id="rekening" icon={<Landmark size={18} />} title="Rekening Pencairan">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Simpan detail rekening bank atau e-wallet Anda di halaman Profil
          agar admin dapat mencairkan upah (payout) hasil kerja non-tunai
          Anda dengan lancar.
        </p>
      </Section>

      <Section id="riwayat" icon={<History size={18} />} title="Riwayat & Rating">
        <FeatureGrid
          items={[
            { icon: <History size={17} />, title: 'Riwayat Tugas', desc: 'Semua pesanan yang pernah Anda kerjakan, dapat difilter per periode.' },
            { icon: <Star size={17} />, title: 'Rating Rata-Rata', desc: 'Skor 1–5 dari ulasan pelanggan, dihitung ulang otomatis tiap ada ulasan baru.' },
          ]}
        />
      </Section>

      <Section id="chat" icon={<MessageCircle size={18} />} title="Chat dengan Pelanggan">
        <p className="text-[14.5px] leading-relaxed text-text-secondary">
          Gunakan fitur chat untuk mengonfirmasi detail sebelum tiba di
          lokasi, atau menjawab pertanyaan pelanggan seputar pekerjaan yang
          sedang berlangsung.
        </p>
      </Section>

      <Section id="keamanan" icon={<ShieldAlert size={18} />} title="Catatan Penting">
        <Callout type="warning">
          Akun kru yang dinonaktifkan admin (status Nonaktif/Diberhentikan)
          tidak bisa lagi menerima tugas baru. Hubungi admin bila akun Anda
          bermasalah.
        </Callout>
      </Section>
    </GuidePage>
  )
}
