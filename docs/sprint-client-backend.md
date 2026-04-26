# Sprint Plan — Client Side Backend & Feature Completion
_Goal: 100% client-side UI + Firebase wiring (chat excluded)_

---

## Sprint 1 — Action Links on Storefront (url_launcher)

**Why first:** Core UX — phone / address / website are displayed but untappable. Zero code change risk.

### Task 1.1 — Add `url_launcher` to pubspec
- Add `url_launcher: ^6.x` to `pubspec.yaml`
- iOS: add `LSApplicationQueriesSchemes` for `tel`, `maps`, `https` to `ios/Runner/Info.plist`

### Task 1.2 — Wire phone tap in `store_profile_screen.part.dart`
- `_InfoTile` phone row: `onTap: () => launchUrl(Uri(scheme: 'tel', path: merchant.phone))`
- Wrap in `try/catch`, show snackbar on failure

### Task 1.3 — Wire address tap → Google Maps
- `_InfoTile` address row: `onTap: () => launchUrl(Uri.parse('geo:0,0?q=${Uri.encodeComponent(merchant.address)}'))`
- iOS fallback: `https://maps.apple.com/?q=...`

### Task 1.4 — Wire website link
- `merchant.websiteUrl` is already in the domain entity but NOT displayed on the store profile
- Add a website `_InfoTile` row in `_AccueilTab` when `merchant.websiteUrl != null`
- Tap: `launchUrl(Uri.parse(merchant.websiteUrl!), mode: LaunchMode.externalApplication)`

### Task 1.5 — Wire reservation / e-boutique link
- `merchant.reservationUrl` / `merchant.shopUrl` — check if these fields exist in `Merchant` entity
- If missing, add `reservationUrl` and `shopUrl` to `Merchant`, `MerchantDto`, and `StorefrontEditProfile`
- Display CTA buttons in the store profile Accueil tab if non-null

**Files:** `pubspec.yaml`, `ios/Runner/Info.plist`, `lib/feature/store_profile/presentation/store_profile_screen.part.dart`, `lib/feature/merchant/domain/entities/merchant.dart`, `lib/feature/merchant/infrastructure/dto/merchant_dto.dart`

---

## Sprint 2 — Profile Completion % (Real Calculation)

**Why second:** Trivial data-wiring, high trust impact, fixes a hardcoded lie.

### Task 2.1 — Define `profileCompletionPercent` in domain
- In `UserRepository` or a pure function, compute completion from fields:
  - `displayName` set → +20%
  - `photoUrl` set → +20%
  - `phone` set → +20%
  - `cities` non-empty → +20%
  - `email` verified → +20%
- Add `int computeProfileCompletion(UserProfileBasics profile)` utility in `lib/feature/auth/core/domain/`

### Task 2.2 — Replace hardcoded `'100%'` in `personal_information_screen.part.dart:156`
- Watch `userProfileBasicsProvider`
- Compute real percentage from the user profile fields
- Display animated progress bar (reuse the existing `LinearProgressIndicator` widget in that screen)

**Files:** `lib/feature/auth/core/domain/utils/profile_completion.dart` (new), `lib/feature/client_profile/presentation/personal_information_screen.part.dart`

---

## Sprint 3 — Multiple Cities for Clients

**Why third:** Cities drive the discovery algorithm and the client's "local" identity.

### Task 3.1 — Wire `+` chip in `personal_information_screen.part.dart`
- Currently `onTap: null` — tap should open a bottom sheet with the existing `CitySelectionModal` (from client onboarding)
- On confirm: call `userRepository.setConnectedCities(uid, updatedCities)` via a provider

### Task 3.2 — Allow city removal
- Each city chip should have an `×` button that calls `setConnectedCities` with the city removed
- At least 1 city must remain (validate)

### Task 3.3 — Re-query discovery after city update
- After `setConnectedCities` succeeds, call `ref.invalidate(discoveryMerchantsProvider)` so the grid refreshes with the new city scope

