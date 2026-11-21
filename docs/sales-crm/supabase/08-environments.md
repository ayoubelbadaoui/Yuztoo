# 08 — Environments, keys, and deploy

## Environments

| Env | Purpose | Notes |
|-----|---------|--------|
| Local | CLI + local Supabase (when bootstrap phase starts) | Never commit `.env` with secrets |
| Staging / preview | Shared demo / QA | Separate project or branch |
| Production | Real sales data | Strict CORS, MFA when ready |

Prefer separate Supabase projects (or official branching) for prod vs non-prod so a demo leak cannot touch production data.

Local workflow reference: [CLI workflows](https://supabase.com/docs/guides/local-development/cli-workflows).

## API keys — what may leave the server

| Key | Browser (`VITE_*`)? | Edge / server? |
|-----|---------------------|----------------|
| Publishable / anon | Yes | Yes |
| Secret / service role | **Never** | Yes (secrets store) |
| JWT secret / signing material | **Never** | Platform / rotation only |
| Meta / WhatsApp tokens | **Never** | Edge secrets |

Official: [API keys](https://supabase.com/docs/guides/getting-started/api-keys), [Migrating to publishable and secret API keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys).

SPA env example (names only — values never committed):

```bash
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=...   # or legacy anon — public by design
```

## Hostinger (current static CRM)

Today the Sales CRM is a **static** build on Hostinger temp domains. That means:

- Only publishable/anon keys can exist in the built JS.  
- Edge Functions still run on Supabase’s Edge runtime (not inside Hostinger static hosting).  
- CORS on Edge must include the Hostinger origin (e.g. `*.hostingersite.com` specifically listed, not `*`).  
- Redeploying static assets does not rotate Supabase keys — rotate in the dashboard / CLI when needed.

## Rotation / leak response

If anon, service role, or JWT material leaks:

1. Rotate immediately.  
2. Redeploy SPA if public keys changed.  
3. Update Edge secrets.  
4. Review Auth sessions and suspicious Data API usage.  

KB: [Rotating Anon, Service, and JWT Secrets](https://supabase.com/kb/troubleshooting/rotating-anon-service-and-jwt-secrets-1Jq6yd). Signing keys: [JWT Signing Keys](https://supabase.com/docs/guides/auth/signing-keys). Secrets CLI: [Manage Supabase secrets](https://supabase.com/docs/reference/cli/supabase-secrets).

## Platform access

Limit who can open the Supabase dashboard / change RLS. Official: [Platform access control](https://supabase.com/docs/guides/platform/access-control).

## Official sources

- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)  
- [Migrating to publishable and secret API keys](https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys)  
- [Rotating keys KB](https://supabase.com/kb/troubleshooting/rotating-anon-service-and-jwt-secrets-1Jq6yd)  
- [Manage secrets](https://supabase.com/docs/reference/cli/supabase-secrets)  
- [CLI workflows](https://supabase.com/docs/guides/local-development/cli-workflows)  
- [Platform access control](https://supabase.com/docs/guides/platform/access-control)  
