import { ShoppingBag, HardHat, ShieldCheck, HelpCircle } from 'lucide-react'

const CHAPTERS = [
  {
    no: '01',
    icon: ShoppingBag,
    title: 'Panduan Pelanggan',
    desc: 'Memulai, menjelajahi layanan, membuat pesanan, pembayaran, melacak pesanan, riwayat & ulasan, voucher & referal, chat & asisten AI, notifikasi, profil & akun.',
  },
  {
    no: '02',
    icon: HardHat,
    title: 'Panduan Kru',
    desc: 'Memulai, daftar tugas, navigasi & detail tugas, laporan kerja, setoran tunai, rekening pencairan, riwayat & rating, chat dengan pelanggan.',
  },
  {
    no: '03',
    icon: ShieldCheck,
    title: 'Panduan Admin',
    desc: 'Masuk & keamanan, dashboard, kelola pesanan/layanan/kru/voucher, setoran tunai, kelola klien, pantau operasional, pengaturan.',
  },
  {
    no: '04',
    icon: HelpCircle,
    title: 'Pertanyaan Umum (FAQ)',
    desc: 'Jawaban cepat untuk pertanyaan yang paling sering diajukan Pelanggan, Kru, dan Admin.',
  },
]

export default function PrintToc() {
  return (
    <section className="print-toc flex h-[194mm] w-[285mm] flex-col justify-center bg-white px-24 py-16 print:h-[194mm] print:w-[285mm]">
      <p className="text-[12px] font-bold uppercase tracking-[0.3em] text-primary">
        Daftar Isi
      </p>
      <h1 className="mt-2 text-[32px] font-extrabold tracking-tight text-ink-soft">
        Isi Buku Panduan
      </h1>

      <div className="mt-10 grid grid-cols-2 gap-x-16 gap-y-8">
        {CHAPTERS.map((ch) => (
          <div key={ch.no} className="flex gap-4">
            <span className="text-[28px] font-extrabold text-primary/25">{ch.no}</span>
            <div>
              <div className="flex items-center gap-2">
                <ch.icon size={16} className="text-primary" />
                <h3 className="text-[16px] font-bold text-ink-soft">{ch.title}</h3>
              </div>
              <p className="mt-1.5 text-[12.5px] leading-relaxed text-text-secondary">
                {ch.desc}
              </p>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
