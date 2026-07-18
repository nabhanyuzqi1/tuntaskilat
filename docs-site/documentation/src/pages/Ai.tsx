import { DocHeader, DocPage, H2, P, Table, Callout, Code, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'multi-provider', label: 'Multi-Provider Config' },
  { id: 'cs-ai', label: 'Customer Service AI (csAi)' },
  { id: 'business-ai', label: 'Business Analyst AI' },
  { id: 'guardrails', label: 'Guardrails' },
]

export default function Ai() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Integrations"
        title="AI Features"
        description="Two AI-powered callables — a customer-facing support chat and an admin-facing business analyst — both provider-agnostic."
      />

      <H2 id="multi-provider">Multi-Provider Config</H2>
      <P>
        <Code>settings/ai</Code> (admin-only, read/write) selects which
        provider is active and holds its key:
      </P>
      <Table
        head={['Field', 'Notes']}
        rows={[
          ['provider', 'gemini | openai | anthropic'],
          ['geminiApiKey / openaiApiKey / anthropicApiKey', 'per-provider key field; falls back to env vars (GEMINI_API_KEY, etc.) if empty'],
          ['model', 'defaults: gemini-2.0-flash, gpt-4o-mini, claude-haiku-4-5'],
          ['aktif', 'master on/off switch'],
        ]}
      />
      <Callout type="warning">
        Because keys fall back to environment variables, a deployed env var
        can silently supply a key even if the admin panel shows none
        configured — worth checking both when debugging "AI not responding".
      </Callout>
      <P>
        A single dispatcher, <Code>panggilAi()</Code>, routes to the correct
        REST endpoint per provider: Gemini's <Code>generateContent</Code>{' '}
        (key in query string), OpenAI's <Code>/chat/completions</Code>, or
        Anthropic's <Code>/v1/messages</Code>.
      </P>

      <H2 id="cs-ai">Customer Service AI — csAi</H2>
      <CodeBlock
        language="typescript"
        code={`// onCall, auth required
Input:  { pertanyaan: string, orderId?: string }
Output: { jawaban: string }`}
      />
      <P>
        The system prompt is grounded in the{' '}
        <strong>live active-service catalog and prices</strong>, fixed
        operating hours (08.00–19.00 WIB), the 3 payment methods, and
        cancellation policy. If <Code>orderId</Code> is supplied and belongs
        to the calling uid, that order's current status is injected as
        additional context — the assistant only ever sees the caller's own
        data.
      </P>
      <P>
        Fallback: if the AI config's key is missing or <Code>aktif</Code> is
        false, the function throws{' '}
        <Code>failed-precondition</Code> ("Asisten AI belum diaktifkan").
      </P>

      <H2 id="business-ai">Business Analyst AI — analisaBisnisAi</H2>
      <CodeBlock
        language="typescript"
        code={`// onCall, admin-only
Output: { ringkasan: string }`}
      />
      <P>
        Purely numeric aggregation is done server-side in TypeScript — the
        LLM never touches the database directly. Over the trailing 30 days
        of <Code>orders</Code>, the function computes: total / selesai /
        dibatalkan counts, omzet (revenue from completed orders), and a
        per-service order-count breakdown — then hands those numbers to{' '}
        <Code>panggilAi()</Code> with a prompt capped at 6 bullet points plus
        2–3 concrete action suggestions.
      </P>

      <H2 id="guardrails">Guardrails</H2>
      <ul className="mb-6 ml-5 list-disc space-y-1.5 text-[13.5px] leading-relaxed text-[color:var(--fg-muted)]">
        <li>The prompt explicitly forbids fabricating data or leaking other customers' PII.</li>
        <li><Code>analisaBisnisAi</Code> is told not to fabricate beyond the numbers it was given.</li>
        <li>Both functions require the caller to be authenticated; the business analyst additionally requires <Code>role == 'admin'</Code>.</li>
      </ul>

      <PrevNext
        prev={{ to: '/payments', label: 'Payments & Gateway' }}
        next={{ to: '/notifications', label: 'Notifications' }}
      />
    </DocPage>
  )
}
