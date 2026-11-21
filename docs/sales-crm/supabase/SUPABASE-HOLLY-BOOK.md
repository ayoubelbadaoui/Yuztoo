# Supabase Holly Book — Yuztoo Sales CRM

**Read and tick before every feature that touches Supabase** (or that will, when mock data is replaced).  
Full chapters: [README.md](./README.md).

**Verify-before-implement:** before writing migrations, RLS, Edge, or client queries, run Supabase MCP `search_docs` for the topic. If the official page disagrees with this bible, update the bible and [CHANGELOG.md](./CHANGELOG.md).

---

## Architecture

- [ ] Data access only in `src/features/**/services/**` — no `supabase.from` / `supabase.rpc` in components or hooks  
- [ ] Tenant rows carry `workspace_id`; UI filters are not authority  
- [ ] Browser uses publishable / anon key only  
- [ ] Privileged or secret work goes through Edge (or server), not the SPA  
- [ ] No Firebase SDK in Sales CRM features  
- [ ] If the feature links or updates a product account: follow the Firebase bridge contract (foreign keys + Edge/CF sync events)  

**→** [01-architecture.md](./01-architecture.md) · [10-firebase-bridge.md](./10-firebase-bridge.md)

---

## Auth & access

- [ ] Session / membership gate for CRM routes (UX)  
- [ ] Authorization data in `app_metadata` or membership tables — **never** `user_metadata` in RLS  
- [ ] Remember JWT claims can be stale until refresh  
- [ ] Public devis/contrat links use server-issued opaque tokens  

**→** [02-auth-and-access.md](./02-auth-and-access.md)

---

## Database & RLS

- [ ] RLS enabled on every new table in an exposed schema  
- [ ] Policies for SELECT / INSERT / UPDATE / DELETE as needed  
- [ ] UPDATE policies paired with SELECT (silent 0-row trap)  
- [ ] Views use `security_invoker` (or are not exposed to anon/authenticated)  
- [ ] No `SECURITY DEFINER` functions in exposed schemas  
- [ ] Migration created with `supabase migration new <name>` — never invent filenames  

**→** [03-database-and-rls.md](./03-database-and-rls.md)

---

## Edge Functions

- [ ] JWT verified on authenticated endpoints; **401** when invalid  
- [ ] Body validated server-side (client validation = UX only)  
- [ ] CORS whitelist — never `*` with credentials  
- [ ] Service role / secret key only in Edge secrets — never `VITE_*`  
- [ ] Client errors generic; details only in server logs  

**→** [04-edge-functions.md](./04-edge-functions.md)

---

## Realtime & storage

- [ ] Realtime in `*Realtime` under services only; hooks subscribe/cleanup  
- [ ] Channel filters scoped by workspace / owner  
- [ ] Storage policies: INSERT + SELECT + UPDATE when upsert is required  
- [ ] Bucket paths scoped by workspace  

**→** [05-realtime-storage.md](./05-realtime-storage.md)

---

## Performance

- [ ] Explicit `.select('col1, col2, …')` — avoid `*`  
- [ ] Pagination on growing lists (default 25/page, max 100) — never render unbounded tables  

- [ ] Aggregations via RPC when heavy  
- [ ] Indexes for filter / join / order columns used in RLS and lists  
- [ ] When code exists: run **advisors** (security + performance) before calling done  

**→** [06-performance.md](./06-performance.md)

---

## Security traps (silent failures)

- [ ] Re-read [07-security-traps.md](./07-security-traps.md) and tick the pre-merge list  

**→** [07-security-traps.md](./07-security-traps.md) · app-level [SECURITY_GUIDELINES.md](../SECURITY_GUIDELINES.md)

---

## Environments & secrets

- [ ] No secrets in git or client bundles  
- [ ] Correct key type for the environment  
- [ ] Know rotation steps if a key leaks  

**→** [08-environments.md](./08-environments.md)

---

## Feature playbook

- [ ] Follow ordered steps in [09-feature-playbook.md](./09-feature-playbook.md)  
- [ ] Update CHANGELOG if you introduce a new reusable pattern  

---

## Official sources (always re-check)

- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api)  
- [Supabase Security](https://supabase.com/docs/guides/security)  
- [Secure configuration of Supabase products](https://supabase.com/docs/guides/security/product-security)  
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)  
- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)  
- [Advisors](https://supabase.com/docs/guides/observability/advisors)  
