# 06 — Performance and egress

Keep API traffic small and predictable. Full short checklist also mirrored in [SUPABASE_BEST_PRACTICES.md](../SUPABASE_BEST_PRACTICES.md).

## Query habits (every service)

| Do | Don’t |
|----|--------|
| Explicit `.select('id, name, stage')` | `.select('*')` by default |
| Paginate / `limit` lists | Unbounded table dumps |
| Count with `head: true` + minimal select | Pull all rows to count in JS |
| Batch or RPC for multi-step reads | N+1 loops of `.from()` |
| Skip `.select()` on DELETE unless returning | Always chaining select “just in case” |

## List screens (leads and every growing table)

**Never render the full catalogue in one page.** At 300 rows it already hurts; at 4 000 it freezes the tab.

Default for Sales CRM list UIs:

| Rule | Detail |
|------|--------|
| Page size | Default **25** (`LEAD_PAGE_SIZE`); allow 25 / 50 / 100 only |
| Service contract | Return `{ items, total, page, pageSize, totalPages }` — not a bare array |
| Filters / sort / search | Reset to page 1; pagination applies **after** filter |
| Counts in tabs | Separate cheap count (`getLeadCounts` / `count: 'exact', head: true`) — do not derive from the current page |
| Supabase later | `.range((page-1)*size, page*size-1)` with `count: 'exact'` on the same query |
| Cap | Hard-cap `pageSize` ≤ 100 in the service even if the UI is buggy |

Reference implementation: `features/leads` (`getLeads`, `LeadsPagination`). Inbox, quotes, contracts, WhatsApp conversation lists must follow the same pattern before they grow.

**Pickers / comboboxes:** use `searchLeads(q, limit)` (capped), not the full table page API.

**Kanban (pipeline):** do not load every lead into every column at 4 000 rows — prefer per-column limits or “load more” when that board becomes the bottleneck.

## Auth egress

- Cache session + membership in auth context.  
- Prefer `getSession()` for routine gates; reserve networky user checks for sensitive moments.  
- `refreshSession()` when claims/membership must be fresh — not on every click.

## RPC for heavy work

Dashboard KPIs, payment schedule horizons, marketing audience resolution, WhatsApp window aggregates → one SQL/RPC round-trip instead of many client queries. Define RPCs in migrations; call from services only.

## Indexes

- Always index `workspace_id` on tenant tables.  
- Index foreign keys and columns used in `WHERE`, `ORDER BY`, and RLS subqueries.  
- Avoid indexing huge text blindly (btree row-size limits). KB: [Improve query performance with indexes](https://supabase.com/kb/troubleshooting/steps-to-improve-query-performance-with-indexes-q8PoC9), [Index row size exceeds btree maximum](https://supabase.com/kb/troubleshooting/error-index-row-size-exceeds-btree-version-4-maximum-for-index-LMmoeU).

## Realtime cost

- Filtered channels only.  
- Unsubscribe on unmount.  
- Prefer targeted tables (messages for one conversation) over listening to entire `leads`.

## Storage cost

- Compress / size-limit marketing media before upload.  
- See [Storage optimizations](https://supabase.com/docs/guides/storage/production/scaling).

## Advisors gate (mandatory when a project exists)

Before calling a schema or query change “done”:

1. Run **security** advisors — fix RLS / exposed object findings.  
2. Run **performance** advisors — missing indexes, etc.  
3. Re-check after fixes.  

Official: [Advisors](https://supabase.com/docs/guides/observability/advisors). MCP: `get_advisors`. Agents: treat unresolved high findings as blockers.

## Official sources

- [Advisors](https://supabase.com/docs/guides/observability/advisors)  
- [Index performance KB](https://supabase.com/kb/troubleshooting/steps-to-improve-query-performance-with-indexes-q8PoC9)  
- [Storage optimizations](https://supabase.com/docs/guides/storage/production/scaling)  
- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api) (least data exposure)  
