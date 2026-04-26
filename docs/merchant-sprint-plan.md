# Merchant Side — Complete Sprint Plan
> **Goal:** After every task in this file is done, the merchant side of Yuztoo is 100 % feature-complete against the functional spec (PDF: "Cahier des charges fonctionnels Application Yuztoo").  
> **Scope:** Merchant role only. Messages feature is excluded (separate sprint).  
> **Context for AI agents:** This is a Flutter + Firebase + Riverpod app. All state uses Riverpod providers. Navigation uses a custom `ScreenId` enum + `_RootShellState` in `lib/main_shell_state.part.dart`. No go_router. Follow DDD layers: `domain` → `application` → `infrastructure` → `presentation`. Style guide is in `docs/yuztoo-ui-style-guide.md`. Colors: `MerchantColors` (dark navy theme) for all merchant screens. Every screen must wrap with `AnnotatedRegion<SystemUiOverlayStyle>`.

---

## Codebase Snapshot (read this before touching any file)

| Layer | Key file paths |
|---|---|
| Shell / nav | `lib/main_shell_state.part.dart`, `lib/types.dart` |
| Bottom nav | `lib/core/shared/widgets/bottom_nav.dart` |
| CRM | `lib/feature/client_list/` |
| Vitrine | `lib/feature/storefront/` |
| Rappels | `lib/feature/rappels/` |
| Notifications auto | `lib/feature/rappels/presentation/notifications_auto_screen.dart` |
| Promotions | `lib/feature/promotions/` |
| E-Fidélité | `lib/feature/e_fidelite/` |
| Merchant settings | `lib/feature/merchant_settings/` |
| Merchant profile form | `lib/feature/merchant_onboarding/` |
| Stats | `lib/feature/merchant_stats/` |
| Auth | `lib/feature/auth/` |
| l10n | `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`, `lib/l10n/app_localizations.dart` |

---

## Sprint 1 — CRM (Vos clients) hardening

### Task 1.1 — Remove dummy CRM fallback data
**File:** `lib/feature/client_list/presentation/client_list_screen.dart` and `.part.dart`  
**What to do:**
- Delete the `_kDummyClients` list (lines ~17–60 in `client_list_screen.dart`).
- In the `.part.dart` `_buildBody` method, remove the lines that fall back to `_kDummyClients` when the Firestore stream returns empty. When empty → show a proper empty-state widget ("Aucun client pour l'instant. Faites scanner votre QR pour connecter votre premier client.") with the existing `ClientQrBox` widget centered below the message.
- Keep the shimmer loading state and error state unchanged.

**Acceptance:** App running with an empty Firestore merchant base shows the empty state, not fake clients.

---

### Task 1.2 — Wire `ClientQrBox` inside the CRM list header
**File:** `lib/feature/client_list/presentation/client_list_screen.part.dart`  
**What to do:**
- Add a banner/card at the top of the scrollable area (below the search bar, above the segment chips) that shows `ClientQrBox` permanently — "Faites scanner ce QR code pour ajouter un client".
- The `ClientQrBox` widget already exists at `lib/feature/client_list/presentation/widgets/client_qr_box.dart` — just place it in a padded container.
- The QR code itself doesn't need to be functional at this task level (it's already a static icon); the card just needs to be visible so the merchant knows how to add clients.

**Acceptance:** CRM screen always shows the QR onboarding card above the client list.

---

### Task 1.3 — Add "Inactifs" segment to CRM
**Files:** 
- `lib/feature/client_list/domain/entities/merchant_client_row.dart`
- `lib/feature/client_list/presentation/client_list_screen.part.dart`

**What to do:**
- In `ClientSegment` enum add `inactif` value with label `'Inactif'`.
- Update `MerchantClientRow.segment` getter: add rule — if `followedAt` is not null and `now.difference(followedAt!).inDays > 60` and heartLevel < 2 → return `ClientSegment.inactif`. Place this check before the `abonne` fallback.
- Update the segment chips list in the UI to include `ClientSegment.inactif`.
- Add color for `inactif` in the `_segColor` helper (use `Colors.grey`).
- Update `ActiveNotification.targetSegments` string values in `trigger_grid.dart` / wherever segments are referenced as strings: add `'inactif'` to the allowed values list.

