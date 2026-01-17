## Prompting & Branching Checklist (for all collaborators)

Always follow `README.md` (architecture) and `prompts_instrcutions.md` (workflow) when creating prompts or coding for Flutter.

### 1) Branch setup (before prompting)
- `git checkout develop && git fetch && git pull`
- Create feature branch: `git checkout -b feat/<scope>` (e.g., `feat/signup_flow`)
- Stay on your feature branch while prompting/coding.

### 2) How to request a “perfect prompt”
- Start your request with the feature title and short description.
- Explicitly mention this file plus `README.md` and `prompts_instrcutions.md` must be respected.
- Provide acceptance criteria and any key flows/edge cases.
- Ask for outputs in the feature-first layered structure (presentation/application/domain/infrastructure) and Riverpod usage aligned with the rules.

### 3) Template to copy-paste and fill
Title: <Feature title>  
Description: <1–3 lines of scope and goal>  
Branch: feat/<scope> (from develop)  
Must follow: @README.md, @prompts_instrcutions.md  
Deliverables (ask for these):
- Architecture placement per layer (presentation/application/domain/infrastructure)
- Riverpod providers (application layer) and UI wiring (presentation)
- Domain purity (no Flutter/Firebase in domain)
- Infrastructure-only Firebase/API/IO; no Firebase types leaking upward
- Validation rules, loading/disabled states, double-submit prevention
- Error handling with user-facing copy (FR if required) and reusable snackbar/toast rules
- Navigation/routing outcomes and role-based flows if applicable
- Data shapes/DTOs and Firestore/API paths with server timestamps where needed
- Test ideas or quick QA checklist

### 4) Example (Signup Flow)
Title: Implement Signup Flow  
Description: Create email+phone signup with role selection; persist user profile; route by role.  
Acceptance (summarize in your prompt):
- Fields: email, password (toggle), phone (intl picker), city (required), role (client/merchant)
- Form validation: all required; phone formatted with country code
- Loading: disable inputs/button, show progress, prevent duplicate submit; reset on success/fail
- Auth: `createUserWithEmailAndPassword`, phone OTP verify, link via `linkWithCredential`; if phone exists → snackbar (FR) and abort
- Profile: write `/users/{uid}` with `{uid,email,phone,roles:{client,merchant,provider:false},city,created_at,updated_at}` using server timestamps
- Routing: client → Client Home; merchant → Merchant Onboarding
- Errors: French snackbars; generic fallback “Une erreur s'est produite.”; reusable snackbar (`core/shared/widgets/snackbar.dart` if none)

Optional asks:
- “generate cursor prompt” → get full Cursor-ready generation prompt (providers, async actions, Firebase calls, UI state, snackbars, errors, Firestore writes)
