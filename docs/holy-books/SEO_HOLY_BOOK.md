# SEO Holy Book — Yuztoo Website

**Goal: 100 % SEO-optimized** Yuztoo website (`https://yuztoo.com`, local `http://localhost:3001/`).

**Scope:** the public website only. The Flutter app, the CRM and tokenized links are **never**
indexed. Language: French first (`lang="fr"`, `og:locale` `fr_MA`). Market: Morocco — commerçants
de proximité and their clients.

---

## 0. The law — no website change ships without its SEO

Any change to the website (new page, new section, renamed URL, new image, new content block,
removed page) is **not done** until:

1. Every item of §1 is satisfied for each affected page.
2. The **Page registry** (§9) is updated.
3. The **Changelog** (§10) has a dated line describing the change.
4. `npm run build` passes. The build ends with **`scripts/verify-seo.mjs` (the SEO gate)**, which
   fails the build if any page breaks §1 / §5b — so a green build means every page passes the
   technical checks below. Never bypass or loosen the gate to ship.
5. The §7 release checklist is ticked in the PR description.

AI agents: do this automatically in the same change, without being asked.

---

## 1. Every indexable page must have

| Item | Rule |
|------|------|
| `<title>` | Unique, 30–65 chars (aim 50–65), primary keyword first, brand last (`… \| Yuztoo`) — **gate-enforced** |
| `meta description` | Unique, 110–160 chars (aim 140–160), keyword + benefit + call to action — **gate-enforced** |
| `link rel="canonical"` | Absolute `https://yuztoo.com/...`, no query string, no trailing slash (Hosting uses `trailingSlash: false`) |
| `meta robots` | `index, follow, max-image-preview:large` |
| Open Graph | `og:title`, `og:description`, `og:url`, `og:image` (**1200×630 JPEG ≤ 200 KB** in `public/images/og/`), `og:image:width/height/alt`, `og:type`, `og:locale`, `og:site_name` |
| Twitter | `twitter:card=summary_large_image`, title, description, image |
| `<h1>` | Exactly one, contains the primary keyword |
| Headings | Logical `h2` → `h3` order, never chosen for styling |
| JSON-LD | `WebPage` + `BreadcrumbList` (+ `Organization` / `SoftwareApplication` on `/`); `Service` on product pages; `FAQPage` when there is an FAQ; `Article` on blog posts; `LocalBusiness` on public vitrine pages |
| Sitemap | Listed in `src/routes.js` with a real `lastmod`, which `scripts/generate-sitemap.mjs` reads. **Bump the date when you change a page; never use the build date.** The gate checks sitemap ⇄ indexable pages match exactly |
| Fonts | Self-hosted via `@fontsource/*` (no `fonts.googleapis.com` — gate-enforced) |
| Search Console | Set `VITE_GSC_VERIFICATION` at build time; prerender adds the `google-site-verification` meta only when set |
| Prerender | Written to `dist/<path>/index.html` by `scripts/prerender.mjs` |
| Internal links | Linked from the header/footer nav or another indexed page with descriptive anchor text |

Pattern: one `<page>SeoData.js` module per page (the single source for both the browser and the
prerenderer), `usePageSeo` applying it client-side, and a `generate<Page>Shell.js` producing the
crawlable HTML. Never hand-write meta tags inline in a page.

## 2. Crawlable HTML

1. Every indexable page ships **prerendered HTML** (meta + JSON-LD + text shell), never an empty
   `<div id="root">`. AI crawlers (ChatGPT, Perplexity, Claude, Gemini) do not run JavaScript.
2. The shell mirrors the real page content — no keyword stuffing, no text visitors can't see.
3. Main text lives in HTML, not in images, canvas or screenshots of the app.
4. Navigation uses real `<a href>` / `<Link>`, never `onClick` on a `div`.
5. Content behind tabs and accordions is rendered in the DOM and toggled with CSS.

## 3. URLs