**Acceptance:** Clients who have been followed for more than 60 days with heartLevel < 2 appear in the "Inactifs" segment chip filter.

---

### Task 1.4 — Add client count badge to CRM tab
**File:** `lib/core/shared/widgets/bottom_nav.dart`  
**What to do:**
- The `YBottomNav` already supports `badgeCount` on a tab. For the merchant "Vos clients" tab (`communaute`), pass the live subscriber count as the badge so the merchant always sees the number of connected clients at a glance.
- Add a `merchantClientCount` optional param to `YBottomNav` and wire it to the "communaute" `_TabItem`.
- In `lib/main_shell_state.part.dart`, watch a provider that returns `merchantClientsProvider(merchantId).valueOrNull?.length ?? 0` and pass it down.

**Acceptance:** The "Vos clients" tab shows the total client count as a badge.

---

## Sprint 2 — "Vos Notifications" tab (manual broadcast hub)

> **Context:** Currently there is no manual notification send screen for merchants. `NotificationsAutoScreen` handles *automated* trigger-based rules only. The spec (page 11) requires a full hub: compose → audience → send now or schedule → history → partners highlight. This sprint builds that hub as a **new tab** replacing the current shell mapping.

### Task 2.1 — Rename tab "Rappels" → "Notifications" in bottom nav & shell
**Files:** `lib/core/shared/widgets/bottom_nav.dart`, `lib/main_shell_state.part.dart`

**What to do:**
- In `YBottomNav` merchant tabs list, change the `rappels` tab item label from `'Rappels'` to `'Notifications'` and keep icon `Icons.notifications_outlined`.
- The tab id stays `'rappels'` to avoid breaking shell navigation (or rename to `'notifications-hub'` and update all references in `main_shell_state.part.dart`; use find-replace carefully).
- The `rappels` tab still opens `RappelsScreen` — this task is just the label fix. The real hub is built in Task 2.2.

**Acceptance:** Bottom nav shows "Notifications" not "Rappels".

---

### Task 2.2 — Create `MerchantNotificationsHubScreen`
**New files to create (follow DDD layer structure):**
```
lib/feature/merchant_notifications/
  domain/entities/sent_notification.dart
  application/providers.dart
  presentation/merchant_notifications_hub_screen.dart
  presentation/merchant_notifications_hub_screen.part.dart
  presentation/widgets/compose_broadcast_section.dart
  presentation/widgets/notification_history_card.dart
  presentation/widgets/quota_info_row.dart
```

**Screen layout (from spec page 11):**

