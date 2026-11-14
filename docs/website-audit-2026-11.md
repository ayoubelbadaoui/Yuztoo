# Audit of the current yuztoo.com — November 2026

Baseline for the rebuild. Audited 2026-11-14 against the live site
[www.yuztoo.com](https://www.yuztoo.com/).

**What it is today:** a 5-page WordPress site on IONOS, built with a page-builder theme. The
positioning is strong and the argument is genuinely good. The execution — technical SEO,
performance, conversion path — is where the rebuild wins.

---

## 1. The positioning (keep this — it is the best asset)

The site makes a sharper argument than most local-commerce products:

> Les plateformes de livraison prennent 6,50 € sur une pizza à 18 €. L'artisan gagne ~10 €/h, le
> client paie 30 % de plus, et **40 % de la valeur quitte le territoire**. Yuztoo crée un lien
> direct : une plaque à scanner en boutique, et le commerçant récupère la relation client.

Three promises: **sans publicité, sans commission, sans dépendance.**

Keep the pizza economics verbatim — it is concrete, it is memorable, and it converts. Keep the
« Pourquoi tu fais ça ? » merchant testimonial series (salon de thé, pisciniste, épicier); real
local voices are the hardest thing to fake and the site already has them.

### Facts the current site states

| Claim | Value |
|---|---|
| Marché actuel | **Belfort** (250 commerces visés) |
| Commerces partenaires | **10** |
| Fréquentation supplémentaire | +10 à 15 % |
| Marge | +20 %, 100 % des clients en direct |
| Coût | 0 € pour le commerçant et pour le client |
| Contact | contact@yuztoo.com, +33 6 09 52 65 11 |

**This matters for the holy books:** the market is **France (Belfort)**, not Morocco. Any `fr_MA`
locale or Morocco-targeted keyword is wrong. Corrected in the SEO Holy Book.

---

## 2. Page inventory

Five pages. All indexable, all in `wp-sitemap.xml`.

| URL | Title today | Chars | Verdict |
|---|---|---:|---|
| `/` | Yuztoo – Fidélisez vos clients et développez votre commerce local | 64 | ✅ Good |
| `/espace-commercant/` | **Espace Pros** | 11 | ❌ No keyword, no brand |
| `/espace-client/` | **Grand Public** | 12 | ❌ Meaningless in a SERP |
| `/espace-collectivites/` | **Espace collectivité** | 19 | ❌ No keyword, no brand |
| `/a-propos-de-nous/` | Yuztoo : Redonner vie au commerce local | 39 | ✅ Good |

Three of five titles are under the 30-character floor and carry no keyword and no brand. These
are the single cheapest SEO win available.

**The third audience is a real finding:** the site sells to **collectivités** (municipalities),
not just merchants and clients. The holy books originally assumed two audiences. Corrected.

---

## 3. Technical SEO problems

| Problem | Detail | Severity |
|---|---|---|
| **Multiple `<h1>` per page** | `/espace-client/` has **8**, `/espace-commercant/` **7**, `/espace-collectivites/` **4**. The page builder emits `h1` for styling | 🔴 High |
| **Images without `alt`** | 17 of 22 images across the site have no `alt` attribute | 🔴 High |
| **Weak titles** | 3 of 5 pages (see §2) | 🔴 High |
| **`og:image` on the wrong host** | Points to `yuztoo.com/wp-content/...` while canonical is `www.yuztoo.com`. The apex 301s, so scrapers follow a redirect to fetch the share image | 🟠 Medium |
| **Thin structured data** | Only `LocalBusiness` on the homepage. No `Organization`, no `BreadcrumbList`, no `FAQPage`, no `SoftwareApplication` for the app | 🟠 Medium |
| **PNG screenshots** | Product images served as PNG, not WebP | 🟠 Medium |
| **No `sitemap.xml`** | Only `wp-sitemap.xml`. `/sitemap.xml` 301s; `/sitemap_index.xml` 404s | 🟡 Low |

What is already correct and must not regress: canonical on every page, a meta description on
every page, `lang="fr-FR"`, apex → www 301, and `robots.txt` pointing at the sitemap.

---

## 4. Performance

| Measure | Value |
|---|---|
| HTML per page | **250–274 KB** before any asset |
| Homepage | 331 KB |
| Stack | WordPress + page builder + jQuery on IONOS shared hosting |

A quarter-megabyte of HTML for a 5-page brochure site is the headline number. The rebuild's
prerendered static HTML should land **under 40 KB per page** — a 6× reduction before counting the
removal of jQuery and the builder's CSS.

---

## 5. Security

**No security headers at all.** The response carries only `server: IONOS Webserver` — no
`Strict-Transport-Security`, no `X-Content-Type-Options`, no `Referrer-Policy`, no
`Permissions-Policy`, no CSP.

WordPress also exposes the usual surface the rebuild simply will not have: `xmlrpc.php`,
`/wp-json/` REST API, comment feeds, `/wp-admin/`.

The site loads IONOS SiteAnalytics, a website translator, YouTube and Google Maps behind a
consent banner. The consent gate is good practice and should carry over; see the
[Security Holy Book](./holy-books/SECURITY_HOLY_BOOK.md) §6.

---

## 6. The biggest problem: there is no way to get the app

**No App Store link. No Google Play link. No `yuztoo.app` link. On any page.**

Yuztoo is a mobile app. The entire site argues for it, and then offers no way to install it.
Every CTA (« Tester Yuztoo », « Essayez Yuztoo », « En savoir plus ») routes to another marketing
page or to `mailto:contact@yuztoo.com`.

There is exactly **one form on the entire site**, on `/a-propos-de-nous/` — the page with the
least commercial intent. The three audience pages, which are where a merchant or a mayor decides,
have no form at all.

Fixing this one gap is worth more than every other item in this audit combined.

---

## 7. Rebuild plan

### Page map

| URL | Replaces | Purpose |
|---|---|---|
| `/` | `/` | Pizza economics, how it works, proof, three audience doors |
| `/pour-commercants` | `/espace-commercant/` | Merchant value, plaque, pricing (gratuit), lead form |
| `/pour-clients` | `/espace-client/` | Client value, carnet, app download |
| `/pour-collectivites` | `/espace-collectivites/` | Territorial value, 40 % argument, contact form |
| `/a-propos` | `/a-propos-de-nous/` | Mission, team, « Pourquoi tu fais ça ? », contact |
| `/telecharger` | — **new** | App Store + Google Play, the missing conversion page |
| `/aide` | — new | Help centre (migrate `aide.html` from the app repo) |
| `/contact` | — new | Real contact page, today only a `mailto:` |
| `/cgu`, `/confidentialite` | — new | Migrate from the app repo |
| `/vitrine/<slug>` | — new | Public merchant storefront, already stubbed in app hosting |

### Redirects (301, in `firebase.json`)

```
/espace-commercant      → /pour-commercants
/espace-client          → /pour-clients
/espace-collectivites   → /pour-collectivites
/a-propos-de-nous       → /a-propos
```

Plus apex and `www` → the canonical host, and `yuztoo.app` → `yuztoo.com`.

**Do not break these:** `/wp-sitemap.xml` should 301 to `/sitemap.xml`, and the four URLs above
must redirect on day one — they are the only pages with any history.

### Priority order

1. **`/telecharger` + app-store links in the header on every page.** The missing conversion path.
2. **One `h1` per page, real `alt` on every image, rewritten titles** for the three weak pages.
3. **A lead form on each of the three audience pages**, routed through one rate-limited Cloud
   Function (see [SEO Holy Book](./holy-books/SEO_HOLY_BOOK.md) §11).
4. **App colors and Inter**, replacing the WordPress theme — see
   [Brand Holy Book](./holy-books/BRAND_HOLY_BOOK.md).
5. **Security headers and prerendered static HTML** on Firebase Hosting.
6. Structured data: `Organization` + `SoftwareApplication` + `BreadcrumbList` + `FAQPage`.

### Open questions for the business

- Are the App Store and Play Store listings live, and what are the final URLs?
- Is Belfort still the only market? « 10 commerces partenaires » and « 250 commerces » need a
  review date, and a figure that ages badly on a static page needs an owner.
- Is `yuztoo.com` staying on IONOS DNS with Firebase Hosting behind it, or moving?
- Canonical host: keep `www.yuztoo.com`, or move to the apex?
