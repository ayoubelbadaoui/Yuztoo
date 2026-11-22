# CMS App Yuztoo

Product-ops surface rebuilt **inside** Sales CRM (`sales-crm/`), same React + CSS tokens. Replaces the old Firebase `admin/` UI for day-to-day boutique / client ops in the SPA — without importing Firebase in the browser.

## Entry

1. In Sales CRM, open the workspace switcher.
2. Choose **CMS App Yuztoo** → `window.open(.../?cms=1)`.
3. `App.tsx` gates on `?cms=1` (after public devis / contrat params) and renders `CmsApp` with its own shell (no Sales nav).

## Screens (phase 1)

| Nav | Module | Status |
|-----|--------|--------|
| Tableau de bord | KPI counts (boutiques, publiées, clients, bloqués…) | Live (mock) |
| Boutiques | List / search / filter / edit / publier / retirer · pagination 25 | Live (mock) |
| Clients | List / search / filter / edit / bloquer / débloquer · pagination 25 | Live (mock) |
| Images app | Fixed design-safe media catalog (logo + heroes + **16 categories** + empty) | Live (mock + localStorage) |
| Force update | Hard gate when installed build &lt; platform min (`app_config/force_update`) | Flutter + Firebase live — CMS UI pending (see handoff) |
| Actu Yuztoo | Editorial feed → in-app full page (`yuztoo_news`) | **Live** via Edge → Firebase + per-actu publish gate; Flutter dual-query |
| Statistiques / Audit / Paramètres | Placeholders | V2 |

## Images app (design-safe catalog)

Fixed slots in `domain/mediaSlot.ts` — not free-form uploads:

| Slot | Profile | Aspect | Recommended | Max | Notes |
|------|---------|--------|-------------|-----|-------|
| `brand.logo` | brand | 1:1 | 1024×1024 | 1.5 Mo | `AppLogo` / bundle |
| `onboarding.*.hero_*` | hero | 1:1 | 512×512 | 1.5 Mo | Step avatars |
| `onboarding.category.*` (**16**) | **icon** | **1:1** | **256×256** | **200 Ko** | Fills category card **banner placeholder** (not the small icon circle); WebP preferred |
| `empty.*` | illustration | 4:3 | 800×600 | 1.5 Mo | Empty-state illustrations |

**Safety:** aspect-locked crop, MIME whitelist (PNG/JPEG/WebP), per-profile max bytes, preview frames (square / circle / 4:3).

**Deferred:** ~191 subcategory business icons — not in catalog yet.

### Publication gate (mandatory test account)

Workflow enforced in CMS (`domain/mediaRelease.ts` + `cmsMediaReleaseService`):

1. **Brouillon** — edit slots; not “online”.
2. **Select test account** — one client or boutique from the CMS lists (required).
3. **Aperçu test** — only that account should see new images once Flutter is wired.
4. **En ligne (tous)** — blocked until step 3 succeeded (`status === preview` + `testAccountId` + `previewActivatedAt`). Confirm dialog before publish.
5. Editing slots while **live** demotes back to **brouillon** (must re-preview before another full publish).

**Out of scope:** user/merchant photos, storefront banners, Play/App Store launcher icons (release build only).

**Flutter (wired):** `lib/feature/app_media` + `ResolvedAppImage` / `AppLogo`. Reads Firebase only:

| Doc / object | Role |
|--------------|------|
| `app_config/app_media_release` | draft / preview / live + `testAccountId` (1 read) |
| `app_config/app_media_catalog` | all slot HTTPS URLs in one doc (0–1 read; denied unless live or preview test UID) |
| Storage `app_media/{slotId}/current` | one overwritten binary per slot |

Writers: Admin callables `adminUpsertAppMediaSlot`, `adminClearAppMediaSlot`, `adminSetAppMediaRelease` only. CMS Images UI still uses localStorage until Supabase Edge bridges those callables / Admin SDK.

Phase 2 media: Edge `cms-upsert-app-media` → same Firebase docs/Storage (no secrets in `VITE_*`).

## Actu Yuztoo

CMS nav **Actu Yuztoo** (`CmsActuPage`) authors the editorial feed Flutter shows in Alertes.

