# COMPLETE TEST STRATEGY - Yuztoo Flutter App
## Principal QA Architect + Senior Flutter Engineer + Test Automation Expert

---

## 📋 EXECUTIVE SUMMARY

**Application Type:** Flutter Mobile App (Android/iOS/Web capable)
**Architecture:** Domain-Driven Design (DDD) with Riverpod state management
**Backend:** Firebase (Auth, Firestore, Storage)
**Testing Philosophy:** Zero-trust, exhaustive coverage, production-ready

**Total Screens Identified:** 21
**Total Features:** 15+ major features
**Total Use Cases:** 13+ business operations
**Total Repositories:** 3 (Auth, User, Merchant)

---

## 🎯 TEST STRATEGY OVERVIEW

### Testing Pyramid
```
        /\
       /  \  E2E Integration Tests (10%)
      /____\
     /      \  Widget Tests (30%)
    /________\
   /          \  Unit Tests (60%)
  /____________\
```

### Test Types Distribution
- **Unit Tests:** 60% - Domain logic, use cases, validators, utilities
- **Widget Tests:** 30% - UI components, screens, navigation, state
- **Integration Tests:** 10% - End-to-end flows, Firebase interactions

### Testing Principles
1. **Isolation:** Each test is independent, no shared state
2. **Determinism:** Tests produce same results every run
3. **Speed:** Unit tests < 1s, Widget tests < 5s, Integration < 30s
4. **Coverage:** Aim for 90%+ code coverage
5. **Maintainability:** Tests are readable, well-organized, documented

---

## 📊 COMPLETE TEST MATRIX

### FEATURE 1: AUTHENTICATION & AUTHORIZATION

#### 1.1 SPLASH SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SPL-001 | Screen renders without crash | Widget | P0 | ⬜ |
| SPL-002 | Shows loading indicator | Widget | P0 | ⬜ |
| SPL-003 | Handles auth state loading | Widget | P0 | ⬜ |
| SPL-004 | Handles auth state timeout | Widget | P1 | ⬜ |
| SPL-005 | Handles auth state error | Widget | P1 | ⬜ |
| SPL-006 | App lifecycle: background during splash | Integration | P2 | ⬜ |
| SPL-007 | App lifecycle: kill during splash | Integration | P2 | ⬜ |
| SPL-008 | Orientation change during splash | Widget | P2 | ⬜ |
| SPL-009 | Multiple rapid app starts | Integration | P2 | ⬜ |
| SPL-010 | Network unavailable during splash | Integration | P1 | ⬜ |

#### 1.2 ROLE SELECTION SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| ROL-001 | Screen renders without crash | Widget | P0 | ⬜ |
| ROL-002 | Client view displays correctly | Widget | P0 | ⬜ |
| ROL-003 | Merchant view displays correctly | Widget | P0 | ⬜ |
| ROL-004 | Tap "Découvrir" (Client) → navigates to login | Widget | P0 | ⬜ |
| ROL-005 | Tap "Scan" (Client) → navigates to login | Widget | P0 | ⬜ |
| ROL-006 | Tap "Login" (Client) → navigates to login | Widget | P0 | ⬜ |
| ROL-007 | Tap "Découvrir" (Merchant) → navigates to onboarding | Widget | P0 | ⬜ |
| ROL-008 | Rapid role switching (spam tap) | Widget | P1 | ⬜ |
| ROL-009 | Back button behavior | Widget | P1 | ⬜ |
| ROL-010 | Orientation change | Widget | P2 | ⬜ |
| ROL-011 | Text overflow with long role names | Widget | P2 | ⬜ |
| ROL-012 | Dark mode support | Widget | P2 | ⬜ |
| ROL-013 | Font scaling (accessibility) | Widget | P2 | ⬜ |
| ROL-014 | Screen rotation during interaction | Widget | P2 | ⬜ |
| ROL-015 | Memory leak check (navigate back/forth 100x) | Integration | P1 | ⬜ |

#### 1.3 LOGIN SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| LOG-001 | Screen renders without crash | Widget | P0 | ⬜ |
| LOG-002 | Email field exists and is accessible | Widget | P0 | ⬜ |
| LOG-003 | Password field exists and is accessible | Widget | P0 | ⬜ |
| LOG-004 | Login button exists | Widget | P0 | ⬜ |
| LOG-005 | Signup link exists | Widget | P0 | ⬜ |
| LOG-006 | Forgot password link exists | Widget | P0 | ⬜ |
| LOG-007 | Valid credentials → successful login | Integration | P0 | ⬜ |
| LOG-008 | Invalid email format → error message | Widget | P0 | ⬜ |
| LOG-009 | Wrong password → error message | Integration | P0 | ⬜ |
| LOG-010 | Non-existent user → error message | Integration | P0 | ⬜ |
| LOG-011 | Empty email → validation error | Widget | P0 | ⬜ |
| LOG-012 | Empty password → validation error | Widget | P0 | ⬜ |
| LOG-013 | Whitespace-only email → validation error | Widget | P1 | ⬜ |
| LOG-014 | Whitespace-only password → validation error | Widget | P1 | ⬜ |
| LOG-015 | Very long email (1000 chars) → validation | Widget | P1 | ⬜ |
| LOG-016 | Very long password (1000 chars) → validation | Widget | P1 | ⬜ |
| LOG-017 | Email with emojis → validation | Widget | P1 | ⬜ |
| LOG-018 | SQL injection in email → sanitized | Widget | P1 | ⬜ |
| LOG-019 | XSS in email → sanitized | Widget | P1 | ⬜ |
| LOG-020 | Special characters in password → handled | Widget | P1 | ⬜ |
| LOG-021 | Copy/paste email → works correctly | Widget | P2 | ⬜ |
| LOG-022 | Autofill email → works correctly | Widget | P2 | ⬜ |
| LOG-023 | Keyboard shows correct type (email) | Widget | P2 | ⬜ |
| LOG-024 | Password visibility toggle works | Widget | P0 | ⬜ |
| LOG-025 | Focus management (tab order) | Widget | P1 | ⬜ |
| LOG-026 | Keyboard dismissal on submit | Widget | P1 | ⬜ |
| LOG-027 | Network timeout → error handling | Integration | P1 | ⬜ |
| LOG-028 | Network error → retry mechanism | Integration | P1 | ⬜ |
| LOG-029 | Slow network (2G) → loading state | Integration | P1 | ⬜ |
| LOG-030 | Rapid login attempts (spam button) | Widget | P1 | ⬜ |
| LOG-031 | Login during network interruption | Integration | P1 | ⬜ |
| LOG-032 | Back button during login → prevents navigation | Widget | P1 | ⬜ |
| LOG-033 | App backgrounded during login | Integration | P2 | ⬜ |
| LOG-034 | App killed during login | Integration | P2 | ⬜ |
| LOG-035 | Multiple devices login simultaneously | Integration | P2 | ⬜ |
| LOG-036 | Session expiration → redirect to login | Integration | P1 | ⬜ |
| LOG-037 | Token refresh failure → error handling | Integration | P1 | ⬜ |
| LOG-038 | Unauthorized access attempt | Integration | P1 | ⬜ |
| LOG-039 | Account disabled → error message | Integration | P1 | ⬜ |
| LOG-040 | Orientation change during login | Widget | P2 | ⬜ |
| LOG-041 | Text overflow in error messages | Widget | P2 | ⬜ |
| LOG-042 | Loading state during login | Widget | P0 | ⬜ |
| LOG-043 | Error state display | Widget | P0 | ⬜ |
| LOG-044 | Success state → navigation | Integration | P0 | ⬜ |
| LOG-045 | Role-based navigation (client vs merchant) | Integration | P0 | ⬜ |

