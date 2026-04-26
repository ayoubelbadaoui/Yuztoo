# Sprint: Merchant UX Final Polish

## Issues identified

| # | Area | Issue | File(s) |
|---|------|--------|---------|
| T1 | Notifications | TextField white-on-white: global theme injects `fillColor: #F3F3F5` (light) overriding the container dark background | `quick_send_section.part.dart` |
| T2 | Settings | "Gardez le contrôle" is a static inline box — should be a one-time popup per session (like rappels welcome) | `merchant_settings_screen.dart` + `.part.dart` |
| T3 | Settings | Fidélité row has a heart icon (`favorite_outline`) on the left — user wants it removed | `settings_services_section.dart`, `merchant_settings_screen.part.dart` |
| T4 | Headers | Account-switch icon (`swap_horiz_rounded`) doesn't clearly communicate "switch profile" | `storefront_screen.part.dart`, `merchant_notifications_hub_screen.part.dart`, `client_list_screen.part.dart` |
| T5 | Settings icons | `chevron_right` (non-rounded) used in both settings sections | `settings_preferences_section.dart`, `settings_services_section.dart` |
| T6 | Settings layout | Description section is vague; no plan/VIP indicator per spec (spec mentions Gratuit/Premium tiers for notifications & promotions) | `merchant_settings_screen.part.dart` |
| T7 | Back button | Android back on screens without inner `PopScope` (`account_preferences`, `merchant_profile_summary`, `storefront_edit`) relies only on root shell — verify all `onBack` callbacks are wired | `main_shell_state.part.dart` |

## Tasks

### T1 — Fix TextField fill color in notification compose
- `quick_send_section.part.dart` → `_buildCompose`: add `filled: true, fillColor: Colors.transparent` to `InputDecoration` so the dark container shows through

### T2 — "Gardez le contrôle" → one-time session popup
- `merchant_settings_screen.dart`: add `static bool _hasShownInfo = false;`, `_showInfoPopup()`, call in `initState`
- `merchant_settings_screen.part.dart`: remove `_buildInfoBox()` from `_buildContent`

### T3 — Remove leading icon from ServiceToggle rows
- `settings_services_section.dart`: make `icon` field `IconData?` (optional)
- `merchant_settings_screen.part.dart`: remove all `icon:` params from `ServiceToggle` instances

### T4 — Better account-switch icon
- Replace `Icons.swap_horiz_rounded` with `Icons.switch_account` (Material "switch account" glyph)
- Locations: storefront header, notifications hub header, client list header

### T5 — Chevron icons → rounded
- `settings_preferences_section.dart`: `Icons.chevron_right` → `Icons.chevron_right_rounded`
- `settings_services_section.dart`: same

### T6 — Improve settings description + add plan badge
- Replace vague description with merchant name + plan tier badge ("Gratuit" / "Pro")
- Remove duplicate `_buildDescriptionSection()` (redundant with `_buildMerchantMiniHeader`)

### T7 — Verify all back callbacks
- Confirm `account_preferences_screen`, `merchant_profile_summary_screen`, `storefront_edit_profile_screen` all receive `onBack: _handleBackFromNested` in the shell (already verified — all wired correctly)
