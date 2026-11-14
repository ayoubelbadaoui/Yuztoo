# DDD Holy Book — Yuztoo Website

**Goal: 100 % DDD.** Every file knows which page or domain it belongs to, only the data layer
talks to Firebase, and no component mixes copy, layout and I/O.

If a rule here conflicts with a convenience, the rule wins. If a rule blocks a real need, change
the rule in this book **and** in `eslint.config.js` in the same PR — never work around it
silently.

A marketing website is not a CRM. It has many pages and almost no data layer, so the structure is
**per page**, not per feature. The Flutter app's four layers
(`domain` / `application` / `infrastructure` / `presentation`, see `docs/yuztoo-holy-book.md` on
`develop`) stay in the app; here the equivalent separation is
**content → seo → sections → page → data**.

---

## 0. The stack

| Item | Choice |
|------|--------|
| Build | Vite 6 |
| UI | React 18, plain JavaScript (`.js` / `.jsx`) — **no TypeScript** |
| Routing | A static route table in `src/routes.js`. **No react-router** — every page is prerendered and served by Firebase Hosting |
| Icons | `lucide-react` (tree-shaken) |
| Fonts | `@fontsource/*`, self-hosted |
| Tests | Vitest |
| Hosting | Firebase Hosting, site `yuztoo`, projects `yuztoo-dev` and `yuztoo` |

Build pipeline (`npm run build`) runs in this order and **every step must pass**:

```
node scripts/generate-sitemap.mjs   # sitemap.xml from the route table
vite build                          # the bundle
node scripts/prerender.mjs          # static HTML per route
node scripts/verify-no-app-code.mjs # no Flutter app / CRM imports
node scripts/verify-seo.mjs         # the SEO gate
```

---

## 1. The one law

> **Only `src/data/**` may import from `src/lib/firebase` or call our backend.**

That covers everything `lib/firebase` exports — Firestore, Auth, Storage, Functions, App Check —
and every raw `fetch` to a Cloud Function.

| Export | Allowed in |
|--------|-----------|
| `db` / Firestore helpers | `src/data/**` |
| `callFunction` / callable wrappers | `src/data/**` |
| `storage`, `auth` | `src/data/**` |
| `initializeApp` from `firebase/app` | `src/lib/firebase.js` only |

Enforced by ESLint (`no-restricted-imports`, **error**) on all of `src/**` except `src/data/**`
and `src/lib/**`.

Pages, sections, components, hooks, content modules, SEO modules → **never**.

Most of this site ships zero Firebase. A static marketing page must not pull the SDK at all
(see the [Performance Holy Book](./PERFORMANCE_HOLY_BOOK.md) §3).

---

## 2. Folder map

```
src/
  main.jsx                  entry + hydration
  routes.js                 the route table — single source for prerender and sitemap
  siteConfig.js             domain, brand, app-store links, contact (one source of truth)
  global.css                reset + tokens

  lib/
    firebase.js             client creation only, no business rules

  data/                     ALL I/O lives here
    leadSources.js          path -> "Site web / <Page>" map
    submitLead.js           the one door to the lead Cloud Function
    vitrineRead.js          public storefront read, by ID

  seo/                      shared SEO plumbing
    pageSeoData.js          per-route title/description/canonical/OG/JSON-LD
    pageSeoRender.js        turns SEO data into head tags (client + prerender)
    usePageSeo.js

  site/
    components/             cross-page pure UI (Button, Card, Section, Container)
    sections/               cross-page composed blocks (Header, Footer, CTA band)
    styles/                 shared CSS incl. responsive.css
    hooks/                  cross-page hooks

    <page>/                 one folder per page
      <Page>Page.jsx        the page component
      <page>Content.js      copy, image src + alt, figures — no JSX
      <page>SeoData.js      this page's SEO data
      generate<Page>Shell.js  static shell for the prerenderer
      sections/             sections used only by this page
      __tests__/

scripts/                    build pipeline (see §0)
public/                     robots.txt, sitemap.xml, images, .well-known
```

- A page folder owns everything only that page uses. The moment a third page needs a section, it
  moves up to `src/site/sections/`.
- `src/site/components/*` are pure: props in, events out. No content, no fetching.
- `src/utils/*` are pure functions, no I/O.

---

## 3. Content is data, not JSX

**Copy, image `src`, `alt` text and every figure live in `<page>Content.js`**, never inline in a
component. One source serves the React render, the prerendered shell, and future translation.

```js
// src/site/commercants/commercantsContent.js
export const COMMERCANTS_HERO = {
  title: 'Votre carnet de fidélité, sans carte ni application à installer',
  intro: 'Vos clients vous suivent en approchant leur téléphone. Vous les retrouvez à chaque passage.',
  image: {
    src: '/images/yuztoo/commercant-passage-nfc.webp',
    alt: 'Une cliente approche son téléphone du badge Yuztoo posé sur le comptoir',
    width: 1280,
    height: 720,
  },
}
```

Rules:

