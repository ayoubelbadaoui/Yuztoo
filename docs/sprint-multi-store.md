# Multi-store (Enseignes) — Complete Sprint Plan

> **Goal:** An entrepreneur with 1 to 50+ points de vente (same city or several cities) can onboard, run, staff, promote and bill all of them from one Yuztoo account, and clients experience the enseigne coherently.
> **Locked product decisions:**
> - **Loyalty:** the entrepreneur chooses per enseigne — *par point de vente* or *partagée sur tout le réseau*.
> - **Team:** three roles — **Propriétaire**, **Gérant** (one or more stores), **Employé** (scan / validate only).
> - A store without an enseigne stays a normal independent merchant. Nothing changes for existing single-store merchants unless they add a second store.
> **Context for agents:** Flutter + Riverpod + Firebase, DDD layers (`domain` → `application` → `infrastructure` → `presentation`). Read `docs/yuztoo-holy-book.md` first. Backend changes deploy to **both** `yuztoo-dev` and `yuztoo` (`docs/firebase-dual-env-deploy.md`) — **only when the owner green-lights prod**.

---

## Current state (why this is mostly additive)

| Area | Today | Impact |
|---|---|---|
| Store data | Everything per store under `merchants/{merchantId}/…` (clients, loyalty_clients, promotions, notifications, stats, photo likes) | ✅ Reused as-is: one store = one merchant doc |
| Ownership | Rules check `merchants/{id}.owner_uid == auth.uid` | ✅ One uid can already own N merchant docs |
| "My store" | Single pointer `users/{uid}.merchant_id`, read by `currentMerchantProvider` (`lib/feature/merchant/application/providers.dart`) and many screens | ❌ Must become an *active store* + list of accessible stores |
| uid fallbacks | Some code assumes `merchantId == uid` (e.g. `profile_edit_state.part.dart` save) | ❌ Must be removed |
| Onboarding | 10-step flow `merchant_onboarding/presentation/onboarding_flow_screen.dart` → `complete_merchant_onboarding.dart` sets `users.merchant_id` | ❌ Needs an "enseigne / multi-store" branch |
| Backend | `functions/src/index.ts` notifies a single `owner_uid` (`onFollowedMerchantCreated`, `onActiveValidationAwaiting`, `purgeAccount`, …) | ❌ Must fan out to store team |
| Billing | `MerchantSubscriptionPlan` per merchant | ❌ Needs enseigne-level billing |
| Grouping that already exists | `merchant_associations`, `merchant_partners` | ⚠️ Different concept (independent shops cooperating) — do **not** reuse for enseignes |

---

## Target data model

```
organizations/{orgId}
  name, logo_url, description, category_id, subcategory_title
  owner_uid
  loyalty_mode: 'per_store' | 'shared'
  subscription_plan, billing_*            (Sprint 11)
  store_count, created_at, updated_at

organizations/{orgId}/members/{uid}
  role: 'owner' | 'manager' | 'employee'
  store_ids: [merchantId…]                (empty for owner = all stores)
  status: 'invited' | 'active' | 'removed'
  invited_by, invited_at, joined_at

organizations/{orgId}/loyalty_clients/{clientUid}   (only when loyalty_mode == 'shared')

organization_invites/{inviteId}
  org_id, role, store_ids, phone|email, code, expires_at, status

merchants/{merchantId}
  + organization_id (nullable)
  + store_label (e.g. "Belfort Centre"), inherited fields flags
  + member_uids: [uid…]                   (denormalized for rules: owner + managers + employees)

users/{uid}
  merchant_id            → kept = ACTIVE store (backward compatible)
  + organization_ids: [orgId…]
  + accessible_merchant_ids: [merchantId…] (denormalized, Cloud Function maintained)
```

### Permission matrix

| Action | Propriétaire | Gérant (his stores) | Employé (his stores) |
|---|:-:|:-:|:-:|
| Scan QR / validate passage / redeem bon | ✅ | ✅ | ✅ |
| See client list (CRM) | ✅ all stores | ✅ | ❌ |
| Edit vitrine, hours, photos | ✅ | ✅ | ❌ |
| Create promo / send notification for a store | ✅ | ✅ | ❌ |
| Multi-store promo / notification | ✅ | ❌ | ❌ |
| Network stats dashboard | ✅ | own stores only | ❌ |
| Add / remove / publish store | ✅ | ❌ | ❌ |
| Invite / remove team members | ✅ | employees of his stores | ❌ |
| Change loyalty mode, enseigne profile, billing | ✅ | ❌ | ❌ |

