export type NavItem = { to: string; label: string }
export type NavGroup = { title: string; items: NavItem[] }

export const NAV: NavGroup[] = [
  {
    title: 'Pengenalan',
    items: [
      { to: '/', label: 'Ringkasan' },
      { to: '/getting-started', label: 'Memulai (Setup)' },
      { to: '/architecture', label: 'Arsitektur' },
    ],
  },
  {
    title: 'Referensi API',
    items: [
      { to: '/data-model', label: 'Skema Data (Firestore)' },
      { to: '/functions', label: 'Cloud Functions' },
      { to: '/security-rules', label: 'Security Rules' },
    ],
  },
  {
    title: 'Logika Bisnis',
    items: [
      { to: '/business-logic', label: 'Komisi & Pembagian Upah' },
      { to: '/payments', label: 'Pembayaran & Gateway' },
      { to: '/ai', label: 'Fitur AI' },
      { to: '/notifications', label: 'Notifikasi' },
    ],
  },
  {
    title: 'Operasional',
    items: [
      { to: '/deployment', label: 'Deployment' },
      { to: '/changelog', label: 'Changelog & Roadmap' },
    ],
  },
]
