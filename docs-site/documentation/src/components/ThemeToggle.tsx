import { useEffect, useState } from 'react'
import { Moon, Sun } from 'lucide-react'

function getInitialTheme(): 'light' | 'dark' {
  const stored = localStorage.getItem('tk-docs-theme')
  if (stored === 'light' || stored === 'dark') return stored
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

export default function ThemeToggle() {
  const [theme, setTheme] = useState<'light' | 'dark'>(getInitialTheme)

  useEffect(() => {
    document.documentElement.dataset.theme = theme
    localStorage.setItem('tk-docs-theme', theme)
  }, [theme])

  return (
    <button
      onClick={() => setTheme((t) => (t === 'dark' ? 'light' : 'dark'))}
      className="flex h-8 w-8 items-center justify-center rounded-full text-[color:var(--fg-muted)] transition-colors hover:bg-[color:var(--bg-subtle)] hover:text-[color:var(--fg)]"
      aria-label="Ganti tema"
      title="Ganti tema terang/gelap"
    >
      {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
    </button>
  )
}