**Files:** `lib/feature/client_profile/presentation/personal_information_screen.part.dart`, `lib/feature/auth/core/domain/repositories/user_repository.dart` (already has `setConnectedCities`), `lib/feature/auth/core/infrastructure/firebase_user_repository.writes.part.dart`

---

## Sprint 4 — Client Data Privacy & Account Deletion

**Why fourth:** RGPD legal requirement. `DataPrivacyScreen` already exists — just needs a route from the client side.

### Task 4.1 — Add "Sécurité & Confidentialité" row to `ClientProfileScreen`
- Wire a row in `lib/feature/client_profile/presentation/client_profile_screen.part.dart` that calls `widget.onNavigate('client-privacy')`

### Task 4.2 — Register `ScreenId.clientDataPrivacy` in `main_shell_state.part.dart`
- Add `ScreenId.clientDataPrivacy` to the `ScreenId` enum (or reuse `ScreenId.merchantDataPrivacy` with a `role` parameter)
- In `_handleNavigate`: when `'client-privacy'` → push `DataPrivacyScreen` with the current user's uid

### Task 4.3 — Wire `deleteCurrentUserProvider` for clients
- `DataPrivacyScreen` already reads `analyticsConsent` from the merchant Firestore doc — add a `role` parameter so it reads/writes the correct document (`users/{uid}` for clients, `merchants/{merchantId}` for merchants)
- Confirm that `deleteCurrentUserProvider` (exists in Firebase auth writes) deletes `users/{uid}`, `users/{uid}/push_tokens`, `users/{uid}/followed_merchants`, and `users/{uid}/notifications`; add batch-delete if incomplete

**Files:** `lib/feature/client_profile/presentation/client_profile_screen.part.dart`, `lib/main_shell_state.part.dart`, `lib/feature/merchant_settings/presentation/data_privacy_screen.dart`, `lib/feature/auth/core/infrastructure/firebase_auth_repository.writes.part.dart`

---

## Sprint 5 — Per-Merchant Notification Mute

### Task 5.1 — Add `isMuted` field to `followed_merchants/{merchantId}` Firestore doc
- In `lib/feature/followed_merchants/infrastructure/` (or whichever repo writes follow records): add `is_muted: false` to the follow document shape
- Add `isMuted` to the `FollowedMerchant` domain entity (if it exists) or the Firestore doc mapper

### Task 5.2 — Mute toggle in notification card
- In `_NotificationCard` (`notifications_screen.part.dart`): add a long-press or swipe-to-reveal context menu with "Mettre en sourdine ce commerce"
- On tap: call a new `muteMerchantNotificationsProvider(merchantId)` use case that writes `is_muted: true` to `users/{uid}/followed_merchants/{merchantId}`

### Task 5.3 — Filter muted merchants from notification stream
- In `FirestoreClientNotificationRepository.watchForClient`, after loading the stream, filter out notifications where `merchant_id` matches a muted merchant
- Or filter in the provider layer by joining with the followed-merchants list

### Task 5.4 — Mute toggle visible on store profile header
- Add a bell icon with a strikethrough toggle in `store_profile_screen.part.dart` header
- Initial state read from `followedMerchantHeartLevelsForCurrentUserProvider` (extend the map to include `isMuted`)

**Files:** `lib/feature/followed_merchants/` (domain + infra), `lib/feature/notifications/presentation/notifications_screen.part.dart`, `lib/feature/store_profile/presentation/store_profile_screen.part.dart`

---

## Sprint 6 — VIP / Habitué / Soutien Loyalty Status Labels

### Task 6.1 — Define `ClientLoyaltyTier` enum in domain
```dart
enum ClientLoyaltyTier { nouveau, soutien, habitue, vip }
```
- Add `ClientLoyaltyTier tier` getter to `ClientLoyaltyEntry` computed from `validatedPassages`:
  - 0–2 → nouveau, 3–9 → soutien, 10–19 → habitue, 20+ → vip
  - Thresholds configurable per merchant (use `LoyaltyProgramConfig.visitsRequired`)

