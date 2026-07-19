const CHAPTERS = [
  { no: '01', title: 'Overview', desc: 'Stats, quick links, tech stack.' },
  { no: '02', title: 'Getting Started', desc: 'Prerequisites, repo structure, local setup, running each app.' },
  { no: '03', title: 'Architecture', desc: 'System overview, client apps, shared package, backend, auth & roles, atomic locking.' },
  { no: '04', title: 'Data Model', desc: 'Every Firestore collection — fields, types, enums.' },
  { no: '05', title: 'Cloud Functions', desc: 'All 22 server-side functions grouped by category.' },
  { no: '06', title: 'Security Rules', desc: 'Access-control matrix and key invariants.' },
  { no: '07', title: 'Commission & Payouts', desc: 'Wage-split formula, commission config, cash-deposit ledger, voucher anti-abuse, capacity slots.' },
  { no: '08', title: 'Payments & Gateway', desc: 'Static gateway vs. Xendit dynamic, webhook flow.' },
  { no: '09', title: 'AI Features', desc: 'Multi-provider CS chat and business analyst.' },
  { no: '10', title: 'Notifications', desc: 'FCM push events and WhatsApp (Fonnte).' },
  { no: '11', title: 'Deployment', desc: 'Hosting targets, env vars, deploy commands, pre-deploy checklist.' },
  { no: '12', title: 'Changelog & Roadmap', desc: 'Development phases from MVP through the current feature set.' },
]

export default function PrintToc() {
  return (
    <section className="print-toc flex h-[194mm] w-[285mm] flex-col justify-center bg-white px-24 py-12 print:h-[194mm] print:w-[285mm]">
      <p className="font-mono text-[11px] font-bold uppercase tracking-[0.3em] text-admin">
        Table of Contents
      </p>
      <h1 className="mt-2 text-[30px] font-extrabold tracking-tight text-ink-soft">
        Contents
      </h1>

      <div className="mt-8 grid grid-cols-3 gap-x-10 gap-y-6">
        {CHAPTERS.map((ch) => (
          <div key={ch.no} className="flex gap-3">
            <span className="font-mono text-[20px] font-extrabold text-admin/30">{ch.no}</span>
            <div>
              <h3 className="text-[14px] font-bold text-ink-soft">{ch.title}</h3>
              <p className="mt-1 text-[11px] leading-relaxed text-text-secondary">{ch.desc}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  )
}
