# Uber-like Firebase — cost & scale sprint plan

**Goal:** Same app flows for merchants and clients; cheaper, stabler Firebase usage (less “juicy” Google invoice).  
**Out of scope:** Product quota launch decisions, App Check / SMS policy, UI redesign, Supabase migration.  
**Rule:** Ship behind flags where possible → soak on `yuztoo-dev` → dual-deploy `yuztoo-dev` + `yuztoo`.

---

## Principles

1. **UX unchanged** — Send, promo, CRM, Découvrir, loyalty behave the same.
2. **No phone fan-out** — Campaigns are one API call; servers batch work.
3. **No per-recipient Function tax for campaigns** — Push in the worker; badge via counter, not `count()`.
4. **No full-table scans** — Jobs query only merchants/docs that need work; lists paginate.
5. **One path per feature** — Delete leftover client fan-out when CF already owns it.

---

## Sprint overview

| Sprint | Name | Theme | Est. |
|--------|------|--------|------|
| **S1** | Post office | Campaign send + push pipeline | 3–5 days |
| **S2** | No N+1 | Block checks + CRM profiles | 2–3 days |
| **S3** | Night janitor | Scheduled jobs don’t scan the world | 1–2 days |
| **S4** | Light shelves | Lean lists + single promo path | 2–3 days |
| **S5** | Prove it | Metrics, soak, dual-env | 1–2 days |

---

## Sprint 1 — Post office (P0)

**Outcome:** Manual send no longer loops on the merchant phone; campaign pushes don’t run `onNotificationCreated` + unread `count()` per person.

### S1-T1 — Callable `sendMerchantNotification`
- [ ] HTTPS callable (europe-west1): auth, merchant ownership, audience/segments.
- [ ] Page followers (or first version: load then chunk).
- [ ] Batch write inbox docs (≤500).
- [ ] Write/update `sent_notifications` + weekly counter (same fields as today).
- [ ] Flutter: `SendMerchantNotification` calls callable; remove per-client `create` loop.
- [ ] Feature flag: `USE_SERVER_NOTIF_FANOUT` (dev on, prod off until soak).

### S1-T2 — FCM in the worker (not per-doc trigger)
- [ ] In the same callable (or Cloud Task worker): load tokens in chunks.
- [ ] `sendEachForMulticast` (or equivalent) ≤500 tokens.
- [ ] For **bulk** sends: do **not** rely on `onNotificationCreated` for FCM.
- [ ] Keep `onNotificationCreated` for true 1:1 / legacy single creates (loyalty, etc.) until S1-T3.

### S1-T3 — Badge without `count()`
- [ ] Add `unread_notif_count` (or reuse existing field if any) on `users/{uid}`.
- [ ] Bulk path: `increment(1)` per inbox write (or batched equivalent).
- [ ] Client inbox read/mark-read adjusts counter.
- [ ] Remove unread `count()` from bulk path; optionally leave on single-doc trigger until cutover.

### S1-T4 — Wire scheduled + promo campaigns to same push helper
- [ ] Extract shared `fanOutCampaign({ merchantId, targets, payload })`.
- [ ] `processScheduledNotifications` and `onPromotionCreated` call helper for FCM (after inbox batch writes).
- [ ] Still create inbox docs (UX unchanged).

**Acceptance**
- Merchant send to N followers: **1** callable from app (not N writes).
- Functions invocations for a 100-person send ≪ 100.
- Client still gets inbox row + push.
- Dual-env deploy after green soak on dev.

---

## Sprint 2 — No N+1 (P1)

**Outcome:** Block and CRM don’t do one read per human.

### S2-T1 — Block flag on follow (or equivalent denorm)
- [ ] When client blocks merchant: set denorm on follow doc / reverse index (choose one model).
- [ ] Fan-out filters blocked without `blocked_merchants/{id}.get()` per target.
- [ ] Backfill script or lazy migrate on next block/unblock.

### S2-T2 — CRM display denorm
- [ ] On follow (and profile update if needed): store `display_name`, `photo_url`, `city` on follow or `loyalty_clients`.
- [ ] `watchClients` stops N× `users/{uid}.get()` for list paint.
- [ ] Fallback read if denorm missing (temporary).