### Task 6.2 — Display tier badge on loyalty cards screen
- In `loyalty_cards_screen.part.dart` `_MerchantLoyaltyCard`: show colored tier pill ("Soutien", "Habitué", "VIP") next to the merchant name

### Task 6.3 — Display tier on store profile loyalty block
- In `store_profile_screen.part.dart` `_buildClientLoyaltyBlock()`: show "Votre statut : Habitué" beneath the progress bar

### Task 6.4 — Display personalized greeting on loyalty screen header
- Replace plain "Fidélité" header with "Bonjour [prénom] 👋" + tier summary count
- Read `userProfileBasicsProvider` for display name

**Files:** `lib/feature/loyalty/domain/entities/`, `lib/feature/loyalty/application/client_loyalty_providers.dart`, `lib/feature/loyalty/presentation/loyalty_cards_screen.part.dart`, `lib/feature/store_profile/presentation/store_profile_screen.part.dart`

---

## Sprint 7 — Invite a Merchant CTA (Discovery)

### Task 7.1 — Wire `_buildInviteButton()` in `discovery_screen.part.dart`
- Currently `onPressed: () {}` — replace with `Share.share(...)` using `share_plus` (already in pubspec)
- Share message: a deep-link URL + French copy ("Rejoins Yuztoo, [Nom du commerce] t'attend !")
- Deep-link format: `https://yuztoo.app/invite?ref={currentUserId}` (or a placeholder if deep link domain not configured)

**Files:** `lib/feature/discovery/presentation/discovery_screen.part.dart`

---

## Sprint 8 — Own-Merchant Vignette in Carnet (Dual Profile)

### Task 8.1 — Inject own merchant at top of feed in `clientHomeFeedProvider`
- In `lib/feature/client_home/application/providers.dart`:
  - After resolving followed merchant list, check if `authState` has merchant role
  - If yes: fetch `getMerchantById(uid)` and prepend to the merchants list
  - Mark this entry with `isOwnMerchant: true` so the card can show a "Mon commerce" badge

### Task 8.2 — Add "Mon commerce" badge to the vignette
- In `_buildBusinessCard()`: if `isOwnMerchant`, overlay a small "Mon commerce" gold chip on the card

**Files:** `lib/feature/client_home/application/providers.dart`, `lib/feature/client_home/presentation/client_home_screen.part.dart`

---

## Sprint 9 — Carnet Search + Drag-to-Reorder (Spec "À faire")

_These are marked "À faire" in the spec — lower priority but completing the spec fully._

### Task 9.1 — Auto-show search bar when > 6 merchants
- In `_buildBusinessCard()`: if `merchants.length > 6`, add a `TextField` search bar above the list
- Filter client-side by `merchant.name.toLowerCase().contains(query)`

### Task 9.2 — Persist merchant order to Firestore
- Add `order` field (int) to `users/{uid}/followed_merchants/{merchantId}` doc
- Default: insertion timestamp index

### Task 9.3 — `ReorderableListView` for the carnet
- Replace `ListView.builder` with `ReorderableListView` in `_buildBusinessCard()`
- On reorder: update `order` field in all affected `followed_merchants` docs via a batch write

**Files:** `lib/feature/client_home/presentation/client_home_screen.part.dart`, `lib/feature/followed_merchants/infrastructure/`

---

## Sprint 10 — B2C / B2B Toggle in Discovery (Dual Profile)

### Task 10.1 — Add `merchantType` field to `Merchant` entity
- `b2c` (default) vs `b2b` (prestataires)
- Add to `MerchantDto.fromFirestore` with default `'b2c'`

### Task 10.2 — Add toggle widget in `discovery_screen.part.dart`
- Show only when `isDualProfile == true`
- Toggle state: local `StateProvider<String>` with values `'b2c'` | `'b2b'`
- Pass to `discoveryMerchantsProvider` as a filter parameter

### Task 10.3 — Filter merchants by type in `discoveryMerchantsProvider`
- Extend the provider to accept a `merchantType` parameter
- Firestore query: `.where('merchant_type', isEqualTo: merchantType)`