---

## Sprint 0 — Audit & foundations (no UI change) — ✅ DONE

> Shipped locally (not deployed): `activeMerchantIdProvider` + `ownedMerchantsProvider` in `merchant/application/providers.dart`; `currentMerchantForOwnerProvider`, `storefrontProvider`, `currentMerchantIdProvider`, profile save and Promotions now resolve the active store; `getMerchantByOwnerUid` queries `owner_uid` (was a `doc(uid)` read) + new `getMerchantsByOwnerUid`. Tests: `test/feature/merchant/infrastructure/merchants_by_owner_test.dart`. Prod check: 64/64 merchants have id == owner uid, 0 owners with 2+ stores.

### Task 0.1 — Remove `merchantId == uid` assumptions
- Grep `?? userId`, `: userId`, `?? uid`, `doc(uid)` near `merchants` across `lib/` and `functions/src/`.
- Replace with the resolved active merchant id (Task 0.2). Start with `lib/feature/storefront/application/profile_edit_state.part.dart` save.
**Acceptance:** no code path derives a merchant id from the auth uid.

### Task 0.2 — Single source of truth: `activeMerchantIdProvider`
- New provider in `lib/feature/merchant/application/` reading `users.merchant_id` (stream), exposing `String?`.
- Migrate every direct `users/{uid}.merchant_id` read (≈30 files: `rg -l merchant_id lib`) to this provider.
**Acceptance:** changing `users.merchant_id` in Firestore switches every merchant screen live without restart.

### Task 0.3 — Backend owner-lookup inventory
- List every `owner_uid` usage in `functions/src/index.ts` and `functions/src/admin/*`; document target behaviour (owner only / store team / managers) in this file's appendix.
**Acceptance:** appendix table complete, reviewed.

---

## Sprint 1 — Data model, rules, functions plumbing

### Task 1.1 — Domain entities
- `lib/feature/organization/domain/`: `Organization`, `OrganizationMember`, `OrganizationRole`, `LoyaltyMode`, `OrganizationRepository` (interface), failures.
### Task 1.2 — Infrastructure
- Firestore DTOs + mappers + `FirestoreOrganizationRepository`; `organization_id`, `store_label`, `member_uids` in `MerchantDto`.
### Task 1.3 — Security rules
- Helpers: `isOrgOwner(orgId)`, `orgRole(orgId)`, `isStoreMember(merchantId)`, `canManageStore(merchantId)`.
- Merchant writes: `owner_uid == auth.uid` **OR** manager of that store. Employees: only passage/validation paths.
- Subcollections (`loyalty_clients`, `active_validations`, `promotions`, `sent_notifications`, …): replace owner check with the role helper per the matrix.
- Emulator tests in `functions/src/__tests__` for each role × action.
### Task 1.4 — Denormalization functions
- `onOrganizationMemberWrite` → maintain `merchants.member_uids` and `users.accessible_merchant_ids`.
- `onMerchantWrite` (organization_id set) → keep `organizations.store_count`.
**Acceptance:** rules test matrix green; single-store merchants untouched (regression suite passes).

---

## Sprint 2 — Onboarding

### Task 2.1 — Branch question
- In `onboarding_flow_screen` after business type: **"Combien de points de vente avez-vous ?"** → `1` / `2 à 5` / `6 et plus`.
- `1` → current flow unchanged.
### Task 2.2 — Enseigne flow (2+)
1. Enseigne identity: name, logo, category/specialty, description (shared defaults).
2. Loyalty mode choice with plain explanation + example ("Un tampon à Belfort compte aussi à Mulhouse").
3. First store: city (shared `CitySearchSheet`), address, phone, hours.
4. "Ajouter vos autres points de vente": quick-add rows (city + address + optional label), skippable — stores created as **hors ligne** drafts.
5. Optional: invite gérants (phone/email per store), skippable.
- Use case `CreateOrganizationWithStores` (application layer) writes org + members + merchants in a batch, sets `users.merchant_id` to the first store.
### Task 2.3 — Existing merchant → enseigne
- Settings entry **"Ajouter un point de vente"**: if no org, create one from current store (prefilled), attach current store, then quick-add.
**Acceptance:** a new user can go from signup to an enseigne with 10 draft stores in < 5 min; single-store onboarding unchanged.

---

## Sprint 3 — Active store context & switcher