**Acceptance**
- Promo/manual send: no N block gets in logs.
- CRM open for 200 clients: profile reads ≪ 200.

---

## Sprint 3 — Night janitor (P1/P2)

**Outcome:** Cron jobs don’t `merchants.get()` the entire collection.

### S3-T1 — Daily auto triggers
- [ ] Replace `db.collection("merchants").get()` with query on auto-notif enabled (add indexed field if needed).
- [ ] Keep birthday / anniversary / inactive behavior identical.

### S3-T2 — Weekly counter reset
- [ ] Query only merchants with `weekly_notif_sent_count > 0` (or equivalent).

### S3-T3 — Scheduled queue bound
- [ ] `processScheduledNotifications`: `.limit(N)` + loop/paginate until empty or time budget.
- [ ] Never unbounded `.get()` on the whole pending set.

**Acceptance**
- Daily job read count ≈ enabled merchants, not all merchants.
- Large pending queue processes across ticks without timeout bomb.

---

## Sprint 4 — Light shelves (P2)

**Outcome:** List UIs don’t download fat merchant documents; one promo notify path.

### S4-T1 — Public projection for lists
- [ ] Discovery / home / partner picker read lean fields (name, logo, city, status, plan visibility fields only).
- [ ] Full merchant doc only on storefront / settings.
- [ ] Optional: `merchants_public/{id}` or `select()`-style field discipline in DTOs.

### S4-T2 — Partner search
- [ ] Replace `merchants.limit(200).get()` + client fuzzy with indexed prefix / search field query (or capped server callable).

### S4-T3 — Single promo fan-out path
- [ ] Ensure toggle-online / create only server path fires.
- [ ] Remove or hard-disable Flutter `NotifyFollowersOfPromotion` call sites to avoid double work.

**Acceptance**
- Découvrir / partner search payload size clearly smaller in Network/Firestore metrics.
- Promo notify: exactly one fan-out implementation in prod paths.

---

## Sprint 5 — Prove it (diligence)

**Outcome:** Numbers that show the invoice won’t explode.

### S5-T1 — Metrics
- [ ] Log per campaign: `targets`, `inbox_writes`, `fcm_batches`, `function_invocations`.
- [ ] Dashboard or log-based: cost proxy = writes + FN runs per 1k recipients.

### S5-T2 — Soak script
- [ ] Dev: send to 50 → 200 → 500 test followers.
- [ ] Compare before/after: FN invocations, duration, failures.

### S5-T3 — Dual-env + rollback
- [ ] Deploy both projects.
- [ ] Flag rollback to legacy phone path if needed (S1 only; remove after confidence).

**Acceptance**
- Written before/after for a 500-recipient send.
- Rollback tested once on dev.

---

## Dependency graph

```
S1-T1 → S1-T2 → S1-T3
              ↘ S1-T4
S1 done  →  S2 (can overlap S3)
S3 parallel with S2
S4 after S1 (promo helper) preferred
S5 continuous from S1 soak
```

---

## Explicitly not this plan

- Enabling free-plan weekly quota product flag (separate product sprint).
- App Check / SMS region policy (security sprint).
- Firestore rules hardening (security sprint — do in parallel if possible).
- Rewriting `main_shell` / go_router.
- Moving off Firebase.

---

## Definition of done (whole initiative)

- [ ] Merchant “send to all” does not write N inbox docs from the device.
- [ ] Bulk campaigns do not invoke one Cloud Function + unread `count()` per recipient.
- [ ] Cron jobs do not full-scan `merchants` without a filter.
- [ ] CRM / block paths are not N+1 reads.
- [ ] Same user-visible flows; dual-env deployed; soak numbers attached to the PR/release notes.

---

## Quick reference — plain language

| Sprint | One sentence |
|--------|----------------|
| S1 | Post office sends the letters; the phone only drops one package. |
| S2 | Don’t open 500 lockers to see who’s blocked; don’t reload 200 full IDs for a list. |
| S3 | Night jobs only visit shops that need work. |
| S4 | Shelves show light labels; full box only when you open the shop. |
| S5 | Prove the bill got smaller before calling it done. |
