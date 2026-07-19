import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { Info, AlertTriangle, ShieldAlert } from 'lucide-react'

export function DocHeader({
  eyebrow,
  title,
  description,
}: {
  eyebrow: string
  title: string
  description: string
}) {
  return (
    <div className="mb-10 border-b border-[color:var(--border)] pb-8">
      <p className="text-[11px] font-bold uppercase tracking-wider text-primary">{eyebrow}</p>
      <h1 className="mt-2 text-3xl font-extrabold tracking-tight md:text-4xl">{title}</h1>
      <p className="mt-3 max-w-2xl text-[15px] leading-relaxed text-[color:var(--fg-muted)]">
        {description}
      </p>
    </div>
  )
}

export function H2({ id, children }: { id: string; children: ReactNode }) {
  return (
    <h2 id={id} className="mb-4 mt-14 scroll-mt-20 text-2xl font-bold tracking-tight first:mt-0">
      <a href={`#${id}`} className="group inline-flex items-center gap-2">
        {children}
        <span className="opacity-0 transition-opacity group-hover:opacity-40">#</span>
      </a>
    </h2>
  )
}

export function H3({ id, children }: { id: string; children: ReactNode }) {
  return (
    <h3 id={id} className="mb-3 mt-9 scroll-mt-20 text-lg font-bold tracking-tight">
      <a href={`#${id}`} className="group inline-flex items-center gap-2">
        {children}
        <span className="opacity-0 transition-opacity group-hover:opacity-40">#</span>
      </a>
    </h3>
  )
}

export function P({ children }: { children: ReactNode }) {
  return (
    <p className="mb-4 text-[14.5px] leading-relaxed text-[color:var(--fg-muted)]">{children}</p>
  )
}

export function Table({
  head,
  rows,
}: {
  head: string[]
  rows: (string | ReactNode)[][]
}) {
  return (
    <div className="mb-6 overflow-x-auto rounded-xl border border-[color:var(--border)]">
      <table className="w-full border-collapse text-[13px]">
        <thead>
          <tr>
            {head.map((h) => (
              <th
                key={h}
                className="border-b border-[color:var(--border)] bg-[color:var(--bg-subtle)] px-3.5 py-2.5 text-left font-semibold"
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} className="print-avoid-break border-b border-[color:var(--border)] last:border-b-0">
              {row.map((cell, j) => (
                <td key={j} className="px-3.5 py-2.5 align-top text-[color:var(--fg-muted)]">
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

const TRIGGER_STYLE: Record<string, string> = {
  onCall: 'bg-blue-500/12 text-blue-500',
  onRequest: 'bg-purple-500/12 text-purple-500',
  onSchedule: 'bg-amber-500/14 text-amber-600',
  onDocumentCreated: 'bg-primary/12 text-primary',
  onDocumentUpdated: 'bg-teal-500/12 text-teal-600',
  onDocumentWritten: 'bg-pink-500/12 text-pink-500',
}

export function TriggerBadge({ type }: { type: string }) {
  const cls = TRIGGER_STYLE[type] ?? 'bg-gray-500/12 text-gray-500'
  return (
    <code className={`inline-flex items-center rounded-md px-2 py-0.5 font-mono text-[11px] font-semibold ${cls}`}>
      {type}
    </code>
  )
}

export function Code({ children }: { children: ReactNode }) {
  return (
    <code className="rounded-[4px] border border-[color:var(--border)] bg-[color:var(--bg-subtle)] px-1.5 py-0.5 font-mono text-[0.85em]">
      {children}
    </code>
  )
}

export function Callout({
  type = 'info',
  children,
}: {
  type?: 'info' | 'warning' | 'danger'
  children: ReactNode
}) {
  const cfg = {
    info: { icon: Info, cls: 'border-blue-500/25 bg-blue-500/8 text-blue-500' },
    warning: { icon: AlertTriangle, cls: 'border-amber-500/25 bg-amber-500/8 text-amber-600' },
    danger: { icon: ShieldAlert, cls: 'border-red-500/25 bg-red-500/8 text-red-500' },
  }[type]
  const Icon = cfg.icon
  return (
    <div className={`print-avoid-break mb-5 flex gap-3 rounded-xl border p-4 ${cfg.cls}`}>
      <Icon size={17} className="mt-0.5 shrink-0" />
      <div className="text-[13.5px] leading-relaxed text-[color:var(--fg)]">{children}</div>
    </div>
  )
}

export function FieldList({
  items,
}: {
  items: { name: string; type: string; desc?: string }[]
}) {
  return (
    <ul className="mb-6 divide-y divide-[color:var(--border)] rounded-xl border border-[color:var(--border)]">
      {items.map((item) => (
        <li key={item.name} className="flex flex-col gap-0.5 px-3.5 py-2.5 sm:flex-row sm:items-baseline sm:gap-3">
          <code className="shrink-0 font-mono text-[12.5px] font-semibold text-primary">{item.name}</code>
          <code className="shrink-0 font-mono text-[11px] text-[color:var(--fg-faint)]">{item.type}</code>
          {item.desc && <span className="text-[12.5px] text-[color:var(--fg-muted)]">{item.desc}</span>}
        </li>
      ))}
    </ul>
  )
}

export function DocPage({
  toc,
  children,
}: {
  toc?: { id: string; label: string }[]
  children: ReactNode
}) {
  return (
    <div className="mx-auto flex max-w-5xl gap-10">
      <div className="min-w-0 flex-1 pb-20">{children}</div>
      {toc && toc.length > 0 && <PageTOC items={toc} />}
    </div>
  )
}

export function PageTOC({ items }: { items: { id: string; label: string }[] }) {
  return (
    <nav className="sticky top-20 hidden max-h-[calc(100vh-6rem)] w-52 shrink-0 overflow-y-auto pb-10 xl:block print:hidden">
      <p className="mb-3 text-[11px] font-bold uppercase tracking-wider text-[color:var(--fg-faint)]">
        Di halaman ini
      </p>
      <ul className="space-y-1 border-l border-[color:var(--border)]">
        {items.map((item) => (
          <li key={item.id}>
            <a
              href={`#${item.id}`}
              className="block border-l-2 border-transparent py-1 pl-3.5 text-[12.5px] text-[color:var(--fg-muted)] transition-colors hover:border-primary/40 hover:text-primary"
            >
              {item.label}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  )
}

export function PrevNext({
  prev,
  next,
}: {
  prev?: { to: string; label: string }
  next?: { to: string; label: string }
}) {
  return (
    <div className="mt-16 flex items-center justify-between gap-4 border-t border-[color:var(--border)] pt-6">
      {prev ? (
        <Link to={prev.to} className="group flex flex-col text-left">
          <span className="text-[11px] text-[color:var(--fg-faint)]">Previous</span>
          <span className="text-[13.5px] font-semibold group-hover:text-primary">{prev.label}</span>
        </Link>
      ) : <span />}
      {next ? (
        <Link to={next.to} className="group flex flex-col text-right">
          <span className="text-[11px] text-[color:var(--fg-faint)]">Next</span>
          <span className="text-[13.5px] font-semibold group-hover:text-primary">{next.label}</span>
        </Link>
      ) : <span />}
    </div>
  )
}
