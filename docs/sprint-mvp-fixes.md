# Sprint Plan — MVP Fixes (Yuztoo)
> Branch: `mvp-fixes` · Audit date: 2026-05-05  
> Every task below is derived from a code audit, not assumptions.  
> File paths, class names, field names, and exact lines are cited for every task.

---

## Audit-confirmed facts (source of truth)

| Area | Finding |
|------|---------|
| Client onboarding | Collects **one `displayName` string** only — no `firstName`, `lastName`, `dateOfBirth` |
| Merchant onboarding | Collects **commerce name** only (`fullName`) — no owner personal name, no DOB |
| Client profile editing | `PersonalInformationScreen` is **read-only** except cities; name/email not editable |
| "Créer un profil pro" | `onTap: () {}` — **empty no-op** in `personal_information_screen.part.dart:270` |
| Weekly quota | Hardcoded **5** in `merchant.dart:130` — but Firestore field `weekly_notif_sent_count` is **not** pre-seeded — real ceiling may be lower |
| Notification targeting | `SendMerchantNotification` use case loops **all** follower IDs — **segments are never applied** |
| Storefront offline trap | `storefront_screen.part.dart:204-209` — when `isPublished=false`, the **entire management UI disappears** including the toggle to re-enable |
| News deletion | `_deleteImage` removes a URL from `newsImageUrls` — **no full post/card delete** |
| Business hours | **Free-text `TextField`** with hints `'8h'`/`'18h'` — case-sensitive, typo-prone |
| City list | **84 entries** with a **duplicate** `'Saint-Denis'` — insufficient coverage |
| Loyalty tab | Position 4 of 5: `home / discovery / notifications / loyalty / profile` — **not center** |
| Unauthenticated QR/NFC | No login gate before `RecordLoyaltyPassage` — unauthenticated user crashes silently |
| Birthday CF | Cloud Function reads `date_of_birth` — **field never written** in client onboarding today |
| "Message conciergerie" | Only a merchant-side **toggle** — no client-facing button anywhere |
| First-visit bonus | `welcomeGiftDescription` is **merchant free text** — no app-enforced first-visit gate |
| Merchant carnet in client mode | `clientHomeFeedProvider` builds feed from **followed** merchants only — merchant's **own store not injected** |
| "Modifier mon profil pro" | Routes to `MerchantProfileSummaryScreen` which only links to storefront — **no inline editable profile form** |
| Image cropping | `image_cropper` **not in pubspec.yaml** — not implemented anywhere |
| Auto notifications | CF triggers exist but `date_of_birth` is never written → birthday never fires; daily cron depends on data that doesn't exist |

---

## Sprint 1 — Data model: first/last name + DOB everywhere
**Scope:** Foundation. Every other sprint depends on DOB and split names being in Firestore.  
**Risk if skipped:** Birthday CF, targeted marketing, and legal identity all break.

### S1-T1 — Add `firstName`, `lastName`, `dateOfBirth` to `UserProfileBasics` entity
- **File:** `lib/feature/auth/core/domain/entities/user_profile_basics.dart`
- **Action:** Add fields `final String? firstName`, `final String? lastName`, `final DateTime? dateOfBirth`
- **Also update:** `UserProfileBasicsDto` in `lib/feature/auth/core/infrastructure/dto/user_profile_basics_dto.dart`
  - Read `first_name`, `last_name`, `date_of_birth` (ISO 8601 string) from Firestore
  - Write back the same keys on `toDomain()` / `fromFirestore()`
- **Also update:** `getUserProfileBasics` use case and its Firestore reads in `firebase_user_repository.reads.part.dart` to map these new fields

### S1-T2 — Update `completeClientProfile` to persist split name + DOB
- **File:** `lib/feature/auth/core/infrastructure/firebase_user_repository.reads.part.dart` (method `completeClientProfile`)
- **Current:** writes `displayName`, optional `city`, optional `photoUrl`
- **Change:**
  - Accept `firstName`, `lastName`, `dateOfBirth` parameters
  - Write `first_name`, `last_name`, `date_of_birth` (ISO string) to `users/{uid}`
  - Compute `displayName = '$firstName $lastName'.trim()` and write it too (backward compat)
  - Update `CompleteClientProfile` use case signature accordingly (`lib/feature/client_onboarding/application/use_cases/` — find the file and align)

### S1-T3 — Update `ClientOnboardingScreen` to collect split name + DOB
- **Files:**
  - `lib/feature/client_onboarding/presentation/client_onboarding_screen.dart`
  - `lib/feature/client_onboarding/presentation/client_onboarding_screen.part.dart`
