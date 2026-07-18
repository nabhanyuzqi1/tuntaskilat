# Tuntaskilat — Developer Documentation

Technical reference site for Tuntaskilat — data model, Cloud Functions API, security rules, and business logic.

Live at: https://tuntaskilat-documentation.web.app

## Stack

React 19 + TypeScript + Vite + Tailwind CSS v4 + Framer Motion + React Router + prism-react-renderer (code blocks).

## Development

```bash
npm install
npm run dev
```

## Build & Deploy

```bash
npm run build
# from repo root:
firebase deploy --only hosting:documentation
```

Content data (Cloud Functions list, Firestore schema) lives in `src/data/` — update there when the backend changes, rather than editing the page components directly.

See `docs-site/manualbook` (the sibling end-user manual site) for the non-technical guide.
