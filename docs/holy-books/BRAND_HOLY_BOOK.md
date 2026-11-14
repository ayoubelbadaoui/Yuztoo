# Brand Holy Book — Yuztoo Website

**Goal: the website looks like the app.** A visitor who downloads Yuztoo after reading the site
must recognise the product instantly — same navy, same gold, same cream, same typography.

**Source of truth: the Flutter app.** Every token below is copied from the app source on
`develop`. When the app changes a token, change it here in the same week and note it in §7.

| App file | Covers |
|---|---|
| `lib/core/shared/constants/merchant_colors.dart` | dark merchant surfaces |
| `lib/feature/storefront/presentation/widgets/storefront_colors.dart` | storefront / vitrine |
| `lib/theme.dart` | global light theme |

---

## 1. Color tokens

Declare these once in `src/global.css` as CSS custom properties. Never hard-code a hex anywhere
else.

### Navy (the brand's primary surface)

| Token | Hex | App source | Use on the website |
|---|---|---|---|
| `--navy-header` | `#0B1F33` | `MerchantColors.bgHeader` | Page header, top band, `theme-color` |
| `--navy-main` | `#0E2A44` | `MerchantColors.bgMain` | Main dark section background |
| `--navy-deep` | `#0B162C` | `StorefrontColors.navyDark` | Footer, deepest surface, dark hero |
| `--navy-card` | `#1A2B4D` | `MerchantColors.navyCard` | Cards and inputs raised above navy |

Three navies is deliberate, not an accident: `--navy-card` must stay visibly lighter than
`--navy-main`, or inputs and cards disappear into the background. This is a bug the app already
fixed once — do not reintroduce it on the site.

### Gold (accent — never a background)

| Token | Hex | App source | Use |
|---|---|---|---|
| `--gold` | `#D4AF37` | `StorefrontColors.primaryGold` | Primary accent, CTA fill, active state |
| `--gold-deep` | `#D4A017` | `MerchantColors.gold` | Hover / pressed on `--gold` |
| `--gold-ink` | `#8A6212` | derived (darkened `AppColors.secondary`) | Gold **text** on light surfaces — 5.3:1 on cream |
| `--gold-on-dark` | `#E0BF55` | derived from `--gold` | Gold text on navy — 8:1 on `--navy-main` |

`AppColors.secondary` (`#C28A1B`) is only 2.9:1 on cream and fails AA for text, so the website
does not use it for copy; `--gold-ink` replaces it.

Gold gradient for premium borders, from `GoldGradient` in the app:

```css
--gold-gradient: linear-gradient(135deg, #BF953F, #FCF6BA, #B38728, #FBF5B7, #AA771C);
```

Gold is an **accent**. Never a large background fill, never body text on white.

### Cream and light surfaces

| Token | Hex | App source | Use |
|---|---|---|---|
| `--cream` | `#E8D5B7` | `MerchantColors.cream` | Warm accent on navy, dividers |
| `--cream-light` | `#FDFBF7` | `StorefrontColors.creamLight` | Light section background |
| `--white` | `#FFFFFF` | `AppColors.background` | Cards on light sections |

### Text

| Token | Hex | App source | Use |
|---|---|---|---|
| `--text-on-light` | `#1E293B` | `StorefrontColors.textPrimary` | Body on cream / white |
| `--text-muted` | `#64748B` | `StorefrontColors.textSecondary` | Secondary text on light |
| `--text-faint` | `#94A3B8` | `StorefrontColors.textTertiary` | Captions, meta |
| `--text-on-dark` | `#F1F5F9` | `StorefrontColors.textLight` | Body on navy |
| `--text-on-dark-muted` | `#CCCCCC` | `MerchantColors.textLightGrey` | Secondary text on navy |

### Feedback

| Token | Hex | App source |
|---|---|---|
| `--success` | `#22C55E` | `StorefrontColors.successGreen` |
| `--danger` | `#D4183D` | `AppColors.destructive` |

### Borders

| Token | Value | App source |
|---|---|---|
| `--border-on-light` | `rgba(0,0,0,0.10)` | `StorefrontColors.borderLight` |
| `--border-on-dark` | `rgba(255,255,255,0.05)` | `StorefrontColors.borderDark` |
| `--border-gold` | `rgba(212,175,55,0.25)` | `MerchantColors.goldBorderStronger` |

