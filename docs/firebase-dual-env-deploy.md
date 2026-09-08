# Firebase dual-environment deploy (AI agents — mandatory)

Whenever you change **any** of the following, you **must** deploy to **both** Firebase projects before considering the task done:

| Artifact | Path(s) | Deploy target |
|----------|---------|---------------|
| Cloud Functions | `functions/` (`src/`, `package.json`, compiled `lib/`) | `functions` |
| Firestore security rules | `firestore.rules` | `firestore:rules` |
| Firestore indexes | `firestore.indexes.json` | `firestore:indexes` |
| Storage security rules | `storage.rules` | `storage` |
| Hosting (AASA, assetlinks, public pages) | `public/`, hosting block in `firebase.json` | `hosting` |

**Never** deploy to only `dev` or only `prod`. Skipping one environment is a process failure.

## Projects

| Alias | Project ID | Used by |
|-------|------------|---------|
| `prod` | `yuztoo` | App Store / Play Store / `--flavor prod` |
| `dev` | `yuztoo-dev` | Local / QA / `--flavor dev` |

CLI alias file: `.firebaserc`. Prefer explicit `--project <id>` when deploying.

## Hard rules for agents

1. If you edit rules, functions, indexes, or hosting → deploy **dev then prod** (or both in sequence) in the **same session**.
2. Do **not** stop after a successful `dev` deploy.
3. Do **not** ask the human “should I also deploy prod?” when the change is backend/rules — **always do both**.
4. If one project fails (billing, Storage not initialized, 403), report the blocker **and** still finish whatever succeeded; leave a clear “remaining deploy” checklist.
5. Use `npx -y firebase-tools@latest` (do not rely on a stale global `firebase` binary).
6. Before functions deploy: build TypeScript in `functions/`.

## Pre-deploy checklist

```bash
# Auth + projects
npx -y firebase-tools@latest login:list
npx -y firebase-tools@latest projects:list

# Functions build (required if functions/ changed)
cd functions && npm ci && npm run build && cd ..
```

Confirm Storage is initialized in the console for each project if storage deploy fails:

- Prod: https://console.firebase.google.com/project/yuztoo/storage  
- Dev: https://console.firebase.google.com/project/yuztoo-dev/storage  

Cloud Functions need billing + App Engine on the project (especially fresh `yuztoo-dev`).

## Canonical deploy commands

### Full backend sync (rules + indexes + functions + storage)

```bash
# 1) DEV
npx -y firebase-tools@latest deploy \
  --project yuztoo-dev \
  --only functions,firestore:rules,firestore:indexes,storage

# 2) PROD
npx -y firebase-tools@latest deploy \
  --project yuztoo \
  --only functions,firestore:rules,firestore:indexes,storage
```

### Rules / indexes only

```bash
npx -y firebase-tools@latest deploy --project yuztoo-dev --only firestore:rules,firestore:indexes,storage
npx -y firebase-tools@latest deploy --project yuztoo --only firestore:rules,firestore:indexes,storage
```

### Functions only

```bash
cd functions && npm ci && npm run build && cd ..
npx -y firebase-tools@latest deploy --project yuztoo-dev --only functions
npx -y firebase-tools@latest deploy --project yuztoo --only functions
```

### Hosting only (when `public/` or hosting config changes)

```bash
npx -y firebase-tools@latest deploy --project yuztoo-dev --only hosting
npx -y firebase-tools@latest deploy --project yuztoo --only hosting
```

> Note: Hosting site id in `firebase.json` may be prod-oriented. If `yuztoo-dev` hosting is not configured yet, say so explicitly and do not pretend it succeeded.

## Verification (after each project)

```bash
npx -y firebase-tools@latest functions:list --project yuztoo-dev
npx -y firebase-tools@latest functions:list --project yuztoo
```

Also confirm in console:

- Rules: Firestore → Rules, Storage → Rules  
- Functions: Functions list matches both projects  
- Indexes: Firestore → Indexes  

## What “done” means

A backend/rules/functions change is **not done** until:

- [ ] `functions` built (`npm run build`) if functions changed  
- [ ] Deploy succeeded on **`yuztoo-dev`** for every touched target  
- [ ] Deploy succeeded on **`yuztoo`** for every touched target  
- [ ] Failures are documented with exact error + next human action  

## App flavors (related — do not confuse with Firebase CLI projects)

| Flavor | Android applicationId | iOS bundle | Firebase project |
|--------|----------------------|------------|------------------|
| `dev` | `com.yuztoo.app.dev` | `com.yuztoo.app.dev` | `yuztoo-dev` |
| `prod` | `com.yuztoo.app` | `com.yuztoo.app` | `yuztoo` |

Run / store builds:

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
flutter build appbundle --flavor prod -t lib/main_prod.dart
flutter build ipa --flavor prod -t lib/main_prod.dart
```

Native Firebase files:

- Android: `android/app/src/dev/google-services.json`, `android/app/src/prod/google-services.json`  
- iOS: `ios/Runner/firebase/dev/GoogleService-Info.plist`, `ios/Runner/firebase/prod/GoogleService-Info.plist`  

Changing those client config files is **not** a Cloud Functions/rules deploy — but if you change **server** rules/functions, still dual-deploy as above.
