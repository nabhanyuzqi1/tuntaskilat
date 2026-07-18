import { Link } from 'react-router-dom'
import { ExternalLink } from 'lucide-react'

export default function Footer() {
  return (
    <footer className="border-t border-border bg-surface-muted">
      <div className="mx-auto max-w-6xl px-5 py-12 md:px-8">
        <div className="grid gap-10 md:grid-cols-4">
          <div className="md:col-span-2">
            <div className="flex items-center gap-2.5">
              <img src="/brand/brandmark.webp" alt="" className="h-8 w-8 rounded-lg" />
              <span className="text-[15px] font-bold text-ink-soft">Tuntaskilat</span>
            </div>
            <p className="mt-3 max-w-xs text-[13px] leading-relaxed text-text-secondary">
              Platform jasa kebersihan on-demand — pesan kru profesional untuk
              rumah, kos, dan kantor Anda dalam hitungan menit.
            </p>
            <p className="mt-4 text-[11px] text-text-muted">
              PT Tuntas Kilat Group · Sampit, Kalimantan Tengah
            </p>
          </div>

          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-text-muted">
              Panduan
            </p>
            <ul className="mt-3 space-y-2 text-[13px]">
              <li><Link to="/pelanggan" className="text-text-secondary hover:text-primary">Pelanggan</Link></li>
              <li><Link to="/kru" className="text-text-secondary hover:text-primary">Kru</Link></li>
              <li><Link to="/admin" className="text-text-secondary hover:text-primary">Admin</Link></li>
              <li><Link to="/faq" className="text-text-secondary hover:text-primary">FAQ</Link></li>
            </ul>
          </div>

          <div>
            <p className="text-[11px] font-bold uppercase tracking-wider text-text-muted">
              Tautan Lain
            </p>
            <ul className="mt-3 space-y-2 text-[13px]">
              <li>
                <a
                  href="https://tuntaskilat-documentation.web.app"
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center gap-1 text-text-secondary hover:text-primary"
                >
                  Dokumentasi Teknis <ExternalLink size={11} />
                </a>
              </li>
              <li><Link to="/faq#kontak" className="text-text-secondary hover:text-primary">Hubungi CS</Link></li>
            </ul>
          </div>
        </div>

        <div className="mt-10 flex flex-col-reverse items-center justify-between gap-4 border-t border-border pt-6 text-[12px] text-text-muted md:flex-row">
          <p>© {new Date().getFullYear()} PT Tuntas Kilat Group. Seluruh hak cipta dilindungi.</p>
          <p>Dibangun dengan Flutter & Firebase.</p>
        </div>
      </div>
    </footer>
  )
}
