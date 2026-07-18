import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  ArrowRight,
  Sparkles,
  ShoppingBag,
  HardHat,
  ShieldCheck,
  Wallet,
  MapPin,
  Star,
  MessageCircle,
  BellRing,
  ExternalLink,
} from 'lucide-react'
import Reveal from '../components/Reveal'
import { FeatureGrid } from '../components/GuideKit'

const ROLES = [
  {
    to: '/pelanggan',
    icon: ShoppingBag,
    title: 'Pelanggan',
    iconBg: 'bg-role-pelanggan/10',
    iconText: 'text-role-pelanggan',
    dot: 'bg-role-pelanggan',
    desc: 'Pesan layanan kebersihan, lacak kru, bayar, dan beri ulasan — semua dari satu aplikasi.',
    points: ['Pesan dalam hitungan menit', 'Lacak kru secara real-time', 'Voucher & kode referal'],
  },
  {
    to: '/kru',
    icon: HardHat,
    title: 'Kru',
    iconBg: 'bg-role-kru/10',
    iconText: 'text-role-kru',
    dot: 'bg-role-kru',
    desc: 'Terima tugas, navigasi ke lokasi, laporkan hasil kerja, dan kelola setoran tunai.',
    points: ['Notifikasi tugas instan', 'Navigasi & peta langsung', 'Pencairan upah transparan'],
  },
  {
    to: '/admin',
    icon: ShieldCheck,
    title: 'Admin',
    iconBg: 'bg-role-admin/10',
    iconText: 'text-role-admin',
    dot: 'bg-role-admin',
    desc: 'Kelola pesanan, kru, layanan, voucher, komisi, dan pantau operasional dari panel web.',
    points: ['Dashboard performa bisnis', 'Kelola tim & komisi', 'Pantau operasional real-time'],
  },
]

const HIGHLIGHTS = [
  { icon: <MapPin size={18} />, title: 'Pelacakan Real-Time', desc: 'Pantau posisi kru langsung di peta sejak ditugaskan hingga tiba.' },
  { icon: <Wallet size={18} />, title: 'Pembayaran Fleksibel', desc: 'Transfer bank, QRIS, atau tunai — dengan verifikasi otomatis.' },
  { icon: <Star size={18} />, title: 'Rating & Ulasan', desc: 'Setiap kru dinilai transparan agar kualitas layanan terjaga.' },
  { icon: <MessageCircle size={18} />, title: 'Chat & Asisten AI', desc: 'Ngobrol langsung dengan kru atau tanya Asisten AI kapan saja.' },
  { icon: <BellRing size={18} />, title: 'Notifikasi Instan', desc: 'Update status pesanan terkirim langsung ke ponsel Anda.' },
  { icon: <Sparkles size={18} />, title: 'Kode Referal', desc: 'Ajak teman pakai Tuntaskilat, dapatkan voucher hadiah.' },
]

