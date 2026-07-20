import type { ReactNode } from 'react'
import Header from './Header'
import Footer from './Footer'
import ScrollToTop from './ScrollToTop'

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-surface">
      <ScrollToTop />
      <Header />
      <main className="flex-1">{children}</main>
      <Footer />
    </div>
  )
}
