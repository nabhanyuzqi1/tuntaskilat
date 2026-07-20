import { DocHeader, DocPage, H2, P, Table, Callout, Code, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'gateway-abstraction', label: 'Gateway Abstraction' },
  { id: 'static-vs-dynamic', label: 'Static vs. Dynamic' },
  { id: 'xendit-flow', label: 'Xendit Flow' },
  { id: 'config-split', label: 'Commission vs. Payment Config' },
]

export default function Payments() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Integrations"
        title="Payments & Gateway"
        description="Payment methods are pluggable — a manual verification flow ships by default, with Xendit available as an opt-in dynamic gateway."
      />

      <H2 id="gateway-abstraction">Gateway Abstraction</H2>
      <P>
        <Code>packages/tk_core/lib/services/payment_gateway.dart</Code>{' '}
        defines a <Code>PaymentGateway</Code> interface to avoid vendor
        lock-in:
      </P>
      <CodeBlock
        language="dart"
        code={`abstract class PaymentGateway {
  Future<InstruksiBayar> buatInstruksi({
    required String orderId,
    required int jumlah,
    required MetodeBayar metode,
  });
  String get nama;
}

class StaticGateway implements PaymentGateway { ... }  // active by default
class XenditGateway implements PaymentGateway { ... }   // opt-in`}
      />

      <H2 id="static-vs-dynamic">Static vs. Dynamic</H2>
      <Table
        head={['', 'StaticGateway', 'XenditGateway']}
        rows={[
          ['Instructions', 'Fixed bank account / QRIS image from settings/pembayaran', 'Per-order dynamic VA / QRIS from Xendit'],
          ['Verification', 'Manual — customer uploads proof, admin approves/rejects', 'Automatic — settled via webhook'],
          ['Requires', 'Nothing extra (default MVP flow)', 'XENDIT_SECRET_KEY + XENDIT_CALLBACK_TOKEN env vars'],
          ['Status if unconfigured', 'Always available', 'buatTagihanXendit throws failed-precondition; xenditWebhook returns HTTP 501'],
        ]}
      />
      <Callout type="info">
        Both paths land on the same <Code>payments</Code> collection and,
        once <Code>terverifikasi</Code>, feed into the same commission /
        payout calculation — they're layered, not competing systems.
      </Callout>

      <H2 id="xendit-flow">Xendit Flow</H2>
      <CodeBlock
        language="text"
        code={`1. Customer selects a Xendit-backed method at checkout
2. App calls buatTagihanXendit({ orderId, amount })
     → verifies caller owns the order
     → POST https://api.xendit.co/v2/invoices  (Basic auth from XENDIT_SECRET_KEY)
     → persists { gateway, invoiceId, invoiceUrl } on the payment doc
     → returns invoiceUrl for the app to open
3. Customer completes payment on Xendit's hosted page
4. Xendit calls xenditWebhook with x-callback-token + { external_id: orderId, status }
     → validates token (401 if wrong)
     → on PAID/SETTLED: payments.statusBayar = 'terverifikasi', orders.status = 'terverifikasi'`}
      />

      <H2 id="config-split">Commission vs. Payment Config — Two Different Things</H2>
      <P>
        It's easy to confuse <Code>settings/komisi</Code> and{' '}
        <Code>settings/pembayaran</Code> because both live under "money
        settings" in the admin panel — but they govern orthogonal concerns:
      </P>
      <Table
        head={['Setting', 'Controls']}
        rows={[
          [<Code>settings/komisi</Code>, "The platform's revenue-share percentage taken from each completed order, used by bagiUpah/onOrderFinalize to split money between platform and crew."],
          [<Code>settings/pembayaran</Code>, 'Which customer-facing payment methods are offered and whether each is statis (manual) or dinamis (Xendit).'],
        ]}
      />
      <P>
        A <Code>dinamis</Code> payment method still goes through the same
        commission calculation once the order completes — the two systems
        are layered, not competing.
      </P>

      <PrevNext
        prev={{ to: '/business-logic', label: 'Commission & Payouts' }}
        next={{ to: '/ai', label: 'AI Features' }}
      />
    </DocPage>
  )
}
