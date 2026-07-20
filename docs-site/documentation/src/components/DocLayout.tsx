import { useEffect, useState, type ReactNode } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { Menu, X, ExternalLink, BookOpen, Download } from 'lucide-react'
import Sidebar from './Sidebar'
import ThemeToggle from './ThemeToggle'

export default function DocLayout({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false)
  const location = useLocation()

  useEffect(() => {
    setOpen(false)
    window.scrollTo({ top: 0 })
  }, [location.pathname])

  return (
    <div className="min-h-screen bg-[color:var(--bg)] text-[color:var(--fg)]">
      {/* Top bar */}
      <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-[color:var(--border)] bg-[color:var(--bg)]/85 px-4 backdrop-blur-lg md:px-6">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setOpen((v) => !v)}
            className="flex h-8 w-8 items-center justify-center rounded-md text-[color:var(--fg-muted)] md:hidden"
            aria-label="Buka navigasi"
          >
            {open ? <X size={18} /> : <Menu size={18} />}
          </button>
          <Link to="/" className="flex items-center gap-2">
            <img src="/brand/brandmark.webp" alt="" className="h-6 w-6 rounded-md" />
            <span className="text-[14px] font-bold tracking-tight">Tuntaskilat</span>
            <span className="hidden rounded-full bg-admin/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-admin sm:inline">
              Docs
            </span>
          </Link>
        </div>
        <div className="flex items-center gap-1.5">
          <a
            href="https://tuntaskilat-manualbook.web.app"
            target="_blank"
            rel="noreferrer"
            className="hidden items-center gap-1.5 rounded-full border border-[color:var(--border)] px-3 py-1.5 text-[12.5px] font-semibold text-[color:var(--fg-muted)] transition-colors hover:text-[color:var(--fg)] sm:flex"
          >
            <BookOpen size={13} />
            Buku Panduan
            <ExternalLink size={11} />
          </a>
          <a
            href="/documentation.pdf"
            download
            className="hidden items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-[12.5px] font-semibold text-white transition-colors hover:bg-primary-dark sm:flex"
          >
            <Download size={13} />
            Download PDF
          </a>
          <ThemeToggle />
        </div>
      </header>

      <div className="mx-auto flex max-w-[1400px]">
        {/* Desktop sidebar */}
        <aside className="sticky top-14 hidden h-[calc(100vh-3.5rem)] w-64 shrink-0 border-r border-[color:var(--border-sidebar)] bg-[color:var(--bg-sidebar)] md:block">
          <Sidebar />
        </aside>

        {/* Mobile drawer */}
        <AnimatePresence>
          {open && (
            <>
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={() => setOpen(false)}
                className="fixed inset-0 z-30 bg-black/40 md:hidden"
              />
              <motion.aside
                initial={{ x: -280 }}
                animate={{ x: 0 }}
                exit={{ x: -280 }}
                transition={{ type: 'tween', duration: 0.22 }}
                className="fixed left-0 top-14 z-40 h-[calc(100vh-3.5rem)] w-72 bg-[color:var(--bg-sidebar)] md:hidden"
              >
                <Sidebar onNavigate={() => setOpen(false)} />
              </motion.aside>
            </>
          )}
        </AnimatePresence>

        <main className="min-w-0 flex-1 px-5 py-10 md:px-10 lg:px-14">{children}</main>
      </div>
    </div>
  )
}
