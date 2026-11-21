# 01 — Architecture

How Supabase fits the Yuztoo Sales CRM stack without breaking DDD or tenancy.

## Stack map

```
Browser (Vite SPA)
  components / hooks     →  feature services only
  feature services       →  supabase-js (publishable/anon)  and/or  callEdgeFunction
Edge Functions
  verify JWT             →  service role / secret for privileged writes
Postgres
  RLS on every tenant table
  RPC for heavy reads / transactions
Realtime / Storage
  same workspace scope as RLS
```

**Rule:** UI never imports the Supabase client. Only `src/features/**/services/**` (and a shared Edge helper if needed). See [DDD compliance](../DDD_COMPLIANCE_PROMPT.md).

## Client vs server responsibility

| Concern | Where |
|---------|--------|
| List / read tenant data under RLS | SPA service + anon/publishable key |
| Mutations allowed by RLS for the signed-in member | SPA service |
| Cross-tenant admin, webhooks, Meta/WhatsApp Graph, signing tokens | Edge + service role / secret |
| Aggregations that would fan out many round-trips | Postgres RPC |

The Data API is public by design; **RLS is the product security boundary**, not hiding table names. Official: [Securing your API](https://supabase.com/docs/guides/api/securing-your-api).

## Multi-workspace tenancy (locked)

- Each commercial team is a **workspace**.  
- Membership links `auth.users` → `workspace_id` (+ role).  
- Every tenant business table includes `workspace_id`.  
- RLS: row visible/writable only if the caller is a member of that workspace.  
- App “workspace switcher” is UX; policies must still enforce membership.

Single Yuztoo sales org can run as **one** workspace; the schema stays multi-tenant so we never re-design later.

## DDD ↔ folders

| Layer | Path | Supabase? |
|-------|------|-----------|
| Domain pure | `features/<x>/domain/` | No |
| Application hooks | `features/<x>/hooks/` | No — call services |
| Services | `features/<x>/services/` | Yes — only place |
| Realtime | `features/<x>/services/*Realtime.ts` | Yes — subscribe/cleanup from hooks |
| UI | `components/` / `containers/` | No |

## Firebase bridge (product CRM)

Sales CRM (Supabase) and the product app (Firebase) are **two systems**. They connect when a commercial account must create or **update** a product account (and the reverse). Full contract: **[10-firebase-bridge.md](./10-firebase-bridge.md)**.

Short rules:

- Product app stays on Firebase; Sales CRM never queries Firebase from the browser.  
- Bridge only via Edge / Cloud Functions with server secrets.  
- Link with stable foreign keys (`yuztoo_merchant_id`, `sales_crm_lead_id`, …).  
- Named sync events keep accounts updated; no shared database.

## Official sources

- [The Supabase way to build](https://supabase.com/docs/guides/getting-started/the-supabase-way-to-build)  
- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api)  
- [Features overview](https://supabase.com/docs/guides/getting-started/features)  
- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)  
