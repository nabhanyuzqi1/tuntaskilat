import { DocHeader, DocPage, H2, P } from '../components/Kit'

const PHASES = [
  {
    phase: 'Fase 1',
    title: 'Bug Blockers',
    items: ['Splash/launcher fixes', 'P6 billing blank-screen fix', 'Voucher rules deploy', 'Multi-crew assignment wiring', 'Profile photos', 'Payment proof + QRIS display', 'Dashboard status chart', 'System bar consistency audit'],
  },
  {
    phase: 'Fase 2',
    title: 'Customer UX',
    items: ['Wizard-style booking form', 'Saved addresses + map picker', 'Reverse-geocoding (Nominatim)', 'Full catalog with category filter', 'Active-order home card', 'Cancel + CS contact from tracking', 'Granular permissions + Terms', 'Chat + call wiring'],
  },
  {
    phase: 'Fase 3',
    title: 'Crew (Kru)',
    items: ['FCM push + assignment reminders (cron)', 'Real-road OSRM routing', 'Custom notification sound'],
  },
  {
    phase: 'Fase 4',
    title: 'Admin',
    items: ['Full dynamic pricing catalog editor', 'Crew lifecycle (keahlian/tipe/status)', 'Skill-based assignment matching', 'New-user + per-phone voucher anti-abuse', 'Service area module', 'TOTP 2FA', 'Admin team management (buatAdmin/setNonaktifAdmin)'],
  },
  {
    phase: 'Fase 5',
    title: 'Business Systems',
    items: ['Commission config (global + per-service)', 'Cash deposit ledger (kasKru/setoran)', 'Referral program with anti-abuse', 'Modular payment gateway (Static + Xendit stub)', 'WhatsApp notifications (Fonnte)'],
  },
  {
    phase: 'Fase 6',
    title: 'Quality & Release',
    items: ['Maintenance mode / forced update (settings/app)', 'Skeleton loading states', 'Memory-leak audit (chat screen controllers)', 'Extended black-box test coverage'],
  },
  {
    phase: 'Post-Fase 6',
    title: 'Business Expansion',
    items: [
      'Multi-provider AI (Gemini/OpenAI/Anthropic) — CS chat (csAi) + business analyst (analisaBisnisAi)',
      'Xendit dynamic invoicing activated (buatTagihanXendit + xenditWebhook)',
      'Capacity-based booking (replaces boolean slot lock with a live crew-count counter)',
      'A10 Pantau Operasional — live crew map + chat quality monitoring',
      'A9 Kelola Klien — customer roster with spend aggregation',
      'Broadcast push notifications + banner promo content',
      'Auto-cancel unassigned orders after 24h',
      'Server-authoritative review rating aggregation',
    ],
  },
]

export default function Changelog() {
  return (
    <DocPage>
      <DocHeader
        eyebrow="Operations"
        title="Changelog & Roadmap"
        description="Development phases, from the initial thesis-scoped MVP through the current business-layer feature set."
      />

      <div className="space-y-10">
        {PHASES.map((p) => (
          <div key={p.phase} className="relative border-l-2 border-[color:var(--border)] pl-6">
            <div className="absolute -left-[7px] top-1 h-3 w-3 rounded-full border-2 border-primary bg-[color:var(--bg)]" />
            <p className="text-[11px] font-bold uppercase tracking-wider text-primary">{p.phase}</p>
            <H2 id={p.phase.toLowerCase().replace(/\s+/g, '-')}>{p.title}</H2>
            <ul className="ml-5 list-disc space-y-1.5 text-[13.5px] leading-relaxed text-[color:var(--fg-muted)]">
              {p.items.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mt-14 border-t border-[color:var(--border)] pt-8">
        <P>
          For the exact commit history, see the repository's Git log — each
          feature phase was developed on its own branch and merged via pull
          request into <code className="rounded bg-[color:var(--bg-subtle)] px-1.5 py-0.5 font-mono text-[0.85em]">dev</code>.
        </P>
      </div>
    </DocPage>
  )
}
