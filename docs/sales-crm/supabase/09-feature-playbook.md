# 09 — Feature playbook

Ordered steps for every Sales CRM domain, plus a map from today’s mock features to future Supabase objects. **No build in this phase** — this is the checklist when leaving mocks.

## Ordered steps (any domain)

1. **Domain** — pure types/rules in `features/<x>/domain/` (no Supabase).  
2. **Migration** — `supabase migration new …` → tables, FKs, indexes, `workspace_id`.  
3. **RLS** — enable + policies for select/insert/update/delete; test two workspaces.  
4. **RPC** (if needed) — aggregates / multi-step writes.  
5. **Service** — `features/<x>/services/*Service.ts` returns `{ data, error }`; only place for `.from` / `.rpc`.  
6. **Realtime / Storage** — `*Realtime.ts` and storage paths if required.  
7. **Edge** — only if secrets, webhooks, or privileged writes are needed.  
8. **Hooks / UI** — call services only; loading / empty / error.  
9. **Gates** — tick [SUPABASE-HOLLY-BOOK.md](./SUPABASE-HOLLY-BOOK.md) + [07-security-traps.md](./07-security-traps.md); run **advisors** when a project exists.  
10. **Docs** — if a new reusable pattern appears, update the bible + [CHANGELOG.md](./CHANGELOG.md).

Dependency direction (never reverse):

```
billing → quotes
contracts → quotes
inbox → leads (convert)
marketing, whatsapp, calendar, pipeline, dashboard → leads / shared refs as needed
```

---

## Mock → Supabase map

Objects below are **planned names** for the bootstrap phase — adjust in migrations but keep the responsibilities.

### Shared tenancy

| Object | Purpose |
|--------|---------|
| `workspaces` | Commercial teams |
| `workspace_members` | `user_id`, `workspace_id`, `role` |
| Storage buckets | Private; path `{workspace_id}/…` |

### `features/leads`

| Today | Later |
|-------|--------|
| `leadData` / `leadService` mocks | Table `leads` (`workspace_id`, stage, type, owner_id, …) |
| `createLead` | Insert under RLS |
| Pipeline drag | Update `stage` + SELECT policy |

### `features/pipeline` / `features/dashboard`

| Today | Later |
|-------|--------|
| Reads leads in memory | Same `leads` + RPC for KPIs / stage counts |

### `features/calendar`

| Today | Later |
|-------|--------|
| `appointmentData` | Table `appointments` FK → `leads`, `workspace_id` |

### `features/quotes`

| Today | Later |
|-------|--------|
| `quoteData` + `mockStore` | Table `quotes` + `quote_lines` |
| Share token in `domain/share.ts` | Table `quote_share_tokens` (opaque, expiry); Edge/RPC to issue & resolve |
| Public `?devis=` | Edge or RPC — no broad select by id |

### `features/contracts`

| Today | Later |
|-------|--------|
| `contractData` + localStorage | Table `contracts` FK → `quotes` |
| Signing token | `contract_signing_tokens` (opaque, single-use) |
| Canvas signature | Storage object + `contract_signatures` written by **Edge** after verify |
| Public `?contrat=` | Edge validates token, returns sealed document |

### `features/billing`

| Today | Later |
|-------|--------|
| Subscriptions / invoices / dunning mocks | `subscriptions`, `invoices`, dunning fields or `dunning_events` |
| Status transitions in domain | Enforce in RPC or CHECK + service; realign scheduled invoices in one transaction RPC |

### `features/inbox`

| Today | Later |
|-------|--------|
| Website form / email mocks | Table `inbox_messages` |
| Unread badge | Count query or RPC; optional Realtime filter by workspace |
| Convert to lead | Service transaction / RPC |
| Inbound | Edge webhook from yuztoo.fr → verify → insert |

### `features/marketing`

| Today | Later |
|-------|--------|
| Channels / posts mocks | `marketing_channels`, `marketing_posts`, `marketing_post_targets` |
| Publish / OAuth tokens | **Edge only**; browser stores channel ids + status |
| Media | Storage under workspace path |
| Audience filter | RPC resolving channel set from filter |

### `features/whatsapp`

| Today | Later |
|-------|--------|
| Numbers / templates / conversations / messages | `wa_numbers`, `wa_templates`, `wa_conversations`, `wa_messages` |
| 24h window (`isWindowOpen`) | Enforce in domain **and** service/RPC before send |
| Free text vs template | Service rejects free text when window closed |
| Graph API send / inbound webhook | **Edge**; signature verify; never expose WA token |
| Template approval status | Mirror Meta status; only `approved` sendable |

### Auth / settings

| Need | Status |
|------|--------|
| Login / register | Done — `features/auth` + session gate in `App.tsx` |
| `workspaces` / `workspace_members` + RLS | Done — migration `workspaces_members_rls`; signup trigger creates owner workspace |
| Workspace switcher | Reads memberships from Auth session (UX); RLS still membership-based |
| Email confirm | Project may require confirm; confirm in Dashboard or disable for local demo |

### Firebase product bridge (account keep-in-sync)

| Need | Later |
|------|--------|
| Link lead/subscription ↔ merchant | Columns `yuztoo_merchant_id` (+ link audit); Firebase stores `sales_crm_*` ids |
| Won deal / plan change → product | Edge `bridge-to-firebase` (idempotent event) |
| Merchant profile/status → CRM | Firebase CF → Edge/RPC updates CRM row |
| Rules | [10-firebase-bridge.md](./10-firebase-bridge.md) |

---

## Definition of done (when wiring starts)

A feature is done only when:

- [ ] Tables + RLS + indexes migrated  
- [ ] Service boundary respected  
- [ ] Holly book + security traps ticked  
- [ ] Advisors clean (or accepted with written reason)  
- [ ] Public/privileged paths go through Edge where required  
- [ ] If it touches a product account: bridge checklist in [10-firebase-bridge.md](./10-firebase-bridge.md) done  

