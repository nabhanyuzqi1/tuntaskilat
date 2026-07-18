# Tuntaskilat — Buku Panduan

End-user manual site for Tuntaskilat (on-demand cleaning service platform) — covers the Pelanggan (customer), Kru (worker), and Admin apps. Bahasa Indonesia, non-technical.

Live at: https://tuntaskilat-manualbook.web.app

## Stack

React 19 + TypeScript + Vite + Tailwind CSS v4 + Framer Motion + React Router.

## Development

```bash
npm install
npm run dev
```

## Build & Deploy

```bash
npm run build
# from repo root:
firebase deploy --only hosting:manualbook
```

See `docs-site/documentation` (the sibling technical reference site) for architecture, data model, and API docs.
