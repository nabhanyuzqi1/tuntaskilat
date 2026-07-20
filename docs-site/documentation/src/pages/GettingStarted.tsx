import { DocHeader, DocPage, H2, P, Callout, PrevNext } from '../components/Kit'
import CodeBlock from '../components/CodeBlock'

const TOC = [
  { id: 'prerequisites', label: 'Prerequisites' },
  { id: 'repo-structure', label: 'Repository Structure' },
  { id: 'setup', label: 'Local Setup' },
  { id: 'running', label: 'Running Each App' },
  { id: 'testing', label: 'Testing' },
]

export default function GettingStarted() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Introduction"
        title="Getting Started"
        description="Clone the monorepo, install dependencies, and get all three apps running locally."
      />

      <H2 id="prerequisites">Prerequisites</H2>
      <P>You'll need the following tools installed:</P>
      <CodeBlock
        language="bash"
        code={`Flutter SDK    3.41.x (stable channel)
Dart SDK       3.11.x
Node.js        20.x
Firebase CLI   latest  (npm i -g firebase-tools)
A Firebase project with Firestore, Auth, Storage, Functions, FCM enabled`}
      />

      <H2 id="repo-structure">Repository Structure</H2>
      <P>This is a Flutter pub workspace monorepo — one Git repository, multiple apps sharing a common package:</P>
      <CodeBlock
        language="bash"
        code={`tkapps/
├── apps/
│   ├── pelanggan/     # Customer app (Android)
│   ├── kru/            # Worker app (Android)
│   └── admin/          # Admin panel (Flutter Web)
├── packages/
│   └── tk_core/         # Shared models, services, theme, widgets
├── firebase/
│   ├── functions/       # Cloud Functions (TypeScript)
│   ├── firestore.rules
│   └── storage.rules
├── docs-site/
│   ├── manualbook/       # This site's sibling — end-user manual
│   └── documentation/    # You are here
├── firebase.json         # Hosting targets, functions, rules
└── pubspec.yaml           # Workspace root`}
      />

      <H2 id="setup">Local Setup</H2>
      <CodeBlock
        language="bash"
        code={`git clone https://github.com/nabhanyuzqi1/tuntaskilat.git
cd tuntaskilat

# Flutter workspace — installs deps for all 3 apps + tk_core at once
flutter pub get

# Cloud Functions
cd firebase/functions
npm install
cd ../..

# Connect to your own Firebase project (or use the existing one)
firebase use --add`}
      />
      <Callout type="info">
        Each app needs its own <code>firebase_options.dart</code>, generated
        via <code>flutterfire configure</code> — run it once per app
        (<code>apps/pelanggan</code>, <code>apps/kru</code>, <code>apps/admin</code>).
      </Callout>

      <H2 id="running">Running Each App</H2>
      <CodeBlock
        language="bash"
        code={`# Customer app (Android emulator/device)
cd apps/pelanggan && flutter run

# Worker app
cd apps/kru && flutter run

# Admin panel (web)
cd apps/admin && flutter run -d chrome

# Cloud Functions emulator
cd firebase && firebase emulators:start --only firestore,functions`}
      />

      <H2 id="testing">Testing</H2>
      <CodeBlock
        language="bash"
        code={`# Unit + widget tests (business logic, pricing, security scenarios)
flutter test packages/tk_core
flutter test apps/admin

# Static analysis across the workspace
flutter analyze packages/tk_core apps/admin apps/pelanggan apps/kru

# Cloud Functions type-check
cd firebase/functions && npx tsc -p .`}
      />

      <PrevNext next={{ to: '/architecture', label: 'Architecture' }} />
    </DocPage>
  )
}