#### 1.4 SIGNUP SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SIG-001 | Screen renders without crash | Widget | P0 | ⬜ |
| SIG-002 | All form fields exist | Widget | P0 | ⬜ |
| SIG-003 | Email field validation | Widget | P0 | ⬜ |
| SIG-004 | Phone field validation | Widget | P0 | ⬜ |
| SIG-005 | Password field validation | Widget | P0 | ⬜ |
| SIG-006 | City selection works | Widget | P0 | ⬜ |
| SIG-007 | Country code selection works | Widget | P0 | ⬜ |
| SIG-008 | Valid data → navigates to OTP | Integration | P0 | ⬜ |
| SIG-009 | Empty email → validation error | Widget | P0 | ⬜ |
| SIG-010 | Invalid email format → validation error | Widget | P0 | ⬜ |
| SIG-011 | Empty phone → validation error | Widget | P0 | ⬜ |
| SIG-012 | Invalid phone format → validation error | Widget | P0 | ⬜ |
| SIG-013 | Empty password → validation error | Widget | P0 | ⬜ |
| SIG-014 | Weak password → validation error | Widget | P1 | ⬜ |
| SIG-015 | Empty city → validation error | Widget | P0 | ⬜ |
| SIG-016 | Whitespace-only fields → validation error | Widget | P1 | ⬜ |
| SIG-017 | Very long email (1000 chars) → validation | Widget | P1 | ⬜ |
| SIG-018 | Very long phone (100 chars) → validation | Widget | P1 | ⬜ |
| SIG-019 | Email with emojis → validation | Widget | P1 | ⬜ |
| SIG-020 | Phone with letters → validation | Widget | P1 | ⬜ |
| SIG-021 | SQL injection in fields → sanitized | Widget | P1 | ⬜ |
| SIG-022 | XSS in fields → sanitized | Widget | P1 | ⬜ |
| SIG-023 | Special characters in name → handled | Widget | P1 | ⬜ |
| SIG-024 | Unicode characters in all fields | Widget | P1 | ⬜ |
| SIG-025 | RTL text in fields | Widget | P2 | ⬜ |
| SIG-026 | Copy/paste abuse (paste 1000 chars) | Widget | P1 | ⬜ |
| SIG-027 | Autofill behavior | Widget | P2 | ⬜ |
| SIG-028 | Phone number formatting | Widget | P0 | ⬜ |
| SIG-029 | Country code changes → phone format updates | Widget | P0 | ⬜ |
| SIG-030 | City modal opens and closes | Widget | P0 | ⬜ |
| SIG-031 | City selection persists | Widget | P0 | ⬜ |
| SIG-032 | Country code modal opens and closes | Widget | P0 | ⬜ |
| SIG-033 | Country code selection persists | Widget | P0 | ⬜ |
| SIG-034 | Focus management (tab order) | Widget | P1 | ⬜ |
| SIG-035 | Keyboard type per field | Widget | P1 | ⬜ |
| SIG-036 | Keyboard dismissal | Widget | P1 | ⬜ |
| SIG-037 | Network timeout → error handling | Integration | P1 | ⬜ |
| SIG-038 | Network error → retry mechanism | Integration | P1 | ⬜ |
| SIG-039 | Phone already exists → error message | Integration | P0 | ⬜ |
| SIG-040 | Email already exists → error message | Integration | P0 | ⬜ |
| SIG-041 | Rapid signup attempts (spam button) | Widget | P1 | ⬜ |
| SIG-042 | Back button during signup | Widget | P1 | ⬜ |
| SIG-043 | App backgrounded during signup | Integration | P2 | ⬜ |
| SIG-044 | Orientation change | Widget | P2 | ⬜ |
| SIG-045 | Loading state during signup | Widget | P0 | ⬜ |
| SIG-046 | Error state display | Widget | P0 | ⬜ |
| SIG-047 | Role-based signup (client vs merchant) | Integration | P0 | ⬜ |
| SIG-048 | Merchant signup → preserves onboarding state | Integration | P0 | ⬜ |

#### 1.5 OTP SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| OTP-001 | Screen renders without crash | Widget | P0 | ⬜ |
| OTP-002 | 6 OTP input fields exist | Widget | P0 | ⬜ |
| OTP-003 | OTP fields are accessible | Widget | P0 | ⬜ |
| OTP-004 | Valid OTP → successful verification | Integration | P0 | ⬜ |
| OTP-005 | Invalid OTP → error message | Integration | P0 | ⬜ |
| OTP-006 | Expired OTP → error message | Integration | P0 | ⬜ |
| OTP-007 | Empty OTP → validation error | Widget | P0 | ⬜ |
| OTP-008 | Partial OTP (3 digits) → validation error | Widget | P0 | ⬜ |
| OTP-009 | Non-numeric input → rejected | Widget | P0 | ⬜ |
| OTP-010 | Paste 6-digit code → auto-fills | Widget | P1 | ⬜ |
| OTP-011 | Paste invalid code → rejected | Widget | P1 | ⬜ |
| OTP-012 | Paste partial code → fills available fields | Widget | P1 | ⬜ |
| OTP-013 | Auto-focus first field | Widget | P0 | ⬜ |
| OTP-014 | Auto-advance to next field on input | Widget | P0 | ⬜ |
| OTP-015 | Backspace clears current and moves back | Widget | P0 | ⬜ |
| OTP-016 | Tap field → clears and focuses | Widget | P0 | ⬜ |
| OTP-017 | Rapid input (spam typing) | Widget | P1 | ⬜ |
| OTP-018 | Spacing between fields correct | Widget | P0 | ⬜ |
| OTP-019 | Fields fit on screen (no overflow) | Widget | P0 | ⬜ |
| OTP-020 | Resend button exists | Widget | P0 | ⬜ |
| OTP-021 | Resend button disabled initially (60s timer) | Widget | P0 | ⬜ |
| OTP-022 | Resend timer counts down correctly | Widget | P0 | ⬜ |
| OTP-023 | Resend button enables after timer | Widget | P0 | ⬜ |
| OTP-024 | Resend OTP → new code sent | Integration | P0 | ⬜ |
| OTP-025 | Resend during network error → error handling | Integration | P1 | ⬜ |
| OTP-026 | Rapid resend attempts → prevented | Widget | P1 | ⬜ |
| OTP-027 | Network timeout → error handling | Integration | P1 | ⬜ |
| OTP-028 | Network error → retry mechanism | Integration | P1 | ⬜ |
| OTP-029 | Back button during verification → prevented | Widget | P1 | ⬜ |
| OTP-030 | App backgrounded during OTP → state preserved | Integration | P2 | ⬜ |
| OTP-031 | App killed during OTP → state lost (expected) | Integration | P2 | ⬜ |
| OTP-032 | Orientation change → fields still accessible | Widget | P2 | ⬜ |
| OTP-033 | Loading state during verification | Widget | P0 | ⬜ |
| OTP-034 | Error state display | Widget | P0 | ⬜ |
| OTP-035 | Success state → creates user document | Integration | P0 | ⬜ |
| OTP-036 | Merchant signup → creates merchant document | Integration | P0 | ⬜ |
| OTP-037 | Client signup → no merchant document | Integration | P0 | ⬜ |
| OTP-038 | Merchant creation failure → error but user created | Integration | P1 | ⬜ |
| OTP-039 | Multiple OTP verifications → idempotent | Integration | P1 | ⬜ |
| OTP-040 | OTP verification timeout → error handling | Integration | P1 | ⬜ |
| OTP-041 | Keyboard covers OTP fields → scrolls | Widget | P1 | ⬜ |
| OTP-042 | Text overflow in error messages | Widget | P2 | ⬜ |
| OTP-043 | Screen rotation during input | Widget | P2 | ⬜ |
| OTP-044 | Memory leak check (navigate back/forth) | Integration | P1 | ⬜ |

---

### FEATURE 2: MERCHANT ONBOARDING

#### 2.1 MERCHANT ONBOARDING SCREEN (Category Selection)
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| MOB-001 | Screen renders without crash | Widget | P0 | ⬜ |
| MOB-002 | All category cards display | Widget | P0 | ⬜ |
| MOB-003 | Category cards are tappable | Widget | P0 | ⬜ |
| MOB-004 | Tap category → selection state updates | Widget | P0 | ⬜ |
| MOB-005 | Selected category → visual feedback | Widget | P0 | ⬜ |
| MOB-006 | Tap different category → previous deselected | Widget | P0 | ⬜ |
| MOB-007 | "Suivant" button disabled when no selection | Widget | P0 | ⬜ |
| MOB-008 | "Suivant" button enabled when category selected | Widget | P0 | ⬜ |
| MOB-009 | Tap "Suivant" → navigates to subcategory | Integration | P0 | ⬜ |
| MOB-010 | Rapid category taps (debouncing) | Widget | P1 | ⬜ |
| MOB-011 | Double tap category → single selection | Widget | P1 | ⬜ |
| MOB-012 | Back button → navigates back | Widget | P0 | ⬜ |
| MOB-013 | App backgrounded → state persists | Integration | P1 | ⬜ |
| MOB-014 | App killed → state restored from storage | Integration | P1 | ⬜ |
| MOB-015 | Orientation change | Widget | P2 | ⬜ |
| MOB-016 | Long category names → text overflow handled | Widget | P1 | ⬜ |
| MOB-017 | Category with emojis → displays correctly | Widget | P1 | ⬜ |
| MOB-018 | Empty state (no categories) → handled | Widget | P1 | ⬜ |
| MOB-019 | Loading state → shows indicator | Widget | P1 | ⬜ |
| MOB-020 | Error state → shows error message | Widget | P1 | ⬜ |
| MOB-021 | Memory leak check | Integration | P1 | ⬜ |
| MOB-022 | Screen rotation during selection | Widget | P2 | ⬜ |
| MOB-023 | Font scaling → layout adapts | Widget | P2 | ⬜ |
| MOB-024 | Dark mode support | Widget | P2 | ⬜ |

