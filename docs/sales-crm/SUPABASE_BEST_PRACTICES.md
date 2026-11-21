# Supabase best practices — Yuztoo Sales CRM

**Full reference:** [supabase/README.md](./supabase/README.md) (architecture, auth, RLS, Edge, realtime, storage, performance, security traps, environments, feature playbook).

Before any Supabase work, tick [supabase/SUPABASE-HOLLY-BOOK.md](./supabase/SUPABASE-HOLLY-BOOK.md) and verify the topic with official docs (`search_docs`).

## Egress quick checklist

- Prefer **explicit** `.select('col1, col2, …')` — avoid `*`  
- **Pagination** on every growing list (default **25**/page, max 100) — never dump 300–4 000 rows into the DOM; service returns `{ items, total, page, … }`  

- **Realtime:** filter by workspace / owner (`filter: 'workspace_id=eq.…'`)  
- Prefer **`getSession()`** over frequent **`getUser()`** for routine auth gates  
- Heavy aggregations → **RPC / SQL** in migrations, one round-trip from the client  
- Count-only: `head: true` with a **minimal** `.select('id')`  
- Don’t append `.select()` to DELETE unless needed  
- Cleanup realtime channels on unmount  
- When a project exists: run **advisors** (security + performance) before “done”  

## Auth session

- Cache user + membership in Auth context — don’t refetch profile on every click  
- `refreshSession()` only when claims / membership must be fresh  
- Gate CRM routes on session + membership (UX); **RLS** is authority  

## Multi-tenant

- Every list query scopes by **workspace** (and owner where designed)  
- RLS must enforce the same scope — UI filters are not enough  

## Bridge to Yuztoo product (Firebase)

Full contract: [supabase/10-firebase-bridge.md](./supabase/10-firebase-bridge.md).

- Do **not** query Firebase from Sales CRM UI  
- Connect via Edge / Cloud Functions when accounts must be created or **updated** on the other side  
- Store only foreign keys (`yuztoo_merchant_id`, `sales_crm_lead_id`, …)  
- Named, idempotent sync events — one source of truth per field family  