**Files:** `lib/feature/merchant/domain/entities/merchant.dart`, `lib/feature/merchant/infrastructure/dto/merchant_dto.dart`, `lib/feature/discovery/application/providers.dart`, `lib/feature/discovery/presentation/discovery_screen.part.dart`

---

## Sprint 11 — Welcome Gift Badge on Storefront

### Task 11.1 — Add `welcomeGiftDescription` to `Merchant` entity
- Check if it already exists — if not, add `String? welcomeGiftDescription` to `Merchant`, `MerchantDto`, and the merchant settings edit screen

### Task 11.2 — Display welcome-gift card in `store_profile_screen.part.dart`
- In `_buildActionRow()` (above the "Suivre ce commerce" button):
  - If `merchant.welcomeGiftDescription != null` AND client does NOT yet follow this merchant:
    - Show a gold card: "🎁 Cadeau de bienvenu : [description]"
  - Hide after the client follows

**Files:** `lib/feature/merchant/domain/entities/merchant.dart`, `lib/feature/merchant/infrastructure/dto/merchant_dto.dart`, `lib/feature/store_profile/presentation/store_profile_screen.part.dart`

---

## Sprint 12 — Guest Tab Bar (Locked Preview)

### Task 12.1 — Build `_GuestShell` widget
- 5-tab `BottomNavigationBar` with all tabs locked
- Each tab body: blurred background + INVITÉ badge + per-tab CTA (reuse `_buildGuestLocked()` pattern from `notifications_screen.part.dart`)

### Task 12.2 — Route unauthenticated users to `_GuestShell`
- In `main_shell_state.part.dart` `_handleAuthenticatedUser()`: if no auth → show `_GuestShell` (currently shows `RoleSelectionScreen` only)
- Tapping any locked CTA → navigates to signup

### Task 12.3 — Carnet locked tab shows scanned merchant vignette
- If `_pendingVitrineMerchantId` is set (QR scan before login), show that merchant's card as a blurred preview in the Carnet tab with "Créez votre carnet pour suivre ce commerce" CTA

**Files:** `lib/main_shell_state.part.dart`, `lib/feature/notifications/presentation/notifications_screen.part.dart` (extract `_buildGuestLocked`), new `lib/feature/guest/presentation/guest_shell.dart`

---

## Sprint 13 — Help / Terms / Payment Stubs → Real Screens

_These are stubs today. Minimum viable implementations._

### Task 13.1 — Terms of Use screen
- Static `WebView` or `SingleChildScrollView` with the TOS text
- Or: `launchUrl` to `https://yuztoo.app/cgu`

### Task 13.2 — Help screen
- Static FAQ list or `launchUrl` to `https://yuztoo.app/aide`

### Task 13.3 — Payment methods screen
- Placeholder "Bientôt disponible" screen with a gold card illustration
- No payment backend needed yet (future feature)

**Files:** `lib/feature/client_profile/presentation/client_profile_screen.part.dart`

---

## Prioritised execution order

| Sprint | Effort | Impact | Depends on |
|--------|--------|--------|------------|
| S1 — url_launcher | XS | ⭐⭐⭐⭐⭐ | nothing |
| S2 — profile % | XS | ⭐⭐⭐ | nothing |
| S3 — multiple cities | S | ⭐⭐⭐⭐ | nothing |
| S4 — client privacy/delete | S | ⭐⭐⭐⭐ | nothing |
| S5 — notification mute | M | ⭐⭐⭐ | nothing |
| S6 — loyalty tiers | S | ⭐⭐⭐ | nothing |
| S7 — invite CTA | XS | ⭐⭐ | nothing |
| S8 — own-merchant carnet | S | ⭐⭐⭐ | nothing |
| S9 — carnet search/reorder | M | ⭐⭐ | S8 |
| S10 — B2C/B2B toggle | M | ⭐⭐ | nothing |
| S11 — welcome gift | S | ⭐⭐⭐ | nothing |
| S12 — guest shell | L | ⭐⭐ | S1 |
| S13 — stubs → real | XS | ⭐ | nothing |