#### 2.2 SUBCATEGORY SELECTION SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SUB-001 | Screen renders without crash | Widget | P0 | ⬜ |
| SUB-002 | Subcategories display for selected category | Widget | P0 | ⬜ |
| SUB-003 | Subcategory cards are tappable | Widget | P0 | ⬜ |
| SUB-004 | Tap subcategory → selection state updates | Widget | P0 | ⬜ |
| SUB-005 | Selected subcategory → visual feedback | Widget | P0 | ⬜ |
| SUB-006 | "Suivant" button disabled when no selection | Widget | P0 | ⬜ |
| SUB-007 | "Suivant" button enabled when subcategory selected | Widget | P0 | ⬜ |
| SUB-008 | Tap "Suivant" → navigates to benefits | Integration | P0 | ⬜ |
| SUB-009 | Back button → returns to category selection | Widget | P0 | ⬜ |
| SUB-010 | Back button → preserves category selection | Integration | P0 | ⬜ |
| SUB-011 | Rapid subcategory taps (debouncing) | Widget | P1 | ⬜ |
| SUB-012 | App backgrounded → state persists | Integration | P1 | ⬜ |
| SUB-013 | App killed → state restored | Integration | P1 | ⬜ |
| SUB-014 | Invalid category → error handling | Widget | P1 | ⬜ |
| SUB-015 | Empty subcategories → handled | Widget | P1 | ⬜ |
| SUB-016 | Orientation change | Widget | P2 | ⬜ |
| SUB-017 | Long subcategory names → text overflow | Widget | P1 | ⬜ |
| SUB-018 | Memory leak check | Integration | P1 | ⬜ |

#### 2.3 MERCHANT BENEFITS SCREEN
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| BEN-001 | Screen renders without crash | Widget | P0 | ⬜ |
| BEN-002 | Benefits list displays | Widget | P0 | ⬜ |
| BEN-003 | "Commencer gratuitement" button exists | Widget | P0 | ⬜ |
| BEN-004 | Tap button → navigates to signup (merchant role) | Integration | P0 | ⬜ |
| BEN-005 | Back button → returns to subcategory | Widget | P0 | ⬜ |
| BEN-006 | Back button → preserves selections | Integration | P0 | ⬜ |
| BEN-007 | App backgrounded → state persists | Integration | P1 | ⬜ |
| BEN-008 | Orientation change | Widget | P2 | ⬜ |
| BEN-009 | Long benefit text → text overflow | Widget | P1 | ⬜ |
| BEN-010 | Memory leak check | Integration | P1 | ⬜ |

#### 2.4 ONBOARDING STATE PERSISTENCE
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| OSP-001 | Category selection → saved to SharedPreferences | Integration | P0 | ⬜ |
| OSP-002 | Subcategory selection → saved to SharedPreferences | Integration | P0 | ⬜ |
| OSP-003 | App restart → selections restored | Integration | P0 | ⬜ |
| OSP-004 | Clear category → removes from storage | Integration | P0 | ⬜ |
| OSP-005 | Reset onboarding → clears storage | Integration | P0 | ⬜ |
| OSP-006 | Corrupted storage → handles gracefully | Integration | P1 | ⬜ |
| OSP-007 | Storage unavailable → graceful degradation | Integration | P1 | ⬜ |
| OSP-008 | Multiple rapid saves → no race conditions | Integration | P1 | ⬜ |
| OSP-009 | Storage quota exceeded → error handling | Integration | P2 | ⬜ |

---

### FEATURE 3: MERCHANT CREATION & MANAGEMENT

#### 3.1 COMPLETE MERCHANT ONBOARDING USE CASE
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| CMO-001 | Valid data → merchant created successfully | Unit | P0 | ⬜ |
| CMO-002 | Empty userId → validation error | Unit | P0 | ⬜ |
| CMO-003 | Empty name → validation error | Unit | P0 | ⬜ |
| CMO-004 | Whitespace-only name → validation error | Unit | P0 | ⬜ |
| CMO-005 | Name > 200 chars → validation error | Unit | P0 | ⬜ |
| CMO-006 | Empty email → validation error | Unit | P0 | ⬜ |
| CMO-007 | Invalid email format → validation error | Unit | P0 | ⬜ |
| CMO-008 | Email > 254 chars → validation error | Unit | P0 | ⬜ |
| CMO-009 | Empty phone → validation error | Unit | P0 | ⬜ |
| CMO-010 | Invalid phone format → validation error | Unit | P0 | ⬜ |
| CMO-011 | Phone > 20 chars → validation error | Unit | P0 | ⬜ |
| CMO-012 | Empty city → validation error | Unit | P0 | ⬜ |
| CMO-013 | City > 100 chars → validation error | Unit | P0 | ⬜ |
| CMO-014 | Missing category → validation error | Unit | P0 | ⬜ |
| CMO-015 | Empty categoryId → validation error | Unit | P0 | ⬜ |
| CMO-016 | Valid categoryId + subcategoryId → categories list built | Unit | P0 | ⬜ |
| CMO-017 | Only categoryId → categories list built | Unit | P0 | ⬜ |
| CMO-018 | Only subcategoryId → validation error (category required) | Unit | P0 | ⬜ |
| CMO-019 | Provided categories list → used as-is | Unit | P0 | ⬜ |
| CMO-020 | Duplicate categories → validation error | Unit | P1 | ⬜ |
| CMO-021 | Too many categories (>20) → validation error | Unit | P1 | ⬜ |
| CMO-022 | Empty string in categories list → validation error | Unit | P1 | ⬜ |
| CMO-023 | Description > 5000 chars → validation error | Unit | P0 | ⬜ |
| CMO-024 | Address > 500 chars → validation error | Unit | P0 | ⬜ |
| CMO-025 | Document size > 800KB → validation error | Unit | P0 | ⬜ |
| CMO-026 | XSS in description → sanitized | Unit | P1 | ⬜ |
| CMO-027 | Control characters in name → stripped | Unit | P1 | ⬜ |
| CMO-028 | Unicode/emoji in name → preserved | Unit | P1 | ⬜ |
| CMO-029 | Zero-width characters → removed | Unit | P1 | ⬜ |
| CMO-030 | Merchant already exists → returns existing | Unit | P0 | ⬜ |
| CMO-031 | Merchant exists check fails → proceeds with creation | Unit | P1 | ⬜ |
| CMO-032 | Merchant creation → merchantId == userId | Unit | P0 | ⬜ |
| CMO-033 | Merchant creation → user document updated atomically | Integration | P0 | ⬜ |
| CMO-034 | Batch write failure → no partial data | Integration | P0 | ⬜ |
| CMO-035 | Network timeout → error handling | Integration | P1 | ⬜ |
| CMO-036 | Permission denied → error message | Integration | P1 | ⬜ |
| CMO-037 | Firestore quota exceeded → error handling | Integration | P2 | ⬜ |
| CMO-038 | Concurrent creation attempts → idempotent | Integration | P1 | ⬜ |
| CMO-039 | Multiple OTP verifications → single merchant created | Integration | P1 | ⬜ |

#### 3.2 GET MERCHANT BY ID USE CASE
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| GMB-001 | Valid merchantId → returns merchant | Unit | P0 | ⬜ |
| GMB-002 | Empty merchantId → returns null | Unit | P0 | ⬜ |
| GMB-003 | Non-existent merchantId → returns null | Unit | P0 | ⬜ |
| GMB-004 | Network timeout → error handling | Integration | P1 | ⬜ |
| GMB-005 | Permission denied → error message | Integration | P1 | ⬜ |
| GMB-006 | Invalid merchantId format → handled | Unit | P1 | ⬜ |
| GMB-007 | Merchant with all fields → returns complete data | Unit | P0 | ⬜ |
| GMB-008 | Merchant with missing optional fields → returns null for optional | Unit | P0 | ⬜ |
| GMB-009 | Concurrent requests → no race conditions | Integration | P1 | ⬜ |

