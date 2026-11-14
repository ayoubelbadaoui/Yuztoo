# SEO Holy Book — Yuztoo Website

**Goal: 100 % SEO-optimized** Yuztoo website (`https://yuztoo.com`, local `http://localhost:3001/`).

**Scope:** the public website only. The Flutter app, the CRM and tokenized links are **never**
indexed. Language: French (`lang="fr-FR"`, `og:locale` `fr_FR`). Market: **France**, currently
Belfort — commerces de proximité, their clients, and the collectivités that want to keep value on
their territory.

Local SEO matters more than national SEO here: the buying decision is « mon commerçant », « ma
ville ». Plan for city pages (`/commerce-local-belfort`) as the market expands, each with
`LocalBusiness` / `City areaServed` structured data.

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
4. One canonical host, every other host 301s to it. The live site canonicalises to
   **`www.yuztoo.com`** (the apex already 301s to it), so keep `www` unless the business decides
   otherwise — switching hosts after launch costs rankings. `yuztoo.app` 301s there too.
   `og:image` and every internal link use the canonical host; the current site gets this wrong
   and serves its share images from the redirecting apex.
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
- Leftover WordPress surface after cutover: `/wp-admin/`, `/wp-json/`, `/xmlrpc.php`, `/feed/`,
  `/comments/feed/`. These simply stop existing on Firebase Hosting — confirm they 404 and are
  not silently rewritten to the SPA shell.

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

- **No `firebase.json` on this branch yet**, so the 301 `/espace-commercant` → `/pour-commercants`
  (and the three other renamed URLs) is not written anywhere. It must ship with the first hosting
  config, together with `cleanUrls: true` and `trailingSlash: false` (`vite preview` falls back to
  the homepage HTML for `/pour-commercants` without the slash; Firebase will not).
- No page has a lead form yet: the closing band of `/pour-commercants`, `/pour-clients`,
  `/pour-collectivites` and `/a-propos` offers `mailto:` and `tel:` only. Forms need the §11 Cloud
  Function (allowlist, honeypot, consent) and a dual-env deploy.
- The `/pour-collectivites` hero shows an illustrative report (labelled « Aperçu illustratif »).
  Replace it with real, anonymised municipal figures once the Belfort pilot publishes them.
- The pages currently served from the app repo (`index.html`, `aide.html`, `cgu.html`,
  `confidentialite.html`, `supprimer-compte.html`, `telecharger-ios.html`,
  `telecharger-android.html`, `vitrine.html`, `invite.html`) are hand-written HTML with no
  canonical, no JSON-LD and an SVG `og:image`. Migrate them into this project, page by page,
  and 301 anything whose URL changes.
- `og-cover.svg` must be replaced by a 1200×630 JPEG (SVG is not a valid `og:image` for most
  crawlers).
- Dev project `yuztoo-dev` previews are publicly reachable and need `Disallow: /`.

Carried over from the live-site audit ([`docs/website-audit-2026-11.md`](../website-audit-2026-11.md)):

- Three of five live pages have titles under 30 chars with no keyword and no brand
  (« Espace Pros », « Grand Public », « Espace collectivité »).
- `/espace-client/` ships **8** `<h1>` tags, `/espace-commercant/` 7, `/espace-collectivites/` 4.
- 17 of 22 images on the live site have no `alt`.
- Only `LocalBusiness` structured data exists, homepage only. No `Organization`,
  `BreadcrumbList`, `FAQPage` or `SoftwareApplication`.
- No App Store / Play Store link anywhere on the site, and only one form (on the lowest-intent
  page). The `/telecharger` page and per-audience forms are the first conversion fixes.
- `/wp-sitemap.xml` must 301 to `/sitemap.xml` at cutover.
- **Owner actions (cannot be done in code):** verify `yuztoo.com` in Google Search Console and
  submit `/sitemap.xml`; create / claim the Google Business Profile; provide official social URLs
  for `sameAs`; confirm the legal entity name, address and phone used in `Organization` JSON-LD.

## 9. Page registry (update on every page change)

