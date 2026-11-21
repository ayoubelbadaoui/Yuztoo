# Yuztoo Sales CRM — Agent instructions

Branch: **`crm-sales-yuztoo`**

You are working on the **commercial / sales CRM**, not the Flutter Firebase product app.

## Source of truth

Before coding, read:

1. [`docs/sales-crm/CRM-HOLLY-BOOK.md`](docs/sales-crm/CRM-HOLLY-BOOK.md)
2. [`docs/sales-crm/supabase/README.md`](docs/sales-crm/supabase/README.md) — **Supabase bible** (tick [`SUPABASE-HOLLY-BOOK.md`](docs/sales-crm/supabase/SUPABASE-HOLLY-BOOK.md) before any Supabase work)
3. [`docs/sales-crm/DDD_COMPLIANCE_PROMPT.md`](docs/sales-crm/DDD_COMPLIANCE_PROMPT.md)
4. [`docs/sales-crm/SECURITY_GUIDELINES.md`](docs/sales-crm/SECURITY_GUIDELINES.md)
5. [`docs/sales-crm/PROJECT_STRUCTURE.md`](docs/sales-crm/PROJECT_STRUCTURE.md)

Full index: [`docs/sales-crm/README.md`](docs/sales-crm/README.md)

These standards are adapted from **IMIGO CRM** (DDD, security, structure, Supabase).

**Verify-before-implement:** for any Supabase topic (RLS, Auth, Edge, Realtime, Storage, keys), look up current official docs via MCP `search_docs` before coding. If the bible disagrees with the official page, update the bible and [`docs/sales-crm/supabase/CHANGELOG.md`](docs/sales-crm/supabase/CHANGELOG.md).

## Hard rules

- **No Firebase** in Sales CRM features.  
- **No direct Supabase** in components/hooks — only in `src/features/**/services/**`.  
- **RLS** on every new tenant table; multi-workspace via `workspace_id`.  
- **Service role** never in the browser.  
- Prefer small files; split hooks by concern.  
- Do not mix product Flutter code (`lib/feature/...`) into Sales CRM unless the user explicitly asks for a bridge.  
- When a Supabase project exists: run **advisors** (security + performance) before calling schema work done.

## Two CRMs

| App | Stack | Role |
|-----|--------|------|
| Yuztoo product | Firebase + Flutter | Merchants, loyalty, storefront |
| Yuztoo Sales CRM | Supabase + web (Imigo pattern) | Pipeline, B2B sales |

Connect via a **server bridge** (Supabase Edge ↔ Firebase Cloud Functions) and foreign keys so linked accounts stay updated — **not** a shared database. Contract: [`docs/sales-crm/supabase/10-firebase-bridge.md`](docs/sales-crm/supabase/10-firebase-bridge.md).