- **Current `_buildNameStep`:** one `_nameController` TextField with hint "Prénom Nom"
- **Change:**
  - Split into `_firstNameController` and `_lastNameController` (two TextFields side-by-side or stacked, same step)
  - Add a DOB step (`_buildDobStep`) after name step — use `showDatePicker` with `initialDate: DateTime(2000)`, `firstDate: DateTime(1920)`, `lastDate: DateTime.now().subtract(const Duration(days: 365 * 13))` (13+ years old)
  - Display selected date as `dd/MM/yyyy` in a read-only field that opens the picker on tap
  - Make DOB **required** (Next button disabled until selected)
- **Flow total:** Welcome → First name + Last name → DOB → City → Photo → Done (6 steps)

### S1-T4 — Add `ownerFirstName`, `ownerLastName`, `ownerDateOfBirth` to `MerchantOnboardingData`
- **File:** `lib/feature/merchant_onboarding/application/onboarding_flow_provider.dart`
- **Current fields:** `fullName` (commerce), `city`, `imagePath`, etc.
- **Add:** `ownerFirstName`, `ownerLastName`, `ownerDateOfBirth` (typed `DateTime?`)
- **Add setters:** `setOwnerFirstName`, `setOwnerLastName`, `setOwnerDateOfBirth` in `OnboardingFlowNotifier`
- **Persist:** When persisting merchant data to Firestore (in `CreateMerchant` use case or wherever `MerchantOnboardingData` is written), also write `owner_first_name`, `owner_last_name`, `owner_date_of_birth` to the merchant doc under `users/{uid}` (these are personal identity fields, not business fields)

### S1-T5 — Add `_StepOwnerInfo` step to `MerchantOnboardingFlowScreen`
- **File:** `lib/feature/merchant_onboarding/presentation/onboarding_flow_screen.part.dart`
- **Add new step widget `_StepOwnerMerchantInfo`:**
  - `_firstNameController`, `_lastNameController` TextFields (same style as `_TextField`)
  - DOB picker (same `showDatePicker` approach as S1-T3)
  - Title: "Votre identité" — subtitle: "Requis pour votre compte commerçant"
- **File:** `lib/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart`
  - Insert `_StepOwnerMerchantInfo` as step index 1 (after Welcome, before business Name)
  - Update `_totalSteps` from `8` to `9`
  - Wire `onChanged` to `setOwnerFirstName`, `setOwnerLastName`, `setOwnerDateOfBirth`
- **`_isOptionalStep()` update:** keep existing optional indices, shift by 1 for all after index 0

### S1-T6 — Verify Firestore security rules allow writing new fields
- **File:** `firestore.rules` (or `firebase/firestore.rules`)
- Confirm `users/{uid}` write rules permit `first_name`, `last_name`, `date_of_birth`, `owner_first_name`, `owner_last_name`, `owner_date_of_birth`
- No `fieldPath` allowlist that would block new fields

---

## Sprint 2 — Client profile fully editable
**Scope:** Make the personal information screen write-enabled and wire the "Créer un profil pro" button.

### S2-T1 — Rewrite `PersonalInformationScreen` as editable form
- **Files:**
  - `lib/feature/profile/presentation/personal_information_screen.dart`
  - `lib/feature/profile/presentation/personal_information_screen.part.dart`
- **Current state:** Reads `authUser.displayName` / email / phone and displays them; no edit path
- **Changes:**
  - Add edit mode toggle (pencil icon in header or inline edit buttons per row)
  - In edit mode, show `TextField`s for `firstName`, `lastName` pre-filled from `UserProfileBasics.firstName/lastName`
  - DOB field — read-only display of stored DOB; tappable to open date picker
  - On save → call `updateUserProfile(displayName: '$firstName $lastName')` + write `first_name`, `last_name`, `date_of_birth` to Firestore via a new `updateClientProfile` use case
  - Phone number edit → show a warning that it requires OTP re-verification (disable for MVP)
  - Email → read-only in MVP (Firebase Auth email change requires verification)
- **New use case:** `lib/feature/profile/application/use_cases/update_client_profile.dart`
  - Writes `first_name`, `last_name`, `date_of_birth` to `users/{uid}` via `updateDoc` (merge)
  - Calls `FirebaseAuth.currentUser.updateDisplayName('$firstName $lastName')`

### S2-T2 — Wire "Créer un profil pro" button from client profile
- **File:** `lib/feature/profile/presentation/personal_information_screen.part.dart`
- **Line 270:** `onTap: () {}` → replace with the actual navigation
- **Fix:** The button must call `widget.onCreateProAccount()` (add this callback to `PersonalInformationScreen`)
- **File:** `lib/feature/profile/presentation/client_profile_screen.dart`
  - Ensure `PersonalInformationScreen` is constructed with `onCreateProAccount: () => widget.onCreateProAccount()`