| URL | Purpose | Primary keyword | SEO data | Sitemap | Prerendered |
|-----|---------|-----------------|----------|---------|-------------|
| `/` | Homepage — économie des plateformes, fonctionnement, preuve, trois publics | fidéliser clients commerce local sans commission | `src/site/home/homeSeoData.js` | ✅ | ✅ |
| `/pour-commercants` | Offre commerçants — constat, impact, mise en place, clients, fidélité, outils, FAQ (replaces `/espace-commercant/`) | fidélisation client commerce gratuit | `src/site/commercants/commercantsSeoData.js` (WebPage, BreadcrumbList, FAQPage) | ✅ | ✅ |
| `/pour-clients` | Offre habitants — pourquoi, carnet, infos & fidélité, recommandation, données, FAQ (replaces `/espace-client/`) | application commerces de proximité | `src/site/clients/clientsSeoData.js` (WebPage, BreadcrumbList, FAQPage) | ✅ | ✅ |
| `/pour-collectivites` | Offre collectivités — constat, impact, réponse souveraine, promesse, bénéfices, FAQ (replaces `/espace-collectivites/`) | commerce local collectivité territoire | `src/site/collectivites/collectivitesSeoData.js` (WebPage, BreadcrumbList, FAQPage) | ✅ | ✅ |
| `/a-propos` | Mission, vision, fondateur, ambition (replaces `/a-propos-de-nous/`) | yuztoo belfort fondateur | `src/site/apropos/aproposSeoData.js` (WebPage, BreadcrumbList, Person) | ✅ | ✅ |
| `/404` | Page introuvable (noindex) | — | `src/site/notFoundSeoData.js` | ❌ | ✅ |

Planned first wave, with the live URL each one replaces — see
[`docs/website-audit-2026-11.md`](../website-audit-2026-11.md) §7:

`/` (replaces `/`), `/pour-commercants` (`/espace-commercant/`), `/pour-clients`
(`/espace-client/`), `/pour-collectivites` (`/espace-collectivites/`), `/a-propos`
(`/a-propos-de-nous/`), then new pages `/telecharger`, `/contact`, `/aide`, `/cgu`,
`/confidentialite`, `/supprimer-compte`, `/vitrine/<slug>`.

The four renamed URLs are the only ones with history. Their 301s ship with the first deploy.

## 10. Changelog (newest first)

- **2026-11-14** — Dark mode (app navy) on every page, header toggle. No URL, title, meta or
  JSON-LD change; prerendered HTML now loads the same-origin `/theme-init.js` in `<head>`.

- **2026-11-14** — `/pour-clients`, `/pour-collectivites` and `/a-propos` shipped (5 indexable
  pages). Each has one `h1`, a visible breadcrumb, `WebPage` + `BreadcrumbList` JSON-LD from the
  shared `src/seo/buildPageSeo.js`, `FAQPage` on the two audience pages and a `Person` node for the
  founder on `/a-propos`. Copy taken from the live `/espace-client/`, `/espace-collectivites/` and
  `/a-propos-de-nous/`; local images with French `alt`. Header nav links are no longer dead. Gate
  passing on 5 pages; layout checked from 320 to 1440 px.

- **2026-11-14** — `/pour-commercants` shipped (second indexable page): one `h1`, visible
  breadcrumb, `BreadcrumbList` + `FAQPage` + `WebPage` JSON-LD, copy and figures taken from the live
  `/espace-commercant/`. Header CTA and homepage CTAs now point to `/pour-commercants#demarrer`
  instead of the unbuilt `/contact`. Footer renders links to unbuilt routes as plain text (no dead
  links) and switches them on automatically once the route is in `routeMeta.js`. Homepage `h1`
  wording unchanged; « pas pour une plateforme. » now in `--gold-deep`. Gate passing on 2 pages.

- **2026-11-14** — Homepage redesigned on the IMIGO website's structural system (hairline grids,
  mono micro-labels, numbered sections, scanner frames). H1 changed to « Vos clients reviennent
  pour vous, pas pour une plateforme. »; title, description and JSON-LD unchanged. Section
  `#fonctionnement` and `#belfort` anchors added. New image `yuztoo-mascotte-logo.webp` (decorative,
  `alt=""` beside the wordmark). Gate still passing on 1 indexable page.

- **2026-11-14** — First build shipped: homepage and 404 prerendered, `sitemap.xml` and
  `robots.txt` generated, SEO gate (`scripts/verify-seo.mjs`) wired into `npm run build` and
  passing on 1 indexable page. The gate caught a missing `og:image` on its first run, which is
  what it is for. Homepage HTML is 16 KB against 331 KB on the live WordPress site.

- **2026-11-14** — Corrected the market after auditing the live site: **France (Belfort)**, not
  Morocco; locale `fr_FR`, not `fr_MA`; **three** audiences (commerçants, clients, collectivités),
  not two. §9 now maps each planned URL to the live URL it replaces. Full baseline in
  [`docs/website-audit-2026-11.md`](../website-audit-2026-11.md).

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