### Task 3.1 — Store switcher
- Header of "Votre vitrine" (and CRM, Promotions, Notifications): `Boulangerie Dupont · Belfort Centre ▾` → bottom sheet listing accessible stores (search when > 8, status dot online/offline, completion %).
- Selecting writes `users.merchant_id` (Task 0.2 makes everything follow).
### Task 3.2 — "Tous les points de vente" view (owner/gérant)
- New screen: list/map of stores, filters by city/status, completion %, views/week, clients count; tap → switch + open vitrine.
### Task 3.3 — Context-safe deep links
- FCM payloads and `main_shell_state.part.dart` handlers carrying `merchant_id` switch the active store first if the user has access; otherwise ignore.
**Acceptance:** owner with 12 stores switches in 2 taps; notification for store B opens store B even if A was active.

---

## Sprint 4 — Store creation & bulk management

### Task 4.1 — Duplicate store
- From any store: "Dupliquer ce point de vente" → copies enseigne fields, hours, categories, accessibility; asks city/address/phone/photos only.
### Task 4.2 — Inheritance
- Fields inherited from enseigne (logo, description, category) with per-store "personnaliser" override; edit at enseigne level propagates to non-overridden stores (Cloud Function or batch use case).
### Task 4.3 — Bulk actions
- Hours / exceptional closure (jours fériés) applied to selected stores; publish / unpublish several stores; completion checklist per store reused from the edit profile page.
**Acceptance:** changing the enseigne logo updates all non-overridden stores; setting Christmas closure on 10 stores is one action.

---

## Sprint 5 — Team & roles

### Task 5.1 — Invitations
- Owner/gérant invites by phone or email → `organization_invites` + share link / SMS. Expiry 7 days, revocable.
### Task 5.2 — Accept flow
- Invite link → signup/login → role-specific landing; user becomes merchant-side without doing merchant onboarding.
### Task 5.3 — Team screen
- List members per store, change role/stores, remove (with confirmation), pending invites.
### Task 5.4 — Employee mode
- Reduced shell: scanner + today's validations + bons, store name visible; no CRM, no settings.
### Task 5.5 — Dual-profile users
- A client account that is also an employee keeps client mode; role switch respects existing client/merchant switching.
**Acceptance:** an employee can only scan for his store (verified by rules tests and UI); removing a member revokes access within one snapshot.

---

## Sprint 6 — Loyalty modes

### Task 6.1 — Per-store mode
- Default and current behaviour (`merchants/{id}/loyalty_clients`).
### Task 6.2 — Shared mode
- Progress stored in `organizations/{orgId}/loyalty_clients/{uid}` with `last_store_id` and per-store passage log.
- `process_vitrine_scan_visit.dart`, `onLoyaltyProgressUpdated`, `dailyBonExpirationScan`, `passage_auto_confirm_core.ts` resolve the loyalty owner (store or org) through one helper.
- Bons redeemable in any store of the enseigne; cooldown applied network-wide.
### Task 6.3 — Mode switch
- per_store → shared: merge strategy (sum stamps per client, cap at reward threshold) behind an explicit confirmation; shared → per_store: keep progress on the client's most-visited store. One-shot migration function.
### Task 6.4 — Client display
- Card shows "Valable dans les 12 boutiques X" + store list.
**Acceptance:** in shared mode a stamp at store A and one at store B count toward the same reward; redeeming at C works.

---

## Sprint 7 — Clients, promotions, notifications

### Task 7.1 — Consolidated CRM
- Owner: "Tous les points de vente" filter + per-store filter; a client following 3 stores appears once with store chips.
### Task 7.2 — Multi-store promotions
- Promotion composer: target "ce point de vente / sélection / tous"; creates one promotion per store (keeps existing per-store model and rules) with shared `campaign_id`.
### Task 7.3 — Multi-store notifications
- Same targeting for manual notifications and auto-notification templates; `notification_quota_core.ts` quota decision: per store (recommended) — document it.
### Task 7.4 — De-duplication for clients
- A client following several stores of one enseigne receives a multi-store campaign once (dedupe by `campaign_id` in `onNotificationCreated` / `processScheduledNotifications`).
**Acceptance:** one campaign to 10 stores → each follower notified exactly once.

---

## Sprint 8 — Network stats

- `merchant_stats`: network dashboard (views, follows, passages, promo performance) with store ranking and city breakdown; per-store drill-down = existing stats screen.
- Aggregation via scheduled function into `organizations/{orgId}/stats_daily/{date}` to avoid N reads.
**Acceptance:** dashboard loads in < 1 s for 50 stores.

---

## Sprint 9 — Client side

