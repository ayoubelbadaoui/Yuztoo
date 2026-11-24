# Yuztoo production bug-fix playbook

Use this process while stabilizing the app for production from branch
`fix/ios-27`.

The installed test app may connect to the real Firebase production project
(`yuztoo`) when a bug only exists with production data. Production access does
not make destructive testing acceptable.

## Non-negotiable safety rules

1. Fix and verify **one client-reported bug at a time**.
2. Reproduce before changing code. Record the account role, device, OS, app
   version, steps, expected result, actual result, and evidence.
3. Use dedicated QA client and merchant accounts in production. Never alter a
   real customer's record without explicit approval.
4. On production, default to read-only tests. Only create or modify data owned
   by the QA accounts.
5. Do not test account deletion, bulk notifications, promotions sent to real
   users, loyalty rewards, payments, or irreversible operations against real
   users. Use synthetic QA records and obtain approval for any action that can
   affect other users.
6. Record IDs of QA data created during testing. Clean up only data confirmed
   to belong to QA; never perform broad cleanup queries.
7. Never log or copy passwords, OTPs, access tokens, private customer data, or
   full production documents into issues, commits, screenshots, or chat.
8. A client-only change does not require a Firebase deployment. Any change to
   Cloud Functions, Firestore rules/indexes, Storage rules, or Hosting must be
   deployed to **both** `yuztoo-dev` and `yuztoo` as described in
   `docs/firebase-dual-env-deploy.md`.
9. If production behavior is unexpected or data appears at risk, stop the test,
   preserve evidence, and assess impact before attempting another action.

## Bug-by-bug workflow

### 1. Intake

Create a bug record from the client's comment:

```text
Bug ID:
Client comment:
Area / feature:
Role: client | merchant | dual | guest
Device and OS:
Observed app version/build:
Expected:
Actual:
Frequency: always | intermittent | once
Risk: low | medium | high
Evidence:
```

Ask for missing information only when it materially changes reproduction or
the safe fix.

### 2. Establish the baseline

- Confirm the branch is `fix/ios-27`.
- Confirm the worktree state so unrelated local work is not overwritten.
- Confirm the installed app version and build number.
- Verify the bug on the current code before implementing a fix.
- Check Crashlytics and logs when available, while avoiding sensitive data.

Classify the bug:

- **P0:** crash, startup/login blocked, security/data corruption, or a core
  production flow unavailable.
- **P1:** important flow is broken but a workaround exists.
- **P2:** visual, copy, accessibility, or low-impact edge case.

### 3. Reproduce safely

Use the smallest data scope that reproduces the issue:

1. Try an automated test, emulator, or the `dev` Firebase project first.
2. If the issue depends on real production data, install/run the `prod` flavor
   on the physical phone.
3. Sign in with a dedicated production QA account.
4. For a write-flow bug, use QA-owned records and predict every expected write
   before tapping the action.
5. Capture concise before-state evidence and the exact reproduction steps.

Production flavor commands:

```bash
flutter run --flavor prod --release
flutter build ipa --flavor prod --release
flutter build appbundle --flavor prod --release
```

Identity checks:

- Production iOS bundle: `com.yuztoo.app`
- Production Android application ID: `com.yuztoo.app`
- Production Firebase project: `yuztoo`
- Dev bundle/application ID: `com.yuztoo.app.dev`
- Dev Firebase project: `yuztoo-dev`

Do not infer the environment from the icon alone. Confirm the flavor/build and,
when diagnosing configuration, verify `Firebase.app().options.projectId` is
`yuztoo`.

### 4. Diagnose

- Identify the owning `lib/feature/<name>/` boundary.
- Trace presentation → application → domain → infrastructure without adding
  direct Firebase calls to UI code.
- Determine whether the cause is app code, production data shape, permissions,
  rules/indexes, a Cloud Function, native configuration, or an external
  service.
- Check whether malformed or legacy production data must be handled safely by
  the app rather than manually rewritten.
- Define the smallest fix and its likely regression area.

Do not edit production data merely to hide a reproducible app defect.

### 5. Implement the smallest fix

- Keep the change inside one feature boundary where possible.
- Add a failing unit/widget/regression test first when practical.
- Preserve loading, empty, and error states.
- Follow existing Riverpod and `go_router` patterns.
- Keep user-visible copy localized.
- Check status and navigation bar styling on changed screens.
- Avoid unrelated refactors during stabilization.

Use one focused commit per bug:

```text
fix(<feature>): <short description> [BUG-ID]
```

### 6. Verify before using production

Run checks proportional to the change:

```bash
flutter analyze
flutter test
flutter test test/qa/
```

At minimum:

- The new regression test passes.
- Existing tests for the touched feature pass.
- Static analysis is clean for touched files.
- A dev build starts and the adjacent happy path still works.

For backend changes, build/test locally and deploy according to the mandatory
dual-environment guide. Verify dev first, then production. Never deploy only
one environment and call the bug complete.

### 7. Verify on the physical phone with production data

Install the production-flavor release build and run:

1. The exact original reproduction steps.
2. The expected fixed path.
3. Cancel/back/retry behavior.
4. Loading, empty, offline/weak-network, and error behavior where relevant.
5. One adjacent happy path and one adjacent failure path.
6. Cold launch and session restore if auth, startup, routing, or native code
   changed.
7. Small-screen layout and system bars if UI changed.

After a production write test:

- Confirm only the predicted QA-owned documents changed.
- Confirm no notification or side effect reached real users.
- Record created document IDs and cleanup status.

### 8. Close the bug

Use this completion record:

```text
Bug ID:
Root cause:
Files/layers changed:
Automated regression test:
Checks run and results:
Phone/device and OS:
Prod build/version:
Prod QA account role:
Production records created/changed:
Cleanup:
Before/after evidence:
Adjacent regression checks:
Commit:
Status: fixed | partial | blocked
Remaining risk:
```

A bug is done only when it is reproduced, fixed, checked automatically where
practical, verified on the physical phone, and documented.

## Release-candidate gate

After all client comments are handled:

- [ ] Every comment has a bug ID and completion record.
- [ ] No P0 or P1 bug remains open without an explicit release decision.
- [ ] `flutter analyze` passes.
- [ ] Unit, widget, QA, and relevant integration tests pass.
- [ ] Production iOS and/or Android artifacts build successfully.
- [ ] Real-device cold launch, auth, logout, deep links, notifications, image
      flow, QR, NFC, and Bluetooth are checked when affected by the release.
- [ ] Relevant P0 scenarios in
      `docs/qa/YUZTOO-500-TEST-SCENARIOS.md` pass.
- [ ] Crashlytics has no new release-blocking regression from the candidate.
- [ ] QA-created production data is accounted for and safely cleaned up.
- [ ] Backend artifacts, if changed, are deployed and verified in both Firebase
      projects.
- [ ] Version/build number and release notes identify the included bug IDs.

If a release gate fails, do not hide it. Record the exact blocker, impact,
workaround, and owner before deciding whether to ship.
