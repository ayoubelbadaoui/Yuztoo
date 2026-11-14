# Yuztoo Website — Holy Books

Five non-negotiable rulebooks for the **public Yuztoo website** (`yuztoo.com`). Read the relevant
one before starting a feature, and run its PR checklist before merging.

| Book | Goal | Enforced by |
|------|------|-------------|
| [DDD Holy Book](./DDD_HOLY_BOOK.md) | 100 % DDD — only the data layer talks to Firebase | ESLint `no-restricted-imports` (error), `max-lines` |
| [Security Holy Book](./SECURITY_HOLY_BOOK.md) | 100 % secure — the server enforces, the browser is hostile | Firestore rules, Cloud Functions, hosting headers, review |
| [SEO Holy Book](./SEO_HOLY_BOOK.md) | 100 % SEO — public pages rank, private pages stay hidden | SEO gate in the build, sitemap/robots scripts, Search Console |
| [Performance Holy Book](./PERFORMANCE_HOLY_BOOK.md) | 100 % fast — quick first paint, cheap reads | Build output, Lighthouse, Firebase usage dashboard |
| [Responsive Holy Book](./RESPONSIVE_HOLY_BOOK.md) | 100 % responsive — perfect from 320 px to 1920 px | Browser audit script (§8), Lighthouse mobile |

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
| Production domain | `https://yuztoo.com` (`yuztoo.app` redirects to it) |
| Language | French first — `lang="fr"`, `og:locale` `fr_MA` |
| Positioning | « Le carnet de vos commerces » — fidélité et proximité par un geste NFC |
| Audiences | **Commerçants** (merchants who open a storefront) and **clients** (shoppers who follow them) |
| Hosting | Firebase Hosting, site `yuztoo`, projects `yuztoo-dev` and `yuztoo` |
| Brand colors | navy `#0B1F33`, navy-2 `#102C49`, navy-3 `#0E2A44`, gold `#C9A352`, cream `#F4EDDD` |

## Assumed stack

Until the first website commit lands, these books assume a **Vite + React + TypeScript** site that
prerenders every indexable page to static HTML and deploys to Firebase Hosting. If the stack
changes, update the books in the same PR instead of letting them drift — the rules (prerendered
HTML, one data layer, server-enforced security, 320 px support) hold for any stack.
