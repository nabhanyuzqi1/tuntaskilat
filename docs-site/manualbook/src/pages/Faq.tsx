import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, MessageCircle, Phone, Mail } from 'lucide-react'
import Reveal from '../components/Reveal'
import { RoleBadge } from '../components/GuideKit'
import type { Role } from '../components/GuideKit'
import { FAQS } from '../data/faqs'
import type { FaqItem } from '../data/faqs'

const FILTERS: { key: Role | 'semua'; label: string }[] = [
  { key: 'semua', label: 'Semua' },
  { key: 'pelanggan', label: 'Pelanggan' },
  { key: 'kru', label: 'Kru' },
  { key: 'admin', label: 'Admin' },
]

function FaqAccordion({ item }: { item: FaqItem }) {
  const [open, setOpen] = useState(false)
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-white">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
      >
        <span className="flex items-center gap-3">
          {item.role !== 'semua' && <RoleBadge role={item.role} />}
          <span className="text-[14px] font-semibold text-ink-soft">{item.q}</span>
        </span>
        <motion.span animate={{ rotate: open ? 180 : 0 }} transition={{ duration: 0.2 }}>
          <ChevronDown size={18} className="shrink-0 text-text-muted" />
        </motion.span>
      </button>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden"
          >
            <p className="px-5 pb-4 text-[13.5px] leading-relaxed text-text-secondary">
              {item.a}
            </p>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default function Faq() {
  const [filter, setFilter] = useState<Role | 'semua'>('semua')
  const filtered = FAQS.filter((f) => filter === 'semua' || f.role === filter || f.role === 'semua')

  return (
    <div>
      <section className="border-b border-border bg-surface-muted">
        <div className="mx-auto max-w-3xl px-5 py-16 text-center md:px-8 md:py-20">
          <Reveal>
            <h1 className="text-3xl font-extrabold tracking-tight text-ink-soft md:text-5xl">
              Pertanyaan Umum
            </h1>
            <p className="mx-auto mt-4 max-w-xl text-[15px] leading-relaxed text-text-secondary">
              Jawaban cepat untuk pertanyaan yang paling sering diajukan
              Pelanggan, Kru, dan Admin.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="mx-auto max-w-3xl px-5 py-12 md:px-8">
        <div className="flex flex-wrap gap-2">
          {FILTERS.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={`rounded-full px-4 py-1.5 text-[13px] font-semibold transition-colors ${
                filter === f.key
                  ? 'bg-primary text-white'
                  : 'bg-surface-muted text-text-secondary hover:bg-border'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        <div className="mt-6 space-y-3">
          {filtered.map((item) => (
            <Reveal key={item.q}>
              <FaqAccordion item={item} />
            </Reveal>
          ))}
        </div>
      </section>

      <section id="kontak" className="scroll-mt-24 border-t border-border bg-surface-muted">
        <div className="mx-auto max-w-3xl px-5 py-16 text-center md:px-8">
          <Reveal>
            <h2 className="text-2xl font-extrabold text-ink-soft">Butuh Bantuan Lebih Lanjut?</h2>
            <p className="mt-2 text-[14px] text-text-secondary">
              Tim Customer Service kami siap membantu Anda.
            </p>
            <div className="mt-8 grid gap-3 sm:grid-cols-3">
              <a href="https://wa.me/6281774900001" target="_blank" rel="noreferrer" className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-white p-5 transition-shadow hover:shadow-md">
                <Phone size={20} className="text-primary" />
                <span className="text-[13px] font-semibold text-ink-soft">WhatsApp CS</span>
              </a>
              <div className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-white p-5">
                <MessageCircle size={20} className="text-primary" />
                <span className="text-[13px] font-semibold text-ink-soft">Chat & Asisten AI di Aplikasi</span>
              </div>
              <div className="flex flex-col items-center gap-2 rounded-2xl border border-border bg-white p-5">
                <Mail size={20} className="text-primary" />
                <span className="text-[13px] font-semibold text-ink-soft">cs@tuntaskilat.com</span>
              </div>
            </div>
          </Reveal>
        </div>
      </section>
    </div>
  )
}
