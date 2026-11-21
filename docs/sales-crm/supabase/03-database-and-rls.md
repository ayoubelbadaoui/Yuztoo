# 03 — Database and RLS

Postgres is the system of record. RLS is mandatory on every tenant table exposed through the API.

## Schema conventions (Sales CRM)

- Tenant tables: `id`, `workspace_id`, timestamps, soft-delete only if product needs it.  
- Foreign keys between tenant tables stay inside the same `workspace_id`.  
- Prefer explicit columns over JSON blobs for filterable fields.  
- Indexes: `(workspace_id)`, plus columns used in list filters, FKs, and order-by.  

Tables overview: [Tables and data](https://supabase.com/docs/guides/database/tables).

## RLS — non-negotiable

1. `ALTER TABLE … ENABLE ROW LEVEL SECURITY;` on every table in `public` (or any exposed schema).  
2. Policies must encode **workspace membership**, not “authenticated = see all”.  
3. UI filters never replace policies.  

Official: [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security), [Securing your data](https://supabase.com/docs/guides/database/secure-data), [Securing your API](https://supabase.com/docs/guides/api/securing-your-api).

### Policy shape (illustrative)

```sql
-- Example pattern — adapt names when migrations exist
create policy leads_select on leads
  for select to authenticated
  using (
    workspace_id in (
      select workspace_id from workspace_members
      where user_id = auth.uid()
    )
  );
```

Write separate policies for `insert` / `update` / `delete` with the same membership check (and role checks where needed).

### Silent traps

| Trap | Effect | Fix |
|------|--------|-----|
| UPDATE without SELECT policy | 0 rows updated, no error | Add matching SELECT |
| Policy uses `user_metadata` | User can escalate | Use membership / `app_metadata` |
| RLS off “temporarily” | Full table via Data API | Never ship without RLS |
| Broad `using (true)` for authenticated | Cross-tenant leak | Scope by workspace |

Permission denials often surface as API **42501** / empty results — debug with a second test user. KB: [Database API 42501 errors](https://supabase.com/kb/troubleshooting/database-api-42501-errors).

Avoid deprecated helpers where docs say so: [Deprecated auth.role() / auth.email()](https://supabase.com/kb/troubleshooting/deprecated-rls-features-Pm77Zs).

## Views

Views **bypass RLS by default** unless created with `security_invoker` (Postgres 15+) or locked down (revoke from `anon` / `authenticated`, or keep in an unexposed schema). Official: [Views](https://supabase.com/docs/guides/database/views).

## Functions / RPC

- Prefer `SECURITY INVOKER` unless there is a documented need for definer.  
- Do **not** put `SECURITY DEFINER` helpers in exposed schemas that anon/authenticated can call freely.  
- Heavy aggregations and multi-step writes → RPC in migrations; services call `.rpc(...)`.  
- Validate arguments inside the function; never trust the client alone.

## Migrations

- Always: `supabase migration new <name>` then edit the generated file.  
- Never invent migration filenames by hand.  
- Keep RLS + indexes in the same change as the table when possible.  
- Local workflow: [CLI workflows](https://supabase.com/docs/guides/local-development/cli-workflows), [Manage migration scripts](https://supabase.com/docs/reference/cli/supabase-migration), [Declarative schemas](https://supabase.com/docs/guides/local-development/declarative-database-schemas).

## Advisors gate

After schema/RLS changes (when a project exists), run security and performance **advisors** and fix high findings before merge. Official: [Advisors](https://supabase.com/docs/guides/observability/advisors).

## Official sources

- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)  
- [Securing your data](https://supabase.com/docs/guides/database/secure-data)  
- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api)  
- [Views](https://supabase.com/docs/guides/database/views)  
- [Tables and data](https://supabase.com/docs/guides/database/tables)  
- [Advisors](https://supabase.com/docs/guides/observability/advisors)  
