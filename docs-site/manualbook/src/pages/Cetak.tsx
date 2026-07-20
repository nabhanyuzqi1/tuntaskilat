import { HelpCircle, Phone, Mail, MessageCircle } from 'lucide-react'
import CoverPage from '../components/print/CoverPage'
import PrintToc from '../components/print/PrintToc'
import { PageHero, RoleBadge } from '../components/GuideKit'
import { FAQS } from '../data/faqs'
import Pelanggan from './Pelanggan'
import Kru from './Kru'
import Admin from './Admin'

function PrintFaq() {
  return (
    <div className="print-chapter">
      <PageHero
        role="pelanggan"
        eyebrow="Bab 04"
        title="Pertanyaan Umum (FAQ)"
        description="Jawaban cepat untuk pertanyaan yang paling sering diajukan Pelanggan, Kru, dan Admin."
      />
      <div className="mx-auto max-w-5xl px-16 py-10">
        <div className="grid grid-cols-2 gap-4">
          {FAQS.map((item) => (
            <div
              key={item.q}
              className="print-avoid-break rounded-2xl border border-border bg-white p-4"
            >
              <div className="flex items-start gap-2">
                {item.role !== 'semua' && <RoleBadge role={item.role} />}
                <p className="text-[13.5px] font-bold text-ink-soft">{item.q}</p>
              </div>
              <p className="mt-2 text-[12.5px] leading-relaxed text-text-secondary">
                {item.a}
              </p>
            </div>
          ))}
        </div>

        <div className="print-avoid-break mt-8 rounded-2xl border border-border bg-surface-muted p-6">
          <div className="flex items-center gap-2">
            <HelpCircle size={16} className="text-primary" />
            <p className="text-[13.5px] font-bold text-ink-soft">Butuh Bantuan Lebih Lanjut?</p>
          </div>
          <div className="mt-4 grid grid-cols-3 gap-4 text-[12.5px] text-text-secondary">
            <div className="flex items-center gap-2">
              <Phone size={14} className="text-primary" /> WhatsApp CS: +62 817-7490-0001
            </div>
            <div className="flex items-center gap-2">
              <MessageCircle size={14} className="text-primary" /> Chat &amp; Asisten AI di aplikasi
            </div>
            <div className="flex items-center gap-2">
              <Mail size={14} className="text-primary" /> cs@tuntaskilat.com
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

/**
 * Standalone print/PDF document — cover, table of contents, then every
 * guide chapter concatenated in reading order. Rendered without site chrome
 * (Header/Footer) and exported via headless Chrome (see docs-site tooling).
 */
export default function Cetak() {
  return (
    <div className="bg-white">
      <CoverPage />
      <PrintToc />
      <div className="print-chapter">
        <Pelanggan />
      </div>
      <div className="print-chapter">
        <Kru />
      </div>
      <div className="print-chapter">
        <Admin />
      </div>
      <PrintFaq />
    </div>
  )
}
