import { useEffect, useState } from 'react'
import { Link, NavLink } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { Menu, X, ExternalLink, Download } from 'lucide-react'

const NAV = [
  { to: '/', label: 'Beranda', end: true },
  { to: '/pelanggan', label: 'Panduan Pelanggan' },
  { to: '/kru', label: 'Panduan Kru' },
  { to: '/admin', label: 'Panduan Admin' },
  { to: '/faq', label: 'FAQ' },
]

export default function Header() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    setOpen(false)
  }, [])

  return (
    <header
      className={`sticky top-0 z-50 w-full transition-all duration-300 ${
        scrolled
          ? 'bg-white/85 backdrop-blur-lg border-b border-border shadow-[0_1px_0_rgba(16,37,26,0.04)]'
          : 'bg-white/0 border-b border-transparent'
      }`}
    >
      <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-3 md:px-8">
        <Link to="/" className="flex items-center gap-2.5 shrink-0">
          <img src="/brand/brandmark.webp" alt="" className="h-8 w-8 rounded-lg" />
          <span className="flex flex-col leading-none">
            <span className="text-[15px] font-bold text-ink-soft tracking-tight">
              Tuntaskilat
            </span>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-text-muted">
              Buku Panduan
            </span>
          </span>
        </Link>

        <nav className="hidden md:flex items-center gap-1">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `relative px-3.5 py-2 text-[13.5px] font-medium rounded-full transition-colors ${
                  isActive
                    ? 'text-primary'
                    : 'text-text-secondary hover:text-ink-soft'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {item.label}
                  {isActive && (
                    <motion.span
                      layoutId="nav-pill"
                      className="absolute inset-0 -z-10 rounded-full bg-primary/10"
                      transition={{ type: 'spring', stiffness: 380, damping: 32 }}
                    />
                  )}
                </>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="hidden md:flex items-center gap-2">
          <a
            href="https://tuntaskilat-documentation.web.app"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-1.5 rounded-full border border-border px-3.5 py-1.5 text-[13px] font-semibold text-text-secondary transition-colors hover:border-primary/40 hover:text-primary"
          >
            Dokumentasi Teknis
            <ExternalLink size={13} strokeWidth={2.4} />
          </a>
          <a
            href="/manual-book.pdf"
            download
            className="flex items-center gap-1.5 rounded-full bg-primary px-3.5 py-1.5 text-[13px] font-semibold text-white transition-colors hover:bg-primary-dark"
          >
            <Download size={13} strokeWidth={2.4} />
            Unduh PDF
          </a>
        </div>

        <button
          onClick={() => setOpen((v) => !v)}
          className="md:hidden flex h-9 w-9 items-center justify-center rounded-full text-ink-soft"
          aria-label="Buka menu"
        >
          {open ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.22, ease: 'easeInOut' }}
            className="md:hidden overflow-hidden border-t border-border bg-white"
          >
            <nav className="flex flex-col gap-1 px-5 py-4">
              {NAV.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  onClick={() => setOpen(false)}
                  className={({ isActive }) =>
                    `rounded-xl px-3.5 py-2.5 text-sm font-medium ${
                      isActive
                        ? 'bg-primary/10 text-primary'
                        : 'text-text-secondary'
                    }`
                  }
                >
                  {item.label}
                </NavLink>
              ))}
              <a
                href="https://tuntaskilat-documentation.web.app"
                target="_blank"
                rel="noreferrer"
                className="mt-2 flex items-center justify-center gap-1.5 rounded-xl border border-border px-3.5 py-2.5 text-sm font-semibold text-text-secondary"
              >
                Dokumentasi Teknis
                <ExternalLink size={13} />
              </a>
              <a
                href="/manual-book.pdf"
                download
                className="flex items-center justify-center gap-1.5 rounded-xl bg-primary px-3.5 py-2.5 text-sm font-semibold text-white"
              >
                <Download size={13} />
                Unduh PDF
              </a>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  )
}