### Task 9.1 — Découverte grouping
- When several stores of the same enseigne match ("Proche de moi" / same city), show the nearest one with "+N autres boutiques".
### Task 9.2 — Enseigne page
- Shared header (logo, description, loyalty mode badge), "Nos boutiques" list + map sorted by distance, each opening its vitrine.
### Task 9.3 — Follow
- Follow a store (current) or the enseigne (news + network campaigns; auto-follows nearest store for local notifications).
### Task 9.4 — Search
- Searching the enseigne name returns the enseigne page first.
**Acceptance:** Découverte never shows 3 identical cards for one enseigne in one city.

---

## Sprint 10 — Backend notifications routing & admin

- Apply the Sprint 0.3 table: new follower / validation awaiting → store team (gérants + employés on duty for validations), owner gets a daily digest instead of every event.
- Push tokens remain per user; payload always includes `merchant_id` (Task 3.3).
- Admin CRM (`functions/src/admin/crm_merchants.ts`): enseigne view, store list, members.
**Acceptance:** owner of 20 stores is not spammed; the right gérant gets the validation request.

---

## Sprint 11 — Billing

- Subscription moves to `organizations` (stores without org keep merchant-level plan).
- Pricing per active store with volume tiers (e.g. 1 / 2–5 / 6–20 / 20+); draft (hors ligne) stores free.
- Découverte visibility gates (`MerchantSubscriptionPlan`) evaluated from org plan when `organization_id` is set.
**Acceptance:** publishing an 11th store shows the price impact before confirming.

---

## Sprint 12 — Lifecycle & compliance

- Remove a store (soft delete, clients notified/unfollowed, loyalty handled per mode).
- Transfer ownership; owner account deletion blocked while org has other members unless transferred or org closed.
- `purgeAccount`, `onAuthUserDeleted`, `purgeSoftDeletedRecords`: handle org membership and org-owned data.
- `portable_user_data_export.dart`: include org + stores for owners.
**Acceptance:** deleting a gérant account leaves stores intact; closing an enseigne cleans every store.

---

## Sprint 13 — QA, migration, release

- QA matrix (`docs/qa/`): roles × screens, loyalty modes, 1 vs 50 stores, offline, deep links.
- Migration: none required for existing merchants (org optional). Backfill `member_uids = [owner_uid]` on existing merchants before rules switch.
- Dual-env deploy (functions, rules, indexes) to `yuztoo-dev` then `yuztoo` **only after explicit go for prod**.
- Release behind a remote flag `multi_store_enabled` (onboarding branch + settings entry hidden when off).

---

## Suggested order & sizing

| Sprint | Depends on | Size |
|---|---|---|
| 0 Audit & foundations | — | S |
| 1 Model, rules, functions | 0 | L |
| 2 Onboarding | 1 | M |
| 3 Switcher & network view | 0, 1 | M |
| 4 Bulk management | 3 | M |
| 5 Team & roles | 1, 3 | L |
| 6 Loyalty modes | 1 | L |
| 7 Clients / promos / notifications | 3, 5 | M |
| 8 Network stats | 3 | M |
| 9 Client side | 1 | M |
| 10 Backend routing & admin | 5 | M |
| 11 Billing | 1 | M |
| 12 Lifecycle | 5, 6 | M |
| 13 QA & release | all | M |

**MVP cut (sellable to a 10-store entrepreneur):** Sprints 0–5 + 6.1/6.2 + 7.2 + 9.1/9.2 + 13.

---

## Appendix — Backend owner lookups (fill in Sprint 0.3)

| Function | Current recipient | Target recipient |
|---|---|---|
| `onFollowedMerchantCreated` | `owner_uid` | store gérants (+ owner digest) |
| `onActiveValidationAwaiting` | `owner_uid` | store team on duty |
| `purgeAccount` / `onAuthUserDeleted` / `purgeSoftDeletedRecords` | owner's merchant | org-aware (Sprint 12) |
| `admin/crm_merchants.ts` | per merchant | + enseigne grouping |

## Client demo (placeholder data, no Firestore)

Paramètres Pro → Vitrine → **Points de vente** opens `StoresScreen`
(`lib/feature/organization/presentation/`). It runs entirely on
`multiStoreDemoProvider` (`application/multi_store_demo.dart`): in-memory
placeholder data ("Boulangerie Dupont", 4 stores, 5 team members), reset on
app restart. Covered: enseigne card + loyalty mode choice, network totals,
store switch, add a store (offline), online/offline toggle, team by role,
invite / edit / remove member.

To go live, swap `multiStoreDemoProvider` for the Firestore-backed providers
in `application/providers.dart` (repository already written, unused by UI).