- **File:** `lib/feature/profile/presentation/client_profile_screen.dart` — verify `onCreateProAccount` propagates up to shell
- **File:** `lib/main_shell_state.part.dart` line ~1492 — `_switchToMerchant()` is already implemented for `AccountPreferencesScreen`; map the same handler into the client profile path
  - Find where `ScreenId.clientProfile` is built → thread `onCreateProAccount: () => unawaited(_switchToMerchant())` down

### S2-T3 — Show `firstName`/`lastName`/DOB in `ProfileAvatarSection`
- **File:** `lib/feature/account_preferences/presentation/widgets/profile_avatar_section.part.dart`
- **Current:** Shows `displayName` as a single string
- **Change:** Read `profileBasics.firstName` + `profileBasics.lastName` when available; fall back to `displayName` if not split yet

### S2-T4 — `updateClientProfileProvider` Riverpod provider
- **File:** `lib/feature/profile/application/providers.dart` (or create new file `update_client_profile_provider.dart`)
- Expose `updateClientProfileProvider` as `Provider<UpdateClientProfile>`
- Used by S2-T1 save action

---

## Sprint 3 — Loyalty tab center + NFC/QR unauthenticated gate + VIP independence
**Scope:** Tab reorder, login guard before passage, and loyalty tier logic verification.

### S3-T1 — Move Loyalty tab to center position (index 2 of 5)
- **File:** `lib/core/shared/widgets/bottom_nav.dart`
- **Current order (lines 30–42):** `home / discovery / notifications / loyalty / profile`
- **New order:** `home / discovery / loyalty / notifications / profile`
- **File:** `lib/main_shell_state.part.dart` lines 788–795 — the tab→`ScreenId` map is keyed by string id, so reordering in `YBottomNav` alone is sufficient (no index arithmetic in the map)
- **Verify:** `_handleTabChange` and badge count wiring are string-based — no index change needed there

### S3-T2 — Login gate before loyalty passage recording
- **File:** `lib/feature/store_profile/presentation/store_profile_screen.dart` (or `.part.dart`)
- **Current flow:** `_RecordLoyaltyPassageSheet` is shown when a user taps the passage CTA — it reads `clientUid` from `ref.watch(auth_providers.authStateProvider)` (find exact line)
- **Problem:** If the user is unauthenticated (`Unauthenticated` state), `clientUid` may be `null`, causing a silent crash or no-op
- **Fix:**
  - In `store_profile_screen.part.dart`, before opening `_RecordLoyaltyPassageSheet`, check `authState is Authenticated`
  - If **not authenticated:** show a bottom sheet `_LoginPromptSheet` with message "Connectez-vous pour enregistrer votre passage de fidélité" + two CTAs: "Se connecter" (→ navigate to login) and "Créer un compte" (→ navigate to signup)
  - After the user completes login/signup and returns, the `authStateProvider` update will rebuild the parent; open the passage sheet automatically via a `ref.listen` on auth state (`_pendingPassageAfterLogin` flag in the screen state)

### S3-T3 — Same NFC gate for unauthenticated flow
- **File:** `lib/feature/qr_scanner/presentation/qr_scanner_screen.dart`
- **Current:** `widget.onVitrineMerchantFound(merchantId)` fires regardless of auth state
- **Fix:** In the QR/NFC scanner result handler, check auth. If unauthenticated, show a modal "Connectez-vous pour profiter des avantages fidélité" with login/signup CTAs. The `merchantId` must be stored in a local variable so the scan result is not lost while the user authenticates.

### S3-T4 — Confirm `ClientLoyaltyTier` is independent of heart count
- **File:** `lib/feature/loyalty/domain/entities/client_merchant_loyalty_progress.dart`
- **Verify:** `ClientLoyaltyTier` is computed from `validatedPassages` count only — no reference to heart/coeur field
- **File:** `lib/feature/loyalty/application/client_loyalty_providers.dart` — verify `ClientLoyaltyEntry` uses only passage-based tier
- **File:** `functions/src/index.ts` — `computeSegment` uses `validated_passages` + `spend` + `last_visit` — no reference to `hearts`
- **Action:** If any code path mixes hearts into tier calculation, remove it. Document the separation with a comment.

### S3-T5 — E-fidélité wizard: remove auto-advance on option select
- **Files:**
  - `lib/feature/e_fidelite/presentation/` — read all wizard step files
  - Find any `setState(() => _currentStep++)` or `widget.onNext()` that fires **inside** an option tap callback rather than a "Continuer" button press
- **Fix:** Any option selection must only update state (`setState(() => _selected = value)`) — the "Continuer" / "Suivant" button must remain the **only** way to advance

### S3-T6 — Loyalty history preservation (defensive Firestore rules + code)
- **File:** `lib/feature/e_fidelite/` — find the deactivate/delete path for a loyalty program
- **Ensure:** Deactivating a program (`programEnabled = false`) never deletes `merchants/{merchantId}/loyalty_clients/{clientId}` documents
- **Ensure:** `RecordLoyaltyPassage` checks `loyaltyProgram.programEnabled` before writing — if disabled, it should reject gracefully (return a `Left(LoyaltyDisabledFailure())`) without touching existing records
- **Firestore rule:** Add a rule that prevents delete of `loyalty_clients` subcollection documents from the client side — only merchant-owned cloud function or server admin can purge

