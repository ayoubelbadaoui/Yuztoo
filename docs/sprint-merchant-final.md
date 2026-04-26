# Sprint — Merchant Final Completion
> **Goal:** Close the remaining backend wiring and data gaps to reach 100% on the merchant side.
> **Scope:** No new screens needed — everything here is wiring existing UI to real Firestore data.
> **Stack:** Flutter + Firebase + Riverpod. DDD layers. Colors: `MerchantColors`. Style guide: `docs/yuztoo-ui-style-guide.md`.

---

## Sprint 1 — CRM cleanup

### Task 1.1 — Remove dummy client fallback data
**File:** `lib/feature/client_list/presentation/client_list_screen.dart` and `.part.dart`

**What to do:**
- Find `_kDummyClients` (a hardcoded list of fake `MerchantClientRow` objects near the top of the file).
- Delete the entire list.
- In `_buildBody` (`.part.dart`), find the line that falls back to `_kDummyClients` when the Firestore stream is empty. Remove it — when empty, the existing `_buildEmptyClients()` widget should show instead.

**Acceptance:** Running the app with no clients in Firestore shows the empty state with the QR box, never fake data.

---

### Task 1.2 — Add `ClientSegment.inactif`
**File:** `lib/feature/client_list/domain/entities/merchant_client_row.dart`

**What to do:**
- Add `inactif` to the `ClientSegment` enum with label `'Inactif'`.
- In the `segment` getter: add a rule — if `followedAt != null` and `now.difference(followedAt!).inDays > 60` and `heartLevel < 2` → return `ClientSegment.inactif`. Place this check **before** the `abonne` fallback.
- In `.part.dart`, add the `inactif` chip to the segment chips list.
- Add its color in the `_segColor` helper: `Colors.grey`.

**Acceptance:** Clients meeting the 60-day / low-heart rule appear under the "Inactif" filter chip.

---

## Sprint 2 — Notification send + quota

### Task 2.1 — Wire the "Envoyer" button in the notifications hub
**File:** `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.part.dart`

**What to do:**
Find the send button's `onPressed` (currently `() {}` or a TODO). Replace with:
1. Validate `_messageController.text.isNotEmpty`.
2. Write a new doc to `merchants/{merchantId}/sent_notifications/{id}`:
   ```
   text: _messageController.text
   audience: _selectedAudience   // 'tous' or segment label
   client_type: _selectedClientType  // 'gratuit' | 'premium' | 'payant'
   sent_at: FieldValue.serverTimestamp()
   recipient_count: 0   // server-side fill later; 0 is honest placeholder
   ```
3. Call `FirebaseFirestore.instance.collection('merchants').doc(merchantId).update({'weeklyNotifSentCount': FieldValue.increment(1)})`.
4. Clear `_messageController`.
5. Show a gold `SnackBar`: "Notification envoyée !".

**Acceptance:** Tapping send writes a doc to Firestore. History list refreshes. Counter increments.

---

### Task 2.2 — Add `weeklyNotifSentCount` to `Merchant` entity + DTO
**Files:**
- `lib/feature/merchant/domain/entities/merchant.dart`
- `lib/feature/merchant/infrastructure/dto/merchant_dto.dart`

**What to do:**
- Add `final int weeklyNotifSentCount` (default `0`) to the `Merchant` entity.
- Add `weeklyNotifResetAt` (`DateTime?`, default `null`).
- In `MerchantDto.fromFirestore`: read `weekly_notif_sent_count` (int) and `weekly_notif_reset_at` (Timestamp?).
- In `MerchantDto.toFirestore`: write them back.

**Quota logic** (can be inline in the send action, Task 2.1):
- If `weeklyNotifResetAt == null` or `now.difference(weeklyNotifResetAt!).inDays >= 7` → reset count to `1` and update `weekly_notif_reset_at` to now.
- Else → increment.
- Expose `canSendNotification` = `weeklyNotifSentCount < 5`.

**Acceptance:** Quota row in the hub shows accurate `X/5`. Send button disables at quota.

---

### Task 2.3 — Wire quota display in the hub UI
**File:** `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.part.dart`

**What to do:**
- Watch `merchantProvider(merchantId)` (already exists). Read `.weeklyNotifSentCount`.
- The quota row widget (already in the UI as a `Text`) should display: `"Quota hebdo : ${count}/5 envois"`.
- Disable the send button when `canSendNotification == false` (grey out, add tooltip "Quota hebdomadaire atteint").

