# Prompting & Contribution Instructions

Use these steps whenever you run prompts or make changes in this project.

1) Branching
- Base off `develop`.
- Features: `feat/<scope>` (e.g., `feat/auth_social_login`).
- Bugs: `bugfix/<scope>` (e.g., `bugfix/messages_crash`).

2) Before prompting/coding
- Read and follow `README.md` architecture rules (feature-first layers, domain purity, infra-only Firebase, presentation UI-only, Riverpod providers in application, shared widgets in `core/shared/widgets`).
- Ensure you are on your feature/bugfix branch.

3) During implementation
- Keep domain pure Dart (no Flutter/Firebase).
- Application layer: state/use-cases only; depends on domain interfaces.
- Infrastructure: Firebase/API/DTOs only; implements domain repos.
- Presentation: UI only; consume Riverpod providers from application.
- Extract reusable UI into `core/shared/widgets` as you touch features.
- Run `flutter analyze` (and tests if added).

4) After changes
- `git status` to review.
- Push branch to GitHub.
- Open a Merge Request into `develop`.
- Request lead review/approval.
- Address review comments, re-run `flutter analyze`, push updates.

Notes
- Use platform version `iOS 13+` per Podfile and keep Firebase types out of domain/application.
- If new collaborators use prompts, remind them to apply the `README.md` rules first.***