1. **Header:** "Vos notifications" title, back arrow absent (it's a tab root), top-right icon that opens `NotificationsAutoScreen` (the automated rules nested flow).
2. **Compose section:**
   - Multiline `TextField` for message body.
   - Row of send-mode chips: `Gratuit` / `Premium` / `Payant` (same visual style as `ClientType` chips in promotions).
3. **Audience section** (reuse or mirror `AudienceSection` widget from rappels):
   - "Tous mes clients" | "Certains clients" (segments picker: nouveau, VIP, habitué, abonné, inactif).
   - Optional: "Clients Yuztoo" chip (disabled/locked with "Premium" badge if not unlocked).
4. **Volume indicators row:** Small grey text row — "X suivis · Y connectés". Derive from `merchantClientsProvider` count.
5. **Quota row:** "Quota hebdo: X/5 envois" (hardcode max=5 for now; Firestore field `weeklyNotifSentCount` to be tracked — see Task 2.3).
6. **Send button:** Gold CTA "Envoyer maintenant". Disabled if text empty.
7. **History section:** `ListView` of `SentNotification` items — each card shows: text preview, date sent, audience label, count sent. Empty state: "Aucune notification envoyée".

**Domain entity `SentNotification`:**
```dart
class SentNotification {
  final String id;
  final String merchantId;
  final String text;
  final String audience;         // 'tous' | segment label
  final String clientType;       // 'gratuit' | 'premium' | 'payant'
  final DateTime sentAt;
  final int recipientCount;
}
```

**Firestore path:** `merchants/{merchantId}/sent_notifications/{id}`  
Fields: `text`, `audience`, `client_type`, `sent_at` (Timestamp), `recipient_count`.

**Provider:** `sentNotificationsProvider(merchantId)` → `StreamProvider<List<SentNotification>>` reading the subcollection ordered by `sent_at desc`.

**Send action:**
- Write a new doc to the subcollection with the composed data.
- Increment `weeklyNotifSentCount` on the merchant doc (Firestore increment).
- Show a `SnackBar` confirmation.
- Clear the compose field after send.

**Acceptance:** Merchant can type a message, choose audience, tap send → doc appears in Firestore → history list refreshes.

---

### Task 2.3 — Quota tracking on merchant Firestore doc
**Files:** `lib/feature/merchant/domain/entities/merchant.dart`, its DTO, and `lib/feature/merchant/infrastructure/`

**What to do:**
- Add `weeklyNotifSentCount` (int, default 0) field to `Merchant` entity.
- Add `weeklyNotifResetAt` (DateTime?) to know when to reset.
- Update `MerchantDto.fromFirestore` and `toFirestore` accordingly.
- In the send action (Task 2.2), after successful write: read current count, if `weeklyNotifResetAt` is null or > 7 days ago → reset count to 1 and update `weeklyNotifResetAt`; else increment.
- Expose a `canSendNotification` derived bool: `weeklyNotifSentCount < 5` (free tier).

**Acceptance:** Quota row in the hub shows accurate count. Send button becomes disabled at quota.

---

### Task 2.4 — Wire `MerchantNotificationsHubScreen` into the shell
**File:** `lib/main_shell_state.part.dart`, `lib/types.dart`

**What to do:**
- Add `merchantNotificationsHub` to `ScreenId` enum.
- In `_buildScreen()` switch, add the case returning `MerchantNotificationsHubScreen(onNavigate: _handleNavigate)`.
- Change the `rappels` tab mapping from `ScreenId.merchantRappels` to `ScreenId.merchantNotificationsHub`.
- Move `RappelsScreen` to be reachable via `onNavigate('rappels')` from inside the hub (it becomes a nested sub-screen — see Task 2.5).

**Acceptance:** Tapping "Notifications" tab opens the hub, not the old rappels screen.

---

### Task 2.5 — Move `RappelsScreen` to be a sub-screen inside the hub
**Files:** `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.part.dart`, `lib/main_shell_state.part.dart`

**What to do:**
- Add `ScreenId.merchantRappels` handling in `_handleNavigate` so `onNavigate('rappels')` pushes a nested `_nestedScreen = ScreenId.merchantRappels`.
- In `MerchantNotificationsHubScreen`, add a section at the bottom: "Notifications automatiques" with a `ListTile` showing how many active rules exist + a chevron that calls `onNavigate('rappels')`.
- This preserves the `RappelsScreen` (`NotificationsAutoScreen`) functionality — it is just no longer the tab root.

**Acceptance:** Tapping "Notifications automatiques" in the hub opens the auto-notifications screen. Back returns to hub.

---

## Sprint 3 — Promotions hardening

### Task 3.1 — Persist geo-targeting and segment audience on `Promotion` entity
**Files:**
- `lib/feature/promotions/domain/entities/promotion.dart`
- `lib/feature/promotions/infrastructure/dto/promotion_dto.dart`
- `lib/feature/promotions/presentation/widgets/add_promo_sheet.dart` + `.part.dart`

**What to do:**

Add fields to `Promotion`:
```dart
final String? targetScope;       // 'mes_clients' | 'yuztoo' | 'ville' | 'quartier' | 'proche'
final String? targetZoneLabel;   // human-readable zone (e.g. "Paris 11e")
final List<String> targetSegments; // empty = all; or ['vip','habitue',...]
final int estimatedReach;        // filled server-side or 0
```

Update `PromotionDto.fromFirestore` / `toFirestore`:
```
target_scope, target_zone_label, target_segments (array), estimated_reach (int)
```

In `AddPromoSheet._submit()`:
- Map `_selectedTargetIndex` to `targetScope` string values (index 0 = `'mes_clients'`, 1 = `'yuztoo'`…).
- Map `_selectedDistanceIndex` to `targetZoneLabel`.
- Persist these on the `Promotion` passed to `Navigator.pop`.

**Acceptance:** A newly created promo has `target_scope` and `target_segments` saved in Firestore.

---

### Task 3.2 — Add segment audience picker to `AddPromoSheet`
**File:** `lib/feature/promotions/presentation/widgets/add_promo_sheet.dart` + `.part.dart`

**What to do:**
- Below the "Type de clients" chips, add a new optional section "Cibler des segments" that appears only when `_selectedTargetIndex == 0` (mes clients).
- Shows the same segment multi-select chips as the CRM (nouveau / VIP / habitué / abonné / inactif). Default = all selected (empty `targetSegments` list = tous).
- Store selection in `_selectedSegments` (Set\<String\>).
- Pass to `Promotion` in `_submit()`.

**Acceptance:** Merchant can optionally restrict a promo to VIP + Habitués and it saves correctly.

---

### Task 3.3 — Replace placeholder analytics with real data
**File:** `lib/feature/promotions/presentation/widgets/promo_analytics.dart`

**What to do:**
- `PromoAnalytics` currently shows hardcoded "X" labels. Add a `Promotion` parameter.
- Show real values from the entity:
  - "Clients ciblés" → `estimatedReach` (or "—" if 0)
  - "Vues" → `viewCount` (already exists on entity)
  - "Impressions" → placeholder `'—'` with tooltip "Disponible en Premium" (no backend yet, honest UX)
  - "Visites" / "Nouveaux clients" → placeholder with same Premium badge
- Style: premium-locked metrics show a small gold lock icon next to "—" instead of an "X".
- Remove the hardcoded "Passez en Premium" button for now (it calls `() {}`) — replace with a `TextButton` that shows a "Bientôt disponible" snack bar.

**Acceptance:** Promo cards show real `viewCount`; other fields clearly show locked vs available.

---

## Sprint 4 — Partners / Recommandations

> **Context:** The spec (page 13) requires merchants to manage a list of recommended partners ("cercle de confiance") and invite new ones. Nothing exists in the codebase for this.

### Task 4.1 — Domain + Firestore model for merchant partners
**New files:**
```
lib/feature/merchant_partners/
  domain/entities/merchant_partner.dart
  domain/repositories/merchant_partner_repository.dart
  application/providers.dart
  infrastructure/dto/merchant_partner_dto.dart
  infrastructure/merchant_partner_repository_impl.dart
```

**`MerchantPartner` entity:**
```dart
class MerchantPartner {
  final String id;
  final String merchantId;       // merchant who owns this partner
  final String partnerMerchantId;// partner's merchant doc id
  final String partnerName;
  final String? partnerLogoUrl;
  final String? partnerCity;
  final DateTime addedAt;
  final bool isPending;          // true = invite sent, not yet accepted
}
```

**Firestore path:** `merchants/{merchantId}/partners/{partnerId}`

**Repository interface:** `getMerchantPartners(merchantId)` → Stream, `addPartner(merchantId, partnerMerchantId)`, `removePartner(merchantId, partnerId)`.

---

### Task 4.2 — Build `MerchantPartnersScreen`
**New files:**
```
lib/feature/merchant_partners/presentation/merchant_partners_screen.dart
lib/feature/merchant_partners/presentation/merchant_partners_screen.part.dart
lib/feature/merchant_partners/presentation/widgets/partner_card.dart
lib/feature/merchant_partners/presentation/widgets/invite_partner_sheet.dart
```

**Screen layout:**
1. **Header:** "Vos partenaires" + back button.
2. **Info card:** "Recommandez des commerces de confiance. Vos clients les découvriront sur votre vitrine."
3. **Partner list:** Each `PartnerCard` shows: logo circle, name, city, "En attente" badge if `isPending`, delete icon.
4. **Empty state:** Illustration + "Aucun partenaire. Invitez votre premier partenaire de confiance."
5. **FAB / CTA:** Gold button "Inviter un partenaire" → opens `InvitePartnerSheet`.

**`InvitePartnerSheet`:**
- `TextField` to search merchant by name (queries Firestore `merchants` collection where `name` starts with input).
- Results list with merchant name + city. Tap → calls `addPartner`.
- Show loading and success/error states.

**Add `ScreenId.merchantPartners` to `lib/types.dart`.**  
**Wire in shell:** `onNavigate('partners')` → `_nestedScreen = ScreenId.merchantPartners`.

---

### Task 4.3 — Surface partner block inside Notifications Hub
**File:** `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.part.dart`

**What to do:**
- At the bottom of the hub screen, below the history section, add a "Mettre en avant des partenaires" card.
- The card shows up to 3 partner thumbnails (logo circles) from `merchantPartnersProvider`.
- A "Gérer mes partenaires" chevron row opens `ScreenId.merchantPartners` via `onNavigate('partners')`.

**Acceptance:** Hub shows real partner thumbnails; tap navigates to partners screen.

---

### Task 4.4 — Show partners on the client-facing store profile
**File:** `lib/feature/store_profile/presentation/store_profile_screen.part.dart`

**What to do:**
- Below the "Horaires" tab content, add a new sub-section "Recommandés par ce commerce" that is visible on the "Accueil" tab.
- Loads `merchantPartnersProvider(merchantId)` (with the merchant's id from the store profile context).
- Shows a horizontal scroll of partner vignettes (logo + name) that navigate to that partner's store profile on tap.
- Empty state: section is hidden entirely when no partners.

**Acceptance:** Clients can see partner recommendations on a merchant's store profile.

---

## Sprint 5 — Vitrine hub shortcuts

### Task 5.1 — Add quick-action row to Vitrine (bell, message, preview)
**File:** `lib/feature/storefront/presentation/storefront_screen.part.dart`

**What to do:**
- Inside `_buildStorefrontBody`, just below `StatsCards` and before `NavigationTabs`, insert a `_buildQuickActions` row with three icon-button cards:
  1. 🔔 **Notifications** — calls `onNavigate('notifications-hub')` (opens the notifications hub tab).
  2. 💬 **Messages** — calls `onNavigate('messages')` (opens merchant messages).
  3. 👁 **Aperçu** — opens `StoreProfileScreen` (the client-facing view) for the current merchant by setting `selectedStoreMerchantIdProvider` to `merchantId` and navigating to `ScreenId.storeProfile`. This is a "preview as client" shortcut.
- Each card: rounded white container with a gold icon, a short label underneath. Style matches the storefront's light cream theme (`StorefrontColors`).

**Note:** `StorefrontScreen` has no `onNavigate` callback currently. Add `final ValueChanged<String>? onNavigate` param to `StorefrontScreen` and pass it from the shell's `_buildScreen` case.

**Acceptance:** Three shortcut cards appear on the vitrine. All three navigate correctly.

---

### Task 5.2 — Expose `onNavigate` on `StorefrontScreen` and wire it in shell
**Files:** `lib/feature/storefront/presentation/storefront_screen.dart`, `lib/main_shell_state.part.dart`

**What to do:**
- Add `final ValueChanged<String>? onNavigate` constructor param to `StorefrontScreen`.
- In `main_shell_state.part.dart`, `case ScreenId.merchantStorefront:` → pass `onNavigate: _handleNavigate`.
- Handle `'notifications-hub'` → `_activeTab = 'rappels'; _authScreen = ScreenId.merchantNotificationsHub` in `_handleNavigate`.
- Handle `'messages'` → `_nestedScreen = ScreenId.merchantMessages`.
- Handle `'store-preview'` → set `selectedStoreMerchantIdProvider` and `_nestedScreen = ScreenId.storeProfile`.

**Acceptance:** Navigation from Task 5.1 buttons all work.

---

## Sprint 6 — Merchant Settings completeness

### Task 6.1 — Wire "Identification et sécurité" screen
**New files:**
```
lib/feature/merchant_settings/presentation/identification_security_screen.dart
lib/feature/merchant_settings/presentation/identification_security_screen.part.dart
```
(These files already exist per git status — check if they have content or are empty stubs.)

**What the screen must have (per spec page 12 / standard pro settings):**
- **Change email** row → inline form: current password + new email + confirm, calls Firebase `updateEmail`.
- **Change password** row → inline form: current + new + confirm, calls Firebase `updatePassword`.
- **Two-factor auth** row → informational only ("Bientôt disponible") for now.
- **Connected devices** row → list of Firebase auth sign-in providers (Google / Email shown).

**Wire:** In `SettingsPreferencesSection`, the "Identification et sécurité" item has no `onTap`. Add `onTap: () => onNavigate?.call('identification-security')`.  
Add `ScreenId.merchantIdentificationSecurity` to `types.dart` and handle in shell.

**Acceptance:** Tapping "Identification et sécurité" opens the screen. Email and password changes work.

---

### Task 6.2 — Wire "Confidentialité des données" screen
**New files:**
```
lib/feature/merchant_settings/presentation/data_privacy_screen.dart
lib/feature/merchant_settings/presentation/data_privacy_screen.part.dart
```

**Screen content:**
- **Consentements** section: single toggle "Partager mes stats anonymisées avec Yuztoo" (persisted to Firestore `merchant.analyticsConsent` bool).
- **Export de données** row → button "Demander un export" → shows a confirmation dialog "Votre demande a été enregistrée. Vous recevrez un email sous 48h." (writes a doc to `data_export_requests/{uid}`).
- **Supprimer mon compte** row → red text → confirms via dialog → calls `deleteUser` (Firebase Auth) and deletes the merchant doc.

**Wire:** `SettingsPreferencesSection` "Confidentialité" item → `onNavigate?.call('data-privacy')`. Add `ScreenId.merchantDataPrivacy` to types and shell.

**Acceptance:** Both sensitive actions work end-to-end.

---

### Task 6.3 — Build "Profil Pro" summary screen
**New files:**
```
lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.dart
lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.part.dart
```

**Screen layout (spec page 12 — "Profil Pro"):**
1. **Banner + logo + name** (same layout as storefront banner section, read-only).
2. **KPI row:** clients (from CRM count), partenaires (from partners count), villes connectées (distinct cities in client base — derive from `MerchantClientRow.city`), recommandations reçues (partners count where `partnerMerchantId == this merchantId` — placeholder 0 for now).
3. **"Profil complété" progress bar** (reuse `profileCompletionPercentage` from `Storefront`).
4. **Google sync row** (see Task 6.4).
5. **CTA "Modifier ma vitrine"** → `onNavigate?.call('storefront')`.

**Wire:** Add a "Mon profil pro" item to `SettingsPreferencesSection` → `onNavigate?.call('pro-profile')`. Add `ScreenId.merchantProfileSummary` to types and shell.

**Acceptance:** Screen opens with real data. KPIs show live counts.

---

### Task 6.4 — Google Business sync toggle (UI only)
**File:** `lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.part.dart`

**What to do:**
- Add a `GoldSwitch` row: "Synchroniser avec Google Business". 
- When toggled on, show a modal bottom sheet: "Cette fonctionnalité est en cours de déploiement. Nous vous notifierons dès qu'elle est disponible." — toggle resets to off.
- Persists nothing to Firestore yet (honest placeholder).

**Acceptance:** Toggle is visible, tap shows the coming-soon modal, switches back off.

---

## Sprint 7 — Dual-profile account switch icon

### Task 7.1 — Detect dual profile (Client + Merchant on same account)
**Files:** `lib/feature/auth/core/` (user domain), `lib/main_shell_state.part.dart`

**What to do:**
- The user Firestore doc has a `roles` map (`{ "client": true, "merchant": true }`). The auth infrastructure already reads this (see `firebase_user_repository.writes.part.dart` migration logic).
- Expose `hasDualProfile` bool in the `AuthState.authenticated` case (or derive from `AppUser.roles` — check existing `AppUser` entity in `lib/feature/auth/core/domain/`).
- In `_RootShellState`, store `_isDualProfile` bool, set it when auth state resolves.

---

### Task 7.2 — Add switch icon to merchant headers
**Files:** Merchant screen headers — `StorefrontScreen` header, `ClientListScreen` header, `RappelsScreen` header.

**What to do:**
- When `_isDualProfile == true`, show a small circular icon button (top-right, person-switch icon `Icons.swap_horiz_rounded`) in the header row.
- Tapping it calls `onNavigate('switch-to-client')` which:
  - Sets `_role = UserRole.client`
  - Sets `_authScreen = ScreenId.clientHome`
  - Saves role preference with `roleCacheServiceProvider`.
- The icon is only visible when the merchant also has the client role. Pass it as a bool param to screens that need it, or let the shell pass an `onSwitchRole` callback.

**Acceptance:** Dual-profile merchant sees the switch icon in headers. Tapping it lands on client home.

---

## Sprint 8 — Stats screen completeness

### Task 8.1 — Add notification reach stats to `MerchantStatsScreen`
**File:** `lib/feature/merchant_stats/presentation/merchant_stats_screen.part.dart`

**What to do:**
- Add a new section "Performance des notifications" below the client segment chart.
- Shows two KPI cards side-by-side:
  - "Notifications envoyées" → count of docs in `sent_notifications` subcollection (from `sentNotificationsProvider`).
  - "Dernière portée" → `recipientCount` of the most recent `SentNotification`.
- If no notifications sent: "Aucune notification envoyée ce mois."

---

### Task 8.2 — Add promo performance row to stats
**File:** `lib/feature/merchant_stats/presentation/merchant_stats_screen.part.dart`

**What to do:**
- Add a "Performance des promotions" section.
- For each active (`isOnline == true`) promotion, show a compact row: title + `viewCount` + date range.
- "Aucune promotion active" empty state.
- Reads from the existing `promotionsProvider` / `merchantPromotionsStreamProvider` (whichever is live in the promotions feature providers).

**Acceptance:** Stats screen shows notification send history and promo view counts.

---

## Sprint 9 — Social login (auth completeness)

### Task 9.1 — Implement Google Sign-In
**Files:** `lib/feature/auth/login/presentation/login_screen.dart`, `lib/feature/auth/login/presentation/login_screen.part.dart`, `lib/feature/auth/core/infrastructure/`

**What to do:**
- `LoginScreen` already has a `TODO: Implement social login`. The `_LoginGoogleIcon` and button scaffold exist.
- Add `google_sign_in` package (if not already in `pubspec.yaml` — check first) and Firebase Google auth.
- In the login screen, the Google button `onPressed`:
  1. Call `GoogleSignIn().signIn()` → get `GoogleSignInAccount`.
  2. Get `GoogleAuthCredential` from `idToken` + `accessToken`.
  3. Call `FirebaseAuth.instance.signInWithCredential(credential)`.
  4. The existing `authControllerProvider` auth-state listener will handle navigation.
- Handle errors: show `SnackBar` on `FirebaseAuthException`.
- Repeat same pattern for the Google button in `SignupScreen` if one exists.

**Note:** `GoogleSignIn` needs `REVERSED_CLIENT_ID` in `ios/Runner/Info.plist` and SHA-1 in Firebase console for Android. Leave a `// TODO: add SHA-1 to Firebase console for Android` comment if the project's `google-services.json` doesn't already have it.

---

### Task 9.2 — Implement Apple Sign-In (iOS)
**Files:** same as 9.1 plus `ios/Runner/Runner.entitlements`

**What to do:**
- Add `sign_in_with_apple` package.
- Implement the Apple button `onPressed` (credential flow via `SignInWithApple.getAppleIDCredential` → Firebase `OAuthProvider('apple.com').credential`).
- Apple Sign-In requires the "Sign In with Apple" capability in Xcode entitlements — add to `ios/Runner/Runner.entitlements`:
  ```xml
  <key>com.apple.developer.applesignin</key>
  <array><string>Default</string></array>
  ```
- Only show the Apple button on iOS (`Platform.isIOS` check or `defaultTargetPlatform == TargetPlatform.iOS`).

---

### Task 9.3 — Facebook login (deferred / mark as "Bientôt disponible")
**File:** `lib/feature/auth/login/presentation/login_screen.part.dart`

**What to do:**
- The Facebook button onPressed → shows a `SnackBar`: "Connexion Facebook bientôt disponible."
- Leave implementation for a future sprint to avoid Facebook SDK configuration complexity.
- Button remains visible but disabled with a "Bientôt" caption.

---

## Sprint 10 — l10n for all hardcoded merchant strings

### Task 10.1 — Audit and replace hardcoded merchant strings
**Files:** `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`, `lib/l10n/app_localizations.dart`, all merchant screen `.part.dart` files.

**Scope — hardcoded strings found in merchant screens (non-exhaustive list, scan all files):**
- Bottom nav labels: `'Vos clients'`, `'Rappels'`, `'Vitrine'`, `'Promotions'`, `'Profil'`
- CRM header: `'Vos clients'`
- Search hint: `'Rechercher un client…'`
- Segment labels: `'Nouveau'`, `'VIP'`, `'Habitué'`, `'Abonné'`, `'Inactif'`
- Empty states across all new screens
- Storefront header: `'Votre vitrine'`
- Settings labels: `'PRÉFÉRENCES DU COMPTE PRO'`, `'Préférences du compte pro'`, `'Identification et sécurité'`, `'Confidentialité des données'`, `'Message conciergerie'`, `'Fidélité'`, `'Notifications automatique'`, `'Galerie'`

**How to do it:**
- For each string, add an ARB key in both `app_en.arb` / `app_fr.arb` (French is main, English mirrors).
- Run `flutter gen-l10n` (or the project's l10n generation command — check `pubspec.yaml` for the flutter l10n config).
- Replace the hardcoded string with `l10n.keyName`.

**Note:** Do NOT rename keys that already exist in the ARB files; only add new ones.

**Acceptance:** `flutter analyze` shows 0 hardcoded user-visible strings in merchant screens (spot-check, not exhaustive lint).

---

## Sprint 11 — Final QA checklist

These are not coding tasks but must be verified before calling merchant side done.

### Task 11.1 — System UI overlay audit
Every merchant screen must have `AnnotatedRegion<SystemUiOverlayStyle>` with:
- `statusBarColor: MerchantColors.bgHeader`
- `statusBarIconBrightness: Brightness.light`
- `systemNavigationBarColor: MerchantColors.bgHeader`
- `systemNavigationBarIconBrightness: Brightness.light`

Exception: `StorefrontScreen` uses `StorefrontColors.backgroundLight` for status bar (cream) — this is correct and intentional.

**Check all new screens added in sprints 2–7.**

---

### Task 11.2 — Loading / empty / error states on all new screens
Each new screen from sprints 2–7 must handle all three `AsyncValue` cases:
- **Loading:** shimmer skeleton or `CircularProgressIndicator` with `MerchantColors.gold` color.
- **Empty:** descriptive empty-state widget with icon + text.
- **Error:** retry button + error message.

---

### Task 11.3 — Back navigation
Every new screen that is a nested (non-tab-root) screen must:
- Use `PopScope(canPop: false, onPopInvokedWithResult: …)` to intercept Android back.
- Call the provided `onBack` callback to navigate correctly within the shell.

---

### Task 11.4 — Remove all `TODO` / `() {}` no-op handlers from merchant screens
Search for `onTap: () {}` and `// TODO` in all merchant feature files. Either implement or mark visually as "Bientôt disponible" with a snack bar.

---

## Task Dependency Map

```
Sprint 1  (CRM)          → no dependencies
Sprint 2  (Notif hub)    → depends on Sprint 1 (inactifs segment for targeting)
Sprint 3  (Promotions)   → no dependencies
Sprint 4  (Partners)     → no dependencies; 4.3 depends on Sprint 2 hub existing
Sprint 5  (Vitrine)      → depends on Sprint 2 (notifications-hub nav target)
Sprint 6  (Settings)     → depends on Sprint 4 (partners count in profil)
Sprint 7  (Dual profile) → no dependencies
Sprint 8  (Stats)        → depends on Sprint 2 (sent_notifications collection)
Sprint 9  (Auth)         → no dependencies
Sprint 10 (l10n)         → run last, after all screens are built
Sprint 11 (QA)           → run after everything
```

---

## Definition of Done

A merchant sprint task is **done** when:
1. The feature works end-to-end (data reads/writes to Firestore, UI reflects it).
2. All three async states (loading / empty / error) are handled.
3. `AnnotatedRegion<SystemUiOverlayStyle>` is present on all new scaffolds.
4. No new `flutter analyze` errors introduced.
5. Hardcoded user-visible strings are in l10n (or marked for Sprint 10).
6. Back navigation works on Android (PopScope) and iOS (back swipe / back button).