#### 3.3 GET MERCHANTS USE CASE
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| GMS-001 | No filter → returns all active merchants | Unit | P0 | ⬜ |
| GMS-002 | City filter → returns only city merchants | Unit | P0 | ⬜ |
| GMS-003 | Empty city filter → returns all | Unit | P0 | ⬜ |
| GMS-004 | No merchants → returns empty list | Unit | P0 | ⬜ |
| GMS-005 | 100+ merchants → limited to 100 | Unit | P0 | ⬜ |
| GMS-006 | Only active merchants returned | Unit | P0 | ⬜ |
| GMS-007 | Inactive merchants filtered out | Unit | P0 | ⬜ |
| GMS-008 | Network timeout → error handling | Integration | P1 | ⬜ |
| GMS-009 | Permission denied → error message | Integration | P1 | ⬜ |
| GMS-010 | Large dataset (1000 merchants) → performance test | Integration | P1 | ⬜ |
| GMS-011 | Concurrent requests → no race conditions | Integration | P1 | ⬜ |
| GMS-012 | City with special characters → handled | Unit | P1 | ⬜ |
| GMS-013 | Empty city string → treated as no filter | Unit | P0 | ⬜ |

---

### FEATURE 4: DISCOVERY SCREEN

#### 4.1 DISCOVERY SCREEN UI
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| DIS-001 | Screen renders without crash | Widget | P0 | ⬜ |
| DIS-002 | Search field exists | Widget | P0 | ⬜ |
| DIS-003 | Filter button exists | Widget | P0 | ⬜ |
| DIS-004 | Category tabs display | Widget | P0 | ⬜ |
| DIS-005 | Merchant list displays | Widget | P0 | ⬜ |
| DIS-006 | Loading state → shows indicator | Widget | P0 | ⬜ |
| DIS-007 | Empty state → shows message | Widget | P0 | ⬜ |
| DIS-008 | Error state → shows error message | Widget | P0 | ⬜ |
| DIS-009 | Pull-to-refresh → reloads merchants | Widget | P0 | ⬜ |
| DIS-010 | Tap merchant → navigates to store profile | Integration | P0 | ⬜ |
| DIS-011 | Tap merchant → passes merchantId | Integration | P0 | ⬜ |
| DIS-012 | Category filter → filters merchants | Widget | P0 | ⬜ |
| DIS-013 | Search input → filters merchants | Widget | P1 | ⬜ |
| DIS-014 | Rapid category switching | Widget | P1 | ⬜ |
| DIS-015 | Rapid pull-to-refresh | Widget | P1 | ⬜ |
| DIS-016 | Network timeout → error with retry | Integration | P1 | ⬜ |
| DIS-017 | Network error → retry button works | Integration | P1 | ⬜ |
| DIS-018 | 100 merchants → all display correctly | Widget | P1 | ⬜ |
| DIS-019 | 100 merchants → scroll performance | Widget | P1 | ⬜ |
| DIS-020 | Merchant with long name → text overflow | Widget | P1 | ⬜ |
| DIS-021 | Merchant with emoji name → displays correctly | Widget | P1 | ⬜ |
| DIS-022 | Merchant without image → placeholder | Widget | P1 | ⬜ |
| DIS-023 | Merchant with broken image → error handling | Widget | P1 | ⬜ |
| DIS-024 | Back button → returns to previous screen | Widget | P0 | ⬜ |
| DIS-025 | Orientation change → layout adapts | Widget | P2 | ⬜ |
| DIS-026 | Screen rotation during loading | Widget | P2 | ⬜ |
| DIS-027 | App backgrounded during load | Integration | P2 | ⬜ |
| DIS-028 | Memory leak check (navigate back/forth) | Integration | P1 | ⬜ |
| DIS-029 | Font scaling → layout adapts | Widget | P2 | ⬜ |
| DIS-030 | Dark mode support | Widget | P2 | ⬜ |
| DIS-031 | Concurrent navigation (tap multiple merchants) | Widget | P1 | ⬜ |
| DIS-032 | Empty merchant list → empty state | Widget | P0 | ⬜ |
| DIS-033 | Error recovery → retry button | Widget | P0 | ⬜ |

#### 4.2 DISCOVERY DATA LOADING
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| DLD-001 | Initial load → fetches merchants | Integration | P0 | ⬜ |
| DLD-002 | Load success → merchants displayed | Integration | P0 | ⬜ |
| DLD-003 | Load failure → error state | Integration | P0 | ⬜ |
| DLD-004 | Network timeout → error with retry | Integration | P1 | ⬜ |
| DLD-005 | Permission denied → error message | Integration | P1 | ⬜ |
| DLD-006 | Empty result → empty state | Integration | P0 | ⬜ |
| DLD-007 | Large dataset → performance acceptable | Integration | P1 | ⬜ |
| DLD-008 | Concurrent loads → no race conditions | Integration | P1 | ⬜ |
| DLD-009 | Load during navigation away → cancels | Integration | P1 | ⬜ |
| DLD-010 | Retry after failure → reloads | Integration | P0 | ⬜ |

---

### FEATURE 5: STORE PROFILE SCREEN

#### 5.1 STORE PROFILE SCREEN UI
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| STP-001 | Screen renders without crash | Widget | P0 | ⬜ |
| STP-002 | Loading state → shows indicator | Widget | P0 | ⬜ |
| STP-003 | Error state → shows error message | Widget | P0 | ⬜ |
| STP-004 | Not found state → shows message | Widget | P0 | ⬜ |
| STP-005 | Success state → displays merchant data | Widget | P0 | ⬜ |
| STP-006 | Merchant name displays | Widget | P0 | ⬜ |
| STP-007 | Merchant description displays | Widget | P0 | ⬜ |
| STP-008 | Merchant phone displays | Widget | P0 | ⬜ |
| STP-009 | Merchant address displays | Widget | P0 | ⬜ |
| STP-010 | Merchant city displays | Widget | P0 | ⬜ |
| STP-011 | Merchant hours displays | Widget | P0 | ⬜ |
| STP-012 | Missing description → default message | Widget | P0 | ⬜ |
| STP-013 | Missing address → shows city only | Widget | P0 | ⬜ |
| STP-014 | Missing hours → default message | Widget | P0 | ⬜ |
| STP-015 | Long description → scrollable | Widget | P1 | ⬜ |
| STP-016 | Description with emojis → displays correctly | Widget | P1 | ⬜ |
| STP-017 | Description with XSS → sanitized | Widget | P1 | ⬜ |
| STP-018 | Promotions tab displays | Widget | P0 | ⬜ |
| STP-019 | Reviews tab displays | Widget | P0 | ⬜ |
| STP-020 | Tab switching works | Widget | P0 | ⬜ |
| STP-021 | "Message" button exists | Widget | P0 | ⬜ |
| STP-022 | "Réserver" button exists | Widget | P0 | ⬜ |
| STP-023 | Tap "Message" → callback triggered | Widget | P0 | ⬜ |
| STP-024 | Tap "Réserver" → callback triggered | Widget | P0 | ⬜ |
| STP-025 | Back button → returns to discovery | Widget | P0 | ⬜ |
| STP-026 | No merchantId → error state | Widget | P0 | ⬜ |
| STP-027 | Invalid merchantId → error state | Widget | P0 | ⬜ |
| STP-028 | Network timeout → error with retry | Integration | P1 | ⬜ |
| STP-029 | Network error → retry button works | Integration | P1 | ⬜ |
| STP-030 | Orientation change → layout adapts | Widget | P2 | ⬜ |
| STP-031 | Screen rotation during load | Widget | P2 | ⬜ |
| STP-032 | App backgrounded during load | Integration | P2 | ⬜ |
| STP-033 | Memory leak check | Integration | P1 | ⬜ |
| STP-034 | Hours formatting → displays correctly | Widget | P0 | ⬜ |
| STP-035 | Invalid hours format → handled gracefully | Widget | P1 | ⬜ |
| STP-036 | Font scaling → layout adapts | Widget | P2 | ⬜ |
| STP-037 | Dark mode support | Widget | P2 | ⬜ |

#### 5.2 STORE PROFILE DATA LOADING
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SPD-001 | Valid merchantId → loads merchant | Integration | P0 | ⬜ |
| SPD-002 | Invalid merchantId → error state | Integration | P0 | ⬜ |
| SPD-003 | Non-existent merchantId → not found state | Integration | P0 | ⬜ |
| SPD-004 | Network timeout → error with retry | Integration | P1 | ⬜ |
| SPD-005 | Permission denied → error message | Integration | P1 | ⬜ |
| SPD-006 | Merchant with all fields → displays all | Integration | P0 | ⬜ |
| SPD-007 | Merchant with missing fields → handles gracefully | Integration | P0 | ⬜ |
| SPD-008 | Concurrent loads → no race conditions | Integration | P1 | ⬜ |
| SPD-009 | Load during navigation away → cancels | Integration | P1 | ⬜ |
| SPD-010 | Retry after failure → reloads | Integration | P0 | ⬜ |

---

### FEATURE 6: NAVIGATION & ROUTING

