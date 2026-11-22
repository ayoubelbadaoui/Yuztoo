# CRM handoff — Force update + Actu Yuztoo

Mirror of the Flutter-side contract (`yuztoo` repo). **Do not write Firestore from the browser.**

**Status in this repo:** Actu CMS under `?cms=1` → **Actu Yuztoo** talks to Firebase via Edge `cms-yuztoo-news` → `crmBridgeYuztooNews` (per-actu test→live gate). Flutter dual-query is in the `yuztoo` repo. Force update CMS screen still pending. Set `VITE_CMS_ACTU_MOCK=1` only for offline UI.

Prepared on the Flutter / Firebase side for Sales CRM (**CMS App Yuztoo**, `?cms=1`). Wire services → Supabase Edge → these Admin callables (same pattern as Images / merchants).

Region for all callables: **`europe-west1`**.

Auth: Firebase Auth session with custom claim **`admin: true`**.  
`adminSetForceUpdate` and `adminDeleteYuztooNews` also require a **fresh login** (&lt; 2h).

---

## 1) Force update (mandatory store upgrade)

### What Flutter does (automatic detection)

1. Reads installed **build number** via `package_info_plus` (`pubspec` `+N`, currently `1.0.8+66`).
2. Watches Firestore `app_config/force_update` live.
3. If `force == true` **and** installed build **&lt;** platform min → full-screen hard gate (no dismiss). CTA opens store URL.
4. Re-checks on **app resume** (after user returns from the store).

CRM does **not** need to push to devices. After a store release is approved, set the new min build + `force: true`.

### Firestore doc

`app_config/force_update`

| Field | Type | Notes |
|-------|------|--------|
| `force` | bool | Gate master switch |
| `android_min_build` | int | Inclusive floor vs Android `versionCode` / `+build` |
| `ios_min_build` | int | Inclusive floor vs iOS build / `+build` |
| `message_fr` | string? | Optional blocking copy |
| `android_store_url` | string? | Default: Play listing `com.yuztoo.app` |
| `ios_store_url` | string? | **Set the real App Store URL** when known |
| `updated_at` / `updated_by` | server | Written by callable |

Rules: **public read** of this doc only; client **write false**.

### Callables

| Name | Purpose | Body |
|------|---------|------|
| `adminGetForceUpdate` | Read current gate | `{}` |
| `adminSetForceUpdate` | Upsert gate (fresh admin) | see below |

**`adminSetForceUpdate` body**

```json
{
  "force": true,
  "android_min_build": 67,
  "ios_min_build": 67,
  "message_fr": "Une nouvelle version est disponible.",
  "android_store_url": "https://play.google.com/store/apps/details?id=com.yuztoo.app",
  "ios_store_url": "https://apps.apple.com/app/idXXXXXXXX"
}
```

**Suggested CMS UX**

1. Show current installed floors + store URLs.
2. Form: force toggle, android/ios min builds, message, URLs.
3. Confirm dialog before enabling `force: true` (“locks outdated installs”).
4. After Play/App Store **approve** a build, set that build number as the new min.

### Flutter files

- `lib/feature/force_update/` (domain + Firestore repo + gate UI)
- Wired in `lib/main.dart` via `ForceUpdateGate`
- Resume refresh in `lib/main_shell_state.part.dart`

---

## 2) Actu Yuztoo (CRM-controlled news page)

### Collection + release gate

Collection: `yuztoo_news/{newsId}` — **client write false**. Reads are gated:

| `release_status` | Who can read |
|------------------|--------------|
| missing / `live` | Public (legacy missing ≡ live) |
| `preview` | Only signed-in `request.auth.uid == test_account_id` |
| `draft` | Nobody (clients) |

| Field | Type | Notes |
|-------|------|--------|
| `title` | string | required |
| `body` | string | required (full page body) |
| `publish_on` | timestamp | shown only when ≤ now |
| `active` | bool | false hides immediately |
| `image_url` | string? | |
| `cta_label` | string? | default “En savoir plus” |
| `cta_url` | string? | http(s) |
| `cta_merchant_id` | string? | opens shop; wins over `cta_url` |
| `release_status` | `draft` \| `preview` \| `live` | per-actu gate |
| `test_account_id` | string? | preview audience UID |
| `test_account_label` | string? | CMS display |
| `preview_activated_at` | timestamp? | required before live |
| `live_at` | timestamp? | set on publish live |

Client Alertes banner → **full-screen detail page** (`YuztooNewsDetailPage`).

### Flutter dual-query (required)

Do **not** query all `active` docs in one listener — foreign `preview` docs would fail rules for other users and break the whole stream.

1. `active == true` + `release_status == live` + `orderBy publish_on desc`
2. `active == true` + `release_status == preview` + `test_account_id == uid` + `orderBy publish_on desc`

