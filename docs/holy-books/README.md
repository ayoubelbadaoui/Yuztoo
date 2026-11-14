# Yuztoo Website — Holy Books

Six non-negotiable rulebooks for the **public Yuztoo website** (`www.yuztoo.com`). Read the
relevant one before starting a feature, and run its PR checklist before merging.

| Book | Goal | Enforced by |
|------|------|-------------|
| [DDD Holy Book](./DDD_HOLY_BOOK.md) | 100 % DDD — only the data layer talks to Firebase | ESLint `no-restricted-imports` (error), `max-lines` |
| [Brand Holy Book](./BRAND_HOLY_BOOK.md) | The website looks like the app — same tokens | Tokens in `global.css`, contrast checks, review |
| [Security Holy Book](./SECURITY_HOLY_BOOK.md) | 100 % secure — the server enforces, the browser is hostile | Firestore rules, Cloud Functions, hosting headers, review |
| [SEO Holy Book](./SEO_HOLY_BOOK.md) | 100 % SEO — public pages rank, private pages stay hidden | SEO gate in the build, sitemap/robots scripts, Search Console |
| [Performance Holy Book](./PERFORMANCE_HOLY_BOOK.md) | 100 % fast — quick first paint, cheap reads | Build output, Lighthouse, Firebase usage dashboard |
| [Responsive Holy Book](./RESPONSIVE_HOLY_BOOK.md) | 100 % responsive — perfect from 320 px to 1920 px | Browser audit script (§8), Lighthouse mobile |

The rebuild baseline — what the current WordPress site does well and where it fails — is in
[`docs/website-audit-2026-11.md`](../website-audit-2026-11.md).

Each book ends with a **Known gaps** section: the violations still open. When you fix one, delete
it from the list in the same PR.

## Scope

**In scope:** the marketing / public website on this `site-web` branch — homepage, product pages,
pricing, merchant acquisition pages, legal pages, blog, and the public `vitrine` (storefront)
pages served from Firebase Hosting.

**Out of scope:** the Flutter mobile app (`develop` and other branches) and the Yuztoo CRM. This
branch contains website code only and must never import app or CRM source.

## Product facts the books assume

| Fact | Value |
|------|-------|
| Production domain | `https://www.yuztoo.com` (apex and `yuztoo.app` redirect to it) |
| Language & market | French — `lang="fr-FR"`, `og:locale` `fr_FR`. **France, currently Belfort** |
| Positioning | Les plateformes possèdent vos clients ; Yuztoo vous rend la relation. Une plaque à scanner en boutique — sans publicité, sans commission, sans dépendance |
| Audiences | **Commerçants**, **clients**, and **collectivités** (municipalities) — three doors, three pages |
| Hosting | Firebase Hosting, site `yuztoo`, projects `yuztoo-dev` and `yuztoo` |
| Brand colors | Copied from the Flutter app — see the [Brand Holy Book](./BRAND_HOLY_BOOK.md) §1 |
| Typography | Montserrat + JetBrains Mono for labels, self-hosted (`@fontsource/*`) |
| Contact | contact@yuztoo.com, +33 6 09 52 65 11 |

## Stack

**Vite 6 + React 18 in plain JavaScript** (`.js` / `.jsx`, no TypeScript), no router — every
indexable page is prerendered to static HTML and served by Firebase Hosting. Icons via
`lucide-react`, fonts self-hosted via `@fontsource/*`, tests with Vitest.

This mirrors the IMIGO website (`themoutaouakil/imigo`, branch `website`), which these books are
adapted from. Full detail and the build pipeline: [DDD Holy Book](./DDD_HOLY_BOOK.md) §0.