---

## Sprint 4 — Notification system: quota, targeting, birthday, auto
**Scope:** All six notification bugs. Some require Cloud Function changes.

### S4-T1 — Fix weekly quota ceiling (audit actual vs expected)
- **Files:**
  - `lib/feature/merchant/domain/entities/merchant.dart:129-144` — literal `5` and `7` days
  - `lib/feature/rappels/infrastructure/firestore_sent_notification_repository.dart:76-99` — `weekly_notif_sent_count` + `weekly_notif_reset_at`
- **Steps:**
  1. Read the Firestore `merchants/{merchantId}` doc live for a test merchant — confirm `weekly_notif_sent_count` value and `weekly_notif_reset_at`
  2. If `weekly_notif_reset_at` is never seeded (first time), the comparison `now.isBefore(resetAt)` may be `false` forever → count never resets
  3. **Fix in `incrementWeeklyNotifCount`:** If `weekly_notif_reset_at` is `null` or missing, treat as if the window has already passed → reset count to 0 before incrementing
  4. **UI fix:** `quick_send_section.part.dart:161-162` — ensure `quotaLabel` displays `"${used}/5 notifications cette semaine"` not just the count
  5. Raise limit to **7** per week (or make it configurable in `merchant.dart`) — confirm with product

### S4-T2 — Implement audience/segment filtering in `SendMerchantNotification`
- **File:** `lib/feature/client_notification/application/use_cases/notify_followers_of_promotion.dart` (similar issue) AND `lib/feature/rappels/application/use_cases/send_merchant_notification.dart`
- **Current:** Iterates **all** `followerIds` unconditionally (lines 43–59)
- **Fix:**
  - Accept `audience: String` and `targetSegments: List<String>` parameters (these already exist on `SentNotification` entity / quick-send UI)
  - If `audience == "Tous mes clients"` → send to all (current behavior)
  - If `audience == "Certains clients"` → for each `followerId`, fetch the `MerchantClientRow` for that client from Firestore `merchants/{merchantId}/loyalty_clients/{clientId}`, compute segment using the same logic as `computeSegment` in the Cloud Function (replicate in Dart), and skip non-matching clients
  - **New helper:** `lib/feature/loyalty/application/segment_calculator.dart` — `ClientSegment computeClientSegment(ClientMerchantLoyaltyProgress progress)` with same thresholds as `index.ts:computeSegment`
- **Add `inactif` segment:** `inactif` is defined in `merchant_client_row.dart:45-58` as 60+ days idle but **missing** from `index.ts:computeSegment` — add it to both the Dart helper and the Cloud Function

### S4-T3 — Apply segment filtering to Cloud Function `computeSegment`
- **File:** `functions/src/index.ts:44-64`
- **Current `computeSegment` returns:** `vip`, `habitue`, `nouveau`, `abonne` only
- **Add `inactif`:** if `daysSinceLastVisit > 60` → return `'inactif'`
- **Also fix `dailyScheduledTriggers` birthday/anniversary/inactive branches** (lines 365–491):
  - These call `fireAutoNotification` directly — they bypass the `target_segments` check in `dispatchTrigger`
  - **Fix:** Before calling `fireAutoNotification`, check if the auto-notification's `audience === "Certains clients"` — if so, compute the segment for the client and skip if not in `target_segments`

### S4-T4 — Ensure birthday notification reaches only matching clients (data + CF)
- **Dependency:** S1-T3 must be deployed first (DOB collected in onboarding)
- **CF `dailyScheduledTriggers` at `functions/src/index.ts:358-423`:** already queries `date_of_birth` field — **no CF change needed here** once data flows
- **Flutter-side:** Ensure `completeClientProfile` (S1-T2) writes `date_of_birth` as `YYYY-MM-DD` string (same format the CF reads)
- **Test:** Create a test user with today's birthday in Firestore → verify daily cron fires a push next run

### S4-T5 — Fix duplicate notification on promotion create
- **Issue:** Promoting a post triggers **both** `NotifyFollowersOfPromotion` (Flutter) **and** `onPromotionCreated` (CF) for merchants with `"Chaque promotion créé"` auto-rule active → client receives **two** notifications
- **File:** `lib/feature/promotions/presentation/promotions_management_screen.dart:99-110` and `:185-197`
- **Fix:** Remove the Flutter-side `NotifyFollowersOfPromotion` call when a promotion is created — rely **exclusively** on the CF `onPromotionCreated` trigger
- **Implication:** The CF trigger fires for every `promotions/{id}` creation/update with `is_active=true` — this is the canonical path

