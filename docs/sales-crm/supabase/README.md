# Supabase bible — Yuztoo Sales CRM

**Living reference for architecture, optimization, and security.**  
Documentation only for now: no project bootstrap until this bible is approved and a later phase starts.

Branch: **`crm-sales-yuztoo`** · Stack: Vite/React SPA + Supabase (Imigo pattern) · **No Firebase** in this app.

## How to use this bible

1. Before any Supabase work, open **[SUPABASE-HOLLY-BOOK.md](./SUPABASE-HOLLY-BOOK.md)** and tick the checklist.
2. Open the chapter for the area you are touching (auth, RLS, Edge, …).
3. **Verify against official docs** with Supabase MCP `search_docs` (or the cited URL) before implementing — Supabase changes; do not rely on memory alone.
4. If a rule in this bible disagrees with a cited official page, update this bible and log it in [CHANGELOG.md](./CHANGELOG.md).

## Chapters

| # | Document | Covers |
|---|----------|--------|
| — | [SUPABASE-HOLLY-BOOK.md](./SUPABASE-HOLLY-BOOK.md) | Mandatory pre-feature checklist |
| 01 | [01-architecture.md](./01-architecture.md) | Layers, tenancy, DDD ↔ Supabase |
| 02 | [02-auth-and-access.md](./02-auth-and-access.md) | Auth, JWT, roles, public links |
| 03 | [03-database-and-rls.md](./03-database-and-rls.md) | Schema, RLS, views, RPCs, migrations |
| 04 | [04-edge-functions.md](./04-edge-functions.md) | JWT, secrets, CORS, service role |
| 05 | [05-realtime-storage.md](./05-realtime-storage.md) | Realtime filters, storage policies |
| 06 | [06-performance.md](./06-performance.md) | Select, pagination, indexes, advisors |
| 07 | [07-security-traps.md](./07-security-traps.md) | Silent failure modes + pre-merge ticks |
| 08 | [08-environments.md](./08-environments.md) | Keys, env vars, Hostinger, rotation |
| 09 | [09-feature-playbook.md](./09-feature-playbook.md) | Feature steps + mock→Supabase map |
| 10 | [10-firebase-bridge.md](./10-firebase-bridge.md) | Supabase CRM ↔ Firebase app account sync |
| — | [CHANGELOG.md](./CHANGELOG.md) | “Verified against docs on …” |

## Locked decisions

| Decision | Choice |
|----------|--------|
| Tenancy | Multi-workspace (`workspace_id` on tenant rows; RLS enforces) |
| Client key | Publishable / anon only in the browser (`VITE_*`) |
| Privileged work | Edge Functions + service role / secret key — never in SPA |
| Data access in app | Only `src/features/**/services/**` |
| Product CRM | Firebase stays separate; account sync via Edge/CF + foreign keys ([10-firebase-bridge.md](./10-firebase-bridge.md)) |

## Related app docs

- [CRM Holly Book](../CRM-HOLLY-BOOK.md)
- [DDD compliance](../DDD_COMPLIANCE_PROMPT.md)
- [Security guidelines](../SECURITY_GUIDELINES.md)
- [Project structure](../PROJECT_STRUCTURE.md)
- [Egress quick list](../SUPABASE_BEST_PRACTICES.md) (pointer + short checklist)
