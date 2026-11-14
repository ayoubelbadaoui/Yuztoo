# DDD Holy Book — Yuztoo Website

**Goal: 100 % DDD.** Every line of code knows which domain it belongs to, and only the data layer
talks to Firebase or the network.

If a rule here conflicts with a convenience, the rule wins. If a rule blocks a real need, change
the rule in this book **and** in `eslint.config.js` in the same PR — never work around it silently.

The Flutter app uses four layers (`domain` / `application` / `infrastructure` / `presentation`,
see `docs/yuztoo-holy-book.md` on `develop`). The website keeps the same spirit with web names:
**content → services → hooks → containers → components.**

---

## 1. The one law

> **Only `src/features/<domain>/services/**` may import from `src/lib/firebase`.**

That covers everything `lib/firebase` exports: the app instance, Firestore, Auth, Storage,
Functions, App Check and every callable wrapper.

| Export | Allowed in |
|--------|-----------|
| `db` / Firestore helpers | `features/**/services/**` |
| `auth` | `features/**/services/**` |
| `callFunction` / callable wrappers | `features/**/services/**` |
| `storage` | `features/**/services/**` |
| `initializeApp` from `firebase/app` | `src/lib/firebase.ts` only |

Enforced by ESLint (`no-restricted-imports`, **error**) on all of `src/**` except
`features/**/services/**` and `src/lib/**`.

Pages, containers, components, hooks, handlers, utils, contexts, `App.tsx`, `main.tsx`
→ **never**.

The same law applies to `fetch`: no raw `fetch` to our backend outside `services/`.

---

## 2. Folder map (per domain)

```
src/features/<domain>/
  services/      data access ONLY (Firestore, callables, Storage)
    <domain>Service.ts            barrel / main entry
    <domain>ServiceRead*.ts       reads
    <domain>ServiceWrite*.ts      writes
    __tests__/
  hooks/         state + orchestration, call services
  handlers/      event handlers composed into containers
  containers/    data-aware sections, wire hooks to components
  components/    pure UI (props in, events out)
  content/       page copy, image paths, alts — no JSX
  seo/           <page>SeoData.ts, the single source for client + prerender
  utils/         pure functions (no I/O)
  constants/     enums, labels, config
```

- `src/pages/*` = thin route entries. They render a container; they never fetch directly.
- `src/components/*` = cross-domain pure UI (buttons, layout, typography).
- `src/utils/*` = cross-domain pure functions (no I/O).
- `src/lib/*` = infrastructure (Firebase client creation, HTTP helpers). No business rules.
- `src/seo/*` = shared SEO plumbing (meta renderer, JSON-LD builders), not page data.

**Content lives in `content/`, never inline in a component.** A section reads its copy, image
`src` and `alt` from a content module so that copy changes, translation and the prerenderer all
have one source.

---

## 3. Service contract (mandatory shape)

```ts
export async function getPublicVitrine(slug: string) {
  try {
    const snap = await getDoc(doc(db, 'storefronts', slug))
    if (!snap.exists()) return { data: null, error: null }
    return { data: toVitrine(snap), error: null }
  } catch (error) {
    return { data: null, error: error as Error }
  }
}
```

Rules:

1. Always return `{ data, error }`. Never throw to the caller.
2. Map raw documents to a typed domain object (`toVitrine`) before returning. Firestore shapes
   never leak into components.
3. Request only the fields the page needs. Never read a whole collection to find one document.
4. "Not found" is an expected outcome (`data: null, error: null`), not an error.
5. No React, no `window`, no DOM in a service.
6. One responsibility per file; split into `*Read*.ts` / `*Write*.ts` before hitting `max-lines`.
7. Every callable gets a named wrapper — never call `callFunction('name', …)` from a hook or a
   component.

---

## 4. Cross-domain access

- Domain A may import **domain B's service** and **domain B's types**.
- Domain A must **not** import domain B's hooks, containers, or internal `services/utils/*`.
- Shared rules used by three or more domains move to a dedicated domain, not into `src/utils`.

---

## 5. Never import app or CRM code

This branch is website-only. It must not import from the Flutter app, the CRM, or any
`lib/feature/**` Dart source. Shared values (brand colors, store slugs, app-store URLs) are
duplicated as small typed constants here, with a comment naming the source of truth.

A build-time check (`scripts/verify-no-app-code.mjs`) fails the build if the rule is broken.

---

## 6. Hooks (composition)

- Big flows are composed from small hooks: `useXFormState`, `useXLoad`, `useXSubmit`.
- The orchestrator `useX` wires sub-hooks and returns the public API — no 200-line `useEffect`.
- `react-hooks/exhaustive-deps` must stay satisfied.

---

## 7. File size limits (ESLint `max-lines`)

| Location | Max lines |
|----------|-----------|
| `features/**/services/**`, `src/lib/**` | 800 |
| `features/**/content/**`, `features/**/seo/**` | 800 |
| `src/pages/**` | 550 |
| `features/**/containers/**`, `src/components/**` | 450 |
| `features/**/handlers/**` | 400 |
| Everything else in `src` | 500 |

Over the limit → split in the same PR. Never raise the ceiling.

---

## 8. Ubiquitous language

Use the same business words the app and the CRM use, in French-facing copy and in code:

| Business term (FR) | Code term |
|---|---|
| Commerçant | `merchant` |
| Client / consommateur | `client` |
| Vitrine (page publique du commerce) | `storefront` / `vitrine` for the URL |
| Programme de fidélité / e-fidélité | `loyalty` |
| Passage (visite validée NFC/BLE) | `passage` |
| Promotion | `promotion` |
| Rappel | `reminder` |
| Prospect (formulaire du site) | `lead` |

Don't invent synonyms. If a new term is needed, add it here.

---

## 9. Allowlists

ESLint DDD allowlists stay **empty forever**. Adding a file to one is a DDD regression and must be
rejected in review.

---

## 10. PR checklist

- [ ] `npx eslint src` → zero `no-restricted-imports` errors
- [ ] No new `lib/firebase` or raw `fetch` import outside `services/`
- [ ] Every callable has a named service wrapper
- [ ] Services return `{ data, error }` with mapped, typed results
- [ ] Copy, image paths and alts live in `content/`, not inline
- [ ] No file over its `max-lines` limit (or split in this PR)
- [ ] No import from the Flutter app or the CRM

Quick audit command:

```bash
rg -n "from ['\"][^'\"]*lib/firebase['\"]" src -g '!src/features/**/services/**' -g '!src/lib/**'
# must print nothing
```

---

## 11. Known gaps (November 2026)

The website does not exist yet on this branch. Everything below is open:

- No `package.json`, no `eslint.config.js`, so none of the rules above are machine-enforced yet.
  Set up ESLint with `no-restricted-imports` and `max-lines` in the first code PR.
- No `scripts/verify-no-app-code.mjs`.
- The stack (Vite + React + TypeScript) is assumed, not decided. Confirm it in the first PR and
  update §2 and §3 if it changes.
