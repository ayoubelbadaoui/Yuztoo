# QA scenario automation

Markdown packs:

- `docs/qa/YUZTOO-500-TEST-SCENARIOS.md`
- `docs/qa/YUZTOO-500-ADVERSARIAL-SCENARIOS.md`

## Phase 1 — domain unit tests (no Firebase)

```bash
flutter test test/qa/yuztoo_scenario_automation_test.dart
```

Policy matrix, expiry, triggers, quota, CRM segments.

## Phase 2 — P0 races + Firestore rules

### A) Transactional races (FakeFirestore, CI-friendly)

```bash
flutter test test/qa/p0_race_fake_firestore_test.dart
```

Covers: double confirm, BLE gate, cooldown SDK guard, cancel-then-confirm.

### B) Real `firestore.rules` (Firestore emulator)

```bash
cd test/firebase-rules
npm ci   # or npm install
npm test
```

Starts emulator on `127.0.0.1:9555`, runs 16 P0 privilege/cooldown/active_validations cases.

Requires: Java + Node.

## Quick all-Dart QA

```bash
flutter test test/qa/
```

## Phase 3 — device smoke (`integration_test`)

Needs a connected simulator/emulator/device. Prefer Flutter ≥3.41 (e.g. `/Users/Apple/development/flutter-3.47.7/bin/flutter`).

```bash
flutter test integration_test/app_smoke_test.dart
# or via driver:
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_smoke_test.dart
```

Firebase-backed E2E flows are not in this smoke yet.

## CI

GitHub Actions: `.github/workflows/qa.yml` runs `flutter test test/qa/` + Firestore rules emulator tests.

## Already in the app (no extra install)

- **Crashlytics** — `firebase_crashlytics` + `CrashGuard`
- **Analyzer / lints** — `flutter_lints`
- **Firestore rules emulator** — `test/firebase-rules` (Jest + firebase-tools)

## Cursor extensions installed for this stack

- Dart / Flutter (already present)
- Error Lens
- GitLens
- EditorConfig

Not installed (on purpose): Playwright, Patrol, Vitest.
