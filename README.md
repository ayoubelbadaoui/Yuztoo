# Yuztoo – Architecture Guide (read this before coding)

This project uses a feature-first, layered architecture with strict boundaries:

## Layout
```
lib/
  core/
    app_bootstrap.dart
    domain/core/        # Either/Result/Failure/ValueObject (pure Dart)
    infrastructure/     # cross-cutting infra (e.g., firebase providers)
    shared/widgets/     # reusable UI components
  feature/
    <feature>/
      presentation/     # screens/widgets only (no business logic)
      application/      # controllers/notifiers/use cases, Riverpod providers
      domain/           # entities, value objects, failures, repo interfaces (pure Dart)
      infrastructure/   # DTOs, Firebase/API implementations of repositories
```

## Rules
- Domain is pure Dart: no Flutter, no Firebase, no state management.
- Application talks only to domain interfaces; no UI and no direct infra calls.
- Infrastructure is the only layer that touches Firebase/API/IO; implements domain repos.
- Presentation contains UI only; uses Riverpod providers from application.
- Reusable widgets → `core/shared/widgets/`; feature-local widgets stay under the feature’s `presentation/widgets/`.
- No feature imports another feature directly; share via `core` abstractions only.
- Prefer immutability and single responsibility; keep files small and focused.
- Use `withValues` instead of deprecated color opacity helpers; use `activeThumbColor` for switches.

## Firebase
- Initialized in `core/app_bootstrap.dart` via `firebase_providers.dart`.
- Firebase types must not leak outside infrastructure.

## State management
- Riverpod for DI/state. Providers live in `feature/<feature>/application`.
- Presentation consumes providers; application calls domain use cases.

## When adding/fixing features
1) Place UI in `feature/<feature>/presentation` (and `presentation/widgets` for local widgets).
2) Add use cases/controllers/providers in `feature/<feature>/application`.
3) Define entities/value objects/failures/repo interfaces in `feature/<feature>/domain`.
4) Implement repos/DTOs/clients in `feature/<feature>/infrastructure`, depending on `core/infrastructure` for shared providers.
5) Extract reusable UI into `core/shared/widgets` as you go.
6) Run `flutter analyze` to keep the tree clean.

Follow these rules for all future prompts and changes.
