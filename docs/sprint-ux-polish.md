# Sprint — UX Polish (QR, Vitrine Edit, Back Buttons)

> **Goal:** Four isolated problem areas — each section can be executed independently.  
> Written for an AI agent: every task includes the exact files, lines, and acceptance test.

---

## Context for AI agents

**Stack:** Flutter + Firebase + Riverpod. No go_router — custom `ScreenId`/`_RootShellState` shell in `lib/main_shell_state.part.dart`.  
**Style guide:** `docs/yuztoo-ui-style-guide.md` — read Section 6 for the canonical back-button spec.  
**Colors:** `MerchantColors` (dark navy, gold) for merchant screens. `StorefrontColors` (cream, gold, navyDark) for the vitrine light-theme screens.  
**Key back-button rule (style guide §6):**
```dart
GestureDetector(
  onTap: widget.onBack,
  behavior: HitTestBehavior.opaque,
  child: const SizedBox(
    width: 44,
    height: 44,
    child: Icon(
      Icons.arrow_back_ios_new_rounded,
      color: MerchantColors.gold,   // or StorefrontColors.primaryGold on light screens
      size: 20,
    ),
  ),
)
```
No border, no circle, no background container. Always `GestureDetector` (never `IconButton`). Always `HitTestBehavior.opaque`.

---

## Area 1 — QR scan bug: clients cannot connect to merchants

### Root cause
`lib/feature/merchant_qr/presentation/merchant_qr_screen.dart` line ~255:
```dart
QrImageView(
  data: merchantId,   // ← encodes ONLY the bare Firestore doc ID
```
The client-side scanner (`lib/feature/qr_scanner/presentation/qr_scanner_screen.dart`) calls `VitrineQrConfig.tryParseMerchantId(raw)`, which expects **either**:
- `https://yuztoo.app/vitrine/{merchantId}`
- `yuztoo://vitrine/{merchantId}`

A bare `merchantId` string matches neither pattern → returns `null` → scanner shows "Ce QR code ne correspond pas à une vitrine Yuztoo." → client cannot follow the merchant.

---

### Task A.1 — Fix QR data encoding (1-line fix, highest priority)
**File:** `lib/feature/merchant_qr/presentation/merchant_qr_screen.dart`  
**Import to add** (at top of file, if not present):
```dart
import '../../../core/config/vitrine_qr_config.dart';
```
**Change:**
```dart
// BEFORE
data: merchantId,

// AFTER
data: VitrineQrConfig.uriStringForMerchant(merchantId),
```
This makes the QR encode `https://yuztoo.app/vitrine/{merchantId}` — the format the scanner already expects.

**Acceptance:** Client scans the merchant's QR → `_onDetect` successfully extracts `merchantId` → `onVitrineMerchantFound` fires → client lands on store profile.

---

### Task A.2 — Make `ClientQrBox` in CRM a tappable shortcut to the QR screen
**File:** `lib/feature/client_list/presentation/widgets/client_qr_box.dart`

**Current state:** The box shows `Icons.qr_code` (a Material icon) with static text. It is not tappable and shows no real QR.

**What to do:**
- Add an `onTap` callback parameter: `final VoidCallback? onTap`.
- Wrap the container in a `GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque)`.
- Change the icon from `Icons.qr_code` to a real `QrImageView` from the `qr_flutter` package using the merchant's ID. To do this, the widget needs the `merchantId`. Add `final String merchantId` as a required param (default to empty string to preserve callers that don't have it).
- When `merchantId.isEmpty`: show the current icon placeholder.
- When `merchantId` is provided: show a small `QrImageView(data: VitrineQrConfig.uriStringForMerchant(merchantId), size: 80)` inside a white rounded container.
- In `lib/feature/client_list/presentation/client_list_screen.part.dart`, wherever `ClientQrBox()` is called (search for `ClientQrBox()`), pass:
  - `merchantId: merchantId` (already available in the build scope)
  - `onTap: () => widget.onNavigate?.call('qr-code')` (if `onNavigate` is available on `ClientListScreen`) — OR navigate via `widget.onClientSelect` / a new `onShowQr` callback
- If `ClientListScreen` doesn't have a QR navigation callback yet, add `final VoidCallback? onShowQr` param. In `main_shell_state.part.dart`, pass `onShowQr: () => _handleNavigate('qr-code')`.

**Acceptance:** Tapping the QR box in the CRM opens `MerchantQRCodeScreen`.

---

### Task A.3 — Remove the "Scanner un code de test" button from the client QR scanner
**File:** `lib/feature/qr_scanner/presentation/qr_scanner_screen.part.dart`

