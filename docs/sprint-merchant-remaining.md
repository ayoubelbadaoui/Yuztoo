# Sprint — Merchant Remaining (chat excluded)
> Everything below is doable Flutter-side only. No Cloud Functions needed.
> All Cloud Function tasks (FCM push delivery execution, auto-notification scheduling) are **out of scope** for this sprint.

---

## Sprint 1 — Notifications fan-out to clients on manual send

### Task 1.1 — Wire `SendMerchantNotification` in the notifications hub
**File:** `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.dart`

**Problem:** `QuickSendSection`'s `onSend` is likely calling only a Firestore write in the hub, but `SendMerchantNotification` (which fans out to each follower's `users/{id}/notifications`) exists as a use case but may not be wired to the hub's send button.

**What to do:**
- In `merchant_notifications_hub_screen.dart`, confirm `QuickSendSection.onSend` calls `ref.read(sendMerchantNotificationProvider).call(...)`.
- If it calls a different / simpler write, replace it with the use case call.
- Pass `merchantName` from the current merchant doc.
- After send: show gold SnackBar "Notification envoyée à X clients !".

**Acceptance:** Tapping send writes to both `merchants/{id}/sent_notifications` **and** `users/{clientId}/notifications` for every follower.

---

### Task 1.2 — Wire `NotifyFollowersOfPromotion` when a promo goes live
**File:** `lib/feature/promotions/presentation/promotions_management_screen.dart`

**Problem:** When a merchant activates/publishes a promotion, `NotifyFollowersOfPromotion` may not be called — confirm and wire if missing.

**What to do:**
- In `promotions_management_screen.dart`, find the promo toggle / publish action.
- After the promo is saved as `isOnline = true`, call `ref.read(notifyFollowersOfPromotionProvider).call(merchantId: ..., merchantName: ..., promotion: ...)`.
- Guard: only notify when transitioning from `isOnline = false → true` (not on every save).

**Acceptance:** When a merchant publishes a promo, each follower gets a notification in their `NotificationsScreen`.

---

## Sprint 2 — Client-side: display merchant notifications received

### Task 2.1 — Confirm `NotificationsScreen` shows in-app merchant notifications
**Files:** `lib/feature/notifications/presentation/notifications_screen.part.dart`

**Problem:** The screen watches `clientNotificationsStreamProvider` (stream of `users/{uid}/notifications`). Verify the list renders `ClientNotificationType.auto` (merchant manual send) and `ClientNotificationType.promotion` notifications correctly — distinct icons / labels.

**What to do:**
- In `_buildAlertTab`: confirm each `ClientNotification` shows `merchantName`, `body`, and a read/unread indicator.
- Add distinct leading icon: bell for `.auto`, tag for `.promotion`.
- Tapping a `.promotion` notification navigates to the store profile (already wired via `onPromotionTap`).

**Acceptance:** A client who follows a merchant sees that merchant's sent notifications in their alerts tab.

---

## Sprint 3 — Storefront profile image upload

### Task 3.1 — Confirm banner + logo uploads work end-to-end in vitrine edit
**Files:** `lib/feature/storefront/presentation/storefront_edit_profile_screen.part.dart`

**Problem:** `image_picker` is imported and `storage_providers` exist, but the actual pick → upload → save URL flow in the edit screen needs verification.

**What to do:**
- Verify `_pickBannerImage()` and `_pickLogoImage()` call `uploadStorefrontImageProvider` and then save the returned URL to the storefront Firestore doc via the update provider.
- If either is a stub (`// TODO`), implement the 3-step flow: pick → upload → update storefront.
- Show a loading overlay during upload; show error snackbar on failure.

**Acceptance:** Changing the banner or logo in the edit screen persists the new image URL to Firestore and refreshes the vitrine.

---

## Sprint 4 — Account preferences: "Créer un compte marchand" CTA

### Task 4.1 — Wire the merchant account creation button in account preferences
**File:** `lib/feature/account_preferences/presentation/account_preferences_screen.part.dart`

**Problem:** When `!isMerchant`, `_buildCreateAccountButton()` is shown. Currently this likely just shows a button — it should trigger the `switch-to-merchant` flow (which creates the merchant role + starts onboarding).

**What to do:**
- The button's `onTap` should call `widget.onNavigate?.call('switch-to-merchant')`.
- This reuses the shell's `_switchToMerchant()` already implemented.

**Acceptance:** A client-only user tapping "Créer un compte marchand" is routed to merchant onboarding.

---

## Run order

```
1.1 → no deps
1.2 → no deps
2.1 → depends on 1.1 (needs real notifications to exist)
3.1 → no deps
4.1 → no deps (reuses existing shell logic)
```

---

## Definition of done
1. No hardcoded stubs or `// TODO` in affected files.
2. Loading / empty / error states handled.
3. `flutter analyze` shows 0 new errors.
