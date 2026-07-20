import type { ReactNode } from 'react'
import { motion } from 'framer-motion'
import { Info, AlertTriangle, Lightbulb } from 'lucide-react'
import Reveal from './Reveal'

const ROLE_STYLE: Record<Role, { bg: string; text: string; ring: string; label: string }> = {
  pelanggan: { bg: 'bg-role-pelanggan/10', text: 'text-role-pelanggan', ring: 'ring-role-pelanggan/25', label: 'Pelanggan' },
  kru: { bg: 'bg-role-kru/10', text: 'text-role-kru', ring: 'ring-role-kru/25', label: 'Kru' },
  admin: { bg: 'bg-role-admin/10', text: 'text-role-admin', ring: 'ring-role-admin/25', label: 'Admin' },
}

export type Role = 'pelanggan' | 'kru' | 'admin'

export function RoleBadge({ role }: { role: Role }) {
  const s = ROLE_STYLE[role]
  return (
    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-bold ring-1 ${s.bg} ${s.text} ${s.ring}`}>
      {s.label}
    </span>
  )
}

export function Eyebrow({ role, children }: { role: Role; children: ReactNode }) {
  const s = ROLE_STYLE[role]
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-[12px] font-bold uppercase tracking-wider ${s.bg} ${s.text}`}>
      {children}
    </span>
  )
}

export function PageHero({
  role,
  eyebrow,
  title,
  description,
}: {
  role: Role
  eyebrow: string
  title: string
  description: string
}) {
  const s = ROLE_STYLE[role]
  return (
    <section className={`relative overflow-hidden border-b border-border ${s.bg}`}>
      <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-white/40 blur-3xl print:hidden" aria-hidden />
      <div className="relative mx-auto max-w-4xl px-5 py-16 md:px-8 md:py-20">
        <Reveal>
          <Eyebrow role={role}>{eyebrow}</Eyebrow>
          <h1 className="mt-4 text-3xl font-extrabold tracking-tight text-ink-soft md:text-5xl">
            {title}
          </h1>
          <p className="mt-4 max-w-2xl text-[15px] leading-relaxed text-text-secondary md:text-[17px]">
            {description}
          </p>
        </Reveal>
      </div>
    </section>
  )
}

export function Section({
  id,
  icon,
  title,
  subtitle,
  children,
}: {
  id: string
  icon?: ReactNode
  title: string
  subtitle?: string
  children: ReactNode
}) {
  return (
    <section id={id} className="scroll-mt-24 border-b border-border py-10 first:pt-6 last:border-b-0 md:py-12">
      <Reveal>
        <div className="flex items-center gap-3">
          {icon && (
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary">
              {icon}
            </span>
          )}
          <h2 className="text-xl font-bold text-ink-soft md:text-2xl">{title}</h2>
        </div>
        {subtitle && (
          <p className="mt-2 text-[14px] leading-relaxed text-text-secondary">{subtitle}</p>
        )}
      </Reveal>
      <div className="mt-6">{children}</div>
    </section>
  )
}

export function Steps({ items }: { items: { title: string; desc: string }[] }) {
  return (
    <ol className="space-y-3">
      {items.map((item, i) => (
        <Reveal key={item.title} delay={i * 0.05}>
          <li className="print-avoid-break flex gap-4 rounded-2xl border border-border bg-white p-4 shadow-[0_1px_2px_rgba(16,37,26,0.04)] transition-shadow hover:shadow-[0_4px_16px_rgba(16,37,26,0.06)]">
            <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary text-[12px] font-bold text-white">
              {i + 1}
            </span>
            <div>
              <p className="text-[14.5px] font-semibold text-ink-soft">{item.title}</p>
              <p className="mt-0.5 text-[13.5px] leading-relaxed text-text-secondary">{item.desc}</p>
            </div>
          </li>
        </Reveal>
      ))}
    </ol>
  )
}

export function FeatureGrid({
  items,
}: {
  items: { icon: ReactNode; title: string; desc: string }[]
}) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {items.map((item, i) => (
        <Reveal key={item.title} delay={i * 0.04}>
          <motion.div
            whileHover={{ y: -3 }}
            transition={{ type: 'spring', stiffness: 300, damping: 20 }}
            className="print-avoid-break h-full rounded-2xl border border-border bg-white p-4"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-surface-muted text-primary">
              {item.icon}
            </span>
            <p className="mt-3 text-[14px] font-semibold text-ink-soft">{item.title}</p>
            <p className="mt-1 text-[13px] leading-relaxed text-text-secondary">{item.desc}</p>
          </motion.div>
        </Reveal>
      ))}
    </div>
  )
}

