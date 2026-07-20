import { DocHeader, DocPage, H2, H3, P, Callout, Code, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'wage-split', label: 'Wage Splitting' },
  { id: 'commission-config', label: 'Commission Config' },
  { id: 'cash-deposit', label: 'Cash Deposit Ledger' },
  { id: 'voucher-formula', label: 'Voucher Discount Formula' },
  { id: 'anti-abuse', label: 'Voucher Anti-Abuse' },
  { id: 'capacity-slots', label: 'Capacity-Based Slots' },
  { id: 'arrears-guard', label: 'Cash Arrears Guard' },
]

export default function BusinessLogic() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Business Logic"
        title="Commission & Payouts"
        description="The exact algorithms behind money in Tuntaskilat — every formula here is enforced server-side, never trusted from the client."
      />

      <H2 id="wage-split">Wage Splitting — bagiUpah()</H2>
      <P>
        <Code>packages/tk_core/lib/models/wage.dart</Code> — splits a
        completed order's total between platform commission and crew,
        weighted by role.
      </P>
      <CodeBlock
        language="text"
        code={`totalInt   = round(total)
komisi     = round(totalInt × komisiPersen / 100)     // platform commission
pool       = totalInt − komisi                        // remaining for crew
totalBobot = Σ peran.bobot for each crew member         // worker=1.0, helper=0.6

for each crew member p:
    bagian[p] = floor(pool × p.peran.bobot / totalBobot)

sisa = pool − Σ bagian                                  // rounding remainder
bagian[crew.first] += sisa                               // remainder → lead/first member

# Guarantee: komisi + Σ bagian == total, exactly. No Rupiah lost or created.`}
      />
      <Callout type="warning">
        The server-side <Code>onOrderFinalize</Code> Cloud Function
        reimplements the same weighted split inline, but rounds each share{' '}
        <em>individually</em> rather than floor + remainder-to-first — so its
        per-share numbers can differ from the client's <Code>bagiUpah()</Code>{' '}
        preview by ±1 for the same input. The client value is only a preview;
        the Cloud Function is authoritative for actual payouts.
      </Callout>

      <H2 id="commission-config">Commission Config — KonfigKomisi</H2>
      <CodeBlock
        language="typescript"
        code={`persenUntuk(serviceId) = clamp(perLayanan[serviceId] ?? komisiPersen, 0, 100)`}
      />
      <P>
        Mirrored server-side as <Code>komisiPersenUntuk(serviceId)</Code>,
        reading <Code>settings/komisi</Code>. Global default is 20%.
      </P>

      <H2 id="cash-deposit">Cash Deposit Ledger — KasKru</H2>
      <P>
        For cash-paid orders, the crew member collects the full amount from
        the customer in person — but the platform's commission share is still
        owed. That amount is tracked as a debt (<Code>saldoTunai</Code>) the
        crew must periodically settle with the office.
      </P>
      <CodeBlock
        language="text"
        code={`saldoTunai == totalMasuk − totalSetor        // audit invariant
bolehTerimaTunai == saldoTunai <= batasNunggak   // default batasNunggak = Rp200,000`}
      />
      <P>
        <Code>saldoTunai</Code> increases exactly once per cash order,
        booked by <Code>onOrderFinalize</Code> (guarded by the{' '}
        <Code>kasTunaiDibukukan</Code> flag) — no client path can write it
        directly (Security Rules restrict <Code>kasKru</Code> writes to
        admin). It decreases only when an admin records a deposit via{' '}
        <Code>terimaSetoran()</Code>, which runs inside a transaction that
        rejects any deposit amount exceeding the current balance.
      </P>

      <H2 id="voucher-formula">Voucher Discount Formula</H2>
      <CodeBlock
        language="text"
        code={`if !aktif                          → reject 'nonaktif'
if now > berlakuHingga             → reject 'kadaluarsa'
if sisaKuota <= 0                  → reject 'kuotaHabis'   // sisaKuota = kuota<=0 ? ∞ : kuota-terpakai
if subtotal < minBelanja           → reject 'minimalBelanja'

potongan = tipe=='persen' ? subtotal × nilai / 100 : nilai
if tipe=='persen' && maxPotongan>0 && potongan>maxPotongan
    potongan = maxPotongan
if potongan > subtotal
    potongan = subtotal`}
      />
      <P>
        The server-side <Code>potonganFormulaVoucher()</Code> applies the
        same nominal-cap math WITHOUT the kuota/expiry/aktif gates (those are
        enforced client-side inside the booking transaction) — its purpose is
        purely to cap the claimed amount: <Code>potonganBenar = min(potonganKlien, formulaMax)</Code>,
        preventing a client from claiming more discount than the voucher's own
        math allows.
      </P>

      <H2 id="anti-abuse">Voucher Anti-Abuse</H2>
      <P>Two independent guards inside <Code>buatPesananLengkap()</Code>:</P>
      <H3 id="new-user-only">New-user-only vouchers</H3>
      <P>
        Checked <em>outside</em> the transaction (a query for any prior order
        by <Code>userId</Code>) — if the user has ordered before, throws{' '}
        <Code>VoucherException(hanyaPenggunaBaru)</Code>.
      </P>
      <H3 id="per-phone-lock">Per-phone-number lock</H3>
      <P>
        Doc ID <Code>voucherUsages/&#123;kode&#125;__&#123;normalizedPhone&#125;</Code>{' '}
        (phone normalized: <Code>0xxxx → 62xxxx</Code>, non-digits stripped).
        Inside the transaction, if that doc already exists → reject. This is
        keyed on <strong>phone number, not uid</strong> — specifically to
        prevent the "make a new account, reuse the phone number" abuse
        vector. <Code>voucher.terpakai</Code> is incremented by exactly 1 in
        the same transaction, matching the Security Rules constraint.
      </P>

      <H2 id="capacity-slots">Capacity-Based Slots</H2>
      <P>
        Replaces a legacy boolean "taken" lock with a live counter.{' '}
        <Code>services.jumlahKru</Code> — maintained by{' '}
        <Code>recomputeKapasitasLayanan()</Code>, triggered by{' '}
        <Code>onKruDitulis</Code> / <Code>onLayananDibuat</Code> /{' '}
        <Code>backfillKapasitasKru</Code> — is the count of active crew
        eligible for that service (empty <Code>keahlian</Code> = generalist,
        or <Code>keahlian</Code> includes the serviceId). This becomes the
        hourly booking capacity.
      </P>
      <CodeBlock
        language="text"
        code={`kapasitas = services.jumlahKru  (fallback 1 if field absent)
terisi >= kapasitas   → JadwalPenuhException
kapasitas <= 0         → TidakAdaKruException`}
      />
      <P>
        A service with zero eligible crew is fully locked for booking.
        Cancellation (<Code>onOrderCancelled</Code>) decrements{' '}
        <Code>terisi</Code> via the admin SDK — the only permitted decrement
        path.
      </P>

      <H2 id="arrears-guard">Cash Arrears Guard</H2>
      <CodeBlock
        language="dart"
        code={`if (order.tunai && !await bolehTerimaTunai(lead.cleanerId)) {
  throw KruNunggakException(lead.nama);
}`}
      />
      <P>
        Before assigning a cash-payment order to a lead crew member,{' '}
        <Code>tugaskanKruMulti()</Code> checks{' '}
        <Code>kasKru/&#123;lead&#125;.bolehTerimaTunai</Code>. A crew member
        who has accumulated more than the arrears threshold in un-deposited
        cash commission cannot be assigned new cash-paying jobs until they
        settle up.
      </P>

      <PrevNext
        prev={{ to: '/security-rules', label: 'Security Rules' }}
        next={{ to: '/payments', label: 'Payments & Gateway' }}
      />
    </DocPage>
  )
}