**What to do:** Lines ~215–250 show a debug button "Scanner un code de test" that resolves `demo` as a merchant ID and navigates. This is only useful during development. Remove the entire `OutlinedButton.icon` block (the test button) and its surrounding `Column` + `SizedBox(height: 16)` wrapper. Keep only the hint text "Le QR code est à la caisse ou à l'entrée".

**Acceptance:** QR scanner shows clean UI with just the framing overlay and the hint text. No debug button visible.

---

## Area 2 — Vitrine edit: remove Horaires + fix AppBar

### Problem
1. **Horaires d'ouverture is inside the edit profile page** but the spec says Horaires should only be in the "Horaires" tab of the main vitrine screen — not in the edit form. The `_HoursEditorWrapper` widget + its section title must be removed from the edit page.
2. **The edit page uses a Material `AppBar`** while all other merchant sub-screens use a custom header in the body (`SafeArea` + `Container`). This inconsistency is a UX mistake.
3. **`_HoursEditorWrapper` passes `ref` as a constructor param** — this is a Riverpod anti-pattern. The class is a `ConsumerWidget` so it has its own `WidgetRef` in `build`; passing an external `ref` is wrong.

---

### Task B.1 — Remove the Horaires section from the vitrine edit page
**File:** `lib/feature/storefront/presentation/storefront_edit_profile_screen.part.dart`

**What to remove:**
1. Delete `import 'widgets/hours_section.dart';` from the top of `storefront_edit_profile_screen.dart` (the `.dart` main file, not `.part.dart`) — only remove if there are no other usages in that file.
2. In the `.part.dart` file, find and delete this block entirely (~lines 1247–1250 area):
```dart
const _SectionTitle('Horaires d\'ouverture'),
const SizedBox(height: 12),
_HoursEditorWrapper(ref: ref),
const SizedBox(height: 24),
```
3. Delete the entire `_HoursEditorWrapper` class definition (lines ~1338–1371).

**Acceptance:** Vitrine edit page no longer has an hours section. Hours remain fully functional in the "Horaires" tab of the main vitrine screen.

---

### Task B.2 — Replace Material AppBar with custom header in vitrine edit
**File:** `lib/feature/storefront/presentation/storefront_edit_profile_screen.part.dart`  
**Context:** The `_buildEditProfileScaffold` method uses `Scaffold(appBar: AppBar(...))`. Every other merchant/vitrine sub-screen uses a custom header row in the body for consistency.

**What to do:**

Replace the `Scaffold(appBar: AppBar(...), body: ...)` structure with:
```dart
Scaffold(
  backgroundColor: StorefrontColors.backgroundLight,
  body: AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: StorefrontColors.backgroundLight,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: StorefrontColors.backgroundLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: PopScope(
      canPop: true,  // this screen uses Navigator.pop() so canPop: true is fine
      child: Column(
        children: [
          _buildEditHeader(context, state, notifier),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... all sections (Visuels, Informations, Coordonnées, Galerie)
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
)
```

The `_buildEditHeader` replaces the old `AppBar` and should look like this:
```dart
Widget _buildEditHeader(BuildContext context, StorefrontProfileEditState state, StorefrontProfileEditNotifier notifier) {
  return Container(
    color: StorefrontColors.backgroundLight,
    child: SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: StorefrontColors.backgroundLight,
          border: Border(
            bottom: BorderSide(
              color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Back button — canonical style (§6 style guide)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: StorefrontColors.primaryGold,
                  size: 20,
                ),
              ),
            ),
            // Centered title
            Expanded(
              child: Center(
                child: Text(
                  'Modifier le profil',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Save button (same gold pill design as before)
            GestureDetector(
              onTap: state.isSaving ? null : () async {
                notifier.setBusinessName(_nameCtrl.text);
                notifier.setDescription(_descCtrl.text);
                notifier.setPhoneNumber(_phoneCtrl.text);
                notifier.setCity(_cityCtrl.text);
                notifier.setWebsiteUrl(_webCtrl.text);
                notifier.setAddress(_addrCtrl.text);
                await notifier.save();
                if (!context.mounted) return;
                final currentState = ref.read(storefrontProfileEditProvider);
                if (currentState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(currentState.errorMessage!, style: GoogleFonts.outfit(color: Colors.white)),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  ref.read(storefrontProfileEditProvider.notifier).clearError();
                  return;
                }
                ref.invalidate(storefrontProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profil enregistré',
                      style: GoogleFonts.outfit(color: StorefrontColors.navyDark, fontWeight: FontWeight.w600)),
                    backgroundColor: StorefrontColors.primaryGold,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: AnimatedOpacity(
                opacity: state.isSaving ? 0.6 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [StorefrontColors.primaryGold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: state.isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: StorefrontColors.navyDark),
                          )
                        : Text(
                            'Enregistrer',
                            style: GoogleFonts.outfit(
                              fontSize: 14, fontWeight: FontWeight.w700, color: StorefrontColors.navyDark,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Also remove the `scrolledUnderElevation: 0`, `surfaceTintColor`, `leadingWidth`, `centerTitle`, etc. AppBar-specific properties since you're replacing the AppBar entirely.

**Acceptance:** Vitrine edit page has a consistent header that matches the style of all other vitrine/merchant sub-screens. Status bar color is cream (`StorefrontColors.backgroundLight`). No jarring AppBar elevation/shadow.

---

## Area 3 — Back button unification

### Problem analysis
The style guide (§6) defines ONE canonical back button: a bare gold icon inside a 44×44 `SizedBox` in a `GestureDetector(behavior: HitTestBehavior.opaque)`. No border, no background, no circle.

Currently the app has **3 different styles in use:**

| Style | Where used |
|---|---|
| A — Bare icon, 44×44, no decoration | `client_list_screen.part.dart` |
| B — Circle border container, gold icon | `merchant_qr_screen.dart`, `merchant_profile_summary_screen.part.dart`, `data_privacy_screen.dart`, `identification_security_screen.dart`, `notifications_hub_screen.part.dart` |
| C — `YBackButton` (rounded rect, dark bg) | `subcategory_header.dart` |
| D — `IconButton(Icons.arrow_back)` | `qr_scanner_screen.part.dart` |

**Target:** Style A everywhere (bare icon, no decoration).

---

### Task C.1 — Update `YBackButton` widget to canonical spec
**File:** `lib/core/shared/widgets/back_button.dart`

Replace the entire class body with the canonical style:
```dart
import 'package:flutter/material.dart';

