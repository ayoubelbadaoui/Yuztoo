# UI/UX code audit — all pages

Static scan using Flutter skills criteria (`flutter-fix-layout-issues`,
responsive patterns, system UI overlay rule, loading/empty/error UX).

**Method:** code-wise only (not device screenshots). Heuristic scan + manual
verification of HIGH hits + `flutter analyze` on flagged files.

Total pages: **48**

| Sev (after verify) | Count |
|--------------------|------:|
| HIGH | 0 |
| MED | 1 |
| LOW | 8 |
| OK | 39 |

## Findings that need attention

| Sev | Page | Finding | Verified |
|-----|------|---------|----------|
| MED | `merchant_profile_form_screen` | Missing `AnnotatedRegion` / `SystemUiOverlayStyle` | Yes — Scaffold without system bar styling |
| LOW | `account_preferences_screen` | Weak loading/error cues in scan | Heuristic |
| LOW | `discovery_screen` | Weak error UI cue | Heuristic |
| LOW | `onboarding_flow_screen` | Weak error UI cue | Heuristic |
| LOW | `subcategory_selection_screen` | Weak loading/error cues | Heuristic |
| LOW | `merchant_qr_screen` | No empty-state cue flagged | Heuristic |
| LOW | `client_gratification_config_screen` | No empty-state cue flagged | Heuristic |
| LOW | `merchant_stats_screen` | Weak error UI cue | Heuristic |
| LOW | `storefront_screen` | No empty-state cue flagged | Heuristic |

## False positives (cleared)

| Was | Page | Why cleared |
|-----|------|-------------|
| HIGH layout | `merchant_partners_screen` | `ListView` sits under `Expanded` |
| HIGH layout | `notifications_screen` | `ListView` sits under `Expanded` / constrained parents |
| analyze | same files | `flutter analyze` → **No issues found** |

## Full page table

| # | Sev | Page | Result |
|---|-----|------|--------|
| 1 | OK | `employment_history_screen` | Pass |
| 2 | LOW | `account_preferences_screen` | Loading/error cues weak |
| 3 | OK | `login_screen` | Pass |
| 4 | OK | `oauth_completion_screen` | Pass |
| 5 | OK | `otp_screen` | Pass |
| 6 | OK | `signup_screen` | Pass |
| 7 | OK | `client_home_screen` | Pass |
| 8 | OK | `client_list_screen` | Pass |
| 9 | OK | `client_onboarding_screen` | Pass |
| 10 | LOW | `discovery_screen` | Error cue weak |
| 11 | OK | `e_fidelite_screen` | Pass |
| 12 | OK | `legal_document_screen` | Pass |
| 13 | OK | `loading_screen` | Pass |
| 14 | OK | `client_ble_broadcast_screen` | Pass |
| 15 | OK | `loyalty_cards_screen` | Pass |
| 16 | OK | `merchant_ble_scan_screen` | Pass |
| 17 | MED | `merchant_profile_form_screen` | Missing system UI overlay |
| 18 | OK | `merchant_notifications_hub_screen` | Pass |
| 19 | OK | `merchant_benefits_screen` | Pass |
| 20 | OK | `merchant_onboarding_screen` | Pass |
| 21 | LOW | `onboarding_flow_screen` | Error cue weak |
| 22 | LOW | `subcategory_selection_screen` | Loading/error cues weak |
| 23 | OK | `merchant_partners_screen` | Pass (layout OK) |
| 24 | LOW | `merchant_qr_screen` | Empty-state cue weak |
| 25 | LOW | `client_gratification_config_screen` | Empty-state cue weak |
| 26 | OK | `data_privacy_screen` | Pass |
| 27 | OK | `identification_security_screen` | Pass |
| 28 | OK | `merchant_identity_edit_screen` | Pass |
| 29 | OK | `merchant_profile_summary_screen` | Pass |
| 30 | OK | `merchant_settings_screen` | Pass |
| 31 | OK | `merchant_storefront_links_screen` | Pass |
| 32 | LOW | `merchant_stats_screen` | Error cue weak |
| 33 | OK | `messages_screen` | Pass |
| 34 | OK | `notifications_screen` | Pass (layout OK) |
| 35 | OK | `client_profile_screen` | Pass |
| 36 | OK | `personal_information_screen` | Pass |
| 37 | OK | `promotions_management_screen` | Pass |
| 38 | OK | `qr_scanner_screen` | Pass |
| 39 | OK | `notifications_auto_screen` | Pass |
| 40 | OK | `rappels_screen` | Pass |
| 41 | OK | `scheduled_notifications_screen` | Pass |
| 42 | OK | `role_selection_screen` | Pass |
| 43 | OK | `splash_screen` | Pass |
| 44 | OK | `store_profile_screen` | Pass |
| 45 | OK | `storefront_edit_profile_screen` | Pass |
| 46 | LOW | `storefront_screen` | Empty-state cue weak |
| 47 | OK | `yuztoo_contact_screen` | Pass |
| 48 | OK | `guest_shell` | Pass |

## Limits of this test

- Code-wise only — no real iPhone/Android screenshots.
- LOW items are heuristics (may already handle states via providers/widgets elsewhere).
- Visual brand / UX taste not scored.