---

## Sprint 3 — Promotions persistence

### Task 3.1 — Persist targeting fields on `Promotion`
**Files:**
- `lib/feature/promotions/domain/entities/promotion.dart`
- `lib/feature/promotions/infrastructure/dto/promotion_dto.dart`
- `lib/feature/promotions/presentation/widgets/add_promo_sheet.dart` + `.part.dart`

**What to do:**
Add to `Promotion` entity:
```dart
final String? targetScope;       // 'mes_clients' | 'yuztoo' | 'ville' | 'quartier' | 'proche'
final String? targetZoneLabel;
final List<String> targetSegments; // empty = all
```

Update `PromotionDto.fromFirestore` / `toFirestore`:
- `target_scope` (String?)
- `target_zone_label` (String?)
- `target_segments` (List\<String\>)

In `AddPromoSheet._submit()`:
- Map `_selectedTargetIndex` → `targetScope` string.
- Map `_selectedDistanceIndex` → `targetZoneLabel`.
- Pass `targetSegments: _selectedSegments.toList()` to the `Promotion` constructor.

**Acceptance:** A newly saved promo has `target_scope` and `target_segments` in Firestore. Existing promos without these fields default gracefully (null / empty list).

---

### Task 3.2 — Add segment audience picker to `AddPromoSheet`
**File:** `lib/feature/promotions/presentation/widgets/add_promo_sheet.dart` + `.part.dart`

**What to do:**
- Below the "Type de clients" chips, add an optional section `"Cibler des segments"` that is only visible when `_selectedTargetIndex == 0` (mes clients).
- Shows multi-select chips: Nouveau / VIP / Habitué / Abonné / Inactif. Default = all selected (empty `Set<String>` = tous).
- Store selection in `Set<String> _selectedSegments`.
- Wire into `_submit()` (Task 3.1 above).

---

### Task 3.3 — Wire real data into `PromoAnalytics`
**File:** `lib/feature/promotions/presentation/widgets/promo_analytics.dart`

**What to do:**
- Add `required Promotion promotion` constructor parameter.
- Replace hardcoded `"X"` labels:
  - "Vues" → `'${promotion.viewCount}'`
  - "Clients ciblés" → `promotion.estimatedReach > 0 ? '${promotion.estimatedReach}' : '—'`
  - "Impressions" / "Visites" / "Nouveaux clients" → `'—'` with a small gold lock icon + tooltip `"Disponible en Premium"`.
- Remove the no-op "Passez en Premium" `TextButton`; replace with a `TextButton` that shows a "Bientôt disponible" `SnackBar`.

**Acceptance:** Promo cards show real `viewCount`. Premium metrics show an honest locked state, not fake numbers.

---

## Sprint 4 — Stats completeness

### Task 4.1 — Add notification performance section to stats
**File:** `lib/feature/merchant_stats/presentation/merchant_stats_screen.part.dart`

**What to do:**
Add a new section "Performance des notifications" below the existing client chart:
- Watch `sentNotificationsProvider(merchantId)` (stream of `sent_notifications` subcollection).
- Two KPI cards side-by-side:
  - "Envoyées" → `sentNotifications.length`
  - "Dernière portée" → `sentNotifications.first.recipientCount` (or `"—"` if empty)
- Empty state text: `"Aucune notification envoyée ce mois."`.

---

### Task 4.2 — Add promo performance section to stats
**File:** `lib/feature/merchant_stats/presentation/merchant_stats_screen.part.dart`

**What to do:**
Add a "Performance des promotions" section:
- Watch `merchantPromotionsStreamProvider(merchantId)` (already exists).
- For each active promo (`isOnline == true`), show a compact row: title + `viewCount` + date range.
- Empty state: `"Aucune promotion active."`.

---

## Run order

```
1.1 → no deps
1.2 → no deps
2.1 → no deps (can wire button stub first, then add quota check after 2.2)
2.2 → no deps
2.3 → depends on 2.2
3.1 → no deps
3.2 → depends on 3.1 (needs _selectedSegments wired)
3.3 → no deps
4.1 → depends on 2.1 (needs sent_notifications collection to exist)
4.2 → no deps
```

---

## Definition of done

A task is done when:
1. Data writes/reads to Firestore end-to-end with real documents.
2. Loading / empty / error states are handled (shimmer or spinner, empty-state text, retry button).
3. `flutter analyze` shows 0 new errors.
4. No hardcoded mock data remains in the affected feature.
