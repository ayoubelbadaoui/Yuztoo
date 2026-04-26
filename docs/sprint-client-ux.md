# Sprint Plan — Client Side UI/UX Polish
_Goal: Every client screen meets the same visual quality bar as the polished merchant side._

---

## Issues Found (Full Audit)

| # | Screen | Issue | Severity |
|---|--------|--------|----------|
| U1 | Personal Info | Completion % pill text color: `bgHeader` (dark navy) on no-fill background = **invisible** | 🔴 Bug |
| U2 | Personal Info | "Créer un compte pro" uses `ElevatedButton` — style guide violation | 🔴 |
| U3 | Personal Info | "Créer un compte pro" `onPressed: () {}` — dead button | 🔴 |
| U4 | Discovery | Search field: white pill (`fillColor: textWhite`, `Colors.black` text) on dark bg — visually jarring | 🔴 |
| U5 | Discovery | "Invite un commerçant" uses `ElevatedButton` — style guide violation | 🔴 |
| U6 | Carnet | `IconButton` for QR button — style guide violation | 🟠 |
| U7 | Carnet | Empty state uses `OutlinedButton.icon` — style guide violation | 🟠 |
| U8 | Carnet | Merchant card: no container/border — no card visual | 🟠 |
| U9 | Carnet | Placeholder image: "Image commerce" text on gold-cream gradient — cheap, off-brand | 🟠 |
| U10 | Loyalty | `IconButton` for notifications bell — style guide violation | 🟠 |
| U11 | Loyalty | Header plain "Fidélité" — spec says personalized "Bonjour [prénom] 👋" | 🟠 |
| U12 | Loyalty | Loading skeleton = plain dark boxes — no shimmer | 🟡 |
| U13 | Loyalty | Loyalty cards not tappable — no navigation to store profile | 🟠 |
| U14 | Client Profile | `_PaymentStubScreen` uses `AppBar` — inconsistent top bar | 🟡 |
| U15 | Discovery | Promo banner is dead placeholder ("À venir…") — unfinished look | 🟡 |
| U16 | Discovery | Grid card: corner radius 8px, no category badge — inconsistent | 🟡 |
| U17 | Carnet | Tagline "Tous les commerces…" plain centered text — no visual hierarchy | 🟡 |
| U18 | Carnet | Quick actions: only `top` border, no separation from content | 🟡 |
| U19 | Personal Info | "Présentez votre carte Yuztoo" is a dead placeholder container | 🟡 |
| U20 | Cities picker | `ListTile` items have no dark styling (default light theme bleeds through) | 🟡 |
| U21 | Notifications | `TextButton` "Tout lire" — minor style guide inconsistency | 🟢 |

---

## Sprint P1 — Critical Bug Fixes (XS · ship first)

**U1** — Fix completion % pill text color  
**U2 + U3** — Replace `ElevatedButton` "Créer un compte pro" with gradient GestureDetector  
**U4** — Discovery search field: match carnet dark-themed search (dark bg + gold border + white text)  
**U5** — Discovery "Invite un commerçant": `ElevatedButton` → gradient GestureDetector  

**Files:** `personal_information_screen.part.dart`, `discovery_screen.part.dart`

---

## Sprint P2 — IconButton → GestureDetector replacements (XS)

**U6** — Carnet QR `IconButton` → `GestureDetector` with gold icon  
**U10** — Loyalty notifications `IconButton` → `GestureDetector`  
**U21** — Notifications "Tout lire" `TextButton` → `GestureDetector`  

**Files:** `client_home_screen.part.dart`, `loyalty_cards_screen.part.dart`, `notifications_screen.part.dart`

---

## Sprint P3 — Discovery screen full polish (S)

**U15** — Remove dead promo banner; replace with a real "Explore la ville" hero section  
**U16** — Grid card: radius 12px, add category badge pill at bottom-left  
  
**Files:** `discovery_screen.part.dart`

---

## Sprint P4 — Carnet card & empty state polish (S)

**U7** — Empty state: `OutlinedButton.icon` → gradient GestureDetector style  
**U8** — Merchant card: wrap in `Container` with `bgHeader` bg + gold border radius 14  
**U9** — Placeholder image: dark navy bg + centered `Icons.storefront_outlined` gold icon  
**U17** — Tagline: upgrade to gradient ShaderMask title + subtitle layout  
**U18** — Quick actions: full card container (bg + border) wrapping the 3 icons  

**Files:** `client_home_screen.part.dart`

---

## Sprint P5 — Loyalty screen full polish (S)

**U11** — Personalized greeting: watch `userProfileBasicsProvider` → "Bonjour [prénom] 👋" + mini-summary (N commerces, total passages)  
**U12** — Animated shimmer for loading skeleton  
**U13** — Make `_MerchantLoyaltyCard` tappable: `GestureDetector` → `onStoreTap` callback → navigate to store profile  

**Files:** `loyalty_cards_screen.dart`, `loyalty_cards_screen.part.dart`

---

## Sprint P6 — Personal info & client profile housekeeping (XS)

**U3** — Wire "Créer un compte pro" → navigate to merchant onboarding signup (call `onNavigate('merchant-signup')` or show a modal)  
**U14** — `_PaymentStubScreen`: replace `AppBar` with custom top bar (same pattern as `DataPrivacyScreen`)  
**U19** — "Présentez votre carte Yuztoo" placeholder: add actual QR card visual using current user's name initial  

**Files:** `personal_information_screen.part.dart`, `client_profile_screen.part.dart`

---

## Sprint P7 — Cities picker dark theme (XS)

**U20** — `ListTile` items in city picker: replace with a custom `GestureDetector` row styled in dark navy  

**Files:** `personal_information_screen.part.dart`

---

## Execution order

| Sprint | Effort | Impact | Items |
|--------|--------|--------|-------|
| P1 — critical bugs | XS | 🔴🔴🔴 | U1 U2 U3 U4 U5 |
| P2 — IconButton sweep | XS | 🟠🟠 | U6 U10 U21 |
| P3 — Discovery polish | S | 🟠🟠🟠 | U15 U16 |
| P4 — Carnet card polish | S | 🟠🟠🟠 | U7 U8 U9 U17 U18 |
| P5 — Loyalty polish | S | 🟠🟠🟠 | U11 U12 U13 |
| P6 — Profile housekeeping | XS | 🟡🟡 | U3 U14 U19 |
| P7 — Cities dark theme | XS | 🟡 | U20 |
