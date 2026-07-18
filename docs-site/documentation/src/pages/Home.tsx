import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  ArrowRight,
  Database,
  Zap,
  Shield,
  Smartphone,
  Bot,
  CreditCard,
  BookOpen,
} from 'lucide-react'
import { DocPage } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const STATS = [
  { value: '3', label: 'Client Apps' },
  { value: '22', label: 'Cloud Functions' },
  { value: '20+', label: 'Firestore Collections' },
  { value: '1', label: 'Shared Package (tk_core)' },
]

const QUICK_LINKS = [
  { to: '/getting-started', icon: Zap, title: 'Getting Started', desc: 'Clone the repo, install dependencies, run each app locally.' },
  { to: '/data-model', icon: Database, title: 'Data Model', desc: 'Full Firestore schema — every collection, field, and enum.' },
  { to: '/functions', icon: Smartphone, title: 'Cloud Functions', desc: 'All 22 server-side functions: triggers, inputs, outputs.' },
  { to: '/security-rules', icon: Shield, title: 'Security Rules', desc: 'Read/write access matrix for every collection.' },
  { to: '/ai', icon: Bot, title: 'AI Features', desc: 'Multi-provider AI customer service & business analyst.' },
  { to: '/payments', icon: CreditCard, title: 'Payments', desc: 'Static gateway + Xendit dynamic invoicing/webhook.' },
]

export default function Home() {
  return (
    <DocPage>
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <p className="text-[11px] font-bold uppercase tracking-wider text-primary">
          Technical Documentation
        </p>
        <h1 className="mt-2 text-4xl font-extrabold tracking-tight md:text-5xl">
          Tuntaskilat
          <span className="block text-[color:var(--fg-muted)]">Developer Reference</span>
        </h1>
        <p className="mt-4 max-w-xl text-[15px] leading-relaxed text-[color:var(--fg-muted)]">
          On-demand home cleaning service platform — 3 Flutter client apps
          (Customer, Worker, Admin) on a shared Firebase backend. This
          reference covers the data model, Cloud Functions API, security
          rules, and business logic that power it.
        </p>
        <div className="mt-6 flex flex-wrap gap-3">
          <Link
            to="/getting-started"
            className="flex items-center gap-2 rounded-full bg-primary px-5 py-2.5 text-[13.5px] font-bold text-white transition-transform hover:scale-[1.02]"
          >
            Get Started
            <ArrowRight size={15} />
          </Link>
          <a
            href="https://tuntaskilat-manualbook.web.app"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 rounded-full border border-[color:var(--border)] px-5 py-2.5 text-[13.5px] font-semibold"
          >
            <BookOpen size={15} />
            End-user Manual
          </a>
        </div>
      </motion.div>

      <div className="mt-12 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {STATS.map((s, i) => (
          <motion.div
            key={s.label}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.1 + i * 0.05 }}
            className="rounded-xl border border-[color:var(--border)] bg-[color:var(--bg-subtle)] p-4"
          >
            <p className="text-2xl font-extrabold text-primary">{s.value}</p>
            <p className="mt-0.5 text-[11.5px] text-[color:var(--fg-muted)]">{s.label}</p>
          </motion.div>
        ))}
      </div>

      <div className="mt-14">
        <h2 className="mb-4 text-lg font-bold">Explore the docs</h2>
        <div className="grid gap-3 sm:grid-cols-2">
          {QUICK_LINKS.map((item, i) => (
            <motion.div
              key={item.to}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.15 + i * 0.04 }}
            >
              <Link
                to={item.to}
                className="group flex h-full flex-col rounded-xl border border-[color:var(--border)] p-4 transition-colors hover:border-primary/40"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
                  <item.icon size={16} />
                </span>
                <p className="mt-3 text-[13.5px] font-bold">{item.title}</p>
                <p className="mt-1 text-[12.5px] leading-relaxed text-[color:var(--fg-muted)]">
                  {item.desc}
                </p>
                <span className="mt-3 flex items-center gap-1 text-[12px] font-semibold text-primary opacity-0 transition-opacity group-hover:opacity-100">
                  Read more <ArrowRight size={12} />
                </span>
              </Link>
            </motion.div>
          ))}
        </div>
      </div>

      <div className="mt-14">
        <h2 className="mb-3 text-lg font-bold">Tech Stack</h2>
        <CodeBlock
          language="yaml"
          title="stack.yaml"
          code={`client:
  framework: Flutter 3.41
  state: Riverpod 2.6
  language: Dart 3.11
  apps: [pelanggan, kru, admin]
  shared_package: packages/tk_core

backend:
  platform: Firebase
  functions: Node.js 20 (2nd Gen), TypeScript
  region: asia-southeast2
  database: Cloud Firestore (NoSQL, document-based)
  auth: Firebase Authentication (email/password + Google)
  storage: Cloud Storage
  messaging: Firebase Cloud Messaging (FCM)

integrations:
  ai: [Gemini, OpenAI, Anthropic]  # multi-provider, admin-configurable
  payments: [transfer_bank, qris, tunai, xendit]
  whatsapp: Fonnte`}
        />
      </div>
    </DocPage>
  )
}