### S4-T6 — Fix "icon 2 commerçants = rappels, not sent notifications" label
- **File:** `lib/core/shared/widgets/bottom_nav.dart` — merchant tabs
- **Current:** The notifications tab for merchants navigates to `RappelsScreen` — this is correct product behavior (rappels = CRM reminders + quick send)
- **Fix:** Only a label/icon clarification is needed:
  - Change the merchant nav tab icon from `notifications_none_rounded` to something more CRM-like: `campaign_rounded` or `send_rounded`
  - Change the label from `l10n.navAlerts` to `l10n.navStorefront` or create a new l10n key `navCrm` = "Rappels" / "CRM"
  - Update both `app_en.arb` and `app_fr.arb`

### S4-T7 — Verify push notification delivery outside app (APNs + FCM debug)
- **Files to verify:**
  1. `ios/Runner/Runner.Release.entitlements` — `aps-environment` must be `production` ✅ (already correct)
  2. `ios/Runner/AppDelegate.swift` — `setForegroundNotificationPresentationOptions` must be set ✅ (done in previous sprint)
  3. `functions/src/index.ts:onNotificationCreated` (lines 187–267) — verify `admin.messaging().send(message)` is called correctly and `fcm_token` field is read from `users/{clientId}/push_tokens/device`
  4. `lib/feature/client_notification/infrastructure/fcm_token_service.dart` — `_persistToken` writes to `users/{uid}/push_tokens/device` with field `fcm_token`
  5. **Action:** Add a Cloud Function log statement before `admin.messaging().send()` and verify in Firebase console that the function is invoked — if `fcm_token` is empty or stale, the message silently fails
  6. **Android:** Check `AndroidManifest.xml` for `<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id">` — if missing, Android 8+ drops notifications silently

---

## Sprint 5 — Storefront: visibility trap + news deletion + image cropping
**Scope:** Three independent storefront bugs, all in presentation layer.

### S5-T1 — Fix storefront visibility trap (merchant can edit when offline)
- **File:** `lib/feature/storefront/presentation/storefront_screen.part.dart:204-209`
- **Current code:**
  ```dart
  if (!storefront.isPublished) {
    return const _StorefrontStateMessage(
      icon: Icons.visibility_off_outlined,
      title: 'Commerce indisponible.',
    );
  }
  ```
  This early return hides **all** management UI including the "en ligne" toggle.
- **Fix:** Replace with a non-destructive banner. Instead of early return:
  - Remove the early return entirely
  - Add an `if (!storefront.isPublished)` **amber warning banner** at the **top** of the scrollable body: "Votre commerce est hors ligne — invisible des clients. [Mettre en ligne]"
  - The "Mettre en ligne" button in the banner calls `_setMerchantPublished(storefront, true)`
  - The full management UI (tabs, edit, hours, etc.) remains rendered below the banner
- **Also fix:** The existing "Commerce en ligne" switch (line 351-364) must remain visible in both states

### S5-T2 — Add full news/actualité post deletion
- **File:** `lib/feature/storefront/presentation/widgets/news_section.part.dart`
- **Current:** `_deleteImage` only removes a photo URL from `newsImageUrls` — no full "post" delete
- **Context:** A "post" (actualité) in the current model is a combination of:
  - A URL in `newsImageUrls` (list on the merchant Firestore doc)
  - Optional associated text (check if `newsDescriptions` parallel array exists — if not, images are standalone)
