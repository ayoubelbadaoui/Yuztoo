# 04 — Edge Functions

Server-side Deno functions for anything that must not run with the browser key: secrets, webhooks, privileged writes, third-party APIs.

## When to use Edge (Sales CRM)

| Use case | Why Edge |
|----------|----------|
| Meta / WhatsApp Graph API | Page/WA tokens never in the browser |
| Inbound webhooks (site form, Meta, WA) | Signature verify + service-role insert |
| Issue devis/contrat signing tokens | Opaque, single-use, server-generated |
| Write signature proof / seal document hash | Trust boundary |
| Admin / cross-workspace jobs | Service role |
| Sync bridge to product app (Firebase) — create/update linked accounts | Credentials stay server-side; see [10-firebase-bridge.md](./10-firebase-bridge.md) |

Routine CRUD under RLS stays in feature services with the publishable/anon client.

## Auth on Edge

- For CRM-authenticated calls: require `Authorization: Bearer <user JWT>`, verify it, then act as that user or as service role only when justified.  
- Official: [Authorization headers](https://supabase.com/docs/guides/functions/auth-headers).  
- Invalid/missing JWT → **401**.  
- Do not trust body fields like `user_id` / `workspace_id` without checking membership against the verified JWT.

## Secrets

- Store Meta tokens, WhatsApp permanent tokens, webhook secrets, service role via Supabase secrets — not in git, not in `VITE_*`.  
- CLI: [Manage Supabase secrets](https://supabase.com/docs/reference/cli/supabase-secrets).  
- Service role bypasses RLS — use the narrowest operation and still validate workspace/resource. KB: [Performing administration tasks with a secret key](https://supabase.com/kb/troubleshooting/performing-administration-tasks-on-the-server-side-with-the-servicerole-secret-BYM4Fa).

## CORS

- Whitelist Sales CRM origins (local Vite, Hostinger temp domain, future prod domain).  
- Never `Access-Control-Allow-Origin: *` together with credentials.  
- Official: [CORS for Edge Functions](https://supabase.com/docs/guides/functions/cors).

## Validation & errors

- Client validation = UX only. Edge / RPC validate types, lengths, enums, and ownership.  
- Return generic messages to the browser (`"Request failed"` / domain-safe codes).  
- Log details server-side without passwords, tokens, or full PII dumps.  
- Error reference: [Edge Function error codes](https://supabase.com/docs/guides/functions/error-codes).

## Client calling pattern (DDD)

- SPA: small helper e.g. `callEdgeFunction(name, body)` used **from services**, not components.  
- Helper attaches the user session JWT; never embeds the service role.

## Future webhook sketch (document now, build later)

1. Provider POSTs to Edge URL.  
2. Verify signature (Meta / WA / form secret).  
3. Map payload → domain insert via service role with explicit `workspace_id`.  
4. Idempotency key to avoid double inserts.  
5. Respond quickly; heavy work async if needed (watch wall-clock limits — [KB](https://supabase.com/kb/troubleshooting/edge-function-wall-clock-time-limit-reached-Nk38bW)).

## Official sources

- [Authorization headers](https://supabase.com/docs/guides/functions/auth-headers)  
- [CORS](https://supabase.com/docs/guides/functions/cors)  
- [Error codes](https://supabase.com/docs/guides/functions/error-codes)  
- [Manage secrets](https://supabase.com/docs/reference/cli/supabase-secrets)  
- [API keys](https://supabase.com/docs/guides/getting-started/api-keys)  