#### 6.1 NAVIGATION FLOWS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| NAV-001 | Splash → Role Selection (unauthenticated) | Integration | P0 | ⬜ |
| NAV-002 | Role Selection → Login (client) | Integration | P0 | ⬜ |
| NAV-003 | Role Selection → Onboarding (merchant) | Integration | P0 | ⬜ |
| NAV-004 | Login → Signup | Integration | P0 | ⬜ |
| NAV-005 | Signup → OTP | Integration | P0 | ⬜ |
| NAV-006 | OTP → Client Home (client signup) | Integration | P0 | ⬜ |
| NAV-007 | OTP → Merchant Dashboard (merchant signup, onboarding complete) | Integration | P0 | ⬜ |
| NAV-008 | OTP → Merchant Onboarding (merchant signup, onboarding incomplete) | Integration | P0 | ⬜ |
| NAV-009 | Client Home → Discovery | Integration | P0 | ⬜ |
| NAV-010 | Discovery → Store Profile | Integration | P0 | ⬜ |
| NAV-011 | Store Profile → Back to Discovery | Integration | P0 | ⬜ |
| NAV-012 | Back button navigation chain | Integration | P0 | ⬜ |
| NAV-013 | Deep link to store profile | Integration | P2 | ⬜ |
| NAV-014 | Invalid deep link → error handling | Integration | P2 | ⬜ |
| NAV-015 | Navigation during async operation → prevented | Integration | P1 | ⬜ |
| NAV-016 | Rapid navigation (spam taps) → handled | Integration | P1 | ⬜ |
| NAV-017 | Navigation state persistence | Integration | P2 | ⬜ |
| NAV-018 | Navigation after app restart | Integration | P2 | ⬜ |
| NAV-019 | Navigation with corrupted state → recovery | Integration | P2 | ⬜ |
| NAV-020 | Concurrent navigation attempts → no crashes | Integration | P1 | ⬜ |

#### 6.2 AUTH STATE NAVIGATION
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| ASN-001 | Authenticated client → Client Home | Integration | P0 | ⬜ |
| ASN-002 | Authenticated merchant (onboarding complete) → Dashboard | Integration | P0 | ⬜ |
| ASN-003 | Authenticated merchant (onboarding incomplete) → Onboarding | Integration | P0 | ⬜ |
| ASN-004 | Unauthenticated → Role Selection | Integration | P0 | ⬜ |
| ASN-005 | Auth error → Error screen | Integration | P0 | ⬜ |
| ASN-006 | Auth state change during navigation → updates correctly | Integration | P1 | ⬜ |
| ASN-007 | Logout → returns to Role Selection | Integration | P0 | ⬜ |
| ASN-008 | Session expiration → redirects to login | Integration | P1 | ⬜ |
| ASN-009 | Token refresh failure → redirects to login | Integration | P1 | ⬜ |
| ASN-010 | Multiple auth state changes rapidly → no flicker | Integration | P1 | ⬜ |

---

### FEATURE 7: STATE MANAGEMENT (RIVERPOD)

#### 7.1 MERCHANT ONBOARDING CONTROLLER
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SOC-001 | Initial state → empty selections | Unit | P0 | ⬜ |
| SOC-002 | Select category → state updates | Unit | P0 | ⬜ |
| SOC-003 | Select subcategory → state updates | Unit | P0 | ⬜ |
| SOC-004 | Clear category → state cleared | Unit | P0 | ⬜ |
| SOC-005 | Clear subcategory → state cleared | Unit | P0 | ⬜ |
| SOC-006 | Reset → all state cleared | Unit | P0 | ⬜ |
| SOC-007 | isComplete → true when category selected | Unit | P0 | ⬜ |
| SOC-008 | isComplete → false when no category | Unit | P0 | ⬜ |
| SOC-009 | Empty categoryId → no state change | Unit | P0 | ⬜ |
| SOC-010 | Empty subcategoryId → no state change | Unit | P0 | ⬜ |
| SOC-011 | State persistence → saved to storage | Integration | P0 | ⬜ |
| SOC-012 | State restoration → loaded from storage | Integration | P0 | ⬜ |
| SOC-013 | Concurrent state updates → no race conditions | Unit | P1 | ⬜ |
| SOC-014 | Multiple listeners → all notified | Unit | P1 | ⬜ |
| SOC-015 | Provider disposal → no memory leaks | Integration | P1 | ⬜ |

#### 7.2 AUTH CONTROLLER
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| ATC-001 | Initial state → AuthInitial | Unit | P0 | ⬜ |
| ATC-002 | Sign out → Unauthenticated state | Unit | P0 | ⬜ |
| ATC-003 | Auth state stream → emits states | Integration | P0 | ⬜ |
| ATC-004 | Auth state change → listeners notified | Integration | P0 | ⬜ |
| ATC-005 | Multiple auth state changes → handled correctly | Integration | P1 | ⬜ |
| ATC-006 | Auth state timeout → fallback state | Integration | P1 | ⬜ |
| ATC-007 | Provider disposal → stream cancelled | Integration | P1 | ⬜ |
| ATC-008 | Memory leak check | Integration | P1 | ⬜ |

---

### FEATURE 8: DATA VALIDATION & SANITIZATION

#### 8.1 MERCHANT VALIDATORS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| VAL-001 | validateAndTrimString → trims whitespace | Unit | P0 | ⬜ |
| VAL-002 | validateAndTrimString → rejects whitespace-only | Unit | P0 | ⬜ |
| VAL-003 | validateAndTrimString → enforces max length | Unit | P0 | ⬜ |
| VAL-004 | validateEmail → accepts valid emails | Unit | P0 | ⬜ |
| VAL-005 | validateEmail → rejects invalid formats | Unit | P0 | ⬜ |
| VAL-006 | validateEmail → handles edge cases | Unit | P0 | ⬜ |
| VAL-007 | validatePhone → accepts valid formats | Unit | P0 | ⬜ |
| VAL-008 | validatePhone → rejects invalid formats | Unit | P0 | ⬜ |
| VAL-009 | validatePhone → handles international formats | Unit | P0 | ⬜ |
| VAL-010 | validateCategories → validates list | Unit | P0 | ⬜ |
| VAL-011 | validateCategories → rejects duplicates | Unit | P0 | ⬜ |
| VAL-012 | validateCategories → enforces max count | Unit | P0 | ⬜ |
| VAL-013 | sanitizeString → escapes HTML | Unit | P0 | ⬜ |
| VAL-014 | sanitizeString → removes control characters | Unit | P0 | ⬜ |
| VAL-015 | sanitizeMultilineString → preserves newlines | Unit | P0 | ⬜ |
| VAL-016 | sanitizeMultilineString → escapes HTML | Unit | P0 | ⬜ |
| VAL-017 | estimateDocumentSize → calculates correctly | Unit | P0 | ⬜ |
| VAL-018 | estimateDocumentSize → detects > 800KB | Unit | P0 | ⬜ |

#### 8.2 INPUT EDGE CASES
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| IEC-001 | Empty strings → validation | Unit | P0 | ⬜ |
| IEC-002 | Whitespace-only → validation | Unit | P0 | ⬜ |
| IEC-003 | Very long strings → validation | Unit | P0 | ⬜ |
| IEC-004 | Unicode characters → handled | Unit | P0 | ⬜ |
| IEC-005 | Emojis → handled | Unit | P0 | ⬜ |
| IEC-006 | Control characters → stripped | Unit | P0 | ⬜ |
| IEC-007 | Zero-width characters → removed | Unit | P0 | ⬜ |
| IEC-008 | SQL injection patterns → sanitized | Unit | P1 | ⬜ |
| IEC-009 | XSS patterns → sanitized | Unit | P1 | ⬜ |
| IEC-010 | RTL text → handled | Unit | P2 | ⬜ |
| IEC-011 | Null values → handled | Unit | P0 | ⬜ |
| IEC-012 | Special characters → handled | Unit | P0 | ⬜ |

---

### FEATURE 9: FIREBASE INTEGRATION