| Field | Notes |
|-------|--------|
| `title` / `body` | Required (max 200 / 8000) |
| `publish_on` | ISO; app shows only when ≤ now |
| `active` | Soft hide (not enough for clients — see gate) |
| `image_url` | Optional HTTPS (banner 46×46 + detail full-width). Upload/crop = Phase B |
| `cta_label` / `cta_url` / `cta_merchant_id` | **Merchant id** = in-app shop (preferred). **URL** = external browser. Empty = no button |
| `release_status` | **Per actu:** `draft` → `preview` → `live` (legacy missing ≡ `live`) |
| `test_account_id` / `test_account_label` | Required before preview |
| `preview_activated_at` / `live_at` | Stamps for the gate |

### Live path (CMS → app)

```
CmsActuPage → yuztooNewsService → Edge cms-yuztoo-news
  → HTTPS crmBridgeYuztooNews (X-CRM-Bridge-Secret)
  → Firestore yuztoo_news → Flutter dual-query
```

- No Firebase in the SPA. Secrets: `CRM_BRIDGE_SECRET`, `FIREBASE_PROJECT_ID` (Edge + CF env).
- Offline UI only: `VITE_CMS_ACTU_MOCK=1` (localStorage).
- Deploy: CF `crmBridgeYuztooNews` first, then Edge `cms-yuztoo-news`.

### Publication gate (mandatory test account)

Same UX rule as Images, but **per news document**:

1. **Brouillon** — new saves always start as draft (even if `active` is checked).
2. **Select test account** — client or boutique from the same list as Images.
3. **Aperçu test** — only that Firebase UID can read the doc (`release_status=preview`).
4. **En ligne (tous)** — blocked until step 3. Confirm before publish.
5. Content edit while **live** demotes to **brouillon** (must re-preview).

**Flutter:** dual listeners (live + own preview). Rules: draft unreadable; live public; preview = test UID only.

### Pictures (Phase B — planned)

App surfaces today: Alertes thumb **46×46 cover**; detail hero **full width cover**. One optional hero per actu (no gallery).

| Spec | Value |
|------|--------|
| Crop profile | `actu.hero` **16:9**, recommend **1200×675** |
| Max size | **1.5 Mo** |
| MIME | PNG / JPEG / WebP |
| Storage | `yuztoo_news/{newsId}/hero` via Edge upload → set `image_url` |
| Publish | Image is content; live edit still demotes to draft |

Until Phase B ships, paste an HTTPS `image_url` only.

## Code layout

```
sales-crm/src/features/cms-app/
  domain/cms.ts, mediaSlot.ts, mediaRelease.ts, yuztooNews.ts
  services/          # overview, merchant, client, cmsMedia*, yuztooNews* + mocks
  hooks/
  components/
  containers/        # CmsApp, shell, Dashboard / Merchants / Clients / Images / Actu
```

- UI and hooks call **services only** → `{ data, error }`.
- No `supabase` / Firebase imports in this feature for phase 1.
- List default page size: `CMS_PAGE_SIZE = 25` (same rule as Sales lists).

## Backend phasing

| Phase | Behaviour |
|-------|-----------|
| **1 (now)** | In-memory mocks in `cmsData.ts` shaped like admin callables (`adminGetOverview`, `adminListMerchants`, `adminListUsers`, status updates). Media overrides in `localStorage`. |
| **2 (later)** | Services call Edge (`cms-list-merchants`, `cms-upsert-app-media`, …) → Firebase Admin / callables / Storage. Secrets never in `VITE_*`. Account links use `yuztoo_merchant_id` / `salesCrmLeadId` per [Firebase bridge](./supabase/10-firebase-bridge.md). |

Keep legacy `admin/` until CMS App is verified against live Firebase; then deprecate.

## Related

- [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)
- [10-firebase-bridge.md](./supabase/10-firebase-bridge.md)
- [CRM-HOLLY-BOOK.md](./CRM-HOLLY-BOOK.md)
- Flutter/Firebase contract: [CRM-HANDOFF-FORCE-UPDATE-AND-ACTU.md](./CRM-HANDOFF-FORCE-UPDATE-AND-ACTU.md)
  (callables: `adminGetForceUpdate`, `adminSetForceUpdate`, `adminListYuztooNews`, `adminUpsertYuztooNews`, `adminSetYuztooNewsRelease`, `adminSetYuztooNewsActive`, `adminDeleteYuztooNews` — region `europe-west1`)
