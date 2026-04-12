# Splitting large Flutter files with `part` / `part of`

Use this guide to continue the same refactor in this repo: **smaller primary `.dart` files**, same behavior and UI, by moving widgets and large `build` trees into **library parts** (usually with **`extension … on State`** or **`extension … on StatelessWidget`**).

## Goal

- Keep the **public widget class** and **state / lifecycle / business callbacks** in the **main file** when that reads clearly.
- Move **large widget trees**, **section builders** (`_buildHeader`, `_buildFoo`), and **private helper widgets** into a **`*.part.dart`** file.
- **Do not change behavior** unless fixing a bug; prefer mechanical moves.

## Conventions used in this codebase

### 1. Library parts

In the **main** file (the library root):

```dart
import '...';

part 'my_screen.part.dart';

class MyScreen extends StatefulWidget { ... }
```

In **`my_screen.part.dart`**:

```dart
part of 'my_screen.dart';

// extensions, private classes, etc.
```

- The part file **inherits imports** from the main file; only add extra imports in the main file if something is missing.
- **Only one** `part of '…'` per part file; the main file lists all `part '…';` directives.

### 2. UI on extensions (StatefulWidget)

Pattern:

```dart
// main
class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) => _buildBody(context);
}

// part
extension _MyScreenUi on _MyScreenState {
  Widget _buildBody(BuildContext context) {
    return Scaffold(/* ... */);
  }
}
```

- Name extensions with a **private** prefix, e.g. `_MyScreenUi`, `_StorefrontScreenUi`.

### 3. UI on extensions (StatelessWidget)

Same idea:

```dart
extension _PromoCardUi on PromoCard {
  Widget _buildPromoCard(BuildContext context) { ... }
}
```

### 4. `setState` and other `protected` members — **not** on extensions

The analyzer reports **`invalid_use_of_protected_member`** if you call `setState` from an `extension on …State`.

**Fix:** add a **small method on the `State` class** and call it from the extension:

```dart
// main
void _rebuildAfterHydrate() {
  setState(() {});
}

// part — in a post-frame callback, etc.
_rebuildAfterHydrate();
```

Same for any pattern where the extension needs to trigger state updates.

### 5. Static members on `State` referenced from an extension

You may see **`unqualified_reference_to_static_member_of_extended_type`**.

**Fix:** qualify with the state class name:

```dart
value: _MyScreenState._overlayStyle,
```

### 6. Private widgets in parts

Private classes (`_Foo`) can live entirely in **`*.part.dart`** as long as the file starts with `part of '…';`. They share the same library as the main file.

## What to move vs keep

| Prefer **main** file | Prefer **part** file |
|----------------------|----------------------|
| `StatefulWidget` / `State` class declaration | Large `build` return tree |
| Fields, `initState`, `dispose`, controllers | `_buildSection…()` helpers |
| `setState`, `ref.read` / async handlers | Private `StatelessWidget` / layout-only widgets |
| Public API, routing args | Dense purely-visual subtrees |

**Optional:** split further into multiple parts (e.g. `foo_screen.part.dart` + `foo_screen_widgets.part.dart`) only if a single part grows unwieldy; one part is usually enough.

## Files to skip

- **`lib/l10n/*.dart`** — generated; do not hand-split.
- **Infrastructure / DTO** — splitting is optional and often lower value than presentation.
- **Don’t** rename public widgets or change routes/exports unless required for the split.

## System UI (status / nav bar)

If the screen uses **`AnnotatedRegion<SystemUiOverlayStyle>`**, keep colors aligned with the app rules in **`.cursor/rules/system-ui-overlay-styling.mdc`** (merchant vs storefront vs client). Moving the widget tree to a part does **not** change those requirements.

## How to find the next targets

From repo root (macOS/Linux):

```bash
find lib -name '*.dart' ! -name '*.part.dart' -print0 | xargs -0 wc -l | sort -n -r | head -40
```

Prioritize **presentation** (`presentation/`, `widgets/`) and **very long screens**; application-layer giants (`providers.dart`, `*_state.dart`) are a different refactor style.

## Verification

After each split:

```bash
dart analyze path/to/main.dart path/to/main.part.dart
```

Fix analyzer issues before moving on (especially `protected_member` and static qualification).

## Examples already done in this repo (reference)

Use these as templates when unsure:

| Area | Main | Part |
|------|------|------|
| Storefront | `lib/feature/storefront/presentation/storefront_screen.dart` | `storefront_screen.part.dart` |
| Hours / banner | `widgets/hours_section.dart`, `banner_section.dart` | `*.part.dart` |
| Day row | `widgets/day_row.dart` | `day_row.part.dart` |
| Client type UI | `promotions/.../client_type_details.dart` | `client_type_details.part.dart` |
| Merchant stats | `merchant_stats_screen.dart` | `merchant_stats_screen.part.dart` |
| Promo card | `promo_card.dart` | `promo_card.part.dart` |
| Notifications | `notifications/presentation/notifications_screen.dart` | `notifications_screen.part.dart` |
| Auth OTP / signup | `otp_screen.dart`, `signup_screen.dart` | `*.part.dart` |
| Rappels auto | `notifications_auto_screen.dart` | `notifications_auto_screen.part.dart` |
| Profile avatar | `profile_avatar_section.dart` | `profile_avatar_section.part.dart` |

## Suggested next files (as of ongoing refactors)

Run the `find … wc -l` command above for current numbers. Typical next presentation targets include:

- `lib/feature/auth/signup/presentation/widgets/signup_ui_widgets.dart`
- `lib/feature/auth/signup/presentation/widgets/phone_number_formatter.dart`
- `lib/feature/merchant_dashboard/presentation/merchant_dashboard_screen.dart`
- `lib/feature/account_preferences/presentation/account_preferences_screen.dart`
- `lib/feature/role_selection/presentation/widgets/client_view.dart`

## Checklist for the other chat

- [ ] Add `part '….part.dart';` to the library root file.
- [ ] Create `….part.dart` with `part of '….dart';`.
- [ ] Move UI / private widgets; keep `setState` on `State` via small helpers if needed.
- [ ] Qualify static `State` members from extensions when the analyzer requires it.
- [ ] Run `dart analyze` on main + part.
- [ ] No behavior/UI regressions intended; keep diffs focused on structure.