/// Canonical Yuztoo back button. Gold icon, 44×44 touch target, no decoration.
/// Use on both dark (navy) and light screens — pass [iconColor] to match the screen.
class YBackButton extends StatelessWidget {
  const YBackButton({
    super.key,
    required this.onPressed,
    this.iconColor,
  });

  final VoidCallback onPressed;

  /// Defaults to gold (`MerchantColors.gold` = `Color(0xFFD4A017)`).
  /// Pass `StorefrontColors.primaryGold` on light screens or `Colors.white` if needed.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor ?? const Color(0xFFD4A017),
          size: 20,
        ),
      ),
    );
  }
}
```

Remove the `backgroundColor` and `borderColor` params entirely — they're no longer used.

---

### Task C.2 — Replace all circle-border back buttons with `YBackButton`

For each file below, find the back button `Container(shape: BoxShape.circle, border: Border.all(...))` pattern and replace with `YBackButton(onPressed: ...)`.

**Files to update:**

#### `lib/feature/merchant_qr/presentation/merchant_qr_screen.dart`
Replace (lines ~160–175):
```dart
// REMOVE
Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: MerchantColors.gold, width: 2),
  ),
  child: const Center(
    child: Icon(Icons.arrow_back_ios_new_rounded, color: MerchantColors.gold, size: 16),
  ),
)

// REPLACE WITH
YBackButton(onPressed: widget.onBack)
```
Add import: `import '../../../core/shared/widgets/back_button.dart';`

#### `lib/feature/merchant_settings/presentation/merchant_profile_summary_screen.part.dart`
Find the circle border back button (~line 100–110) and replace with `YBackButton(onPressed: widget.onBack)`.

#### `lib/feature/merchant_settings/presentation/identification_security_screen.dart`
Find the circle border back button (~line 285–295) and replace with `YBackButton(onPressed: widget.onBack)`.

#### `lib/feature/merchant_settings/presentation/data_privacy_screen.dart`
Find the circle border back button (~line 267–278) and replace with `YBackButton(onPressed: widget.onBack)`.

#### `lib/feature/merchant_notifications/presentation/merchant_notifications_hub_screen.part.dart`
The dual-profile switch icon (swap icon) is NOT a back button — leave it alone. But if there's a back button in this screen's header, replace it.

#### `lib/feature/rappels/presentation/notifications_auto_screen.part.dart`
Find the back button in `_buildHeader()` (~line 170) and replace with `YBackButton(onPressed: widget.onBack ?? () {})`.

#### `lib/feature/promotions/presentation/promotions_management_screen.part.dart`
Find the back button (~line 202) and replace with `YBackButton(onPressed: widget.onBack ?? () {})`.

#### `lib/feature/merchant_stats/presentation/merchant_stats_screen.part.dart`
Find the back button (~line 180) and replace with `YBackButton(onPressed: widget.onBack)`.

#### `lib/feature/merchant_partners/presentation/merchant_partners_screen.part.dart`
Find the back button (~line 78) and replace with `YBackButton(onPressed: widget.onBack)`.

---

### Task C.3 — Fix `IconButton` in QR scanner back button
**File:** `lib/feature/qr_scanner/presentation/qr_scanner_screen.part.dart`

The QR scanner uses `IconButton(Icons.arrow_back)` which is inconsistent (wrong icon variant and uses `IconButton`). The scanner's black overlay context is special since it overlays the camera, so we keep no border but match the canonical icon.

Replace (~line 124–127):
```dart
// REMOVE
IconButton(
  onPressed: widget.onBack,
  icon: const Icon(Icons.arrow_back, color: MerchantColors.gold, size: 26),
),

