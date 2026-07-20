import { DocHeader, DocPage, H2, P, Table, Callout, Code, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'helpers', label: 'Helper Functions' },
  { id: 'matrix', label: 'Access Control Matrix' },
  { id: 'invariants', label: 'Key Invariants' },
]

export default function SecurityRules() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="API Reference"
        title="Security Rules"
        description="firebase/firestore.rules — the second line of defense alongside Cloud Functions. Read/write access per collection."
      />

      <H2 id="helpers">Helper Functions</H2>
      <CodeBlock
        language="javascript"
        code={`function isSignedIn() { return request.auth != null; }
function role() { return get(/databases/$(db)/documents/users/$(request.auth.uid)).data.role; }
function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }
function isAdmin() { return isSignedIn() && role() == 'admin'; }`}
      />

      <H2 id="matrix">Access Control Matrix</H2>
      <Table
        head={['Collection', 'Read', 'Create', 'Update', 'Delete']}
        rows={[
          [<Code>users/&#123;userId&#125;</Code>, 'owner or admin', 'owner only', 'owner or admin', 'admin'],
          [<Code>services</Code>, 'public', '—', 'admin', 'admin'],
          [<Code>slots/&#123;slotId&#125;</Code>, 'any signed-in', 'signed-in, terisi must be exactly +1', 'same rule, or admin', 'admin'],
          [<Code>orders/&#123;orderId&#125;</Code>, 'participant or admin', 'signed-in owner; price fields must match services', 'admin, or participant limited to status/photos/cancellation', 'admin'],
          [<Code>orders/{'{id}'}/messages</Code>, 'participant or admin', 'participant or admin', '—', '—'],
          [<Code>kru/&#123;cleanerId&#125;</Code>, 'public', 'admin', 'owner/admin, or signed-in diff-only on rating fields', 'admin'],
          [<Code>settings/ai</Code>, 'admin only', 'admin', 'admin', 'admin'],
          [<Code>settings/&#123;other&#125;</Code>, "signed-in, or public if docId=='app'", 'admin', 'admin', 'admin'],
          [<Code>payments</Code>, 'owner or admin', 'signed-in owner', 'admin only', '—'],
          [<Code>reviews</Code>, 'public', 'signed-in owner', 'admin', 'admin'],
          [<Code>notifications</Code>, 'owner', 'any signed-in (ideally server-written)', '—', '—'],
          [<Code>vouchers/&#123;kode&#125;</Code>, 'signed-in', 'admin', 'admin, or diff-only terpakai == old+1', 'admin'],
          [<Code>voucherUsages</Code>, 'get: any signed-in; list: admin/owner', 'signed-in owner', 'admin', 'admin'],
          [<Code>broadcasts / banners</Code>, 'admin / public', 'admin', 'admin', 'admin'],
          [<Code>admin2fa/&#123;uid&#125;</Code>, 'owner', 'owner', 'owner', 'owner'],
          [<Code>payouts</Code>, 'admin or owning cleaner', 'admin or signed-in (in completion tx)', 'admin', 'admin'],
          [<Code>kasKru</Code>, 'admin or owning cleaner', '—', 'admin only', 'admin'],
          [<Code>setoran</Code>, 'admin or owning cleaner', 'admin', 'admin', 'admin'],
          [<Code>referralClaims</Code>, 'admin or any signed-in', '—', 'admin only', 'admin'],
          [<Code>disputes</Code>, 'admin or the filer', 'signed-in filer, status must be diajukan', 'admin', 'admin'],
        ]}
      />

      <H2 id="invariants">Key Invariants</H2>
      <Callout type="warning">
        Order money/ownership fields are immutable to non-admins once created
        — a client can only ever touch{' '}
        <Code>['status', 'fotoSebelum', 'fotoSesudah', 'penugasan']</Code> on
        an existing order, and cancellation is only permitted from
        pre-assignment statuses.
      </Callout>
      <P>Other write-shape constraints enforced at the rules layer:</P>
      <ul className="mb-6 ml-5 list-disc space-y-1.5 text-[13.5px] leading-relaxed text-[color:var(--fg-muted)]">
        <li>Slot <Code>terisi</Code> can only be incremented by exactly +1 per client write — decrements are admin-SDK only (the atomic-locking mechanism).</li>
        <li>Voucher <Code>terpakai</Code> can only increment by exactly 1 per write.</li>
        <li><Code>kru</Code> rating fields (<Code>rataRating</Code>, <Code>jumlahUlasan</Code>) can only move via a controlled delta matching a genuine review submission.</li>
        <li><Code>kasKru</Code> balances are never client-writable — only Cloud Functions (admin SDK, which bypasses rules entirely) or admin-authenticated writes can change them.</li>
      </ul>

      <PrevNext
        prev={{ to: '/functions', label: 'Cloud Functions' }}
        next={{ to: '/business-logic', label: 'Commission & Payouts' }}
      />
    </DocPage>
  )
}
