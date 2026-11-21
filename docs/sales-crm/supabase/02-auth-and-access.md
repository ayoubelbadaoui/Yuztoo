# 02 — Auth and access

Identity via Supabase Auth; authorization via RLS + membership (and optional `app_metadata` claims).

## Identity

- Use **Supabase Auth** for sign-in (email/password, magic link, or SSO later).  
- SPA keeps the session with the official JS client defaults.  
- Cache user + workspace membership in app auth context — do not refetch the profile on every click.  
- Prefer session/claims for routine gates; avoid hammering `getUser()` on every navigation (egress).  

Official overview: [Users](https://supabase.com/docs/guides/auth/users), [JWT claims reference](https://supabase.com/docs/guides/auth/jwt-fields).

## Authorization: what is safe

| Source | Safe for RLS / access decisions? |
|--------|----------------------------------|
| `auth.uid()` | Yes |
| Membership / role tables | Yes |
| `app_metadata` / custom claims set **server-side** | Yes, with JWT freshness caveat |
| `user_metadata` / `raw_user_meta_data` | **No** — user-editable |

Never put roles or workspace IDs only in `user_metadata`. Prefer a `workspace_members` table, or claims written into `app_metadata` by a trusted path. Official: [Custom Claims & RBAC](https://supabase.com/docs/guides/api/custom-claims-and-role-based-access-control-rbac).

### JWT freshness

Claims in the access token are a snapshot. After changing `app_metadata` or membership, the user may need a **session refresh** before policies that read `auth.jwt()` see the new values. Prefer policies that join membership tables when freshness matters.

### Session invalidation

Deleting a user does **not** by itself invalidate already-issued access tokens. For sensitive CRM actions: short JWT expiry, sign-out/revoke sessions on disable, and for strict cases validate session against `auth.sessions`. See product security guidance: [Secure configuration of Supabase products](https://supabase.com/docs/guides/security/product-security).

## Roles (Sales CRM)

Typical roles (names can evolve): `owner`, `admin`, `seller`, `viewer`.

- Store on `workspace_members.role` (source of truth).  
- Optional mirror in `app_metadata` for coarse UX gates only.  
- RLS still checks membership for every tenant row.

## Public links (devis / contrat)

Demo today derives tokens from ids — **not production-safe**.

Production pattern:

1. Edge (or RPC with service role) creates a **random, single-use or expiring** opaque token.  
2. Token stored hashed (or high-entropy) with expiry and resource id.  
3. Public page calls an Edge/RPC that validates the token and returns only that resource.  
4. RLS or Edge must ensure no other tenant’s document leaks.

Same idea for contract signing proof: write proof from Edge after validation, not from an open client update.

## MFA

Enable MFA in the Auth dashboard when the CRM leaves internal demo. Official: [Multi-Factor Authentication](https://supabase.com/docs/guides/auth/auth-mfa).

## Official sources

- [Users](https://supabase.com/docs/guides/auth/users)  
- [JWT claims reference](https://supabase.com/docs/guides/auth/jwt-fields)  
- [Custom Claims & RBAC](https://supabase.com/docs/guides/api/custom-claims-and-role-based-access-control-rbac)  
- [Token Security and Row Level Security](https://supabase.com/docs/guides/auth/oauth-server/token-security)  
- [JWT Signing Keys](https://supabase.com/docs/guides/auth/signing-keys)  
- [Product security](https://supabase.com/docs/guides/security/product-security)  