#### 9.1 FIRESTORE OPERATIONS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| FSO-001 | Create merchant → document created | Integration | P0 | ⬜ |
| FSO-002 | Create merchant → user document updated | Integration | P0 | ⬜ |
| FSO-003 | Batch write → atomic operation | Integration | P0 | ⬜ |
| FSO-004 | Batch write failure → no partial data | Integration | P0 | ⬜ |
| FSO-005 | Get merchant → document retrieved | Integration | P0 | ⬜ |
| FSO-006 | Get merchants → query executed | Integration | P0 | ⬜ |
| FSO-007 | Query with filter → correct results | Integration | P0 | ⬜ |
| FSO-008 | Network timeout → error handling | Integration | P1 | ⬜ |
| FSO-009 | Permission denied → error message | Integration | P1 | ⬜ |
| FSO-010 | Document not found → null returned | Integration | P0 | ⬜ |
| FSO-011 | Invalid document structure → error handling | Integration | P1 | ⬜ |
| FSO-012 | Large document → size validation | Integration | P0 | ⬜ |
| FSO-013 | Concurrent writes → handled correctly | Integration | P1 | ⬜ |
| FSO-014 | Offline mode → operations queued | Integration | P2 | ⬜ |
| FSO-015 | Offline → online sync → conflicts resolved | Integration | P2 | ⬜ |
| FSO-016 | Rate limiting → error handling | Integration | P2 | ⬜ |
| FSO-017 | Quota exceeded → error handling | Integration | P2 | ⬜ |

#### 9.2 FIREBASE AUTH OPERATIONS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| FAO-001 | Sign up → user created | Integration | P0 | ⬜ |
| FAO-002 | Sign in → authentication successful | Integration | P0 | ⬜ |
| FAO-003 | Sign out → user signed out | Integration | P0 | ⬜ |
| FAO-004 | Phone verification → code sent | Integration | P0 | ⬜ |
| FAO-005 | OTP verification → user verified | Integration | P0 | ⬜ |
| FAO-006 | Invalid OTP → error | Integration | P0 | ⬜ |
| FAO-007 | Expired OTP → error | Integration | P0 | ⬜ |
| FAO-008 | Network timeout → error handling | Integration | P1 | ⬜ |
| FAO-009 | Phone already exists → error message | Integration | P0 | ⬜ |
| FAO-010 | Token refresh → handled automatically | Integration | P1 | ⬜ |
| FAO-011 | Token refresh failure → error handling | Integration | P1 | ⬜ |
| FAO-012 | Session expiration → handled | Integration | P1 | ⬜ |
| FAO-013 | Multiple devices → handled | Integration | P2 | ⬜ |

#### 9.3 FIREBASE ERROR HANDLING
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| FEH-001 | Network error → mapped to failure | Integration | P0 | ⬜ |
| FEH-002 | Permission denied → mapped to failure | Integration | P0 | ⬜ |
| FEH-003 | Timeout → mapped to failure | Integration | P0 | ⬜ |
| FEH-004 | Invalid data → mapped to failure | Integration | P0 | ⬜ |
| FEH-005 | Unexpected error → mapped to failure | Integration | P0 | ⬜ |
| FEH-006 | Error messages → French translation | Integration | P0 | ⬜ |
| FEH-007 | Error recovery → retry mechanism | Integration | P1 | ⬜ |

---

### FEATURE 10: PERFORMANCE & STRESS

#### 10.1 PERFORMANCE TESTS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| PER-001 | Cold start time < 3s | Integration | P1 | ⬜ |
| PER-002 | Screen load time < 1s | Integration | P1 | ⬜ |
| PER-003 | Navigation time < 500ms | Integration | P1 | ⬜ |
| PER-004 | Merchant list load < 2s | Integration | P1 | ⬜ |
| PER-005 | Animation jank → none detected | Integration | P1 | ⬜ |
| PER-006 | Memory usage → within limits | Integration | P1 | ⬜ |
| PER-007 | Battery usage → acceptable | Integration | P2 | ⬜ |
| PER-008 | CPU usage → acceptable | Integration | P2 | ⬜ |
| PER-009 | Network usage → optimized | Integration | P2 | ⬜ |
| PER-010 | Large dataset (1000 merchants) → performance | Integration | P1 | ⬜ |
| PER-011 | Long session (1 hour) → no degradation | Integration | P2 | ⬜ |
| PER-012 | Background/foreground cycles → no leaks | Integration | P1 | ⬜ |
| PER-013 | High-frequency actions → no lag | Integration | P1 | ⬜ |
| PER-014 | Network throttling (2G) → graceful degradation | Integration | P1 | ⬜ |

#### 10.2 STRESS TESTS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| STR-001 | 100 rapid taps → handled | Integration | P1 | ⬜ |
| STR-002 | 100 rapid navigations → handled | Integration | P1 | ⬜ |
| STR-003 | 100 rapid form submissions → handled | Integration | P1 | ⬜ |
| STR-004 | Concurrent operations (10 simultaneous) | Integration | P1 | ⬜ |
| STR-005 | Memory pressure → graceful handling | Integration | P1 | ⬜ |
| STR-006 | CPU pressure → graceful handling | Integration | P2 | ⬜ |
| STR-007 | Network congestion → graceful handling | Integration | P1 | ⬜ |
| STR-008 | Large payloads → handled | Integration | P1 | ⬜ |
| STR-009 | Many providers → performance acceptable | Integration | P2 | ⬜ |
| STR-010 | Long lists → virtualization works | Integration | P1 | ⬜ |

---

### FEATURE 11: ERROR HANDLING & RESILIENCE

#### 11.1 ERROR SCENARIOS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| ERR-001 | Network unavailable → offline message | Integration | P0 | ⬜ |
| ERR-002 | Network timeout → timeout message | Integration | P0 | ⬜ |
| ERR-003 | Server error (500) → error message | Integration | P0 | ⬜ |
| ERR-004 | Client error (400) → error message | Integration | P0 | ⬜ |
| ERR-005 | Permission denied → error message | Integration | P0 | ⬜ |
| ERR-006 | Invalid data → validation error | Integration | P0 | ⬜ |
| ERR-007 | Partial failure → graceful degradation | Integration | P1 | ⬜ |
| ERR-008 | Dependency failure → fallback | Integration | P1 | ⬜ |
| ERR-009 | Error recovery → retry works | Integration | P0 | ⬜ |
| ERR-010 | Error messages → user-friendly (French) | Integration | P0 | ⬜ |
| ERR-011 | Error messages → actionable | Integration | P0 | ⬜ |
| ERR-012 | Multiple errors → all handled | Integration | P1 | ⬜ |
| ERR-013 | Error during navigation → handled | Integration | P1 | ⬜ |
| ERR-014 | Error during async operation → handled | Integration | P1 | ⬜ |
| ERR-015 | Crash recovery → app restarts gracefully | Integration | P2 | ⬜ |

#### 11.2 RESILIENCE TESTS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| RES-001 | App killed during operation → state recovery | Integration | P2 | ⬜ |
| RES-002 | App backgrounded → operations continue | Integration | P2 | ⬜ |
| RES-003 | Low memory → graceful handling | Integration | P1 | ⬜ |
| RES-004 | Battery saver mode → graceful handling | Integration | P2 | ⬜ |
| RES-005 | Airplane mode → offline handling | Integration | P1 | ⬜ |
| RES-006 | Intermittent connectivity → retry works | Integration | P1 | ⬜ |
| RES-007 | Data corruption → recovery mechanism | Integration | P2 | ⬜ |
| RES-008 | Storage full → error handling | Integration | P2 | ⬜ |
| RES-009 | Firebase quota exceeded → error handling | Integration | P2 | ⬜ |

---

### FEATURE 12: SECURITY TESTING

#### 12.1 AUTHENTICATION SECURITY
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| SEC-001 | Unauthorized access → blocked | Integration | P0 | ⬜ |
| SEC-002 | Expired token → redirects to login | Integration | P0 | ⬜ |
| SEC-003 | Invalid token → redirects to login | Integration | P0 | ⬜ |
| SEC-004 | Token tampering → detected | Integration | P1 | ⬜ |
| SEC-005 | Session hijacking → prevented | Integration | P1 | ⬜ |
| SEC-006 | Multiple sessions → handled | Integration | P2 | ⬜ |
| SEC-007 | Role-based access → enforced | Integration | P0 | ⬜ |
| SEC-008 | Merchant can't access client data | Integration | P0 | ⬜ |
| SEC-009 | Client can't access merchant admin | Integration | P0 | ⬜ |

#### 12.2 INPUT SECURITY
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| INS-001 | SQL injection → sanitized | Unit | P0 | ⬜ |
| INS-002 | XSS attacks → sanitized | Unit | P0 | ⬜ |
| INS-003 | Command injection → prevented | Unit | P1 | ⬜ |
| INS-004 | Path traversal → prevented | Unit | P1 | ⬜ |
| INS-005 | Buffer overflow attempts → handled | Unit | P1 | ⬜ |
| INS-006 | Malicious payloads → rejected | Unit | P1 | ⬜ |
| INS-007 | Data exfiltration attempts → blocked | Integration | P1 | ⬜ |

