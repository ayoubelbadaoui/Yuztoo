# CRM handoff — Force update + Actu Yuztoo

Prepared on the Flutter / Firebase side for the Sales CRM (**CMS App Yuztoo**, `?cms=1` on branch `crm-sales-yuztoo`). Wire CMS screens → Supabase Edge → these Admin callables (same pattern as Images app / merchants). **Do not write Firestore from the browser.**

Region for all callables: **`europe-west1`**.

Auth: Firebase Auth session with custom claim **`admin: true`**.  
`adminSetForceUpdate` and `adminDeleteYuztooNews` also require a **fresh login** (&lt; 2h).

---

## 1) Force update (mandatory store upgrade)

### What Flutter does (automatic detection)

1. Reads installed **build number** via `package_info_plus` (`pubspec` `+N`, currently `1.0.9+67`).
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

### Already in production (Flutter read path)

Collection: `yuztoo_news/{newsId}` — public read, client write false.

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

Client Alertes banner → **full-screen detail page** (`YuztooNewsDetailPage`).

### New Admin callables

| Name | Purpose | Body highlights |
|------|---------|-----------------|
| `adminListYuztooNews` | List (newest first) | `{ "limit": 50, "includeInactive": true }` |
| `adminUpsertYuztooNews` | Create / update | see below |
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

Omit `id` to create. Response is the JSON document (`id` + fields).

**Suggested CMS UX**

- List with active filter + schedule.
- Editor: title, body (textarea/markdown plain), publish datetime, image URL (or upload later), CTA fields.
- Preview card matching the in-app banner.
- Publish / unpublish via `active`.

### Flutter files

- Existing: `lib/feature/yuztoo_news/`
- New page: `lib/feature/yuztoo_news/presentation/yuztoo_news_detail_page.dart`
- Banner opens the page (no longer a bottom sheet only)

---

## 3) Edge bridge checklist (other guy)

Mirror existing CMS → Edge → Firebase Admin pattern:

| CMS action | Edge function (suggested name) | Firebase callable |
|------------|--------------------------------|-------------------|
| Load force gate | `cms-get-force-update` | `adminGetForceUpdate` |
| Save force gate | `cms-set-force-update` | `adminSetForceUpdate` |
| List actus | `cms-list-yuztoo-news` | `adminListYuztooNews` |
| Upsert actu | `cms-upsert-yuztoo-news` | `adminUpsertYuztooNews` |
| Toggle active | `cms-set-yuztoo-news-active` | `adminSetYuztooNewsActive` |
| Delete actu | `cms-delete-yuztoo-news` | `adminDeleteYuztooNews` |

Secrets stay server-side — never in `VITE_*`.

---

## 4) QA

**Force update**

1. Deploy rules + functions to **yuztoo-dev** and **yuztoo**.
2. On dev: `adminSetForceUpdate` with `force: true`, `android_min_build` / `ios_min_build` = current build + 1.
3. Cold start app → blocking screen → “Mettre à jour” opens store.
4. Set `force: false` (or min ≤ installed) → resume app → gate gone.
5. Offline / missing doc → app must still open (fail open).

**Actu**

1. `adminUpsertYuztooNews` with `publish_on` in the past, `active: true`.
2. Client Alertes → banner → full page shows title/body/image/CTA.
3. `active: false` → banner disappears.
4. Future `publish_on` → not shown yet.

---

## 5) Source references

- Functions: `functions/src/admin/crm_force_update.ts`, `crm_yuztoo_news.ts`
- Exports: `functions/src/index.ts`
- Rules: `firestore.rules` (`app_config`, `yuztoo_news`)
- CMS product notes: `yuztoo-crm-app/docs/sales-crm/CMS-APP.md`