1. No user-facing string hard-coded in a `.jsx` file — including button labels and `aria-label`.
2. No image `src` or `alt` hard-coded in a section.
3. No invented figures. A number in a content module is real and verifiable, or it is not there.
4. Content modules contain no JSX, no imports from components, no I/O.

---

## 4. Data contract (mandatory shape)

```js
export async function getPublicVitrine(slug) {
  try {
    const snap = await getDoc(doc(db, 'storefronts', slug))
    if (!snap.exists()) return { data: null, error: null }
    return { data: toVitrine(snap), error: null }
  } catch (error) {
    return { data: null, error }
  }
}
```

Rules:

1. Always return `{ data, error }`. Never throw to the caller.
2. Map the raw document to a plain object (`toVitrine`) before returning. Firestore shapes never
   reach a component.
3. Read by ID. A query must be indexed, limited, and return explicit fields.
4. "Not found" is an expected outcome (`data: null, error: null`), not an error.
5. No React, no `window`, no DOM in `src/data/**`.
6. Every Cloud Function call gets a named wrapper — never call `callFunction('name', …)` from a
   component or a hook.
7. One door per concern: **all** forms go through `submitLead.js`.

---

## 5. Routes

`src/routes.js` is the single source of truth. Adding a page means adding one entry there, and
the prerenderer, the sitemap generator and the SEO gate all pick it up:

```js
{ path: '/pour-commercants', component: () => import('./site/commercants/CommercantsPage.jsx'),
  indexable: true, lastmod: '2026-11-14' }
```

A page that exists but is not in `routes.js` is a bug: it will not be prerendered and the SEO
gate will fail on the sitemap mismatch.

---

## 6. Never import app or CRM code

This branch is website-only. It must not import from the Flutter app (`lib/feature/**`), the CRM,
or any Dart source. Shared values (brand colors, app-store URLs, store slugs) are duplicated as
small constants in `src/siteConfig.js`, with a comment naming the source of truth.

`scripts/verify-no-app-code.mjs` fails the build if this is broken — the same role
`verify-no-crm.mjs` plays on the IMIGO website.

---

## 7. Hooks (composition)

- Big flows are composed from small hooks: `useLeadFormState`, `useLeadSubmit`.
- The orchestrator wires sub-hooks and returns the public API — no 200-line `useEffect`.
- `react-hooks/exhaustive-deps` must stay satisfied.

---

## 8. File size limits (ESLint `max-lines`)

| Location | Max lines |
|----------|-----------|
| `src/data/**`, `src/lib/**` | 800 |
| `src/site/**/*Content.js`, `src/seo/**` | 800 |
| `src/site/**/*Page.jsx` | 550 |
| `src/site/components/**`, `src/site/sections/**` | 450 |
| Everything else in `src` | 500 |

Over the limit → split in the same PR. Never raise the ceiling.

---

## 9. Ubiquitous language

Use the same business words the app and the CRM use, in French copy and in code:

| Business term (FR) | Code term |
|---|---|
| Commerçant | `merchant` (URL: `/pour-commercants`) |
| Client / consommateur | `client` (URL: `/pour-clients`) |
| Vitrine (page publique du commerce) | `vitrine` |
| Programme de fidélité / e-fidélité | `loyalty` |
| Passage (visite validée NFC/BLE) | `passage` |
| Promotion | `promotion` |
| Rappel | `reminder` |
| Prospect venu du site | `lead` |

Don't invent synonyms. If a new term is needed, add it here.

---

## 10. PR checklist

- [ ] `npx eslint src` → zero `no-restricted-imports` errors
- [ ] No `lib/firebase` import and no raw backend `fetch` outside `src/data/**`
- [ ] Every Cloud Function call has a named wrapper in `src/data/**`
- [ ] Data functions return `{ data, error }` with mapped results
- [ ] Copy, image `src` and `alt` live in a `*Content.js`, not inline in JSX
- [ ] New page added to `src/routes.js`
- [ ] No file over its `max-lines` limit (or split in this PR)
- [ ] No import from the Flutter app or the CRM
- [ ] `npm run build` passes all five pipeline steps

Quick audit command:

```bash
rg -n "from ['\"][^'\"]*lib/firebase['\"]" src -g '!src/data/**' -g '!src/lib/**'
# must print nothing
```

---

## 11. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No `package.json`, no `eslint.config.js`, no `vite.config.js` — none of the rules above are
  machine-enforced yet. Set up ESLint with `no-restricted-imports` and `max-lines` in the first
  code PR.
- None of the five pipeline scripts exist: `generate-sitemap.mjs`, `prerender.mjs`,
  `verify-no-app-code.mjs`, `verify-seo.mjs`, and the sitemap/route wiring they depend on.
- No `src/routes.js`, no `src/siteConfig.js`.
- The nine pages currently served from the app repo are hand-written single-file HTML with copy,
  CSS and markup in one file. Each one needs splitting into page / content / SEO modules when it
  is migrated here.
