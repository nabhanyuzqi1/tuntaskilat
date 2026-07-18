import { DocHeader, DocPage, H2, P, Table, Callout, PrevNext, Code } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'overview', label: 'System Overview' },
  { id: 'apps', label: 'Client Applications' },
  { id: 'shared-package', label: 'Shared Package (tk_core)' },
  { id: 'backend', label: 'Backend Services' },
  { id: 'auth', label: 'Auth & Roles' },
  { id: 'atomic-locking', label: 'Atomic Locking Pattern' },
]

export default function Architecture() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Introduction"
        title="Architecture"
        description="A monorepo of 3 Flutter clients sharing one package, backed by Firebase — Firestore as the source of truth, Cloud Functions as the money-critical safety net."
      />

      <H2 id="overview">System Overview</H2>
      <P>
        Every client writes optimistically via a Firestore transaction (client-side
        pricing/locking), and every write of consequence is re-validated by a
        Cloud Function running with the Admin SDK — which bypasses Security
        Rules and is treated as the single source of truth for money. The
        client is a preview; the server is authoritative.
      </P>
      <CodeBlock
        language="text"
        code={`┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Pelanggan  │   │     Kru     │   │    Admin    │
│  (Android)  │   │  (Android)  │   │    (Web)    │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       └────────────┬────┴────────┬────────┘
                     │             │
              packages/tk_core (models, services, theme)
                     │
       ┌─────────────┴─────────────────────────┐
       │            Firebase                     │
       │  Firestore · Auth · Storage · FCM        │
       │  Cloud Functions (asia-southeast2)       │
       └───────────────────────────────────────────┘
                     │
       ┌─────────────┴─────────────┐
       │  Xendit · Fonnte (WA) · AI providers  │
       │  (Gemini / OpenAI / Anthropic)          │
       └────────────────────────────────────────┘`}
      />

      <H2 id="apps">Client Applications</H2>
      <Table
        head={['App', 'Platform', 'Users', 'Purpose']}
        rows={[
          ['apps/pelanggan', 'Android', 'Customers', 'Browse services, book, pay, track, review, chat, AI CS.'],
          ['apps/kru', 'Android', 'Field crew', 'Accept jobs, navigate, report work, manage cash deposits.'],
          ['apps/admin', 'Flutter Web', 'Staff/owner', 'Manage orders, catalog, crew, vouchers, commission, operations.'],
        ]}
      />

      <H2 id="shared-package">Shared Package (tk_core)</H2>
      <P>
        <Code>packages/tk_core</Code> holds everything that must stay
        consistent across apps: Firestore models &amp; enums, the{' '}
        <Code>FirestoreService</Code> facade (all reads/writes/transactions),
        auth flow, theme tokens (colors, typography, radius), and shared
        widgets. No app talks to Firestore directly — everything routes
        through <Code>tk_core</Code>.
      </P>

      <H2 id="backend">Backend Services</H2>
      <Table
        head={['Service', 'Role']}
        rows={[
          ['Cloud Firestore', 'Document-based NoSQL database — the system of record for orders, users, payments, etc.'],
          ['Firebase Auth', 'Email/password + Google sign-in. Role (pelanggan/kru/admin) stored on the users document, not in Auth claims.'],
          ['Cloud Storage', 'Payment proof uploads, work-report photos, profile photos, service images.'],
          ['Cloud Functions', '22 functions (Node.js 20, TypeScript, region asia-southeast2) — triggers, scheduled jobs, and callables. See Functions reference.'],
          ['FCM', 'Push notifications for order status changes, chat messages, assignment reminders, broadcasts.'],
        ]}
      />

      <H2 id="auth">Auth &amp; Roles</H2>
      <P>
        A single <Code>UserRole</Code> enum (<Code>pelanggan</Code> |{' '}
        <Code>kru</Code> | <Code>admin</Code>) gates which app an account can
        log into. <Code>AuthService.signIn()</Code> checks the role against
        the app performing the login and signs the session out immediately on
        a mismatch (a pelanggan account cannot log into the Kru portal, etc.)
        — this check exists both client-side and mirrored in Security Rules.
      </P>
      <Table
        head={['Role', 'Self-registration?', 'How the account is created']}
        rows={[
          ['pelanggan', 'Yes', 'registerPelanggan() — email/password or Google sign-in, self-service.'],
          ['kru', 'No', "Admin only, via A5 → AkunKruService.buatAkunKru() (uses a secondary Firebase App instance so the admin's own session is never disturbed)."],
          ['admin', 'No', 'Existing admin only, via the buatAdmin callable Cloud Function (admin.auth().createUser() server-side).'],
        ]}
      />
      <Callout type="info">
        Admin accounts can additionally require TOTP 2FA (RFC 6238) at login —
        secret stored in <Code>admin2fa/&#123;uid&#125;</Code>, owner-only read/write.
      </Callout>

      <H2 id="atomic-locking">Atomic Locking Pattern</H2>
      <P>
        Booking a time slot is a classic race condition — two customers could
        both read "slot open" and both write a booking. Tuntaskilat solves
        this without a dedicated locking service, using a Firestore
        transaction against a capacity counter:
      </P>
      <CodeBlock
        language="typescript"
        title="simplified booking transaction"
        code={`await db.runTransaction(async (tx) => {
  const slotSnap = await tx.get(slotRef)
  const { terisi = 0, kapasitas } = slotSnap.data() ?? {}

  if (terisi >= kapasitas) throw new JadwalPenuhException()

  // Firestore rule enforces this write can ONLY increment by exactly 1
  tx.set(slotRef, { terisi: terisi + 1, kapasitas }, { merge: true })
  tx.set(orderRef, order.toMap())
})`}
      />
      <P>
        <Code>kapasitas</Code> (capacity) is not a fixed number — it's
        recomputed automatically whenever crew data changes (see{' '}
        <Code>recomputeKapasitasLayanan()</Code> in the Functions reference),
        so booking availability always reflects how many eligible crew are
        actually active for that service.
      </P>

      <PrevNext
        prev={{ to: '/getting-started', label: 'Getting Started' }}
        next={{ to: '/data-model', label: 'Data Model' }}
      />
    </DocPage>
  )
}
