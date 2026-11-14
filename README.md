# Yuztoo — Site web

Public marketing website for Yuztoo (`https://www.yuztoo.com`), deployed on Firebase Hosting.
It replaces the current WordPress site — see
[`docs/website-audit-2026-11.md`](./docs/website-audit-2026-11.md) for the baseline and the
rebuild plan.

This branch (`site-web`) contains **website code only**. It has no shared history with the Flutter
app and must never import app or CRM source. The mobile app lives on `develop` and its siblings.

**Stack:** Vite 6 + React 18 in plain JavaScript (no TypeScript), no router — every page is
prerendered to static HTML. Build pipeline and folder map:
[DDD Holy Book](./docs/holy-books/DDD_HOLY_BOOK.md) §0–§2.

## Holy books — read before you code

Six non-negotiable rulebooks live in [`docs/holy-books/`](./docs/holy-books/README.md). Read the
relevant one before starting a feature and run its PR checklist before merging.

| Book | Goal |
|------|------|
| [DDD](./docs/holy-books/DDD_HOLY_BOOK.md) | Only `src/data` talks to Firebase |
| [Brand](./docs/holy-books/BRAND_HOLY_BOOK.md) | The site looks like the app — tokens copied from Flutter |
| [Security](./docs/holy-books/SECURITY_HOLY_BOOK.md) | The server enforces; the browser is hostile |
| [SEO](./docs/holy-books/SEO_HOLY_BOOK.md) | Public pages rank, private pages stay hidden |
| [Performance](./docs/holy-books/PERFORMANCE_HOLY_BOOK.md) | Static first, fast on mobile, cheap on Firebase |
| [Responsive](./docs/holy-books/RESPONSIVE_HOLY_BOOK.md) | Perfect from 320 px to 1920 px |

Each book ends with a **Known gaps** section listing what is still open. Right now every book's
gap list is the build-out backlog, because no site code exists yet.

## Deployment

Firebase Hosting, site `yuztoo`. Every change to hosting, rules or functions deploys to **both**
projects in the same task — `yuztoo-dev` and `yuztoo`. See
[`docs/firebase-dual-env-deploy.md`](./docs/firebase-dual-env-deploy.md).

## Status

No site code yet. The next step is the first scaffold PR: Vite + React skeleton, `src/routes.js`,
ESLint with the DDD and `max-lines` rules, and the five build-pipeline scripts
(`generate-sitemap`, `prerender`, `verify-no-app-code`, `verify-seo`).