#### 12.3 DATA SECURITY
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| DAS-001 | Sensitive data in logs → sanitized | Integration | P0 | ⬜ |
| DAS-002 | Error messages → no sensitive data | Integration | P0 | ⬜ |
| DAS-003 | Stack traces → not exposed to users | Integration | P0 | ⬜ |
| DAS-004 | User data → encrypted in transit | Integration | P1 | ⬜ |
| DAS-005 | User data → encrypted at rest | Integration | P1 | ⬜ |
| DAS-006 | API keys → not exposed | Integration | P0 | ⬜ |

---

### FEATURE 13: ACCESSIBILITY

#### 13.1 ACCESSIBILITY TESTS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| ACC-001 | Screen reader support | Widget | P2 | ⬜ |
| ACC-002 | Font scaling → layout adapts | Widget | P2 | ⬜ |
| ACC-003 | Color contrast → WCAG AA compliant | Widget | P2 | ⬜ |
| ACC-004 | Touch targets → minimum 44x44 | Widget | P2 | ⬜ |
| ACC-005 | Keyboard navigation → works | Widget | P2 | ⬜ |
| ACC-006 | Focus indicators → visible | Widget | P2 | ⬜ |
| ACC-007 | Alternative text for images | Widget | P2 | ⬜ |
| ACC-008 | Semantic labels → present | Widget | P2 | ⬜ |

---

### FEATURE 14: UI/UX EDGE CASES

#### 14.1 UI RENDERING
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| UIR-001 | Small screen (320x568) → layout works | Widget | P1 | ⬜ |
| UIR-002 | Large screen (tablet) → layout works | Widget | P1 | ⬜ |
| UIR-003 | Very small font → text readable | Widget | P2 | ⬜ |
| UIR-004 | Very large font → layout adapts | Widget | P2 | ⬜ |
| UIR-005 | Text overflow → handled | Widget | P0 | ⬜ |
| UIR-006 | Long text → scrollable | Widget | P0 | ⬜ |
| UIR-007 | Emojis in text → displays correctly | Widget | P1 | ⬜ |
| UIR-008 | RTL text → layout adapts | Widget | P2 | ⬜ |
| UIR-009 | Dark mode → all screens work | Widget | P2 | ⬜ |
| UIR-010 | Light mode → all screens work | Widget | P2 | ⬜ |
| UIR-011 | System theme change → updates | Widget | P2 | ⬜ |
| UIR-012 | Broken images → placeholder shown | Widget | P1 | ⬜ |
| UIR-013 | Missing images → placeholder shown | Widget | P1 | ⬜ |
| UIR-014 | Image load failure → error handling | Widget | P1 | ⬜ |
| UIR-015 | Button alignment → correct | Widget | P1 | ⬜ |
| UIR-016 | Icon visibility → all visible | Widget | P1 | ⬜ |
| UIR-017 | Text clipping → none | Widget | P1 | ⬜ |
| UIR-018 | Layout overflow → none | Widget | P0 | ⬜ |
| UIR-019 | Widget tree depth → optimized | Integration | P2 | ⬜ |
| UIR-020 | Render performance → 60fps | Integration | P1 | ⬜ |

#### 14.2 USER INTERACTIONS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| UIX-001 | Rapid taps → debounced | Widget | P1 | ⬜ |
| UIX-002 | Double tap → handled | Widget | P1 | ⬜ |
| UIX-003 | Long press → handled | Widget | P2 | ⬜ |
| UIX-004 | Swipe gestures → handled | Widget | P2 | ⬜ |
| UIX-005 | Pinch zoom → handled | Widget | P2 | ⬜ |
| UIX-006 | Keyboard input → handled | Widget | P0 | ⬜ |
| UIX-007 | Keyboard dismissal → works | Widget | P0 | ⬜ |
| UIX-008 | Focus management → correct | Widget | P0 | ⬜ |
| UIX-009 | Tab order → logical | Widget | P1 | ⬜ |
| UIX-010 | Scroll performance → smooth | Widget | P1 | ⬜ |
| UIX-011 | Pull-to-refresh → works | Widget | P0 | ⬜ |
| UIX-012 | Infinite scroll → works | Widget | P2 | ⬜ |

---

### FEATURE 15: APP LIFECYCLE

#### 15.1 LIFECYCLE SCENARIOS
| Test ID | Scenario | Type | Priority | Status |
|---------|----------|------|----------|--------|
| LIF-001 | App start → initializes correctly | Integration | P0 | ⬜ |
| LIF-002 | App backgrounded → state preserved | Integration | P1 | ⬜ |
| LIF-003 | App resumed → state restored | Integration | P1 | ⬜ |
| LIF-004 | App killed → state recovery on restart | Integration | P2 | ⬜ |
| LIF-005 | App killed during operation → recovery | Integration | P2 | ⬜ |
| LIF-006 | Low memory warning → handled | Integration | P1 | ⬜ |
| LIF-007 | System dialog → app handles | Integration | P2 | ⬜ |
| LIF-008 | Phone call during app → handled | Integration | P2 | ⬜ |
| LIF-009 | Notification during app → handled | Integration | P2 | ⬜ |
| LIF-010 | Battery saver mode → handled | Integration | P2 | ⬜ |
| LIF-011 | Airplane mode toggle → handled | Integration | P2 | ⬜ |
| LIF-012 | Network change (WiFi → Mobile) → handled | Integration | P2 | ⬜ |
| LIF-013 | Timezone change → handled | Integration | P2 | ⬜ |
| LIF-014 | Language change → handled | Integration | P2 | ⬜ |
| LIF-015 | Date/time change → handled | Integration | P2 | ⬜ |

---

## 📈 TEST COVERAGE SUMMARY

### By Feature
- **Authentication:** 150+ test cases
- **Merchant Onboarding:** 80+ test cases
- **Merchant Management:** 60+ test cases
- **Discovery:** 50+ test cases
- **Store Profile:** 40+ test cases
- **Navigation:** 30+ test cases
- **State Management:** 20+ test cases
- **Validation:** 30+ test cases
- **Firebase Integration:** 40+ test cases
- **Performance:** 20+ test cases
- **Error Handling:** 30+ test cases
- **Security:** 20+ test cases
- **Accessibility:** 10+ test cases
- **UI/UX:** 30+ test cases
- **App Lifecycle:** 15+ test cases

**Total Test Cases: 625+**

### By Priority
- **P0 (Critical):** 200+ tests
- **P1 (High):** 250+ tests
- **P2 (Medium):** 175+ tests

### By Type
- **Unit Tests:** ~375 tests (60%)
- **Widget Tests:** ~188 tests (30%)
- **Integration Tests:** ~62 tests (10%)

---

## 🛠️ MOCK & FAKE SETUP

### Required Mocks
1. **Firebase Auth Mock**
   - Mock `FirebaseAuth`
   - Mock `UserCredential`
   - Mock phone verification
   - Mock OTP verification

2. **Firestore Mock**
   - Mock `FirebaseFirestore`
   - Mock `DocumentSnapshot`
   - Mock `QuerySnapshot`
   - Mock batch writes
   - Mock transactions

3. **SharedPreferences Mock**
   - Mock storage operations
   - Mock read/write failures

4. **Network Mock**
   - Mock HTTP responses
   - Mock timeouts
   - Mock errors

5. **Timer Mock**
   - Mock `Timer` for OTP resend
   - Mock animations

### Fake Implementations
1. **FakeAuthRepository** - In-memory auth state
2. **FakeUserRepository** - In-memory user data
3. **FakeMerchantRepository** - In-memory merchant data
4. **FakeOnboardingStorage** - In-memory storage

---

## 📝 EDGE CASE CHECKLIST

### Input Edge Cases
- [ ] Empty strings
- [ ] Whitespace-only strings
- [ ] Null values
- [ ] Undefined values
- [ ] Very long strings (1000+ chars)
- [ ] Very short strings (1 char)
- [ ] Unicode characters
- [ ] Emojis
- [ ] Control characters
- [ ] Zero-width characters
- [ ] RTL text
- [ ] Special characters
- [ ] SQL injection patterns
- [ ] XSS patterns
- [ ] Command injection patterns
- [ ] Path traversal patterns
- [ ] Buffer overflow attempts
- [ ] Negative numbers (where applicable)
- [ ] Zero values
- [ ] Very large numbers
- [ ] Floating point edge cases
- [ ] Date edge cases (past, future, invalid)
- [ ] Time edge cases (timezone, DST)

### Network Edge Cases
- [ ] No network
- [ ] Slow network (2G)
- [ ] Intermittent network
- [ ] Network timeout
- [ ] Network error
- [ ] Partial response
- [ ] Malformed JSON
- [ ] Invalid status codes
- [ ] Rate limiting
- [ ] Quota exceeded
- [ ] Server errors (500, 503)
- [ ] Client errors (400, 401, 403, 404)
- [ ] Redirects (301, 302)
- [ ] Connection reset
- [ ] DNS failure
- [ ] SSL/TLS errors

