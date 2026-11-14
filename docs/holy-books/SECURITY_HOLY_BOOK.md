# Security Holy Book — Yuztoo Website

**Goal: 100 % secure.** The browser is hostile. Every rule assumes a visitor can read and modify
all front-end code, every request, and every token in their browser.

Security is enforced **server-side** — Firestore security rules, Cloud Functions, Storage rules
and Hosting headers. The front end only hides what the server already forbids.

A Firebase Web API key is **not** a secret: it identifies the project, it does not authorize
anything. Everything that matters is decided by rules and functions.

---

## 1. Authentication

1. The public website is mostly anonymous. Do not add a login to it unless there is a real need;
   account actions belong in the app.
2. Where the site does authenticate (account deletion, invitation acceptance), use Firebase Auth
   only. No custom JWTs, no passwords in our collections.
3. Never store tokens in `localStorage` by hand. Read the session through the Firebase SDK.
4. Account deletion and password reset go through a Cloud Function, never through client-side
   writes. Confirmations are shown once and never logged.
5. App Check is enabled for callable functions and Firestore reads used by the site.

## 2. Authorization (the real gate)

1. **Firestore security rules deny by default.** A collection the site reads must have an explicit
   rule that allows exactly that read and nothing more. A collection without rules is a P0 bug.
2. Public reads are limited to genuinely public documents (a published `vitrine`, a public
   promotion). Never expose merchant private fields, client phone numbers, counters, or any
   personal data through a rule written for the website.
3. Test every rule with the emulator against at least: anonymous visitor, signed-in client,
   merchant owner, merchant of a different store.
4. Front-end checks (hiding a button, filtering a list) are UX only. The same rule must exist in
   Firestore rules or in the function.
5. **The Admin SDK and service-account credentials never reach the browser.** They live only in
   Cloud Functions and in secret manager.
6. Storage rules mirror Firestore rules: public assets in a public path, everything else private
   and served through signed URLs that expire.

## 3. Public / tokenized links

Routes like `/vitrine/<slug>`, `/invite/<token>`, `/supprimer-compte`:

1. Tokens are random (≥ 128 bits), single-purpose, and expire. Never use a sequential or guessable
   ID as a token.
2. A token page reads through a purpose-built callable function, not a direct collection query,
   whenever the data is not fully public.
3. The response returns only the fields the page needs — never a whole merchant or client
   document.
4. Token pages send `Cache-Control: no-store`, `X-Frame-Options: DENY`,
   `Referrer-Policy: strict-origin-when-cross-origin` and are `noindex`.
5. Rate-limit every write path an anonymous visitor can reach (lead form, invitation acceptance,
   deletion request).

## 4. Cloud Functions

1. Verify App Check and, where applicable, the caller's auth and role at the top of the function.
   Reject before doing any work.
2. Validate the body against a schema — types, lengths, enums. Reject unknown fields.
3. CORS: allowlist our origins (`https://yuztoo.com`, the dev Hosting URL, `localhost` in dev).
   Never `*` with credentials.
4. Rate-limit by IP and by identifier (5 per IP and 3 per email per hour is the baseline). Store
   IPs only as salted hashes, in a collection closed to all clients.
5. Add a honeypot field to every public form and drop submissions that fill it.
6. Return generic error messages. Log details server-side only — never return `error.message`.
7. Secrets through Firebase secrets / environment config. Never commit a `.env` with real values.
8. Destructive operations require an explicit flag; the default is dry-run.

## 5. XSS & injection

1. Never render user, merchant or form-supplied content with `dangerouslySetInnerHTML` —
   **sanitize with DOMPurify first**, or render inside a sandboxed `<iframe sandbox>`.
   Merchant-controlled text (store name, description, vitrine content) counts as user input.
2. No `eval`, no `new Function`, no string-built `setTimeout`.
3. URLs coming from data: allow `https:`, `mailto:` and `tel:` only before putting them in `href`.
   A merchant-supplied website link is untrusted.
4. Uploaded images rendered on the site: validate MIME, extension and size server-side; serve from
   our bucket, never from an arbitrary remote URL.
5. Outbound links to third parties use `rel="noopener noreferrer"`.

## 6. Data protection (PII)

1. Leads, invitations and deletion requests are personal data. Collect the minimum, keep it the
   shortest time that works.
2. Never log tokens, phone numbers, emails or full names. `console.log` of PII is forbidden in
   committed code.
3. The privacy page (`/confidentialite`) must match what the site actually collects, including
   analytics and any third-party tag. Update it in the same PR that adds a tracker.
4. Cookie / analytics consent is required before loading any non-essential third-party script.

## 7. Front-end hardening

1. Production builds: `sourcemap: false`.
2. Security headers for all routes in `firebase.json` → `headers`:
   `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`,
   `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`,
   `Permissions-Policy` (deny camera, microphone, geolocation unless a page needs it),
   `X-Frame-Options: DENY` (except pages meant to be embedded), and a
   `Content-Security-Policy` restricting `script-src` to self plus the exact third parties in use.
3. Keep the existing `Content-Type` / `Cache-Control` headers on
   `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`. Breaking them
   breaks deep links.
4. Hashed build assets get `Cache-Control: public, max-age=31536000, immutable`; HTML gets
   `no-cache`. A replaced image must use a new file name.
5. Remove or environment-gate test and debug routes in production builds.
6. Third-party scripts (pixels, chat) load only after consent, `async`/`defer`, and never on
   legal or token pages.

## 8. Dependencies

1. `npm audit --omit=dev` before each release; fix high and critical.
2. Lockfile committed. No installs from git URLs or random tarballs.
3. No surprise major upgrades in a feature PR — upgrade in its own PR.

## 9. PR checklist

- [ ] New Firestore read from the site → rule written, emulator-tested with anon + 2 roles
- [ ] New callable → App Check + validation + CORS allowlist + rate limit
- [ ] No secret, key or service account in code, logs or the client bundle
- [ ] No unsanitized `dangerouslySetInnerHTML`; merchant content sanitized
- [ ] Public token page → `noindex`, `no-store`, minimal data returned
- [ ] Any UI-level gating duplicated server-side
- [ ] Headers in `firebase.json` still cover every new route
- [ ] Rules/functions/headers deployed to **both** `yuztoo-dev` and `yuztoo`

## 10. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No security headers for website routes in `firebase.json`: no HSTS, no `nosniff`, no
  `Referrer-Policy`, no `Permissions-Policy`, no CSP. Only the deep-link files have headers today.
- No Content-Security-Policy at all. Write one after taking an inventory of third-party scripts.
- No lead-capture Cloud Function, so no origin allowlist, honeypot or rate limiting exists yet.
- No App Check on the website's reads.
- No cookie / analytics consent mechanism, while `/confidentialite` already exists in the app repo
  and will need to match whatever the site ships.
- The `vitrine.html` page currently served from the app repo renders merchant-supplied content;
  audit its sanitization before porting it here.
- `npm audit` baseline not established (no `package.json` yet).
- **Owner actions:** confirm the legal entity, data-retention periods and the DPO / contact
  address used on `/confidentialite`; decide whether analytics are used at all.
