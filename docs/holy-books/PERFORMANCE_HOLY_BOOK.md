# Performance Holy Book — Yuztoo Website

**Goal: 100 % fast.** Fast for the visitor (first paint, interaction) and cheap on Firebase
(document reads, Storage egress, function invocations).

Targets:

| Metric | Target (mobile, 4G) |
|--------|---------------------|
| LCP | < 2.0 s |
| INP | < 200 ms |
| CLS | < 0.05 |
| TTFB (Hosting CDN hit) | < 200 ms |
| JS on first load (gzip) | < 170 KB |
| Lighthouse Performance | ≥ 90 mobile, ≥ 95 desktop |
| Firestore reads per page view | 0 on static pages, ≤ 3 on a vitrine page |

---

## 1. Static first

1. Every indexable page is **prerendered to static HTML** and served from the Hosting CDN. A
   marketing page must render fully with JavaScript disabled.
2. A static page does **zero** Firebase calls. Copy, images and figures come from
   `content/` modules baked into the build.
3. Only genuinely dynamic pages (a public vitrine) read from Firestore, and they read one
   document by ID — never a query, never a collection scan.
4. Data that changes rarely (store directory, pricing) is generated at build time, not fetched at
   runtime.

## 2. Data fetching (Firebase)

1. Read a document by ID when you can. When a query is unavoidable, it is indexed, limited, and
   returns explicit fields.
2. Never fetch a whole collection. Paginate or cap with `limit()`.
3. Cache per session what cannot change during a visit.
4. No realtime listeners on the public website. Use a one-shot read; the marketing site has no
   reason to hold an open socket.
5. Call Cloud Functions on user intent only (form submit), never on page load.

## 3. Bundle & loading

1. Every route is lazy-loaded. A new page = a new dynamic `import()`.
2. Heavy libs (maps, charts, video players, date libraries) are imported dynamically inside the
   feature that needs them, never at the top of a shared module.
3. The Firebase SDK is imported **only** inside `services/`, modular style
   (`firebase/firestore` subpath), and loaded lazily — a static page must not ship it at all.
4. Vendor chunks stay split; check `npm run build` output. Any chunk > 500 KB raw needs a reason
   in the PR.
5. No new dependency for something a 20-line util can do.

## 4. Rendering (React)

1. Hydrate, don't re-render: the prerendered HTML and the first client render must match, or
   you get a hydration flash that costs LCP.
2. Derive values with `useMemo` only when the computation is measurable; don't wrap everything.
3. Stable callbacks (`useCallback`) for props passed to memoized children and for effect deps.
4. No state updates during render, and no effect chains that set state → trigger effect → set
   state.
5. Debounce inputs (≥ 250 ms) before calling a service.
6. Guard concurrent submits with a ref — one lead, not three.

## 5. Assets

1. Images: WebP/AVIF, explicit `width`/`height`, `loading="lazy"` below the fold,
   `fetchPriority="high"` on the LCP image only, `srcset` for the sizes actually rendered.
2. Serve every image from our own origin. Never hotlink.
3. Fonts: self-hosted via `@fontsource/*`, `font-display: swap`, preloaded for the one family used
   above the fold, subset to Latin. No `fonts.googleapis.com` (the SEO gate blocks it).
4. Icons: tree-shaken SVG components. No icon fonts, no full icon-pack imports.
5. Hashed assets get `Cache-Control: public, max-age=31536000, immutable` in `firebase.json`;
   HTML gets `no-cache`. A replaced image must use a **new file name**.

## 6. Core Web Vitals

1. LCP element is a prerendered image or heading, preloaded, never behind a fetch or an animation.
2. CLS: every image and embed has reserved dimensions; no content injected above existing content
   after load; fonts preloaded so there is no reflow.
3. INP: no blocking work on first interaction; defer analytics and chat widgets until after first
   paint and after consent.
4. Respect `prefers-reduced-motion`; scroll-reveal animations never delay the LCP element.

## 7. Monitoring

1. Lighthouse (mobile) on the homepage, the main merchant page and a vitrine page before each
   release.
2. Check the Firebase console after a deploy: Firestore reads, function invocations, Hosting
   bandwidth. A spike after a website release is a bug in §1 or §2.
3. Watch Core Web Vitals in Search Console once traffic exists.

## 8. PR checklist

- [ ] New page prerendered and renders with JS disabled
- [ ] No Firebase call on a static page; dynamic pages read by ID
- [ ] New page lazy-loaded; heavy libs dynamically imported
- [ ] No chunk > 500 KB without justification
- [ ] Images sized, lazy, modern format, served from our origin
- [ ] LCP image preloaded; no CLS from fonts or images
- [ ] Lighthouse mobile ≥ 90 on the changed page

## 9. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No build, so no bundle budget, no Lighthouse baseline and no prerender.
- No caching headers for website assets in `firebase.json` — only the deep-link files have
  headers today. Add the immutable-assets / no-cache-HTML pair in the first deploy PR.
- Fonts in the current app-repo pages load from `fonts.googleapis.com`. Self-host them when those
  pages are migrated here.
- `og-cover.svg` and `favicon.svg` are the only shared images; no responsive image pipeline
  exists.
- No performance monitoring in place; Core Web Vitals cannot be read until the domain is verified
  in Search Console.