// REPLACE WITH
GestureDetector(
  onTap: widget.onBack,
  behavior: HitTestBehavior.opaque,
  child: const SizedBox(
    width: 44,
    height: 44,
    child: Icon(Icons.arrow_back_ios_new_rounded, color: MerchantColors.gold, size: 22),
  ),
),
```

---

### Task C.4 — Update `YBackButton` call in subcategory header
**File:** `lib/feature/merchant_onboarding/presentation/widgets/subcategory/subcategory_header.dart`

The `YBackButton` is already used here. After Task C.1 updates the class, this call automatically gets the new look. Verify the call passes `onPressed` and optionally the `iconColor` if needed. Remove any `backgroundColor` / `borderColor` named arguments since those params no longer exist.

---

### Task C.5 — Fix `Icons.arrow_back_ios` (old variant) in merchant onboarding
**File:** `lib/feature/merchant_onboarding/presentation/onboarding_flow_screen.dart` line ~241

```dart
// REMOVE
icon: const Icon(Icons.arrow_back_ios),

// REPLACE WITH
icon: const Icon(Icons.arrow_back_ios_new_rounded),
```

**Acceptance for all C tasks:** `flutter analyze` shows no regression. All back buttons in merchant screens are bare gold icons in 44×44 touch targets. No circle borders, no rounded-rect containers, no `IconButton` usage for back navigation.

---

## Area 4 — Vitrine screen UI alignment with spec

### Task D.1 — Remove the QR section card from the vitrine main screen
**File:** `lib/feature/storefront/presentation/storefront_screen.part.dart`  
**Context:** The vitrine screen contains a `StorefrontQrSection` widget. Per the spec, the QR code has its own dedicated screen (`MerchantQRCodeScreen`) accessible from the quick-action row on the vitrine. Having it inline in the vitrine adds clutter.

**What to do:** Find where `StorefrontQrSection` is rendered inside `_buildStorefrontBody` and remove it (the widget + any surrounding padding/SizedBox).

Check: if `StorefrontQrSection` is ONLY used in the vitrine screen, also remove the import.

**Acceptance:** Vitrine screen no longer shows a QR code card inline. QR access remains via the "🔔 / 💬 / 👁" quick action row (if a QR shortcut is one of those actions — if not, add a QR icon to the quick-action row as the 4th action).

---

### Task D.2 — Verify quick-action row covers all 3 spec shortcuts
**File:** `lib/feature/storefront/presentation/storefront_screen.part.dart`

The spec (page 10) says the vitrine hub has three shortcuts:
1. **Image → aperçu de la fiche** (preview as client)  
2. **Cloche → notifications en cours** (go to notifications hub)  
3. **Message → accès direct au chat** (go to messages)

Verify the quick-action row built in `_buildQuickActions` has these three. If the row currently shows different icons or labels, align them to the spec icons/labels.

Also check: is there a 4th shortcut for the QR code? If yes and D.1 removed the inline QR, keep the QR shortcut in this row. If there are already 3 shortcuts and none is QR, add QR as a 4th.

---

## Run order / dependencies

```
A.1  → no deps (fix first, it's a bug)
A.2  → depends on A.1 being done (QR display needs correct URL)
A.3  → no deps
B.1  → no deps
B.2  → no deps (but run after B.1 to avoid merge conflicts in same file)
C.1  → no deps (update widget first)
C.2  → depends on C.1
C.3  → no deps
C.4  → depends on C.1
C.5  → no deps
D.1  → no deps
D.2  → no deps (or after D.1 to see the row clearly)
```

---

## Definition of done

- `flutter analyze` 0 errors after each area.
- Scan a real merchant QR from the client scanner screen → navigates to store profile.
- Vitrine edit page has no Horaires section; header matches all other sub-screens.
- Every back button in the app is `Icons.arrow_back_ios_new_rounded` in a `44×44` bare `GestureDetector`. Zero `IconButton` for navigation. Zero circle-border or rounded-rect containers around back icons.