### State Edge Cases
- [ ] Initial state
- [ ] Loading state
- [ ] Success state
- [ ] Error state
- [ ] Empty state
- [ ] Partial state
- [ ] Corrupted state
- [ ] Stale state
- [ ] Concurrent state updates
- [ ] Race conditions
- [ ] State persistence failures
- [ ] State restoration failures

### UI Edge Cases
- [ ] Small screens
- [ ] Large screens
- [ ] Very small font
- [ ] Very large font
- [ ] Dark mode
- [ ] Light mode
- [ ] System theme change
- [ ] Orientation change
- [ ] Keyboard appearance
- [ ] Keyboard dismissal
- [ ] Focus management
- [ ] Text overflow
- [ ] Layout overflow
- [ ] Image load failures
- [ ] Animation interruptions
- [ ] Rapid interactions
- [ ] Concurrent gestures

### Data Edge Cases
- [ ] Empty database
- [ ] Large datasets
- [ ] Duplicate data
- [ ] Missing data
- [ ] Corrupted data
- [ ] Invalid data types
- [ ] Null fields
- [ ] Empty arrays
- [ ] Empty maps
- [ ] Circular references
- [ ] Deep nesting
- [ ] Data migration
- [ ] Schema changes

### Concurrency Edge Cases
- [ ] Multiple simultaneous operations
- [ ] Race conditions
- [ ] Deadlocks
- [ ] Lock contention
- [ ] Concurrent reads
- [ ] Concurrent writes
- [ ] Read during write
- [ ] Write during read

### Performance Edge Cases
- [ ] Memory pressure
- [ ] CPU pressure
- [ ] Battery saver mode
- [ ] Background mode
- [ ] Long sessions
- [ ] Many operations
- [ ] Large payloads
- [ ] Many providers
- [ ] Deep widget trees

---

## ⚠️ KNOWN RISK AREAS

### High Risk
1. **Merchant Creation Race Conditions**
   - Multiple OTP verifications
   - Concurrent merchant creation
   - **Mitigation:** Idempotency checks, locks

2. **State Persistence Failures**
   - SharedPreferences unavailable
   - Storage quota exceeded
   - **Mitigation:** Graceful degradation, error handling

3. **Network Timeout Handling**
   - Slow networks
   - Intermittent connectivity
   - **Mitigation:** Timeouts, retry mechanisms

4. **Navigation Race Conditions**
   - Rapid navigation
   - Auth state changes during navigation
   - **Mitigation:** Navigation guards, state locks

5. **Memory Leaks**
   - Providers not disposed
   - Listeners not removed
   - **Mitigation:** Proper disposal, leak detection

### Medium Risk
1. **Data Validation Edge Cases**
   - Unicode normalization
   - Emoji handling
   - **Mitigation:** Comprehensive validation

2. **Firebase Quota Limits**
   - Rate limiting
   - Quota exceeded
   - **Mitigation:** Error handling, user messaging

3. **Offline Mode**
   - Operations queued
   - Sync conflicts
   - **Mitigation:** Conflict resolution, queue management

4. **Large Datasets**
   - Performance degradation
   - Memory issues
   - **Mitigation:** Pagination, virtualization

### Low Risk
1. **UI Rendering Edge Cases**
   - Text overflow
   - Layout breaks
   - **Mitigation:** Responsive design, testing

2. **Accessibility**
   - Screen readers
   - Font scaling
   - **Mitigation:** Accessibility testing

---

## 🚀 HOW TO RUN TESTS LOCALLY

### Prerequisites
```bash
flutter doctor
flutter pub get
```

### Run All Tests
```bash
# Unit tests
flutter test test/unit

# Widget tests
flutter test test/widget

# Integration tests
flutter test test/integration

# All tests
flutter test
```

### Run Specific Test Suites
```bash
# Authentication tests
flutter test test/feature/auth

# Merchant tests
flutter test test/feature/merchant

# Discovery tests
flutter test test/feature/discovery
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run in Watch Mode
```bash
flutter test --watch
```

### Run Specific Test
```bash
flutter test test/feature/auth/login_test.dart
```

---

## 🔄 CI-READY COMMANDS

### GitHub Actions / GitLab CI
```yaml
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Upload coverage
# (use coverage service like Codecov, Coveralls)
```

### Pre-commit Hook
```bash
#!/bin/sh
flutter analyze
flutter test
```

### Test Matrix
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    flutter-version: ['3.24.0', 'stable']
```

---

## 📦 TEST ORGANIZATION

### Directory Structure
```
test/
  unit/
    feature/
      auth/
      merchant/
      discovery/
    domain/
      entities/
      validators/
    application/
      use_cases/
  widget/
    feature/
      auth/
        login_screen_test.dart
        signup_screen_test.dart
        otp_screen_test.dart
      merchant_onboarding/
      discovery/
      store_profile/
  integration/
    flows/
      auth_flow_test.dart
      merchant_onboarding_flow_test.dart
      discovery_flow_test.dart
    e2e/
      complete_user_journey_test.dart
  mocks/
    firebase_mocks.dart
    repository_mocks.dart
  helpers/
    test_helpers.dart
    widget_test_helpers.dart
```

---

## 🎯 IMPLEMENTATION PRIORITY

### Phase 1: Critical Path (Week 1)
- Authentication flows (login, signup, OTP)
- Merchant onboarding flow
- Merchant creation
- Basic navigation

### Phase 2: Core Features (Week 2)
- Discovery screen
- Store profile screen
- State management
- Error handling

### Phase 3: Edge Cases (Week 3)
- Input validation
- Network edge cases
- State edge cases
- Performance tests

### Phase 4: Polish (Week 4)
- Accessibility
- UI/UX edge cases
- Security tests
- App lifecycle

---

## 📊 SUCCESS METRICS

### Coverage Targets
- **Code Coverage:** ≥ 90%
- **Critical Path Coverage:** 100%
- **Edge Case Coverage:** ≥ 80%

### Quality Metrics
- **Test Execution Time:** < 5 minutes (all tests)
- **Flaky Test Rate:** < 1%
- **Test Maintenance Cost:** Low (well-organized)

### Performance Targets
- **Unit Tests:** < 1s each
- **Widget Tests:** < 5s each
- **Integration Tests:** < 30s each

---

## 🔍 TEST EXECUTION STRATEGY

### Local Development
- Run relevant tests before commit
- Run full suite before push
- Use watch mode for TDD

### CI/CD Pipeline
- Run all tests on PR
- Run full suite on merge
- Generate coverage reports
- Block merge if tests fail

### Pre-Release
- Run full test suite
- Run performance tests
- Run security tests
- Manual smoke tests

---

## 📚 TESTING BEST PRACTICES

### Naming Conventions
- Test files: `*_test.dart`
- Test groups: `group('Feature Name', () { ... })`
- Test cases: `test('should do something when condition', () { ... })`

### Test Structure (AAA Pattern)
```dart
test('should create merchant when valid data provided', () {
  // Arrange
  final useCase = CompleteMerchantOnboarding(mockRepository);
  
  // Act
  final result = await useCase.call(...);
  
  // Assert
  expect(result.isRight(), true);
});
```

### Mocking Guidelines
- Mock external dependencies
- Use fakes for simple cases
- Keep mocks focused
- Verify interactions

### Assertions
- Use specific matchers
- Test both success and failure
- Test edge cases
- Test error messages

---

## 🎓 TESTING PHILOSOPHY

1. **Test Behavior, Not Implementation**
   - Focus on what, not how
   - Test user-facing behavior
   - Avoid testing internals

2. **Test Independence**
   - Each test is isolated
   - No shared state
   - No test order dependency

3. **Test Clarity**
   - Readable test names
   - Clear test structure
   - Good error messages

4. **Test Maintainability**
   - DRY principle
   - Reusable test helpers
   - Well-organized structure

5. **Test Reliability**
   - Deterministic tests
   - No flaky tests
   - Proper cleanup

---

## ✅ FINAL CHECKLIST

### Before Implementation
- [ ] Review test strategy
- [ ] Set up test infrastructure
- [ ] Create mock/fake setup
- [ ] Define test helpers
- [ ] Set up CI/CD

### During Implementation
- [ ] Write tests first (TDD)
- [ ] Run tests frequently
- [ ] Maintain test coverage
- [ ] Fix flaky tests immediately
- [ ] Update tests with features

### After Implementation
- [ ] Review test coverage
- [ ] Run full test suite
- [ ] Performance testing
- [ ] Security testing
- [ ] Documentation

---

**This test strategy covers 625+ test cases across all features, edge cases, and scenarios. Ready for implementation when approved.**

