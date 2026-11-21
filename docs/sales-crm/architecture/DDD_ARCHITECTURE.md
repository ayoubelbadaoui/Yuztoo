# DDD architecture — Yuztoo Sales CRM

Adapted from IMIGO CRM (+ Eden layer clarity for greenfield work).

## Read first

| Document | Purpose |
|----------|---------|
| [../DDD_COMPLIANCE_PROMPT.md](../DDD_COMPLIANCE_PROMPT.md) | Mandatory AI/human checklist |
| [CODING_STANDARDS.md](./CODING_STANDARDS.md) | Query, state, async patterns |
| [../PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) | Folders |
| [../CRM-HOLLY-BOOK.md](../CRM-HOLLY-BOOK.md) | Per-feature checklist |

## Core rules

1. **Feature-based modules** under `src/features/{domain}/`  
2. **Supabase only in** `src/features/**/services/**`  
3. **Realtime** = `*Realtime.js` under that domain’s `services/`; hooks only subscribe/cleanup  
4. **Large hooks** — split by concern (form state, loaders, submit, navigation)  
5. **File size** — prefer &lt; 300 lines; split before growing monoliths  

## Optional stricter layers (Eden-style)

When a domain grows, you may split further:

```
src/features/deals/
  domain/           # pure rules, formatters (no Supabase)
  application/      # use-case hooks / orchestration
  infrastructure/   # optional if services/ is not enough
  presentation/     # pages & components
  services/         # Supabase repository implementations
```

**Domain never imports React, Supabase, or UI.**

## Dependency rule

```
Presentation → Application / hooks → Domain helpers
Services (infra) → Domain helpers
```

## Bounded contexts (starting set)

| Context | Owns |
|---------|------|
| Leads | Inbound commercial contacts |
| Accounts | Companies / B2B accounts |
| Deals | Pipeline / opportunities |
| Quotes | Commercial offers |
| Configuration | Stages, sources, products catalog |

Extend only with a clear ubiquitous language name — avoid catch-all `misc` features.
