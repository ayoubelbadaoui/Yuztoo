# Yuztoo Sales CRM — documentation base

Branch: **`crm-sales-yuztoo`**

Base standards adapted from **IMIGO CRM** (DDD, security, structure, Supabase practices).  
This Sales CRM is **not Firebase** — product/mobile Yuztoo stays on Firebase; this app is a separate commercial CRM that can sync later via API.

## Read first

| Priority | Document |
|----------|----------|
| 1 | [CRM-HOLLY-BOOK.md](./CRM-HOLLY-BOOK.md) — checklist before every feature |
| 2 | [supabase/README.md](./supabase/README.md) — **Supabase bible** (architecture, RLS, Edge, perf, security) |
| 3 | [DDD_COMPLIANCE_PROMPT.md](./DDD_COMPLIANCE_PROMPT.md) — mandatory DDD rules |
| 4 | [SECURITY_GUIDELINES.md](./SECURITY_GUIDELINES.md) — auth, RLS, secrets |
| 5 | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) — folders & layout |
| 6 | [architecture/DDD_ARCHITECTURE.md](./architecture/DDD_ARCHITECTURE.md) |
| 7 | [architecture/CODING_STANDARDS.md](./architecture/CODING_STANDARDS.md) |
| 8 | [SUPABASE_BEST_PRACTICES.md](./SUPABASE_BEST_PRACTICES.md) — egress quick list → bible |
| 9 | [architecture/CODE_REVIEW_CHECKLIST.md](./architecture/CODE_REVIEW_CHECKLIST.md) |
| 10 | [CMS-APP.md](./CMS-APP.md) — product ops UI (boutiques / clients) inside Sales CRM |

## Agent entry

Root **[AGENTS.md](../../AGENTS.md)** — instructions for AI / contributors on this branch.

## Relationship to product CRM

| App | Stack | Owns |
|-----|--------|------|
| Yuztoo product (Flutter + admin) | Firebase | Merchants, clients, loyalty, storefront |
| **Yuztoo Sales CRM** (this branch) | Supabase (Imigo pattern) | Pipeline, commercial leads, quotes, B2B sales |
| **CMS App Yuztoo** (same SPA, `?cms=1`) | Sales CRM UI + (later) Edge → Firebase | Product ops: boutiques / clients |

They connect when a sales account must create or **update** a product account (and the reverse): server bridge + stable IDs — do not share one database.  
Contract: [supabase/10-firebase-bridge.md](./supabase/10-firebase-bridge.md). CMS screen map: [CMS-APP.md](./CMS-APP.md).
