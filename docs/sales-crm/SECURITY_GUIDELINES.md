# Security guidelines — Yuztoo Sales CRM

Adapted from **IMIGO CRM** security guidelines for Vite/React + Supabase.  
**No Firebase** in this app. Do not put service-role or Firebase Admin keys in the browser.

Supabase-specific architecture, RLS patterns, silent traps, and the mandatory pre-feature checklist live in the **[Supabase bible](./supabase/README.md)** — start with [SUPABASE-HOLLY-BOOK.md](./supabase/SUPABASE-HOLLY-BOOK.md) and [07-security-traps.md](./supabase/07-security-traps.md).

---

## 1. Authentication & authorization

- Use **Supabase Auth** for identity.  
- Enforce access in **two** places:
  - **Database:** RLS on every tenant table — never UI alone  
  - **App:** role / company gates for UX only  
- Tokens: SPA SDK defaults are fine; document any BFF/cookie deviation.  
- MFA / password policy: configure in Supabase Dashboard.

---

## 2. Data protection

- **Transit:** HTTPS + WSS in production.  
- **At rest:** rely on Supabase; field-level encryption only if product requires it.  
- **Passwords:** only via Auth — never log or store raw passwords.  
- **Bridge to Yuztoo product CRM:** Supabase (sales) and Firebase (product) stay separate DBs. When they connect, keep accounts updated via authenticated Edge/Cloud Function sync events and foreign keys only — never share DB credentials or put Admin/service-role keys in either client. See [supabase/10-firebase-bridge.md](./supabase/10-firebase-bridge.md).

---

## 3. Input validation & injection

- Client validation = UX only.  
- Edge Functions / RPCs must validate.  
- Parameterized queries only (Supabase client / SQL params).  
- Avoid `dangerouslySetInnerHTML`; sanitize if rich HTML is required.  
- Strict CSP at the host when possible.

---

## 4. API & Edge security

- Verify JWT on Edge Functions; **401** on invalid tokens.  
- Rate-limit public and sensitive endpoints.  
- CORS: whitelist origins — never `*` with credentials.  
- Generic client errors; detailed logs server-side only.

---

## 5. Secrets & configuration

- Never commit secrets.  
- `VITE_*` vars are **public** — anon key only.  
- **Service role** only on Edge / server.  
- Separate projects or branches for dev / staging / prod.  
- Rotate leaked keys immediately.

---

## 6. Database

- RLS on all sensitive tables; test with multiple identities.  
- Least privilege; no service role in the browser.  
- Cap heavy reads with RPCs / pagination.

---

## 7. Logging & monitoring

- Log auth failures (no password), permission denials, sanitized Edge failures.  
- Never log passwords, refresh tokens, service_role, full payment payloads.  
- Prefer user id + action + outcome for PII-minimized audit.

---

## 8. Dependencies

- Run `npm audit`; fix high/critical before release.  
- Lockfile installs; review major upgrades.

---

## Pre-production checklist

- [ ] No secrets in git; service role only server-side  
- [ ] HTTPS + security headers on host  
- [ ] RLS enabled and tested  
- [ ] Public Edge paths reviewed  
- [ ] `npm audit` clean enough for release  
- [ ] Client errors sanitized  