export default function Home() {
  return (
    <div>
      {/* Hero */}
      <section className="relative overflow-hidden bg-surface-muted">
        <motion.div
          className="pointer-events-none absolute -right-32 -top-32 h-96 w-96 rounded-full bg-primary/10 blur-3xl"
          animate={{ scale: [1, 1.08, 1] }}
          transition={{ duration: 8, repeat: Infinity, ease: 'easeInOut' }}
        />
        <motion.div
          className="pointer-events-none absolute -bottom-40 -left-20 h-80 w-80 rounded-full bg-accent/15 blur-3xl"
          animate={{ scale: [1, 1.1, 1] }}
          transition={{ duration: 10, repeat: Infinity, ease: 'easeInOut', delay: 1 }}
        />

        <div className="relative mx-auto max-w-6xl px-5 py-20 md:px-8 md:py-28">
          <div className="mx-auto max-w-2xl text-center">
            <motion.span
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-1.5 rounded-full bg-white px-3.5 py-1.5 text-[12px] font-bold text-primary shadow-sm ring-1 ring-border"
            >
              <Sparkles size={13} /> Buku Panduan Resmi
            </motion.span>

            <motion.h1
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.08 }}
              className="mt-5 text-4xl font-extrabold tracking-tight text-ink-soft md:text-6xl"
            >
              Panduan Lengkap
              <span className="block text-primary">Aplikasi Tuntaskilat</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.16 }}
              className="mx-auto mt-5 max-w-lg text-[15px] leading-relaxed text-text-secondary md:text-[17px]"
            >
              Semua yang perlu Anda ketahui tentang memesan, mengerjakan, dan
              mengelola layanan kebersihan on-demand — untuk Pelanggan, Kru,
              dan Admin.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 14 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.24 }}
              className="mt-8 flex flex-wrap items-center justify-center gap-3"
            >
              <Link
                to="/pelanggan"
                className="group flex items-center gap-2 rounded-full bg-primary px-6 py-3 text-[14px] font-bold text-white shadow-lg shadow-primary/25 transition-transform hover:scale-[1.03] active:scale-[0.98]"
              >
                Mulai dari Pelanggan
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-0.5" />
              </Link>
              <a
                href="https://tuntaskilat-documentation.web.app"
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-2 rounded-full border border-border bg-white px-6 py-3 text-[14px] font-semibold text-ink-soft transition-colors hover:border-primary/40"
              >
                Dokumentasi Teknis
                <ExternalLink size={14} />
              </a>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Role cards */}
      <section className="mx-auto max-w-6xl px-5 py-16 md:px-8 md:py-20">
        <Reveal>
          <p className="text-center text-[12px] font-bold uppercase tracking-wider text-text-muted">
            Pilih Panduan Sesuai Peran Anda
          </p>
        </Reveal>
        <div className="mt-8 grid gap-5 md:grid-cols-3">
          {ROLES.map((role, i) => (
            <Reveal key={role.to} delay={i * 0.08}>
              <Link to={role.to} className="group block h-full">
                <motion.div
                  whileHover={{ y: -6 }}
                  transition={{ type: 'spring', stiffness: 280, damping: 22 }}
                  className="flex h-full flex-col rounded-3xl border border-border bg-white p-7 shadow-[0_1px_2px_rgba(16,37,26,0.04)] transition-shadow group-hover:shadow-[0_12px_32px_rgba(16,37,26,0.09)]"
                >
                  <span className={`flex h-12 w-12 items-center justify-center rounded-2xl ${role.iconBg} ${role.iconText}`}>
                    <role.icon size={24} />
                  </span>
                  <h3 className="mt-5 text-lg font-bold text-ink-soft">{role.title}</h3>
                  <p className="mt-2 text-[13.5px] leading-relaxed text-text-secondary">
                    {role.desc}
                  </p>
                  <ul className="mt-4 space-y-1.5">
                    {role.points.map((p) => (
                      <li key={p} className="flex items-center gap-2 text-[12.5px] text-text-secondary">
                        <span className={`h-1 w-1 rounded-full ${role.dot}`} />
                        {p}
                      </li>
                    ))}
                  </ul>
                  <span className="mt-6 flex items-center gap-1.5 text-[13px] font-bold text-primary">
                    Buka Panduan
                    <ArrowRight size={14} className="transition-transform group-hover:translate-x-1" />
                  </span>
                </motion.div>
              </Link>
            </Reveal>
          ))}
        </div>
      </section>

      {/* Highlights */}
      <section className="border-t border-border bg-surface-muted">
        <div className="mx-auto max-w-6xl px-5 py-16 md:px-8 md:py-20">
          <Reveal>
            <div className="mx-auto max-w-xl text-center">
              <h2 className="text-2xl font-extrabold tracking-tight text-ink-soft md:text-3xl">
                Dibangun untuk Pengalaman yang Mulus
              </h2>
              <p className="mt-3 text-[14.5px] text-text-secondary">
                Fitur-fitur inti yang membuat pemesanan jasa kebersihan
                terasa cepat, transparan, dan dapat dipercaya.
              </p>
            </div>
          </Reveal>
          <div className="mt-10">
            <FeatureGrid items={HIGHLIGHTS} />
          </div>
        </div>
      </section>
    </div>
  )
}
