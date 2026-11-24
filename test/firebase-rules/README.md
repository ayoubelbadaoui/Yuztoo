# Firestore rules — P0 emulator tests

Exercises real `firestore.rules` for loyalty / active_validations (P0 race + privilege cases).

## Prerequisites

- Java (Firestore emulator)
- Node 20+

## Run

```bash
cd test/firebase-rules
npm ci   # first time
npm test
```

Uses the **repo-root** `firebase.json` emulator (`127.0.0.1:9555`) via `firebase emulators:exec`, then Jest (**16** P0 rules tests).

## Dart companion (no emulator)

Transactional races in the Flutter repo:

```bash
flutter test test/qa/p0_race_fake_firestore_test.dart
```