Merge → `selectCurrentYuztooNews(..., viewerUid: uid)`. Composite indexes are in `firestore.indexes.json`.

### Admin callables

| Name | Purpose | Body highlights |
|------|---------|-----------------|
| `adminListYuztooNews` | List (newest first); backfills missing `release_status` → `live` | `{ "limit": 50, "includeInactive": true }` |
| `adminUpsertYuztooNews` | Create / update content | create → `draft`; edit while live → demote to `draft` |
| `adminSetYuztooNewsRelease` | Gate transitions | `{ "id", "release_status": "draft\|preview\|live", "test_account_id?", "test_account_label?" }` |
| `adminSetYuztooNewsActive` | Soft hide/show | `{ "id": "...", "active": false }` |
| `adminDeleteYuztooNews` | Hard delete (fresh admin) | `{ "id": "..." }` |

**`adminUpsertYuztooNews` body**

```json
{
  "id": "optional-existing-id",
  "title": "Nouvelle fonctionnalité",
  "body": "Texte long contrôlé depuis le CRM…",
  "publish_on": "2026-11-21T09:00:00.000Z",
  "active": true,
  "image_url": "https://…",
  "cta_label": "Découvrir",
  "cta_url": "https://yuztoo.com",
  "cta_merchant_id": null
}
```

Omit `id` to create. Response is the JSON document (`id` + fields). New docs always start as **draft**.

**`adminSetYuztooNewsRelease`**

- `preview` requires `test_account_id` (or already stored on the doc).
- `live` requires current status `preview` + `test_account_id` + `preview_activated_at`.
- `draft` clears preview/live stamps (keeps test account for convenience).

**CMS UX (sales-crm — live)**

- List status: Brouillon / Aperçu test / En ligne (tous) / Programmée / Inactive.
- Editor Publication block: pick test account → Activer aperçu → Mettre en ligne pour tous (confirm).
- CTA: prefer `cta_merchant_id` (in-app); `cta_url` warns it opens the external browser.

### Flutter files

- `lib/feature/yuztoo_news/` (dual-query repository + uid-aware `selectCurrentYuztooNews`)
- Detail: `presentation/yuztoo_news_detail_page.dart`

---

## 3) Edge bridge (Actu — shipped pattern)

| CMS action | Edge | Firebase |
|------------|------|----------|
| All Actu ops | `cms-yuztoo-news` `{ action }` | HTTPS `crmBridgeYuztooNews` |
| actions | `list` \| `upsert` \| `setActive` \| `setRelease` \| `delete` | same handlers as admin callables |
| Load force gate | `cms-get-force-update` (pending) | `adminGetForceUpdate` |
| Save force gate | `cms-set-force-update` (pending) | `adminSetForceUpdate` |

**Secrets (never `VITE_*`)**

| Name | Where |
|------|--------|
| `CRM_BRIDGE_SECRET` | Firebase CF env + Supabase Edge secrets (same value) |
| `FIREBASE_PROJECT_ID` | Edge (default `yuztoo`) |
| `CRM_BRIDGE_YUZTOO_NEWS_URL` | Edge optional override |

Callables `adminListYuztooNews` / `adminUpsertYuztooNews` / … remain for legacy Firebase admin UI.

**Pictures Phase B:** Storage `yuztoo_news/{id}/hero`, crop 16:9 ≤1.5Mo — see [CMS-APP.md](./CMS-APP.md).

---

## 4) QA

**Force update**

1. Deploy rules + functions to **yuztoo-dev** and **yuztoo**.
2. On dev: `adminSetForceUpdate` with `force: true`, `android_min_build` / `ios_min_build` = current build + 1.
3. Cold start app → blocking screen → “Mettre à jour” opens store.
4. Set `force: false` (or min ≤ installed) → resume app → gate gone.
5. Offline / missing doc → app must still open (fail open).

**Actu**

1. Upsert content → doc is **draft** (not visible in app).
2. `adminSetYuztooNewsRelease` → `preview` with `test_account_id` → only that UID sees banner.
3. Other UIDs still see previous **live** actus (dual-query; no permission errors).
4. `adminSetYuztooNewsRelease` → `live` → everyone sees it (when `publish_on` ≤ now).
5. Live without prior preview → rejected.
6. `active: false` → banner disappears; future `publish_on` → not shown yet.
7. Deploy **rules + indexes + functions** together before relying on dual-query clients.

---

## 5) Source references

- Functions: `functions/src/admin/crm_force_update.ts`, `crm_yuztoo_news.ts`
- Exports: `functions/src/index.ts`
- Rules: `firestore.rules` (`app_config`, `yuztoo_news`)
- CMS product notes: `yuztoo-crm-app/docs/sales-crm/CMS-APP.md`