1. Lowercase, hyphenated, French keywords: `/pour-commercants`, `/programme-fidelite`, `/contact`.
2. One URL per piece of content; duplicates canonicalize to the primary URL.
3. Renamed or removed page → **301 in `firebase.json`** (`redirects` array, `"type": 301`), added
   in the same change. Deploy to **both** `yuztoo-dev` and `yuztoo`.
4. `yuztoo.app` and `www.yuztoo.com` → 301 to the apex `https://yuztoo.com`.
5. Unknown URL → real 404 with `noindex` (Firebase Hosting `"cleanUrls": true` plus a 404 page;
   never serve the SPA shell with status 200).
6. Deep-link files (`/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json`)
   keep their existing `Content-Type` and `Cache-Control` headers. Never route them through the SPA.

## 4. Never index

`robots.txt` `Disallow` **and** `noindex` (meta plus a `X-Robots-Tag` header in `firebase.json`):

- CRM routes and any admin host
- Tokenized / invitation links: `/invite*`, `/supprimer-compte`, account and auth callbacks
- App-only deep-link landing targets that duplicate a real page
- Experiments and tools: `/test*`, preview and staging hosts (`*.web.app`, `*.firebaseapp.com`
  → `Disallow: /` so the dev project never competes with production)

## 5. Content

1. Product pages answer: who it is for, what the merchant or client gets, how it works (NFC,
   fidélité, vitrine), what it costs, how to start, FAQ, CTA. ~600+ words of useful original text.
2. Show expertise and trust (E-E-A-T): real company identity, address, named team, real merchant
   testimonials, last-updated date on anything with figures.
3. Images: descriptive French `alt`; decorative `alt=""`; explicit `width`/`height`; WebP/AVIF;
   hosted in `public/` (never hotlinked).
4. Keep pricing, store counts and app-store links current.
5. Same NAP (name, address, phone) on the site, in JSON-LD, and on the Google Business Profile.
6. No invented numbers. No fake counters, fake charts or placeholder testimonials — ever.

## 5b. Images (every image, every time)

| Rule | How |
|------|-----|
| Self-hosted | `public/images/yuztoo/`, never hotlinked (Drive, Unsplash CDN, app stores…) |
| File name | French keywords, hyphenated, describes the subject: `commercant-carte-fidelite-nfc.webp`, never `IMG_1234.jpg` |
| Format & weight | WebP (OG image: JPEG). Hero ≤ 120 KB, cards ≤ 90 KB, OG ≤ 200 KB. Re-encode at `quality≈62` |
| Dimensions | Exported at 2× the displayed size; `width`/`height` attributes = real pixel size (no CLS) |
| `alt` | French, specific: says what is shown and why it matters. Decorative → `alt=""`. People → name + role |
| Loading | Hero: `fetchPriority="high"` + `<link rel="preload">` in the prerendered head. Everything else: `loading="lazy" decoding="async"` |
| Source | Image paths and alts live in a content module, never hard-coded inside a section component |
| Licence | Own photos and real app screenshots, or Unsplash/Pexels (free commercial use). No Google Images, no watermarked stock |
| App screenshots | Real builds only, current UI, device frame optional, text legible at the displayed size |
| Share image | `og:image` 1200×630 + `og:image:width/height/alt` |

## 6. Core Web Vitals

Follow the [Performance Holy Book](./PERFORMANCE_HOLY_BOOK.md) §6: LCP < 2 s, CLS < 0.05,
INP < 200 ms on mobile.

## 7. Release checklist (copy into the PR)

- [ ] §1 complete for each new/changed page (title, description, canonical, OG, one `h1`, JSON-LD)
- [ ] Page added to `src/routes.js` (so sitemap + prerender pick it up)
- [ ] Linked from nav/footer or another indexed page
- [ ] Renamed/removed URLs added to `firebase.json` `redirects` (301) and deployed to both projects
- [ ] Private/test pages in `robots.txt` **and** `noindex`
- [ ] Images local, with `alt`, dimensions, modern format
- [ ] `npm run build` passes, ending with `✓ SEO gate: N indexable pages, all checks passed`
- [ ] New cover image → matching 1200×630 JPEG in `public/images/og/`; changed page → `lastmod` bumped
- [ ] JSON-LD passes the Google Rich Results Test; Lighthouse SEO = 100, Performance ≥ 90 (mobile)
- [ ] §9 Page registry and §10 Changelog updated
- [ ] Deployed to **both** `yuztoo-dev` and `yuztoo` (see `.cursor/rules/firebase-dual-env-deploy`)
- [ ] After deploy: sitemap resubmitted in Search Console, no new coverage errors