- **Fix:**
  - Find news rendering in `news_section.dart` / `news_section.part.dart` — read the current post list structure
  - Add a long-press or "..." menu on each post card in the **merchant**-side view (not client-side) with a "Supprimer" option
  - Call `_deleteImage(merchantId, url, currentUrls)` which already handles Firestore update + Storage delete
  - Show a `ConfirmDeleteDialog` before deletion ("Supprimer cette actualité ? Cette action est définitive.")
  - On merchant side in `storefront_edit_profile_screen.part.dart` — the gallery row must also show per-image delete affordance (check if this already exists via `_deleteImage` — it does, but verify it's visible in the UI)

### S5-T3 — Add image crop after picking (logo, banner, profile photo)
- **Step 1 — `pubspec.yaml`:** Add `image_cropper: ^6.0.0` (or latest stable) to `dependencies`
- **Step 2 — Android:** In `android/app/src/main/AndroidManifest.xml`, add `UCropActivity` declaration (required by `image_cropper`):
  ```xml
  <activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
  ```
- **Step 3 — iOS:** No extra config needed for `image_cropper` v6+
- **Step 4 — Create `_cropImage` helper** in a shared file `lib/core/utils/image_crop_utils.dart`:
  ```dart
  Future<String?> cropImage(String sourcePath, {CropAspectRatio? ratio}) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: ratio,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Recadrer', toolbarColor: Color(0xFF0E2A44), ...),
        IOSUiSettings(title: 'Recadrer'),
      ],
    );
    return cropped?.path;
  }
  ```
- **Step 5 — Integrate in all image pickers:**
  - `lib/feature/merchant_onboarding/presentation/onboarding_flow_screen.part.dart` — `_StepImage._pickLogoFromGallery` and `_pickBannerFromGallery` — after `ImagePicker.pickImage`, call `cropImage(path, ratio: CropAspectRatio(ratioX: 1, ratioY: 1))` for logo and `CropAspectRatio(ratioX: 16, ratioY: 9)` for banner
  - `lib/feature/storefront/presentation/storefront_edit_profile_screen.part.dart` — all `_pickImage` / gallery pick methods — add crop step
  - `lib/feature/client_onboarding/presentation/client_onboarding_screen.part.dart` — profile photo step — add `1:1` crop

---

## Sprint 6 — Business hours: predefined time picker
**Scope:** Replace free-text hour fields with a proper time picker or predefined drop-down.

### S6-T1 — Create `TimeSlotPicker` widget
- **New file:** `lib/core/shared/widgets/time_slot_picker.dart`
- **Design:** A row showing `[Start ▾]` → `[End ▾]` buttons that open a bottom sheet with a grid of predefined times
- **Predefined times:** Every 30 min from `6h00` to `23h30` (36 options): `['6h', '6h30', '7h', '7h30', '8h', '8h30', '9h', '9h30', '10h', '10h30', '11h', '11h30', '12h', '12h30', '13h', '13h30', '14h', '14h30', '15h', '15h30', '16h', '16h30', '17h', '17h30', '18h', '18h30', '19h', '19h30', '20h', '20h30', '21h', '21h30', '22h', '22h30', '23h', '23h30']`
- **Stored value:** Same string format as today (`'8h'`, `'18h30'`) so Firestore data is backward-compatible — no migration needed
- **Interface:** `TimeSlotPicker({ required String startTime, required String endTime, required ValueChanged<String> onStartChanged, required ValueChanged<String> onEndChanged })`

### S6-T2 — Replace free-text fields in onboarding `_OnboardingDayRow`
- **File:** `lib/feature/merchant_onboarding/presentation/onboarding_flow_screen.part.dart`
- Replace `_buildEditor()` inline time `TextField`s with `TimeSlotPicker` widget (S6-T1)
- Remove all `_startCtrls` / `_endCtrls` `TextEditingController` infrastructure from `_OnboardingDayRowState`
- Default slot when enabling: `TimeSlot(start: '8h', end: '12h')` + `TimeSlot(start: '14h', end: '18h')` (unchanged)

### S6-T3 — Replace free-text fields in storefront `day_row`
- **Files:**
  - `lib/feature/storefront/presentation/widgets/day_row.dart`
  - `lib/feature/storefront/presentation/widgets/day_row.part.dart`
- Same replacement: swap text field for `TimeSlotPicker`
- Existing stored string format is preserved — no Firestore migration

---

## Sprint 7 — Merchant: profil pro edit, carnet client mode, first bonus, contact, concierge removal
**Scope:** Merchant-specific functional bugs.

### S7-T1 — "Modifier mon profil pro" → dedicated editable form
- **Current path:** `MerchantProfileSummaryScreen` → "Modifier ma vitrine" → `StorefrontScreen`
- **Problem:** There is no screen to edit the **merchant owner's personal identity** (name, DOB, email) separately from the storefront (business identity)
- **Fix:**
  - In `lib/feature/merchant_settings/presentation/widgets/settings_preferences_section.dart`, the nav item **"Mon profil pro"** routes to `'pro-profile'` which maps to `MerchantProfileSummaryScreen`
  - Keep the summary screen but add a visible CTA "Modifier mes informations personnelles" on it
  - This CTA routes to a new `MerchantIdentityEditScreen` that edits: display name, email (read-only with change request CTA), `ownerFirstName`, `ownerLastName`, `ownerDateOfBirth`, professional email (new `owner_email` field)
  - **New file:** `lib/feature/merchant_settings/presentation/merchant_identity_edit_screen.dart`
  - Backed by `updateMerchantOwnerProfile` use case (writes to `users/{uid}` same fields as S1-T4)

### S7-T2 — Yuztoo carnet works for merchant using app in client mode
- **File:** `lib/feature/client_home/application/providers.dart` — `clientHomeFeedProvider`
- **Current:** builds carnet from `followedMerchantIdsForCurrentUserProvider` only — if a merchant user switches to client mode, their **own** merchant doesn't appear unless they followed themselves (which is impossible)
- **Fix:**
  - After building the followed merchant list, check if the current user also has a `UserRole.merchant` (dual-role)
  - If yes, fetch their own `merchantId` from the user doc / `selectedStorefront` provider and **prepend** it to the carnet list with a label "Votre commerce"
  - This allows the merchant-as-client to scan their own QR (test), and see their own loyalty stats
  - **Provider to add:** `currentUserOwnMerchantIdProvider` in `lib/feature/merchant/application/` (reads `users/{uid}.merchant_id` or equivalent)

### S7-T3 — First-visit bonus: enforce app-side and surface to client
- **Current state:** `Merchant.welcomeGiftDescription` is a free-text field shown conditionally on the store profile (non-follower view)
- **Gap:** The app does not track whether a client has visited this merchant for the **first time** — it cannot enforce "first visit only"
- **Fix:**
  - In `FirestoreClientLoyaltyRepository`, when `recordLoyaltyPassage` creates a new `loyalty_clients/{clientId}` doc (i.e., `totalPassages == 0` before the write), set a flag `is_first_visit: true` on the resulting doc
  - In `RecordLoyaltyPassage` use case, after a successful first-passage write, return a `LoyaltyPassageResult.firstVisit(welcomeGift: merchant.welcomeGiftDescription)` result variant
  - In `store_profile_screen.part.dart`, in the `_RecordLoyaltyPassageSheet` success handler, if result is `firstVisit`, show an animated celebration sheet: "🎉 Bienvenue ! [welcomeGiftDescription]" (only if `welcomeGiftDescription` is non-empty)

### S7-T4 — Collect merchant professional email in onboarding + settings
- **`MerchantOnboardingData`:** add `ownerEmail` field (optional)
- **`_StepAddress` in `onboarding_flow_screen.part.dart`:** add an email `TextField` below the website field (hint: "E-mail professionnel (facturation, contact)")
- **Persist:** write `owner_email` to `users/{uid}` Firestore doc
- **`MerchantIdentityEditScreen` (S7-T1):** include owner email as editable field

### S7-T5 — Remove "Message conciergerie" from merchant settings MVP
- **File:** `lib/feature/merchant_settings/presentation/merchant_settings_screen.part.dart:45,67-69`
- **Action:** Comment out or conditionally hide the `ServiceToggle` with label `"Message conciergerie"` behind a `kDebugMode` flag or remove entirely
- **Do not** remove `messagingEnabled` from the domain model or Firestore — it will be needed when messaging is implemented post-MVP

---

## Sprint 8 — Cities list: comprehensive coverage
**Scope:** Replace the 84-city list with a proper French geography dataset.

### S8-T1 — Compile and replace cities list
- **File:** `lib/core/utils/cities.dart`
- **Current:** 84 strings, one duplicate (`'Saint-Denis'` appears twice)
- **Target:** Minimum **500+ French municipalities** covering:
  - All 100+ cities with population > 20,000 (source: INSEE)
  - All overseas collectivities (Guadeloupe, Martinique, Guyane, Réunion, Mayotte, Polynésie, etc.)
  - Major communes in Ile-de-France (all 36 arrondissements of Paris separately is overkill — use "Paris" once)
  - Alps, Côte d'Azur, Alsace, Bretagne, Normandie regions fully represented
- **Format:** Keep same `const List<String> frenchCities = [...]` — no model change; sorted alphabetically
- **Remove duplicate:** `'Saint-Denis'` de-duplicated
- **Implementation:** Write a separate `tools/generate_cities.dart` script or manually curate the list from the INSEE top-500 CSV — do not use an API (offline list is required for no-network onboarding)

### S8-T2 — Add city search to `CitySelectionModal`
- **File:** `lib/feature/auth/signup/presentation/widgets/city_selection_modal.dart` (or wherever the city modal is)
- **Current:** Likely a scrollable list
- **Fix:** Add a search `TextField` at the top of the modal that filters `frenchCities` in real-time by `contains(query.toLowerCase())` — essential once the list grows to 500+
- **Performance:** Filter is done on a `List<String>` — no async needed; `ListView.builder` ensures no off-screen rendering

---

## Sprint 9 — Rewards visibility to clients
**Scope:** Make loyalty bons/rewards clearly visible in the client loyalty tab.

### S9-T1 — Audit current reward display in `LoyaltyCardsScreen`
- **Files:**
  - `lib/feature/loyalty/presentation/loyalty_cards_screen.dart`
  - `lib/feature/loyalty/presentation/loyalty_cards_screen.part.dart`
  - `lib/feature/loyalty/application/client_loyalty_providers.dart` — `rewardLabel()` lines ~128–134
- **Find:** Where is `rewardLabel` / reward CTA currently rendered? Is it shown if `validatedPassages < passagesForReward`?
- **Expected behavior:** Client should see a card per merchant showing:
  - Current tier (Connecté / Habitué / VIP)
  - Passages progress bar (e.g. "7 / 10 passages pour votre récompense")
  - When reward is unlocked: prominent golden "Bon d'achat X€ débloqué — présentez à votre commerçant" card
  - When reward is used: "Récompense utilisée ✓"

### S9-T2 — "Reward unlocked" visual state
- **File:** `lib/feature/loyalty/presentation/loyalty_cards_screen.part.dart`
- If `rewardStatus == LoyaltyRewardStatus.unlocked` (or equivalent field):
  - Show a full-width gold "✨ Récompense disponible" card above the progress bar — tappable to show instructions
  - Add animation: `TweenAnimationBuilder` shimmer on the reward card
- **New provider check:** If `ClientMerchantLoyaltyProgress.rewardStatus` field doesn't exist yet, derive it: `if (validatedPassages >= program.passagesRequired && !rewardUsed) → unlocked`

### S9-T3 — Merchant reward-ready alert
- **File:** `lib/feature/rappels/application/providers.dart:147-160` (`rappelsAlertsProvider` — `loyaltyRewardReady`)
- **Verify:** The alert card appears in `alertes_section.dart` when clients have unlocked rewards
- **Fix if missing:** The `rappel_alert.dart` entity has `loyaltyRewardReady` type — verify it maps to a dismissible card in `alertes_section.dart` with client name and store + CTA "Valider le bon"

---

## Sprint 10 — Google Profile integration
**Scope:** Wire Google account connect for merchant profile (sync / display name source).

### S10-T1 — Audit `merchant_profile_summary_screen` Google sync stub
- **File:** `lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.part.dart`
- Find the "Google sync" placeholder — what exactly is stubbed?
- Determine if this is about:
  - (a) Google My Business API → out of scope for MVP
  - (b) Sign in with Google to associate the account → already works via OAuth in login screen
  - (c) Showing "Connected with Google" status on merchant profile → UI only

### S10-T2 — Show Google/Apple connected status on merchant profile summary
- **File:** `lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.part.dart`
- Read `FirebaseAuth.currentUser.providerData` — if contains `google.com` → show "Connecté avec Google 🟢"; if `apple.com` → "Connecté avec Apple 🟢"
- Add a "Connecter Google" button if Google not connected — calls the existing `signInWithGoogle` OAuth flow (link credential)
- **Use case:** Add `LinkGoogleAccount` use case in `lib/feature/auth/core/application/` — calls `FirebaseAuth.currentUser.linkWithCredential(GoogleAuthCredential)`
- Handle `provider-already-linked` error gracefully

---

## Execution order & dependencies

```
S1 (data model) ──► S2 (client edit) ──► S9 (rewards display)
S1              ──► S4-T4 (birthday CF)
S1              ──► S3-T5 (e-fidelite wizard)
S3-T1           ──► (deploy immediately, cosmetic)
S4-T2           ──► S4-T3 (CF segments must match Dart)
S5-T3 (crop)    ──► add to pubspec FIRST, then pod install
S6-T1 (widget)  ──► S6-T2, S6-T3
S7-T1           ──► (requires S1-T4 fields to exist)
S8-T1           ──► S8-T2 (search on large list)
```

**Recommended delivery order:**
1. S3-T1 (tab reorder — 15 min, zero risk)
2. S7-T5 (remove concierge — 5 min, zero risk)
3. S5-T1 (visibility trap — 30 min, critical UX)
4. S2-T2 (pro account CTA — 20 min, one-liner)
5. S1 entirely (data model — 1 day, blocks birthday + personalization)
6. S2-T1 (edit profile — 3 hours)
7. S4-T1 → S4-T7 (notifications — 1 day)
8. S6 (time picker — half day)
9. S5-T2, S5-T3 (news delete + crop — half day)
10. S3-T2, S3-T3 (auth gate — 2 hours)
11. S7 remaining, S8, S9, S10

---

## Files that must NOT be touched without explicit test
- `lib/feature/auth/core/infrastructure/firebase_user_repository.create.part.dart` — Firestore transaction; one wrong read-after-write causes all signups to fail
- `functions/src/index.ts` — CF deploy: always `firebase deploy --only functions` in staging first
- `lib/main_shell_state.part.dart` — auth state machine; changes here affect all navigation

---

## Definition of "done" per task
- [ ] Code compiles with `flutter analyze` — 0 errors, 0 warnings
- [ ] No `ElevatedButton` / `OutlinedButton` / `IconButton` for back buttons in new screens (style guide)
- [ ] New screens wrap Scaffold in `AnnotatedRegion<SystemUiOverlayStyle>` matching top/bottom colors
- [ ] New Firestore writes have matching security rule coverage
- [ ] New user-visible strings added to both `app_en.arb` and `app_fr.arb`, then `flutter gen-l10n` run
- [ ] New `pubspec.yaml` dependencies: `flutter pub get` + `cd ios && pod install --no-repo-update`
