import { useMemo, useState } from 'react'
import { Search } from 'lucide-react'
import { DocHeader, DocPage, H2, P, Callout, TriggerBadge, Code, PrevNext } from '../components/Kit'
import { FN_GROUPS } from '../data/functions'
import CodeBlock from '../components/CodeBlock'

const TOC = FN_GROUPS.map((g) => ({ id: g.title.toLowerCase().replace(/[^a-z0-9]+/g, '-'), label: g.title }))

export default function Functions() {
  const [query, setQuery] = useState('')

  const filteredGroups = useMemo(() => {
    if (!query.trim()) return FN_GROUPS
    const q = query.toLowerCase()
    return FN_GROUPS.map((g) => ({
      ...g,
      fns: g.fns.filter(
        (fn) => fn.name.toLowerCase().includes(q) || fn.desc.toLowerCase().includes(q),
      ),
    })).filter((g) => g.fns.length > 0)
  }, [query])

  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="API Reference"
        title="Cloud Functions"
        description="22 server-side functions — all running in asia-southeast2 as a safety-net layer that mirrors and validates client-side transactions."
      />

      <Callout type="info">
        Every function shares one Firestore admin instance and the{' '}
        <Code>REGION = "asia-southeast2"</Code> constant, defined in{' '}
        <Code>firebase/functions/src/index.ts</Code>.
      </Callout>

      <div className="mb-8 flex items-center gap-2 rounded-xl border border-[color:var(--border)] bg-[color:var(--bg-subtle)] px-3.5 py-2.5">
        <Search size={15} className="text-[color:var(--fg-faint)]" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search functions (e.g. referral, payment, review)..."
          className="w-full bg-transparent text-[13.5px] outline-none placeholder:text-[color:var(--fg-faint)]"
        />
      </div>

      {filteredGroups.map((group) => (
        <div key={group.title}>
          <H2 id={group.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}>{group.title}</H2>
          <div className="space-y-3">
            {group.fns.map((fn) => (
              <div
                key={fn.id}
                id={fn.id}
                className="scroll-mt-20 rounded-xl border border-[color:var(--border)] p-4"
              >
                <div className="flex flex-wrap items-center gap-2">
                  <code className="font-mono text-[14px] font-bold text-primary">{fn.name}</code>
                  <TriggerBadge type={fn.trigger} />
                  <code className="font-mono text-[11px] text-[color:var(--fg-faint)]">{fn.path}</code>
                </div>
                <p className="mt-2 text-[13.5px] leading-relaxed text-[color:var(--fg-muted)]">
                  {fn.desc}
                </p>
                {fn.detail && (
                  <p className="mt-2 border-l-2 border-primary/30 pl-3 text-[12.5px] leading-relaxed text-[color:var(--fg-faint)]">
                    {fn.detail}
                  </p>
                )}
              </div>
            ))}
          </div>
        </div>
      ))}

      {filteredGroups.length === 0 && (
        <P>No functions match "{query}".</P>
      )}

      <H2 id="shared-helpers">Shared Helpers</H2>
      <P>Two utilities worth knowing when reading the source:</P>
      <CodeBlock
        language="typescript"
        code={`// Reads settings/komisi — perLayanan[serviceId] override, else global, clamped 0–100.
async function komisiPersenUntuk(serviceId: string): Promise<number>

// Recomputes services.jumlahKru = count of active kru (status undefined/null/'aktif')
// whose keahlian is empty (generalist) or includes the serviceId. Drives the
// capacity-based booking slot mechanism.
async function recomputeKapasitasLayanan(): Promise<void>`}
      />

      <PrevNext
        prev={{ to: '/data-model', label: 'Data Model' }}
        next={{ to: '/security-rules', label: 'Security Rules' }}
      />
    </DocPage>
  )
}