## 8. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No site, no build, no `src/routes.js`, no SEO gate (`scripts/verify-seo.mjs`), no prerender, no
  sitemap generator.
- No `robots.txt` and no `sitemap.xml` in `public/`.
- The pages currently served from the app repo (`index.html`, `aide.html`, `cgu.html`,
  `confidentialite.html`, `supprimer-compte.html`, `telecharger-ios.html`,
  `telecharger-android.html`, `vitrine.html`, `invite.html`) are hand-written HTML with no
  canonical, no JSON-LD and an SVG `og:image`. Migrate them into this project, page by page,
  and 301 anything whose URL changes.
- `og-cover.svg` must be replaced by a 1200×630 JPEG (SVG is not a valid `og:image` for most
  crawlers).
- Dev project `yuztoo-dev` previews are publicly reachable and need `Disallow: /`.
- **Owner actions (cannot be done in code):** verify `yuztoo.com` in Google Search Console and
  submit `/sitemap.xml`; create / claim the Google Business Profile; provide official social URLs
  for `sameAs`; confirm the legal entity name, address and phone used in `Organization` JSON-LD.

## 9. Page registry (update on every page change)

| URL | Purpose | Primary keyword | SEO data | Sitemap | Prerendered |
|-----|---------|-----------------|----------|---------|-------------|
| _(empty — add a row with the first page)_ | | | | | |

Planned first wave, for reference (not yet built): `/` (homepage),
`/pour-commercants`, `/pour-clients`, `/fonctionnalites`, `/tarifs`, `/telecharger`,
`/aide`, `/contact`, `/cgu`, `/confidentialite`, `/supprimer-compte`, `/vitrine/<slug>`.

## 10. Changelog (newest first)

- **2026-11-14** — SEO Holy Book created on the empty `site-web` branch, adapted from the IMIGO
  SEO Holy Book to Yuztoo (domain `yuztoo.com`, Firebase Hosting redirects and headers instead of
  nginx/.htaccess, dual-env deploy requirement, vitrine pages in scope). No site code yet; §9 is
  intentionally empty and §8 lists the full backlog.

## 11. Forms and lead capture (every form, every time)

Every website form must land in **one** place through **one** door: a single Cloud Function
(`websiteLead` or equivalent) that is public, origin-allowlisted, honeypot-protected,
server-validated and rate-limited. The website never embeds Firebase Admin credentials and never
writes to Firestore directly from the browser. See the
[Security Holy Book](./SECURITY_HOLY_BOOK.md) §3–§4.

**Source rule.** Each form records `source = "Site web / <Page>"` so the team sees exactly which
page produced the lead.

| Page | Source |
|---|---|
| `/` | Site web / Accueil |
| `/pour-commercants` | Site web / Commerçants |
| `/pour-clients` | Site web / Clients |
| `/tarifs` | Site web / Tarifs |
| `/contact` | Site web / Contact |
| `/aide` | Site web / Aide |
| anything else | Site web / Autre page |

**When you add a page or a form:**

1. Add the path → label to `src/data/leadSources.js`. The format is strict: `Site web / ` followed by
   2–40 letters, digits, spaces or `'`. Anything else is stored as plain `Site web`.
2. If one page has two forms, pass an explicit `source` prop using the same format.
3. Add the new value to the server-side allowlist in the Cloud Function, or it is rejected.
4. Reuse the shared form component: themed tokens, 48 px fields, 16 px inputs, honeypot, consent
   linking to `/confidentialite`, redirect to a `noindex` thank-you page.
5. Test once against `yuztoo-dev`, confirm the lead arrives with the right source, then delete the
   test record.