## 2. Typography

The app renders with **Inter** (`GoogleFonts.interTextTheme()` in `lib/theme.dart`). The website
uses the same family, **self-hosted** via `@fontsource/inter` — loading it from
`fonts.googleapis.com` fails the SEO gate (see [SEO Holy Book](./SEO_HOLY_BOOK.md) §1).

```css
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

Subset to Latin, weights 400 to 900 (headings run at 900 with tight tracking), `font-display: swap`.

Every uppercase micro-label (eyebrows, badges, stat labels, tags, footer headings) runs in
**JetBrains Mono** 500 / 700, self-hosted via `@fontsource/jetbrains-mono`:

```css
--font-mono: 'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
```

Mono reads as instrumentation, not decoration. It is never used for body copy.

## 3. Contrast (non-negotiable)

Every pairing ships at **WCAG AA** — 4.5:1 for body text, 3:1 for large text and UI borders:

- `--text-on-dark` on `--navy-main` ✅
- `--text-on-light` on `--cream-light` ✅
- `--gold` on `--navy-deep` ✅ (gold on navy is the signature pairing)
- `--gold` on `--cream-light` ❌ — use `--gold-ink` for text; `--gold` only for fills, rules and ticks
- Gold body text on white ❌ — never

Check both directions on every section: the site alternates navy and cream bands, so each block
needs its own check. This is enforced in the
[Responsive Holy Book](./RESPONSIVE_HOLY_BOOK.md) §7 checklist.

## 4. Surfaces and rhythm

- The site alternates **navy** and **cream** bands. Navy carries the emotional and product
  moments; cream carries explanation and proof.
- `theme-color` always matches the band at the top of the page (`#0B1F33`), mirroring the app's
  status-bar rule.
- Sections set their context with `.yz-light` or `.yz-dark`; components read only the context
  variables (`--surface`, `--border`, `--text`, `--accent-ink`…), so one card works on both bands.
- **Hard structure, soft controls.** Cards, tiles and grids sit at radius 0 and separate with
  1px hairlines (`.yz-grid`: the gap *is* the divider). Only interactive controls get
  `--r-ctl` (6px); pills are reserved for the nav and the header CTA.
- **No glow, no radial spotlight, no gradient text, no floating mascot.** Texture is flat
  (`grid`, `dots`, `rules`), each used once per page, dissolved at section seams.
- Recurring motifs: scanner corner brackets (`.yz-frame`) on focal images, gold-left-border
  credential strips (`.yz-badge`, `.yz-strip`), numbered section eyebrows, anchored opaque
  plates over images. Hover: a gold rule runs in from the left; arrows travel; cells never lift.

## 5. Voice

French, `tutoiement` never — always `vous`. Short sentences. Concrete figures, never invented.
The product is « le carnet de vos commerces » and the gesture is a **scan en boutique**.

Two words that must stay consistent with the app and the CRM:
**commerçant**, **client**. See the [DDD Holy Book](./DDD_HOLY_BOOK.md) §9 for the full glossary.

## 6. PR checklist

- [ ] No raw hex in a component — only `var(--token)` from `global.css`
- [ ] New token traced back to a file in the Flutter app, named in the table above
- [ ] AA contrast checked on both the navy and the cream version of the block
- [ ] Gold used as accent only, never as a large fill or as body text on light
- [ ] `theme-color` matches the top band
- [ ] Inter self-hosted, not from Google Fonts

## 7. Known gaps (November 2026)

- The app has three overlapping palettes (`MerchantColors`, `StorefrontColors`, `AppColors`) with
  two different golds (`#D4AF37` and `#D4A017`) and two creams. The website collapses them into
  the single scale above; if the app ever unifies its own tokens, re-sync this book.
- The current live site (`yuztoo.com`) uses none of these colors — it is a WordPress theme with
  unrelated styling. See [`docs/website-audit-2026-11.md`](../website-audit-2026-11.md).
- No official logo asset yet. The header uses a 84×96 cut-out of the mascot
  (`yuztoo-mascotte-logo.webp`) next to a type wordmark until the owner supplies the real logo.
