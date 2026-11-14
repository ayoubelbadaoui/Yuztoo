# Responsive Holy Book — Yuztoo Website

**100 % responsive is non-negotiable.** Scope: every page of the Yuztoo website. A change that
breaks any rule below does not ship.

Yuztoo's audience arrives on a phone — merchants between two customers, clients in a shop. Mobile
is the primary design target, not an adaptation.

---

## 1. Widths that must be perfect

Test every change at all of these, portrait and landscape where relevant:

| Width | Device class |
|------:|--------------|
| 320 | Small phone (iPhone SE 1st gen, older Android) |
| 360 | Most Android phones |
| 375 / 390 / 414 / 430 | iPhones |
| 768 | Tablet portrait |
| 1024 | Tablet landscape / small laptop |
| 1280 / 1440 | Laptop / desktop |
| 1920+ | Large desktop (content stays inside `max-width: 1240px`) |

Pick a small, fixed breakpoint set (1180, 1024, 900, 767, 680, 420 px, plus `max-height: 520px`
for phones in landscape) and reuse it. Don't invent a new breakpoint without a reason.

## 2. Zero horizontal overflow

- `document.documentElement.scrollWidth === clientWidth` at every width in §1. No sideways
  scroll, ever.
- No fixed px `width` on layout elements; use `max-width`, `%`, `fr`, `minmax(0, 1fr)`, `clamp()`.
- Grid tracks use `minmax(0, …)` when content can be long; long words, URLs and emails get
  `overflow-wrap: anywhere`.
- Buttons with long labels wrap below 420 px (`white-space: normal`).
- Images and media: `max-width: 100%; height: auto`.
- Watch French copy: « programme de fidélité », « commerçant » and store names are long. Test
  with the longest real string, not a placeholder.

## 3. Touch targets

- Every link, button and form control is **≥ 44 × 44 px** on screens ≤ 767 px (height ≥ 44 px;
  short inline words may be narrower, but the row height stays 44 px).
- At least 8 px between adjacent targets.
- Footer and contact lists: links are `inline-flex; min-height: 44px`, list `gap: 0`.
- App-store badges and the main CTA are ≥ 48 px tall on mobile.

## 4. Text

- Minimum font size **12 px** anywhere (labels, eyebrows, badges, legal).
- Body text ≥ 15 px on mobile, 16 px preferred.
- Form inputs ≥ **16 px** (prevents iOS zoom on focus).
- Headings use `clamp()` so they never overflow at 320 px.
- Line length ≤ ~75 characters on desktop (`max-width: 60–70ch` on paragraphs).

## 5. Layout behaviour

- Mobile-first: single column ≤ 680 px, two columns on tablet where it helps, full layout
  ≥ 1024 px.
- Grids never leave an empty cell at any breakpoint — check item count against column count.
- Small-card grids (features, store categories) go to 2 columns on phones, not 1, to avoid
  endless scrolling.
- Sticky header stays ≤ ~80 px tall on phones.
- Mobile menu: full-screen, opaque, above all content, closes on link tap and `Esc`, locks body
  scroll.
- No hover-only information: anything revealed on hover is visible or tappable on touch.
- Phone mockups of the app scale with `clamp()` and are hidden or reduced below 420 px rather
  than squeezing the copy.

## 6. Images

- `width`/`height` attributes set (no layout shift); `object-fit: cover` in fixed-ratio frames.
- Served at ≤ 2× the largest displayed size; `loading="lazy"` except the hero.
- Art direction must still read at 320 px — the subject is not cropped out.

## 7. Safe areas, theme and input

- Respect `env(safe-area-inset-*)` for anything fixed to the screen edges (sticky CTA bar,
  drawer, cookie banner).
- `theme-color` matches the top of the page (`#0B1F33` on navy surfaces), consistent with the
  app's status-bar rule.
- `:focus-visible` outlines visible on all interactive elements.
- Respect `prefers-reduced-motion` — no scroll-reveal or counter animation when it is set.
- Check both light and dark surfaces: navy-on-cream and cream-on-navy sections must each keep
  AA contrast.

## 8. How to verify (every PR touching the website)

1. Run the site (`npm run dev`).
2. In DevTools device mode, scroll the whole page at each width in §1 (scroll first so reveal
   animations fire).
3. Paste this in the console — it must print `{ overflow: [], smallTargets: [], tinyText: [] }`
   at 320 and 375:

```js
(() => {
  const vw = document.documentElement.clientWidth
  const overflow = [], smallTargets = [], tinyText = []
  document.querySelectorAll('body *').forEach((el) => {
    const r = el.getBoundingClientRect()
    if (!r.width) return
    if (r.right > vw + 1) {
      let p = el.parentElement, clipped = false
      while (p) {
        if (['hidden', 'clip', 'auto', 'scroll'].includes(getComputedStyle(p).overflowX) && p.getBoundingClientRect().right <= vw + 1) { clipped = true; break }
        p = p.parentElement
      }
      if (!clipped) overflow.push(el)
    }
    if (el.matches('a,button,input,select,textarea') && vw <= 767 && r.height < 44 && !el.closest('.sr-only')) smallTargets.push(el)
    if ([...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim()) && parseFloat(getComputedStyle(el).fontSize) < 12) tinyText.push(el)
  })
  return { overflow, smallTargets, tinyText }
})()
```

4. Open the mobile menu and test a landscape phone (`max-height: 520px`).
5. Lighthouse mobile: no "tap targets" and no "font size" warnings.
6. Tick §9 in the PR.

## 9. PR checklist

- [ ] No horizontal scroll at 320 → 1920 px
- [ ] Touch targets ≥ 44 px on mobile
- [ ] No text < 12 px; inputs ≥ 16 px
- [ ] No empty grid cells at any breakpoint
- [ ] Mobile menu opaque, on top, closes correctly
- [ ] Images keep their ratio, no layout shift
- [ ] Landscape phone and 1920 px checked
- [ ] Console audit (§8) returns empty arrays
- [ ] Contrast checked on both navy and cream sections

## 10. Changelog (newest first)

- **2026-11-14** — Responsive Holy Book created on the empty `site-web` branch, adapted from the
  IMIGO Responsive Holy Book to Yuztoo (brand surfaces navy/cream, `theme-color` rule aligned
  with the app's system-UI rule, French copy-length warning, app-mockup scaling). No pages audited
  yet.

## 11. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No `styles/responsive.css` and no agreed breakpoint set — fix in the first layout PR.
- No page has been audited at any width.
- The pages currently served from the app repo (`index.html`, `aide.html`, `cgu.html`,
  `confidentialite.html`, `vitrine.html`, …) have never gone through the §8 audit. Run it when
  each one is migrated here.
