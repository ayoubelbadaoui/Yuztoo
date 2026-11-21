# 07 — Security traps (silent failures)

Supabase-specific mistakes that often produce **empty results or wrong access without a loud error**. Tick before merge.

Also read: [SECURITY_GUIDELINES.md](../SECURITY_GUIDELINES.md), [Product security](https://supabase.com/docs/guides/security/product-security), [Supabase Security](https://supabase.com/docs/guides/security).

---

## Pre-merge checklist

- [ ] No `user_metadata` / `raw_user_meta_data` in RLS or JWT-based authorization  
- [ ] No service role / secret key in SPA, git, or `VITE_*`  
- [ ] RLS enabled on every new exposed-schema table; policies tested with **two** users in different workspaces  
- [ ] UPDATE policies have matching SELECT (else 0 rows, no error)  
- [ ] Views: `security_invoker` or not granted to anon/authenticated  
- [ ] No callable `SECURITY DEFINER` in exposed schemas without a hard review  
- [ ] Storage upsert: INSERT + SELECT + UPDATE policies  
- [ ] Edge: JWT verified; CORS whitelist; generic client errors  
- [ ] Public link tokens are opaque + server-issued (not derived from guessable ids)  
- [ ] Logs scrub tokens, passwords, service keys, unnecessary PII  
- [ ] Advisors (security) reviewed when a project exists  

---

## Trap catalog

### 1. Authorizing from `user_metadata`

Users can edit their own metadata. Putting role / workspace there in RLS is privilege escalation.

**Fix:** membership table or server-written `app_metadata`.  
Docs: [Custom Claims & RBAC](https://supabase.com/docs/guides/api/custom-claims-and-role-based-access-control-rbac), [Users](https://supabase.com/docs/guides/auth/users).

### 2. Service role in the browser

Bypasses RLS. One leaked bundle = full database.

**Fix:** publishable/anon in SPA; service role only Edge/server.  
Docs: [API keys](https://supabase.com/docs/guides/getting-started/api-keys), [Migrating to publishable and secret API keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys).

### 3. Views bypass RLS

Default view owner rights can expose rows policies would hide.

**Fix:** `CREATE VIEW … WITH (security_invoker = true)` or revoke API roles.  
Docs: [Views](https://supabase.com/docs/guides/database/views).

### 4. UPDATE without SELECT

Postgres RLS requires the row to be visible to update. Silent no-op.

**Fix:** SELECT policy covering the same rows.  
Docs: [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

### 5. Storage upsert incomplete

INSERT alone → new files ok, replace fails.

**Fix:** INSERT + SELECT + UPDATE.  
Docs: [Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control).

### 6. Deleting a user ≠ killing JWTs

Existing access tokens may still work until expiry.

**Fix:** revoke sessions, short expiry for sensitive apps, validate session when needed.  
Docs: [Product security](https://supabase.com/docs/guides/security/product-security).

### 7. Stale JWT claims

`app_metadata` changed but token not refreshed → policies using `auth.jwt()` lag.

**Fix:** membership joins in RLS, or force refresh after role changes.

### 8. UI-only “security”

Hiding a nav item does nothing against the Data API.

**Fix:** RLS always. UI gates for UX only.  
Docs: [Securing your API](https://supabase.com/docs/guides/api/securing-your-api).

### 9. CORS `*` with credentials

Browser or misconfiguration can open Edge to unwanted origins.

**Fix:** explicit origin list.  
Docs: [Edge CORS](https://supabase.com/docs/guides/functions/cors).

### 10. Guessable public tokens

Deriving `?contrat=` from contract id allows enumeration.

**Fix:** random server tokens + expiry + single-use where required.

---

## Official sources

- [Product security](https://supabase.com/docs/guides/security/product-security)  
- [Supabase Security](https://supabase.com/docs/guides/security)  
- [Securing your API](https://supabase.com/docs/guides/api/securing-your-api)  
- [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)  
- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)  
- [Storage Access Control](https://supabase.com/docs/guides/storage/security/access-control)  
- [Observability security agents](https://supabase.com/docs/guides/observability/automate-with-agents/security)  
