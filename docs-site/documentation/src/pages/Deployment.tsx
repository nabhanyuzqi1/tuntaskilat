import { DocHeader, DocPage, H2, P, Table, Callout, Code, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'hosting-targets', label: 'Hosting Targets' },
  { id: 'functions-env', label: 'Cloud Functions Env Vars' },
  { id: 'deploy-commands', label: 'Deploy Commands' },
  { id: 'ci-checklist', label: 'Pre-Deploy Checklist' },
]

export default function Deployment() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Operations"
        title="Deployment"
        description="One Firebase project, multiple hosting sites, one Cloud Functions codebase."
      />

      <H2 id="hosting-targets">Hosting Targets</H2>
      <P>
        <Code>firebase.json</Code> declares multiple hosting entries, each
        mapped to a distinct Firebase Hosting site via{' '}
        <Code>.firebaserc</Code> target aliases:
      </P>
      <Table
        head={['Target', 'Public dir', 'Serves']}
        rows={[
          ['admin', 'apps/admin/build/web', 'Admin panel (Flutter web build)'],
          ['manualbook', 'docs-site/manualbook/dist', 'This end-user manual'],
          ['documentation', 'docs-site/documentation/dist', 'This developer reference'],
        ]}
      />
      <Callout type="info">
        Site IDs must be globally unique across all Firebase projects. If a
        bare name like <Code>manualbook</Code> is taken, Firebase assigns a
        project-prefixed fallback (e.g. <Code>tuntaskilat-manualbook</Code>)
        — check the actual <Code>*.web.app</Code> URL printed after{' '}
        <Code>firebase hosting:sites:create</Code>.
      </Callout>

      <H2 id="functions-env">Cloud Functions Env Vars</H2>
      <P>
        Optional integrations are gated behind environment variables in{' '}
        <Code>firebase/functions/.env</Code> — every one of them degrades
        gracefully (no-op, HTTP 501, or a clear <Code>failed-precondition</Code>{' '}
        error) when unset, so partial configuration never breaks the core
        booking flow.
      </P>
      <CodeBlock
        language="bash"
        title="firebase/functions/.env"
        code={`# WhatsApp notifications (waNotifOrder) — no-op if unset
FONNTE_TOKEN=

# Xendit dynamic payments — buatTagihanXendit throws if unset
XENDIT_SECRET_KEY=

# Xendit webhook — xenditWebhook returns HTTP 501 if unset
XENDIT_CALLBACK_TOKEN=

# AI fallback keys (settings/ai Firestore fields take precedence)
GEMINI_API_KEY=
OPENAI_API_KEY=
ANTHROPIC_API_KEY=`}
      />

      <H2 id="deploy-commands">Deploy Commands</H2>
      <CodeBlock
        language="bash"
        code={`# Build the docs sites
cd docs-site/manualbook && npm run build && cd ../..
cd docs-site/documentation && npm run build && cd ../..

# Build the admin web app
cd apps/admin && flutter build web --release && cd ../..

# Deploy everything
firebase deploy --only functions,firestore:rules,storage:rules,hosting

# Or scope to just the docs sites
firebase deploy --only hosting:manualbook,hosting:documentation`}
      />

      <H2 id="ci-checklist">Pre-Deploy Checklist</H2>
      <ul className="mb-6 ml-5 list-disc space-y-1.5 text-[13.5px] leading-relaxed text-[color:var(--fg-muted)]">
        <li><Code>flutter analyze</Code> clean across all 4 packages (tk_core, admin, pelanggan, kru).</li>
        <li><Code>flutter test packages/tk_core apps/admin</Code> — all green.</li>
        <li><Code>cd firebase/functions && npx tsc -p .</Code> — no type errors.</li>
        <li>Firestore Security Rules reviewed for any collection touched this release.</li>
        <li>New Cloud Functions match the region convention (<Code>asia-southeast2</Code>).</li>
      </ul>

      <PrevNext
        prev={{ to: '/notifications', label: 'Notifications' }}
        next={{ to: '/changelog', label: 'Changelog & Roadmap' }}
      />
    </DocPage>
  )
}
