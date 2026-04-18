# Yuztoo Holy Book — task-time guide

Use this as a **reminder checklist** when you pick up or finish a task. It matches how **this repo** is organized (not generic blog advice).

---

## 1) Domain-Driven Design (stay inside the lanes)

**Ubiquitous language**

- Name types, methods, and variables after **business words** used in the product (merchant, storefront, promotion, rappel, etc.).
- If naming fights the domain, pause: you might be in the wrong layer.

**Bounded context**

- Treat each `lib/feature/<name>/` folder as a **feature boundary**. Prefer changing **one feature** at a time; when two features must talk, use **application** orchestration or **shared core**, not “reach into” another feature’s internals.

**Layer rules (this codebase)**

| Layer | Responsibility | OK here | Not here |
|--------|----------------|----------|----------|
| **domain** | Pure model + contracts | Entities, value objects, failures, **repository interfaces** | Flutter widgets, `BuildContext`, Firebase, Riverpod |
| **application** | Orchestration | Use cases, flow controllers, providers that **wire** domain + infra | UI layout, `TextEditingController` details in use cases (keep thin) |
| **infrastructure** | IO + mapping | Firestore/HTTP, DTOs, mappers, repository **implementations** | Business rules that belong in domain/use cases |
| **presentation** | UI | Screens, widgets, theming, localization usage | Direct Firestore calls; bypassing repositories |

**Dependencies**

- **domain** → depends on almost nothing (Dart + small shared abstractions like `Failure`).
- **application** → domain (+ injected repos).
- **infrastructure** → domain contracts + SDKs.
- **presentation** → application (read models / controllers / providers), not raw infra unless an existing pattern already does (prefer not to add new exceptions).

**Before you merge**

- [ ] New behavior has a **clear owner layer** (no “god screen” with hidden rules).
- [ ] Repository **interface** in domain, **implementation** in infrastructure.
- [ ] Failures/errors are **domain- or use-case-shaped**, not raw SDK exceptions leaking to UI.

---

## 2) Flutter best practices (this project)

**State & DI**

- Prefer **Riverpod** patterns already used in the repo (`Provider`, `Notifier`, etc. — follow neighbors in the same feature).
- Keep widgets **dumb** where possible: they render and forward events; **logic** lives in application/domain.

**Structure & file size**

- Large screens: follow **`docs/flutter-presentation-part-split-guide.md`** (`part` / `part of`, `extension _FooUi on _FooState`).
- Keep **one** `part of '…';` per part file; add imports on the **library** root file.

**Navigation**

- Use **go_router** consistently with existing `application/screens.dart` patterns in features.

**Async & UI**

- Handle loading / empty / error states explicitly (no infinite spinners without messaging).
- Prefer `const` constructors where possible; avoid unnecessary rebuilds.

**Quality bar**

- [ ] `flutter analyze` clean for touched files.
- [ ] Widgets remain readable on **small phones** (overflow checked).

---

## 3) UI / UX best practices

**Product & visual source of truth**

- **`design.md`** — layout, tone, and visual references for Yuztoo.
- **System chrome** — status bar + Android navigation bar must match the screen; follow **`.cursor/rules/system-ui-overlay-styling.mdc`** (AnnotatedRegion + correct brightness).

**Interaction**

- Touch targets large enough; primary actions obvious; destructive actions confirmed.
- Respect platform **back** behavior and existing navigation stacks.

**Accessibility & copy**

- Meaningful labels for icons / critical controls where semantics matter.
- User-facing strings through **l10n** (`lib/l10n/`) when adding new visible copy.

**Checklist**

- [ ] New/changed screen: **system UI overlay** matches header/footer colors.
- [ ] Loading and error paths have **clear user feedback**.
- [ ] Spacing/typography **matches nearby screens** (reuse shared widgets / tokens).

---

## 4) Quick “start / end of task” prompts

**Start**

1. Which **feature** (`lib/feature/...`) owns this?
2. Which **layer** gets the change first?
3. Does UI need a **part split**?

**End**

1. Did I leak **infra** into **presentation**?
2. Did I add **rules** in the right layer (domain vs use case)?
3. **System bars** + **design.md** alignment OK?

---

## 5) Related docs in this repo

| Doc | Use |
|-----|-----|
| `design.md` | Visual / UX reference |
| `docs/flutter-presentation-part-split-guide.md` | Splitting large presentation files |
| `.cursor/rules/system-ui-overlay-styling.mdc` | Status & navigation bar styling |

This file is a **guideline**, not a spec: if a task genuinely needs an exception, document it in the PR / commit message and keep the exception **narrow**.
