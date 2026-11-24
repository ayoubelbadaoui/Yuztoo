# Handoff — Claude session 2026-11-24 (onboarding hardening)

For Cursor / any agent picking up this branch (`fix/ios-27`). Read before touching
onboarding, signup routing, Découvrir cities, notifications or the role-selection screen.

## State
- `flutter test`: green (≈1 430 tests). `flutter analyze lib test`: no errors.
- NOT yet verified on a real device: everything below. Next step = build → TestFlight → manual onboarding pass (client + merchant, iPhone + Samsung).
- Use `--flavor dev` (Firebase `yuztoo-dev`) for manual tests that create accounts; `prod` = real users.
- `integration_test` is currently commented out in `pubspec.yaml` (release build workaround). `integration_test/onboarding_flow_test.dart` exists and needs it re-enabled; run with `flutter drive` (NOT `flutter test integration_test/...` on a phone: it uninstalls the app). iOS wireless can't attach the VM service → use USB.

## What changed and why (keep these invariants)

### Startup / routing
- `lib/core/infrastructure/firebase_providers.dart` — `signOutSessionRestoredByFreshInstall`: iOS keeps Firebase Auth in the keychain after uninstall; on a fresh install (no SharedPreferences keys + no marker) the restored session is signed out. App updates keep the session.
- `lib/feature/auth/core/application/{client,merchant}_onboarding_routing.dart` + `onboarding_completion_cache.dart`: Firestore onboarding reads are bounded (8 s ×2) and fall back to a per-uid "completed on this device" flag. A definitive Firestore answer always wins. Never route a completed merchant into the creation wizard on a network blip.
- `main_shell_state.part.dart`:
  - `_routedUid`: same-user `Authenticated` after a transient `AuthError` does not re-route (it used to recreate onboarding at « Bienvenue »).
  - `lib/core/navigation/onboarding_link_policy.dart` (pure, tested): shop links (QR/NFC/referrer) and tapped pushes are deferred during signup/onboarding and replayed by `_consumeWaitingLinksAfterOnboarding()` (client + merchant `onComplete`).
  - BLE does not start during onboarding/auth screens (iOS one-time Bluetooth prompt); started after onboarding.
  - `_signupReturnScreen`: back from signup returns to where it was opened (role selection / merchant benefits / login / guest), not always login.
  - Leaving a wizard while signed in → `confirmLeaveOnboarding` dialog + sign-out (`lib/core/shared/widgets/leave_onboarding_dialog.dart`).

### Notifications (soft ask)
- No `requestPermission` at cold start nor in `FcmTokenService.registerToken` anymore.
- `lib/feature/client_notification/application/notification_permission_prompt.dart`: explanation sheet after onboarding / on first home arrival → system prompt only on « Activer ». Max 3 offers, 7 days apart; never on iOS after a refusal.

### Client onboarding (`lib/feature/client_onboarding/`)
- City sheet (`city_selection_modal.dart`): city applied immediately, commune details after (stale results ignored).
- Draft saved per uid (`application/client_onboarding_draft.dart`) → resume at the same step after app kill; cleared on success. Android lost camera photo recovered (`retrieveLostData`).
- `_finish`: 20 s write timeout, 5 s for the cosmetic Auth displayName update; never a silent no-op.
- « Ce n'est pas votre compte ? Se déconnecter » on the welcome step. Names capped at 50 chars.
- `completeClientProfile` also updates `cities` / `cities_metadata` when a list exists (`client_onboarding_city_patch.dart`) — Découvrir reads `cities` first.

### Merchant onboarding
- `Merchant.isValid()` no longer requires phone (it is optional in the UI).
- `createMerchantAndLinkUser`: an existing live shop is merged with onboarding fields only (status/plan/loyalty/logo kept); the owner's personal `city` is only set when empty (shop city added to `cities`).
- Wizard draft per uid (`merchant_onboarding_draft.dart`), `initialStep` / `onStepChanged` on `MerchantOnboardingFlowScreen`.
- System back / iOS edge-swipe always go back (never forward on optional steps). `setCategory` clears a stale subcategory. Benefits back skips the auto-forwarding subcategory screen.
- Controllers are prefilled post-frame (`_prefillController`) — writing `.text` in `initState` threw « setState during build ».
- Field caps (name 60, address 150, email 254, website 200, description 1000); phone optional but must be complete; Apple « Hide My Email » relay is never used as public contact email.
- Timeouts on every save step; final step scrolls (large text on small phones).

### Phone input (`lib/core/utils/phone_number_formatter.dart`)
- « +33 6 12 34 56 78 » / « 0033… » pasted OR typed digit by digit now yields the national number (was « 3 36 12 34 56 »).

### Découvrir cities
- `CityAgglomerationExpander`: Territoire de Belfort (90) = whole département; elsewhere = the city's EPCI only (Héricourt, Montbéliard, Belfort never linked). No distance rule.
- `expandArea()` → `CityArea.allowsShop`: same-name commune in another département hidden only when BOTH sides have stored metadata (an API guess never hides a shop: Saint-Louis 68 vs 974).

### UI polish
- Role selection: single sliding gold pill + cross-faded content with animated height (`role_selection_header.dart`, `role_selection_screen.dart`).
- Photo likes (`news_section.part.dart`): optimistic heart kept until the server confirms (no off/on flicker when a view-reload lands first) + « pop » animation.
- Small screens / large text: overflow fixes in onboarding (min-height buttons, wrap).

### Tests infra
- `test/flutter_test_config.dart` drops the `fontsChange` system message (Google Fonts async load) — fixes "animation still running after dispose" in widget tests. Test-only.

## Known, not done
- Storefront edit (change shop city later) still overwrites the owner's personal `city`, replaces `cities_metadata` with a single entry, and `removeCity` empties all `cities` (dual-profile data loss). See `firestore_merchant_repository.writes.part.dart` ~L355–400.
- Role selection: « Se connecter » link half under the Samsung nav bar until scrolled; merchant view shows « Se connecter » twice.
- Mac env: no JDK 21 (Android Studio removed) → release lint disabled in `android/app/build.gradle.kts`. Xcode 27.2 OK.
