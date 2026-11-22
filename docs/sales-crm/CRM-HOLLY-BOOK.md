# Yuztoo Sales CRM — Holly Book

**Quick reference — read before starting each feature.**  
Adapted from IMIGO CRM Holly Book.

---

## Feature creation checklist

### Domain-Driven Design

- Model core business logic in the domain / service layer  
- Define clear boundaries between features (bounded contexts)  
- Use ubiquitous language consistently (leads, deals, quotes, accounts…)  
- Isolate domain logic from infrastructure (UI never talks to DB client)  
- Keep entities independent; immutable where it fits  

**→ See:** [DDD Architecture](./architecture/DDD_ARCHITECTURE.md) · [DDD Compliance](./DDD_COMPLIANCE_PROMPT.md)

---

### Supabase (bible + egress)

- Before any Supabase work: tick [Supabase Holly Book](./supabase/SUPABASE-HOLLY-BOOK.md)  
- Verify the topic with official docs (`search_docs`) — do not rely on memory alone  
- Minimize API calls — batch when possible  
- Prefer RPCs for complex queries  
- Request only required columns (explicit `.select(...)`)  
- Paginate every growing list (default 25/page; never unbounded tables)  
- Cache reference data where appropriate  
- Filter realtime by workspace / user  
- When a project exists: run advisors before calling done  

**→ See:** [Supabase bible](./supabase/README.md) · [Egress quick list](./SUPABASE_BEST_PRACTICES.md)

---

### UI / UX

- Clear loading / empty / error states  
- Consistent design system  
- Mobile-first layouts  
- Accessible labels and contrast  

---

### Architecture & code quality

- Fix root causes, not symptoms  
- Single responsibility; small files  
- No “temporary” hacks in shared paths  
- Tests on critical paths where feasible  
- Review before merge  

**→ See:** [Coding standards](./architecture/CODING_STANDARDS.md) · [Code review](./architecture/CODE_REVIEW_CHECKLIST.md)

---

### Security

- [ ] **Auth / authorization** — UI gate + **RLS** (never UI alone)  
- [ ] **Input validation** — client = UX only; Edge / RPC validate for real  
- [ ] **Secrets** — never hardcode; service role **never** in the browser  
- [ ] **Transit** — HTTPS / WSS only in production  
- [ ] **RLS** — on every tenant table; test with multiple users  
- [ ] **Rate limiting** — public / sensitive endpoints  
- [ ] **Errors** — no stack traces or internals to the client  
- [ ] **Logging** — no passwords, tokens, or unnecessary PII  
- [ ] **CORS** — whitelist origins; no `*` with credentials  

**→ See:** [Security guidelines](./SECURITY_GUIDELINES.md)

---

## When you need more detail

| Topic | Document |
|--------|----------|
| DDD rules for this repo | [DDD Compliance](./DDD_COMPLIANCE_PROMPT.md) |
| Folder layout | [Project structure](./PROJECT_STRUCTURE.md) |
| Query / state patterns | [Coding standards](./architecture/CODING_STANDARDS.md) |
| Supabase architecture / RLS / Edge / traps | [Supabase bible](./supabase/README.md) |
| Egress quick list | [Supabase best practices](./SUPABASE_BEST_PRACTICES.md) |
| Security, RLS, secrets (app-level) | [Security guidelines](./SECURITY_GUIDELINES.md) |
| Feature → tables / Edge map | [Feature playbook](./supabase/09-feature-playbook.md) |
| Supabase CRM ↔ Firebase account sync | [Firebase bridge](./supabase/10-firebase-bridge.md) |
| Product ops UI (boutiques / clients) | [CMS App Yuztoo](./CMS-APP.md) |

### CMS App Yuztoo (product ops)

- Opened from the workspace switcher as a **second window** (`?cms=1`) — not the sales pipeline.
- Same design tokens as Sales CRM; own shell (`CmsAppShell`).
- **Still no Firebase SDK in the browser** — phase 1 uses mock services; phase 2 goes Edge → Firebase callables.
- Paginate lists (default **25**/page), same as leads.
- **Images app:** fixed slot catalog + aspect-locked crop only — never free-form uploads that break layout. Category icons (`onboarding.category.*`): **1:1 · 256×256 · max 200 Ko** (icon profile). **Never publish to all users without a selected test account + preview step.** Flutter resolves via `lib/feature/app_media` (2 Firestore docs + overwritten Storage). Subcategories deferred. CMS publish still mock until Edge → Admin CF.
- **Actu Yuztoo:** same publish gate **per news doc** (`release_status` draft → preview → live + `test_account_id`). Flutter dual-query (live + own preview). CMS live path: Edge `cms-yuztoo-news` → HTTPS `crmBridgeYuztooNews` (`CRM_BRIDGE_SECRET`). Prefer `cta_merchant_id` (in-app); `cta_url` opens the external browser. Image upload crop = Phase B (HTTPS `image_url` for now).

**→ See:** [CMS-APP.md](./CMS-APP.md)

---

**Tip:** Keep this file open while building Sales CRM features.