export function ScreenFigure({
  src,
  caption,
  variant = 'phone',
}: {
  src: string
  caption: string
  variant?: 'phone' | 'admin'
}) {
  return (
    <figure
      className={`print-avoid-break mx-auto shrink-0 overflow-hidden rounded-2xl border border-border bg-surface-muted p-2.5 shadow-[0_1px_2px_rgba(16,37,26,0.04)] lg:mx-0 ${
        variant === 'phone' ? 'w-[168px]' : 'w-full max-w-[340px]'
      }`}
    >
      <img
        src={src}
        alt={caption}
        className={`w-full rounded-xl ${variant === 'phone' ? 'aspect-[390/844] object-cover' : 'aspect-[1440/900] object-cover'}`}
      />
      <figcaption className="mt-2 text-center text-[10.5px] font-semibold uppercase tracking-wide text-text-muted">
        {caption}
      </figcaption>
    </figure>
  )
}

export function WithScreen({
  screen,
  children,
}: {
  screen: ReactNode
  children: ReactNode
}) {
  return (
    <div className="flex flex-col gap-6 lg:flex-row lg:items-start print:block print:overflow-hidden">
      {/* Print uses a float instead of flex — Chromium's flexbox page-break
          fragmentation is unreliable and was cutting/overlapping content
          across page boundaries. Floats paginate correctly. */}
      <div className="shrink-0 lg:order-2 print:float-right print:ml-8 print:mb-4">{screen}</div>
      <div className="min-w-0 flex-1 lg:order-1 print:block">{children}</div>
    </div>
  )
}

export function Callout({
  type = 'info',
  children,
}: {
  type?: 'info' | 'warning' | 'tip'
  children: ReactNode
}) {
  const cfg = {
    info: { icon: Info, bg: 'bg-blue-50', border: 'border-blue-200', text: 'text-blue-900', iconColor: 'text-blue-500' },
    warning: { icon: AlertTriangle, bg: 'bg-amber-50', border: 'border-amber-200', text: 'text-amber-900', iconColor: 'text-amber-500' },
    tip: { icon: Lightbulb, bg: 'bg-primary/5', border: 'border-primary/20', text: 'text-ink-soft', iconColor: 'text-primary' },
  }[type]
  const Icon = cfg.icon
  return (
    <div className={`print-avoid-break flex gap-3 rounded-xl border ${cfg.border} ${cfg.bg} p-4`}>
      <Icon size={18} className={`mt-0.5 shrink-0 ${cfg.iconColor}`} />
      <div className={`text-[13.5px] leading-relaxed ${cfg.text}`}>{children}</div>
    </div>
  )
}

export function GuidePage({
  role,
  eyebrow,
  title,
  description,
  toc,
  children,
}: {
  role: Role
  eyebrow: string
  title: string
  description: string
  toc: { id: string; label: string }[]
  children: ReactNode
}) {
  return (
    <div>
      <PageHero role={role} eyebrow={eyebrow} title={title} description={description} />
      <div className="mx-auto flex max-w-6xl gap-10 px-5 py-4 md:px-8">
        <TOC items={toc} />
        <div className="min-w-0 flex-1 prose-manual">{children}</div>
      </div>
    </div>
  )
}

export function TOC({ items }: { items: { id: string; label: string }[] }) {
  return (
    <nav className="sticky top-24 hidden max-h-[calc(100vh-8rem)] w-56 shrink-0 overflow-y-auto pb-10 lg:block print:hidden">
      <p className="mb-3 text-[11px] font-bold uppercase tracking-wider text-text-muted">
        Di halaman ini
      </p>
      <ul className="space-y-1 border-l border-border">
        {items.map((item) => (
          <li key={item.id}>
            <a
              href={`#${item.id}`}
              className="block border-l-2 border-transparent py-1 pl-3.5 text-[13px] text-text-secondary transition-colors hover:border-primary/40 hover:text-primary"
            >
              {item.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  )
}
