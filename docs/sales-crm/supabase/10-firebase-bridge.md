# 10 — Firebase ↔ Supabase bridge (accounts stay in sync)

Yuztoo runs **two systems**. They stay separate databases, but they **connect when a commercial account becomes (or updates) a product account**. This chapter is the contract so “the account is updated” on both sides without leaking credentials or mixing SDKs in the wrong app.

## Two systems of record

| System | Stack | Owns |
|--------|-------|------|
| **Sales CRM** (this web app) | Supabase (Auth, Postgres, Edge, Storage) | Pipeline, leads, devis, contrats, billing, marketing, WhatsApp sales ops |
| **Product app** (Flutter + product admin) | Firebase (Auth, Firestore, Functions, …) | Merchants, clients, loyalty, storefront, NFC / product runtime |

**Hard rules**

- Sales CRM UI / services: **no Firebase SDK**.  
- Product Flutter / product admin: **no Supabase client** for CRM tables.  
- **No shared database**, no shared service-role / Admin credentials in either browser.  
- All cross-system traffic goes through a **trusted bridge** (Supabase Edge and/or Firebase Cloud Functions) with secrets only on the server.

## When they connect

Typical moments (product can add more; the pattern stays the same):

1. Lead / quote / contract **won** in Sales CRM → create or link a **merchant** (or client) in Firebase.  
2. Merchant updates profile / plan / status in the **product app** → Sales CRM account / lead / subscription mirror must stay current.  
3. Billing or dunning change in CRM → product access or plan flags may need an update.  
4. Manual “link account” by a seller (paste / search by email or product id).

Every connection is an **explicit link**, not an implicit join across clouds.

## Identity link (the only shared truth)

Store stable foreign keys on both sides — never copy whole user documents across.

| Side | Field (planned) | Meaning |
|------|-----------------|--------|
| Supabase | `yuztoo_merchant_id` / `yuztoo_client_id` on lead, account, or subscription | Firebase document / Auth uid (as designed) |
| Firebase | `sales_crm_lead_id` / `sales_crm_workspace_id` (or equivalent) | Supabase row ids |
| Both | Optional `link_status`, `linked_at`, `last_synced_at` | Audit / sync health |

Emails and phones are **match hints**, not the permanent key. After link, updates use the ids.

## “Make sure the account is updated” — sync contract

### Source of truth by field family

| Field family | Source of truth | Other side |
|--------------|-----------------|------------|
| Commercial stage, owner, devis, contrat, CRM notes | **Supabase** | Firebase gets only status / “won” flags it needs |
| Product runtime: storefront, loyalty, NFC, app login | **Firebase** | CRM stores ids + display snapshot if needed |
| Shared profile slice (name, company, phone, city, plan label) | **Defined per event** — one writer per sync | Other side is updated by the bridge |

Never let both UIs write the same field without a bridge event, or the accounts diverge.

### Directions

```
Sales CRM (Supabase)  --Edge/CF-->  Product (Firebase)   // e.g. won deal → create/update merchant
Product (Firebase)    --CF/Edge-->  Sales CRM (Supabase) // e.g. merchant plan/status → update lead/subscription
```

Both directions are allowed. Each direction is a **named event** with a payload schema, not a free “sync everything” dump.

### Required properties of every sync job

1. **Authenticated bridge** — verify JWT or signed webhook; reject anonymous.  
2. **Idempotent** — same event id twice does not create two merchants or two CRM rows.  
3. **Workspace / tenant safe** — Supabase writes use service role but still set and check `workspace_id`; Firebase writes use Admin SDK with path rules that match the linked merchant.  
4. **Minimal payload** — only fields in the contract; no passwords, refresh tokens, or full dumps.  
5. **Audit** — write `last_synced_at` + event id on both sides (or a `sync_events` table in Supabase).  
6. **Failure visible** — CRM UI can show “link pending / sync failed”; never silent drop.

## CMS App Yuztoo (product-ops UI)

The **CMS App** (`features/cms-app`, entry `?cms=1`) is the Sales CRM–skinned replacement for the legacy Firebase `admin/` console (dashboard, boutiques, clients).

- Phase 1: mock services only — UI contracts match admin callable shapes.
- Phase 2: those services call Supabase Edge (e.g. `cms-list-merchants`) which invokes Firebase Admin / callables (`adminListMerchants`, …). That is the same bridge trust boundary: **no Firebase in the SPA**, secrets only server-side.
- Linked rows may expose `salesCrmLeadId` / `yuztoo_merchant_id` so sellers see the commercial ↔ product link without a shared database.

See [CMS-APP.md](../CMS-APP.md).

## Where the bridge lives

| Component | Role |
|-----------|------|
| Supabase Edge Function e.g. `bridge-to-firebase` | CRM → product: after won / subscription change |
| Supabase Edge e.g. `cms-list-merchants` | CMS App → Firebase admin callables (phase 2) |
| Supabase Edge e.g. `cms-upsert-app-media` | CMS Images → Admin CF / Storage (`app_media/{slotId}/current`) + `app_config/app_media_*` |
| Supabase Edge `cms-yuztoo-news` | CMS Actu → HTTPS `crmBridgeYuztooNews` (`CRM_BRIDGE_SECRET`) → `yuztoo_news` |
| Firebase Admin CF `adminUpsertAppMediaSlot` / `adminSetAppMediaRelease` | Writers for Flutter remote Images (preview/live gate) |
| Firebase HTTPS `crmBridgeYuztooNews` | Bridge writers for Actu (same validation as admin callables) |
| Firebase Cloud Function e.g. `bridgeToSalesCrm` | Product → CRM: after merchant profile / plan update |
| Optional shared HTTPS contract | Same JSON schema both ways; versioned (`v1`) |

Firebase Admin credentials live only in Cloud Functions (or a dedicated server).  
Supabase service role lives only in Edge secrets.  
Neither key is ever in `VITE_*` or the Flutter client.

See also: [04-edge-functions.md](./04-edge-functions.md).

## Sales CRM implementation rules (DDD)

- Domain: pure “link state” / sync status helpers if needed — no SDKs.  
- Service: `features/<x>/services/` may call `callEdgeFunction('bridge-…')` only — never Firebase.  
- Hooks/UI: show link status; trigger “sync now” via the service.  
- Do not import Firebase into `sales-crm/`.

## Product app rules (reminder)

- Product code talks to Firebase as today.  
- When a merchant must update the CRM account, call the Cloud Function / HTTPS bridge — do not open Supabase from Flutter with a service role.  
- Store `sales_crm_*` ids after first successful link.

## Checklist before shipping a sync path

- [ ] Event name + payload version documented  
- [ ] Source of truth per field listed  
- [ ] Idempotency key defined  
- [ ] Both sides store foreign keys after link  
- [ ] Secrets only server-side  
- [ ] Failure path + retry / manual “resync”  
- [ ] No Firebase in Sales CRM SPA; no Supabase service role in Flutter  

## Out of scope for the docs-only bible phase

Implementing Edge/CF code, choosing exact Firebase collection paths, or wiring the won-deal button — that is a later build phase. This chapter locks the **rules** so that phase cannot invent a shared DB or client-side Admin keys.

## Related

- [01-architecture.md](./01-architecture.md)  
- [04-edge-functions.md](./04-edge-functions.md)  
- [09-feature-playbook.md](./09-feature-playbook.md)  
- [SECURITY_GUIDELINES.md](../SECURITY_GUIDELINES.md)  
