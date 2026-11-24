# Yuztoo — 500 Test Scenarios Plan

Generated from **application code** (features, domain policies, Cloud Function triggers), not product docs.

## How to use
- **P0**: must pass before release
- **P1**: should pass for solid beta
- **P2**: polish / scale / a11y
- **Role**: `client` | `merchant` | `dual` | `guest` | `any` | `both` (client+merchant devices)
- Traceability: map failures to feature folders under `lib/feature/`

## Coverage map
- **Auth & session**: 55 scenarios
- **Client home & shell**: 40 scenarios
- **Discovery**: 50 scenarios
- **Store profile & follow**: 50 scenarios
- **Loyalty, passage, QR, BLE**: 101 scenarios
- **Merchant onboarding**: 40 scenarios
- **Merchant CRM, promos, rappels, settings**: 64 scenarios
- **Notifications, profile, messages**: 55 scenarios
- **Cross-cutting, permissions, BG, security**: 45 scenarios

Priority mix: {'P0': 142, 'P1': 294, 'P2': 64}

## Domain rules encoded in scenarios
- Loyalty: `LoyaltyTriggerType` visitCount / purchaseTotal; reward kinds; auto vs manual passage
- Passage: cooldown, BLE vs QR/NFC auto-confirm rules (`loyalty_passage_program_policy.dart` + functions)
- Auto notifications: wired triggers in `AutoNotificationTriggers` (excludes unwired `Visite client détectée` from merchant pickers)
- Quota: `kFreePlanWeeklyNotificationQuotaEnabled` currently **false** (unlimited manual); scenarios include future enablement
- Roles: `UserRole.client` / `merchant` + dual + guest shell

---

## Scenarios

| ID | Pri | Role | Area | Scenario | Steps | Expected |
|---:|:---:|:---:|:-----|:---------|:------|:---------|
| T-001 | P0 | any | Auth & session | Cold start splash then route by auth state | Kill app → open → wait splash | Authenticated users reach role shell; guests reach login/role; no infinite splash |
| T-002 | P0 | any | Auth & session | Login email/password success | Valid credentials → submit | Home/shell for that role; session persisted |
| T-003 | P0 | any | Auth & session | Login wrong password | Valid email, wrong password | Error snack/message; stay on login; no partial session |
| T-004 | P0 | any | Auth & session | Login unknown email | Unknown email | Clear auth error; not crash |
| T-005 | P0 | any | Auth & session | Login empty fields validation | Submit empty email/password | Field validation; no network call or rejected early |
| T-006 | P0 | any | Auth & session | Login invalid email format | Bad email string | Validation error |
| T-007 | P1 | any | Auth & session | Login network offline | Airplane mode → login | Graceful failure message |
| T-008 | P0 | any | Auth & session | Signup email creates account | New email + password + role path | Account created; OTP or next step as coded |
| T-009 | P0 | any | Auth & session | Signup duplicate email | Existing email | Failure with readable message |
| T-010 | P0 | any | Auth & session | OTP correct code | Enter valid OTP | Proceed to onboarding/home |
| T-011 | P0 | any | Auth & session | OTP wrong code | Enter invalid OTP | Error; can retry |
| T-012 | P0 | any | Auth & session | OTP resend | Tap resend | New code path works; rate-limit if any |
| T-013 | P1 | any | Auth & session | OTP expired code | Wait expiry → submit old | Rejected with message |
| T-014 | P0 | any | Auth & session | OAuth Google success | Complete Google OAuth | Lands oauth completion or shell |
| T-015 | P0 | any | Auth & session | OAuth Apple success | Complete Apple OAuth | Same as Google path |
| T-016 | P1 | any | Auth & session | OAuth cancel mid-flow | Cancel provider sheet | Back to login/signup; no half account |
| T-017 | P0 | any | Auth & session | OAuth completion missing profile fields | OAuth user incomplete | Forced to complete profile |
| T-018 | P0 | any | Auth & session | Logout clears session | Logout from settings/profile | Back to auth; protected routes blocked |
| T-019 | P0 | any | Auth & session | Session restore after kill | Login → kill → reopen | Still authenticated |
| T-020 | P1 | any | Auth & session | Token refresh while using app | Use app for long session | No unexpected logout; or soft reauth |
| T-021 | P0 | client | Auth & session | Role selection client | Pick client | Client shell / onboarding |
| T-022 | P0 | merchant | Auth & session | Role selection merchant | Pick merchant | Merchant onboarding/shell |
| T-023 | P0 | dual | Auth & session | Dual profile switch client→merchant | User with both roles → switch | Correct shell; data for merchant |
| T-024 | P0 | dual | Auth & session | Dual profile switch merchant→client | Switch back | Client shell; no merchant UI leak |
| T-025 | P1 | any | Auth & session | Password rules reject weak password | Too short password on signup | Validation before create |
| T-026 | P1 | any | Auth & session | Legal links from auth | Open CGU/privacy from signup | Legal document screen loads |
| T-027 | P2 | any | Auth & session | Keyboard dismiss on auth forms | Tap outside fields | Keyboard closes |
| T-028 | P1 | any | Auth & session | Back from OTP to signup | Back navigation | State coherent; can re-edit |
| T-029 | P1 | any | Auth & session | Auth SystemUI colors | Check status/nav bar on login/signup/OTP | Match MerchantColors / design rules |
| T-030 | P0 | any | Auth & session | Delete account from privacy | Confirm delete | Account gone; cannot login; data deletion path |
| T-031 | P1 | any | Auth & session | Delete account cancel | Open delete → cancel | Account remains |
| T-032 | P0 | any | Auth & session | Blocked user cannot use app | User status blocked if supported | Denied access / message |
| T-033 | P1 | guest | Auth & session | Guest shell browse limits | Open as guest | Can see allowed guest UI; blocked actions prompt login |
| T-034 | P1 | guest | Auth & session | Guest attempt follow merchant | Try follow | Login required |
| T-035 | P1 | guest | Auth & session | Guest attempt QR scan loyalty | Try scan | Login or blocked |
| T-036 | P0 | client | Auth & session | Client onboarding complete name+city+photo | Fill required → save | onComplete; home; profile cache refresh |
| T-037 | P0 | client | Auth & session | Client onboarding skip photo if allowed | Save without photo | Succeeds or validates per rules |
| T-038 | P0 | client | Auth & session | Client onboarding validation missing name | Empty name | Blocked with error |
| T-039 | P1 | client | Auth & session | Client onboarding city picker | Select city | Persisted on user |
| T-040 | P1 | client | Auth & session | Client onboarding DOB | Set date of birth | Saved; used later for birthday trigger |
| T-041 | P1 | client | Auth & session | Client onboarding after OAuth | OAuth → completion → onboarding | No splash stuck loop |
| T-042 | P0 | client | Auth & session | Client onboarding failure shows snackbar | Force repo failure | Error message; can retry |
| T-043 | P1 | any | Auth & session | Deep link while logged out | Open store/loyalty link | Auth first then continue if coded |
| T-044 | P1 | any | Auth & session | Deep link while logged in | Open link authenticated | Correct screen |
| T-045 | P2 | any | Auth & session | Multiple rapid login taps | Spam login button | No double account / single in-flight |
| T-046 | P2 | any | Auth & session | Signup then immediate login | New account → login elsewhere | Works |
| T-047 | P1 | any | Auth & session | Email verification if required | Unverified email edge | Follow app rule |
| T-048 | P1 | merchant | Auth & session | Merchant cannot finish without onboarding | New merchant incomplete | Forced onboarding flow |
| T-049 | P0 | any | Auth & session | Loading screen appears on cold start | Observe cold start | Loading/splash then destination |
| T-050 | P2 | any | Auth & session | Accessibility large text on login | Increase text size | Fields usable |
| T-051 | P1 | any | Auth & session | Logout from merchant settings | Logout | Clears merchant session |
| T-052 | P1 | any | Auth & session | Logout from client profile | Logout | Clears client session |
| T-053 | P2 | any | Auth & session | Switch language if l10n | Change locale | Auth strings update |
| T-054 | P1 | any | Auth & session | Airplane mode during OTP | Offline OTP submit | Error; app stable |
| T-055 | P0 | any | Auth & session | Re-login after delete fails | Delete → login same creds | Fails as expected |
| T-056 | P0 | client | Client home & shell | Client home loads followed merchants | Open home with follows | Carnet list shows merchants |
| T-057 | P0 | client | Client home & shell | Client home empty carnet | No follows | Empty state CTA to discovery |
| T-058 | P0 | client | Client home & shell | Pull to refresh carnet | Pull refresh | Data reloads; no duplicate rows |
| T-059 | P1 | client | Client home & shell | Carnet order stable | Reorder if supported / default order | Order matches domain carnet_merchant_order |
| T-060 | P0 | client | Client home & shell | Tap merchant opens store profile | Tap card | Store profile for that id |
| T-061 | P1 | client | Client home & shell | Home notifications badge | Unread notifs | Badge/count correct |
| T-062 | P1 | client | Client home & shell | Home dual-profile switch entry | Dual user | Can switch to merchant |
| T-063 | P1 | client | Client home & shell | Home offline cached view | Offline open | Graceful empty/error; no crash |
| T-064 | P1 | client | Client home & shell | Home loyalty progress chips | Merchant with progress | Shows passages/reward state |
| T-065 | P2 | client | Client home & shell | Home image load failure | Broken photo URL | Placeholder; no crash |
| T-066 | P0 | client | Client home & shell | Navigate discovery from home | Tap Découvrir | Discovery screen |
| T-067 | P0 | client | Client home & shell | Navigate QR from home/shell | Open scanner | Camera permission flow |
| T-068 | P0 | client | Client home & shell | Navigate loyalty cards | Open fidélité | Loyalty cards screen |
| T-069 | P0 | client | Client home & shell | Navigate profile | Open profile | Client profile |
| T-070 | P0 | client | Client home & shell | Navigate messages | Open messages | Messages (even if mock) |
| T-071 | P0 | client | Client home & shell | Navigate notifications | Open notifications | Notifications list |
| T-072 | P1 | client | Client home & shell | Back stack from store profile to home | Open store → back | Returns home |
| T-073 | P1 | client | Client home & shell | System back Android from home | System back | Exit or shell behavior OK |
| T-074 | P2 | client | Client home & shell | Rotate device on home | Rotate | Layout OK |
| T-075 | P1 | client | Client home & shell | Home SystemUI cream/white | Check bars | Match client light theme |
| T-076 | P1 | client | Client home & shell | Carnet merchant disabled/hidden | Follow removed merchant | Handled; no crash |
| T-077 | P1 | client | Client home & shell | Carnet after unfollow | Unfollow from profile → home | Removed from list |
| T-078 | P1 | client | Client home & shell | Carnet after follow | Follow → home | Appears |
| T-079 | P2 | client | Client home & shell | Slow network skeleton | Throttle network | Loading indicators |
| T-080 | P1 | client | Client home & shell | Deep link to home tab | Link to home | Correct tab |
| T-081 | P2 | client | Client home & shell | Home memory after many navigations | Open/close stores 20× | No jank crash |
| T-082 | P1 | client | Client home & shell | BLE broadcast entry from loyalty path | Open client BLE screen | Broadcast UI |
| T-083 | P0 | client | Client home & shell | Account preferences entry | Open prefs | Prefs screen |
| T-084 | P1 | client | Client home & shell | Personal information entry | Open personal info | Form loads user data |
| T-085 | P1 | client | Client home & shell | Yuztoo contact from profile | Open contact | Contact screen |
| T-086 | P2 | client | Client home & shell | Home pull refresh during navigation | Refresh then tap | No race crash |
| T-087 | P1 | client | Client home & shell | Empty state CTA works | Tap empty CTA | Goes discovery |
| T-088 | P2 | client | Client home & shell | Very long merchant name | Long name in carnet | Truncates/ellipsis |
| T-089 | P1 | client | Client home & shell | City-filtered discovery from home context | User city set | Discovery respects city where coded |
| T-090 | P2 | client | Client home & shell | Home dark mode N/A | App forced theme | Consistent |
| T-091 | P1 | client | Client home & shell | Notifications permission prompt | First notif-related action | OS prompt; deny/allow paths |
| T-092 | P1 | client | Client home & shell | Allow notifications then receive | Allow → merchant sends | Appears in list / tray |
| T-093 | P1 | client | Client home & shell | Deny notifications | Deny permission | App still usable |
| T-094 | P2 | client | Client home & shell | Home analytics no crash | Open home | No exception |
| T-095 | P0 | client | Client home & shell | Shell bottom nav all tabs | Tap each tab | Correct screens |
| T-096 | P0 | client | Discovery | Discovery loads merchants | Open discovery | Lists featured/grid |
| T-097 | P0 | client | Discovery | Discovery search finds merchant | Type known name | Results scored/fuzzy |
| T-098 | P0 | client | Discovery | Discovery search empty query | Clear search | Back to default lists |
| T-099 | P1 | client | Discovery | Discovery search no results | Nonsense query | Empty results UI |
| T-100 | P1 | client | Discovery | Discovery search debounce | Type fast | Not one request per key ideally |
| T-101 | P1 | client | Discovery | Discovery proche filter | Enable proche | Filters by proximity logic |
| T-102 | P1 | client | Discovery | Discovery proche without location permission | Deny location | Filter disabled or prompt |
| T-103 | P1 | client | Discovery | Discovery association filter | Toggle association | List updates |
| T-104 | P1 | client | Discovery | Discovery recommended partners | Open recommended section | Shows partners logic |
| T-105 | P1 | client | Discovery | Discovery followed section | Has follows | Followed merchants section |
| T-106 | P1 | client | Discovery | Discovery artiste merchants | Open artiste bucket | Correct category set |
| T-107 | P1 | client | Discovery | Discovery city merchants | User city Casablanca | City list |
| T-108 | P0 | client | Discovery | Discovery tap opens store profile | Tap card | Correct merchant id |
| T-109 | P1 | client | Discovery | Discovery pull refresh | Pull | Invalidates providers; fresh data |
| T-110 | P1 | client | Discovery | Discovery subscription visibility | Free vs paid merchants | Visibility rules applied |
| T-111 | P1 | client | Discovery | Discovery offline | Offline open | Error/empty; stable |
| T-112 | P2 | client | Discovery | Discovery image placeholders | Slow images | Placeholders |
| T-113 | P1 | client | Discovery | Discovery SystemUI | Check bars | Client styling |
| T-114 | P2 | client | Discovery | Discovery scroll performance | Scroll long list | No freeze on 8GB device |
| T-115 | P1 | client | Discovery | Discovery share merchant if available | Share action | Share sheet |
| T-116 | P1 | client | Discovery | Discovery back to home | Back | Home |
| T-117 | P2 | client | Discovery | Discovery special characters search | é, à, spaces | Fuzzy normalize works |
| T-118 | P1 | client | Discovery | Discovery limit 200 merchants search path | Large catalog | Search still returns something; documents limit risk |
| T-119 | P2 | client | Discovery | Discovery dual role entry | From dual shell | Works |
| T-120 | P1 | guest | Discovery | Guest discovery browse | Guest open discovery | Read-only OK |
| T-121 | P1 | guest | Discovery | Guest cannot follow from discovery | Follow | Login gate |
| T-122 | P2 | client | Discovery | Discovery category chips | Select category | Filters |
| T-123 | P2 | client | Discovery | Discovery clear filters | Reset | Full list |
| T-124 | P1 | client | Discovery | Discovery merchant without photo | Null photo | Placeholder |
| T-125 | P1 | client | Discovery | Discovery merchant without city | Null city | Still listed or filtered per rules |
| T-126 | P2 | client | Discovery | Discovery reopen caches | Leave and return | Data sensible |
| T-127 | P1 | client | Discovery | Discovery error state retry | Force provider error | Retry control if any |
| T-128 | P2 | client | Discovery | Discovery accessibility | VoiceOver labels | Tappable cards labeled |
| T-129 | P1 | client | Discovery | Discovery from notifications deep link | Notif → store | Opens profile |
| T-130 | P2 | client | Discovery | Discovery map N/A | No map crash | OK |
| T-131 | P1 | client | Discovery | Discovery followed then unfollow refresh | Unfollow elsewhere → refresh | Section updates |
| T-132 | P2 | client | Discovery | Discovery RTL N/A | LTR French | OK |
| T-133 | P1 | client | Discovery | Discovery search by subcategory | Search subcategory label | Match |
| T-134 | P1 | client | Discovery | Discovery search by category id label | Search category | Match |
| T-135 | P2 | client | Discovery | Discovery keyboard search submit | Keyboard search | Triggers search |
| T-136 | P1 | client | Discovery | Discovery simultaneous refresh+search | Refresh while typing | No crash |
| T-137 | P2 | client | Discovery | Discovery low memory | Background many apps | Recovers |
| T-138 | P1 | client | Discovery | Discovery merchant type filter | Filter type | Applied |
| T-139 | P1 | client | Discovery | Discovery recommended empty | No partners | Empty section |
| T-140 | P0 | client | Discovery | Discovery notifications icon | Tap bell | Notifications |
| T-141 | P2 | client | Discovery | Discovery long press N/A | Long press | No crash |
| T-142 | P1 | client | Discovery | Discovery after onboarding city set | Set city → discovery | City scoped |
| T-143 | P1 | client | Discovery | Discovery without city | No city | Fallback list |
| T-144 | P2 | client | Discovery | Discovery analytics events | Open/search | No crash |
| T-145 | P1 | client | Discovery | Discovery blocked merchant hidden | If safety block | Not shown or blocked open |
| T-146 | P0 | client | Store profile & follow | Store profile loads by id | Open merchant | Banner, name, info |
| T-147 | P0 | client | Store profile & follow | Store profile invalid id | Bad id | Error/empty; no crash |
| T-148 | P0 | client | Store profile & follow | Follow merchant | Tap follow | followed_merchants write; UI followed |
| T-149 | P0 | client | Store profile & follow | Unfollow merchant | Unfollow | Removed; CRM loses follower |
| T-150 | P1 | client | Store profile & follow | Follow while offline | Offline follow | Error; not fake success |
| T-151 | P1 | client | Store profile & follow | Store hours display | Merchant with hours | Correct open/closed if coded |
| T-152 | P1 | client | Store profile & follow | Store links open | Tap Instagram/web | External app/browser |
| T-153 | P1 | client | Store profile & follow | Store loyalty program summary | Program enabled | Shows visits/reward summary |
| T-154 | P1 | client | Store profile & follow | Store loyalty disabled | programEnabled false | No false progress CTA |
| T-155 | P0 | client | Store profile & follow | Store QR / scan CTA | Start passage scan from profile | QR/NFC/BLE path |
| T-156 | P1 | client | Store profile & follow | Store partners section | Has partners | List partners |
| T-157 | P1 | client | Store profile & follow | Store promotions visible to client | Active promos | Shown |
| T-158 | P1 | client | Store profile & follow | Store expired promo hidden | Expired | Not shown |
| T-159 | P1 | client | Store profile & follow | Store profile view counted | Open profile | profile view stats increment path |
| T-160 | P1 | client | Store profile & follow | Store block merchant if safety | Block | Cannot see / interactions blocked |
| T-161 | P1 | client | Store profile & follow | Store report if available | Report | Request recorded |
| T-162 | P2 | client | Store profile & follow | Store share | Share | Share sheet |
| T-163 | P1 | client | Store profile & follow | Store SystemUI cream | Bars | Storefront cream/navy rules |
| T-164 | P1 | client | Store profile & follow | Store back | Back | Previous screen |
| T-165 | P2 | client | Store profile & follow | Store large banner image | Heavy image | Loads/compress OK |
| T-166 | P1 | client | Store profile & follow | Store without banner | Null banner | Placeholder |
| T-167 | P1 | client | Store profile & follow | Store dual role viewing own store | Merchant as client views self | Sensible UX |
| T-168 | P1 | merchant | Store profile & follow | Merchant preview storefront | From settings | Edit vs public coherent |
| T-169 | P0 | merchant | Store profile & follow | Edit storefront profile save | Edit fields → save | Persisted |
| T-170 | P0 | merchant | Store profile & follow | Edit storefront validation | Required missing | Blocked |
| T-171 | P1 | merchant | Store profile & follow | Edit storefront photo upload | Upload banner/logo | Storage success |
| T-172 | P1 | merchant | Store profile & follow | Edit storefront photo fail | Deny photos permission | Error |
| T-173 | P1 | merchant | Store profile & follow | Business hours editor | Set Mon–Sun | Saved |
| T-174 | P1 | merchant | Store profile & follow | Storefront links editor | Add/edit/remove links | Saved |
| T-175 | P1 | merchant | Store profile & follow | Identity edit | Change identity fields | Saved with rules |
| T-176 | P1 | client | Store profile & follow | Follow increments heart_level path | Follow events | heart_level defaults 1 |
| T-177 | P1 | client | Store profile & follow | Re-follow after unfollow | Follow again | Works |
| T-178 | P2 | client | Store profile & follow | Spam follow/unfollow | Rapid toggles | No corrupt state |
| T-179 | P1 | client | Store profile & follow | Store category/subcategory labels | Open | Correct titles |
| T-180 | P1 | client | Store profile & follow | Store address / maps | Tap address | Maps if coded |
| T-181 | P2 | client | Store profile & follow | Store scroll sections | Scroll all | No overflow |
| T-182 | P1 | client | Store profile & follow | Store loyalty progress for follower | Follower opens | Personal progress |
| T-183 | P1 | client | Store profile & follow | Store loyalty progress non-follower | Not following | Follow CTA first |
| T-184 | P1 | client | Store profile & follow | Store NFC passage entry | NFC if available | Session created |
| T-185 | P1 | client | Store profile & follow | Store deep link open | Universal link | Correct merchant |
| T-186 | P2 | client | Store profile & follow | Store offline open cached | Offline | Partial/error |
| T-187 | P1 | merchant | Store profile & follow | Storefront publish incomplete onboarding | Incomplete merchant | Blocked or incomplete UI |
| T-188 | P1 | client | Store profile & follow | Store partners tap partner | Tap partner | Opens partner store |
| T-189 | P2 | client | Store profile & follow | Store animations | Open | No jank crash |
| T-190 | P1 | client | Store profile & follow | Store gratification display | Config set | Hearts/labels |
| T-191 | P1 | client | Store profile & follow | Store after merchant renames | Rename → client refresh | New name |
| T-192 | P2 | client | Store profile & follow | Store accessibility | Labels | OK |
| T-193 | P1 | client | Store profile & follow | Store messages CTA if any | Message | Messages or login |
| T-194 | P0 | client | Store profile & follow | Store from discovery and carnet parity | Open both ways | Same merchant |
| T-195 | P1 | client | Store profile & follow | Store profile very long description | Long text | Scrollable |
| T-196 | P0 | merchant | Loyalty, passage, QR, BLE | Loyalty program disabled blocks passage | loyaltyEnabled false → scan | No passage write |
| T-197 | P0 | merchant | Loyalty, passage, QR, BLE | Loyalty programEnabled false blocks | programEnabled false | No passage |
| T-198 | P0 | merchant | Loyalty, passage, QR, BLE | Automatic passage validation mode | passageValidation automatic | Scan/BLE auto validates per policy |
| T-199 | P0 | merchant | Loyalty, passage, QR, BLE | Manual passage validation mode | manual mode | Client request → merchant confirms |
| T-200 | P0 | client | Loyalty, passage, QR, BLE | QR scan valid merchant QR | Scan merchant QR | active_validations session |
| T-201 | P0 | client | Loyalty, passage, QR, BLE | QR scan invalid code | Scan garbage | Error; no session |
| T-202 | P0 | client | Loyalty, passage, QR, BLE | QR camera permission deny | Deny camera | Guidance UI |
| T-203 | P0 | client | Loyalty, passage, QR, BLE | QR camera permission allow | Allow | Scanner works |
| T-204 | P1 | client | Loyalty, passage, QR, BLE | QR scanner torch toggle | Toggle flash | Works |
| T-205 | P1 | client | Loyalty, passage, QR, BLE | QR scanner cancel | Close scanner | Back safely |
| T-206 | P0 | merchant | Loyalty, passage, QR, BLE | Merchant QR screen displays code | Open merchant QR | Readable QR for clients |
| T-207 | P1 | merchant | Loyalty, passage, QR, BLE | Merchant QR share/save | Share/save | Works |
| T-208 | P0 | merchant | Loyalty, passage, QR, BLE | Manual validate passage from CRM | Client awaiting → validate | loyalty_clients updated |
| T-209 | P0 | merchant | Loyalty, passage, QR, BLE | Reject/cancel awaiting validation | Cancel request | No passage credit |
| T-210 | P0 | client | Loyalty, passage, QR, BLE | Visit count trigger progress | N visits toward threshold | Progress increments |
| T-211 | P0 | client | Loyalty, passage, QR, BLE | Reward unlocks at visitsRequired | Reach threshold | Reward available |
| T-212 | P0 | client | Loyalty, passage, QR, BLE | Purchase total trigger needs amount | purchaseTotal program | Amount entry required |
| T-213 | P0 | merchant | Loyalty, passage, QR, BLE | Merchant enters purchase amount | Amount on validate | Spend accumulates |
| T-214 | P1 | client | Loyalty, passage, QR, BLE | Optional ask client purchase amount | optionalAsk true | Client can enter amount |
| T-215 | P1 | client | Loyalty, passage, QR, BLE | Loyalty points reward kind | pointsPerEuro | Points accrue |
| T-216 | P1 | client | Loyalty, passage, QR, BLE | Discount percent reward | Unlock discount | Shown in rewards |
| T-217 | P1 | client | Loyalty, passage, QR, BLE | Free product reward label | freeProductSummaryLabel | Shown |
| T-218 | P1 | client | Loyalty, passage, QR, BLE | Purchase voucher percent/value | Voucher config | Correct display |
| T-219 | P1 | client | Loyalty, passage, QR, BLE | Minimum per visit enforced | minimumPerVisitEnabled | Below min rejected |
| T-220 | P1 | client | Loyalty, passage, QR, BLE | Reward validity expiry | rewardValidityDays | Expired reward not usable |
| T-221 | P0 | client | Loyalty, passage, QR, BLE | Passage cooldown prevents double | Double scan within cooldown | PassageCooldownFailure |
| T-222 | P0 | merchant | Loyalty, passage, QR, BLE | Cooldown setting off allows rapid | passageCooldownEnabled false | Second passage allowed |
| T-223 | P0 | client | Loyalty, passage, QR, BLE | BLE broadcast screen starts advertising | Open broadcast | Advertising active |
| T-224 | P0 | merchant | Loyalty, passage, QR, BLE | BLE scan finds nearby client | Client broadcast + merchant scan | Client appears list |
| T-225 | P0 | merchant | Loyalty, passage, QR, BLE | BLE scan RSSI threshold | Weak signal | Hidden if below _kListMinRssi |
| T-226 | P1 | merchant | Loyalty, passage, QR, BLE | BLE Bluetooth off | BT off | Prompt enable |
| T-227 | P1 | client | Loyalty, passage, QR, BLE | BLE Bluetooth off client | BT off | Prompt |
| T-228 | P1 | merchant | Loyalty, passage, QR, BLE | BLE permission deny Android | Deny BT/location | Guidance |
| T-229 | P1 | client | Loyalty, passage, QR, BLE | BLE permission deny iOS | Deny | Guidance |
| T-230 | P0 | merchant | Loyalty, passage, QR, BLE | BLE automatic mode auto-confirm rules | Auto mode + BLE session | isBle sessions not auto-confirm without merchant per policy |
| T-231 | P0 | merchant | Loyalty, passage, QR, BLE | Non-BLE auto session auto-confirm | QR/NFC auto mode no amount | Auto confirm aligned with CF |
| T-232 | P1 | merchant | Loyalty, passage, QR, BLE | Vitrine passage request manual only | Auto mode | Vitrine request blocked |
| T-233 | P1 | merchant | Loyalty, passage, QR, BLE | Vitrine passage request manual mode | Manual | Request allowed |
| T-234 | P0 | client | Loyalty, passage, QR, BLE | Loyalty cards list | Open cards | Cards for followed with program |
| T-235 | P0 | client | Loyalty, passage, QR, BLE | Loyalty cards empty | No programs | Empty state |
| T-236 | P1 | client | Loyalty, passage, QR, BLE | Loyalty card detail progress | Open card | Progress UI |
| T-237 | P1 | client | Loyalty, passage, QR, BLE | Reward redemption section | Redeem | State updates |
| T-238 | P1 | client | Loyalty, passage, QR, BLE | Client bons list | Open bons | List rewards coupons |
| T-239 | P1 | merchant | Loyalty, passage, QR, BLE | Active validation sheet | Awaiting client | Sheet actions |
| T-240 | P1 | merchant | Loyalty, passage, QR, BLE | Passage debug simulate sheet if debug | Debug simulate | Only debug builds |
| T-241 | P0 | merchant | Loyalty, passage, QR, BLE | CRM validation tab | Open Vos clients → validation | Pending list |
| T-242 | P1 | merchant | Loyalty, passage, QR, BLE | CRM list tab clients | List section | Followers |
| T-243 | P1 | merchant | Loyalty, passage, QR, BLE | CRM apercu stats periods | 7j / 30j / all | Charts update |
| T-244 | P1 | merchant | Loyalty, passage, QR, BLE | CRM client search/filter | Search name | Filters rows |
| T-245 | P1 | merchant | Loyalty, passage, QR, BLE | CRM pull refresh | Refresh | Reload |
| T-246 | P1 | merchant | Loyalty, passage, QR, BLE | CRM N clients load | Merchant with many followers | Loads; may be slow — note |
| T-247 | P1 | merchant | Loyalty, passage, QR, BLE | CRM offline | Offline | Error |
| T-248 | P0 | client | Loyalty, passage, QR, BLE | Scan when merchant loyalty off | Scan | Friendly error |
| T-249 | P1 | client | Loyalty, passage, QR, BLE | Scan own merchant as dual | Dual user | Defined behavior |
| T-250 | P1 | merchant | Loyalty, passage, QR, BLE | Manual segment override on client | Set manual_segment | UI segment updates |
| T-251 | P1 | merchant | Loyalty, passage, QR, BLE | Gratification hearts display | heart_level 1–3 | UI hearts |
| T-252 | P1 | merchant | Loyalty, passage, QR, BLE | Client gratification config save | Edit config | Persisted |
| T-253 | P1 | client | Loyalty, passage, QR, BLE | E-fidelite merchant screen | Open e-fidelite | Program editor |
| T-254 | P0 | merchant | Loyalty, passage, QR, BLE | E-fidelite enable program | Toggle on + save | programEnabled true |
| T-255 | P0 | merchant | Loyalty, passage, QR, BLE | E-fidelite switch trigger visit↔spend | Change trigger | Saved; UI fields swap |
| T-256 | P0 | merchant | Loyalty, passage, QR, BLE | E-fidelite switch reward kinds | Each LoyaltyRewardKind | Saved |
| T-257 | P1 | merchant | Loyalty, passage, QR, BLE | E-fidelite visitsRequired bounds | 0 / negative / huge | Validation |
| T-258 | P1 | merchant | Loyalty, passage, QR, BLE | E-fidelite spend threshold | Set euros | Saved |
| T-259 | P1 | merchant | Loyalty, passage, QR, BLE | E-fidelite passage auto vs manual toggle | Toggle | Aligns rappelsAutoPassageValidation / config |
| T-260 | P1 | merchant | Loyalty, passage, QR, BLE | Rappels auto client validation toggle | Toggle | Persisted |
| T-261 | P1 | client | Loyalty, passage, QR, BLE | Pending loyalty client row | Awaiting | Shown pending |
| T-262 | P1 | merchant | Loyalty, passage, QR, BLE | Confirm pending client | Confirm | Moves to validated |
| T-263 | P1 | client | Loyalty, passage, QR, BLE | Progress not lose on app kill | Mid progress → kill | Progress persisted |
| T-264 | P1 | client | Loyalty, passage, QR, BLE | Concurrent two merchants passages | Two stores | Independent counters |
| T-265 | P2 | client | Loyalty, passage, QR, BLE | Clock skew cooldown | Device time wrong | Document behavior |
| T-266 | P1 | merchant | Loyalty, passage, QR, BLE | BLE resolve display name | Scan unknown → resolve | Name/photo load |
| T-267 | P1 | merchant | Loyalty, passage, QR, BLE | BLE resolve failure flag | Fail GATT | resolveNameFailed UI |
| T-268 | P2 | merchant | Loyalty, passage, QR, BLE | BLE many devices noise | Crowded BT | List stable |
| T-269 | P1 | client | Loyalty, passage, QR, BLE | Stop BLE broadcast on leave | Leave screen | Advertising stops |
| T-270 | P1 | merchant | Loyalty, passage, QR, BLE | Stop BLE scan on leave | Leave | Scan stops |
| T-271 | P0 | client | Loyalty, passage, QR, BLE | NFC MVP path if device supports | NFC tap | Session |
| T-272 | P1 | client | Loyalty, passage, QR, BLE | NFC unsupported device | No NFC | Fallback QR/BLE |
| T-273 | P1 | merchant | Loyalty, passage, QR, BLE | Passage validated notification trigger | Validate passage | Auto notif if template on |
| T-274 | P1 | client | Loyalty, passage, QR, BLE | Reward available notification | Unlock reward | Client notified |
| T-275 | P1 | client | Loyalty, passage, QR, BLE | Reward near notification | Near threshold | Notified |
| T-276 | P2 | client | Loyalty, passage, QR, BLE | Loyalty UI SystemUI | Bars | OK |
| T-277 | P1 | merchant | Loyalty, passage, QR, BLE | Simulate passage in debug only | Release build | Simulate hidden |
| T-278 | P0 | client | Loyalty, passage, QR, BLE | Cannot write loyalty_clients from client | Inspect rules/attempt | Permission denied |
| T-279 | P0 | merchant | Loyalty, passage, QR, BLE | Merchant can write loyalty on validate | Validate | Write succeeds |
| T-280 | P1 | client | Loyalty, passage, QR, BLE | Active validation expiry | Wait expire | Removed from awaiting |
| T-281 | P1 | merchant | Loyalty, passage, QR, BLE | Expired validation cannot confirm | Confirm expired | Error |
| T-282 | P2 | client | Loyalty, passage, QR, BLE | QR scanner performance | Long session | No overheat crash |
| T-283 | P1 | client | Loyalty, passage, QR, BLE | Deep link passage | Link with merchant id | Session |
| T-284 | P1 | merchant | Loyalty, passage, QR, BLE | CRM client select detail | Open client | Detail actions |
| T-285 | P1 | merchant | Loyalty, passage, QR, BLE | CRM QR box for client | Show client QR box | Displays |
| T-286 | P2 | merchant | Loyalty, passage, QR, BLE | CRM charts empty data | No visits | Empty chart |
| T-287 | P1 | client | Loyalty, passage, QR, BLE | Loyalty cards pull refresh | Refresh | OK |
| T-288 | P1 | merchant | Loyalty, passage, QR, BLE | Program change mid-progress | Change visitsRequired down | Progress/reward rules coherent |
| T-289 | P2 | merchant | Loyalty, passage, QR, BLE | Program change mid-progress up | Increase threshold | Progress retained |
| T-290 | P1 | client | Loyalty, passage, QR, BLE | Blocked client cannot pass | Blocked user | Denied |
| T-291 | P1 | merchant | Loyalty, passage, QR, BLE | Validate without network | Offline validate | Error |
| T-292 | P0 | both | Loyalty, passage, QR, BLE | End-to-end visitCount happy path | Follow → scan × N → reward | Full path works |
| T-293 | P0 | both | Loyalty, passage, QR, BLE | End-to-end purchaseTotal happy path | Validate with amounts → threshold | Reward |
| T-294 | P0 | both | Loyalty, passage, QR, BLE | End-to-end manual validation path | Client request → merchant OK | Passage |
| T-295 | P0 | both | Loyalty, passage, QR, BLE | End-to-end BLE proximity path | Broadcast+scan+validate | Passage |
| T-296 | P0 | merchant | Merchant onboarding | Onboarding flow starts | New merchant | First step shown |
| T-297 | P0 | merchant | Merchant onboarding | Category selection required | Skip category | Blocked |
| T-298 | P0 | merchant | Merchant onboarding | Subcategory selection | Pick subcategory | Saved |
| T-299 | P0 | merchant | Merchant onboarding | Audience selection | Pick audience | Saved |
| T-300 | P0 | merchant | Merchant onboarding | Benefits selection | Pick benefits | Saved |
| T-301 | P0 | merchant | Merchant onboarding | Merchant profile form required fields | Submit empty | Validation |
| T-302 | P0 | merchant | Merchant onboarding | Merchant profile form success | Fill → save | Merchant created |
| T-303 | P1 | merchant | Merchant onboarding | Onboarding photo upload | Upload | OK |
| T-304 | P1 | merchant | Merchant onboarding | Onboarding back between steps | Back | State retained |
| T-305 | P1 | merchant | Merchant onboarding | Onboarding kill mid-flow | Kill → reopen | Resume or restart cleanly |
| T-306 | P1 | merchant | Merchant onboarding | Onboarding offline save | Offline | Error |
| T-307 | P1 | merchant | Merchant onboarding | Benefits screen content | Open benefits | Renders |
| T-308 | P1 | merchant | Merchant onboarding | Duplicate merchant creation guard | Double submit | One merchant |
| T-309 | P0 | merchant | Merchant onboarding | After onboarding lands storefront/clients | Complete | Merchant shell |
| T-310 | P1 | merchant | Merchant onboarding | Onboarding SystemUI | Bars | OK |
| T-311 | P2 | merchant | Merchant onboarding | Onboarding long text fields | Long bio | OK |
| T-312 | P1 | merchant | Merchant onboarding | Category list loads | Open categories | From data |
| T-313 | P1 | merchant | Merchant onboarding | Subcategory depends on category | Change category | Subcats refresh |
| T-314 | P1 | merchant | Merchant onboarding | Invalid subcategory blocked | Mismatch | Error |
| T-315 | P2 | merchant | Merchant onboarding | Onboarding accessibility | Labels | OK |
| T-316 | P1 | dual | Merchant onboarding | Client becomes merchant | Add merchant role | Onboarding then dual |
| T-317 | P1 | merchant | Merchant onboarding | Merchant subscription plan default free | New merchant | free plan |
| T-318 | P2 | merchant | Merchant onboarding | Onboarding analytics | Complete steps | No crash |
| T-319 | P1 | merchant | Merchant onboarding | Address/city in profile form | Set city | Used in discovery |
| T-320 | P1 | merchant | Merchant onboarding | Phone validation | Bad phone | Error |
| T-321 | P1 | merchant | Merchant onboarding | Email prefilled from auth | Open form | Email shown |
| T-322 | P2 | merchant | Merchant onboarding | Onboarding images compression | Large photo | Upload works |
| T-323 | P1 | merchant | Merchant onboarding | Legal accept if required | Accept CGU | Required |
| T-324 | P0 | merchant | Merchant onboarding | Cannot access CRM before complete | Force navigate | Redirect onboarding |
| T-325 | P1 | merchant | Merchant onboarding | Onboarding flow large screen stability | All steps | No crash (large file smoke) |
| T-326 | P2 | merchant | Merchant onboarding | Rotate during onboarding | Rotate | OK |
| T-327 | P1 | merchant | Merchant onboarding | Network blip mid save | Toggle airplane | Recover |
| T-328 | P1 | merchant | Merchant onboarding | Edit category after create if allowed | Change | Saved or locked per rules |
| T-329 | P2 | merchant | Merchant onboarding | Onboarding French copy | Read UI | FR coherent |
| T-330 | P1 | merchant | Merchant onboarding | Merchant name uniqueness if any | Duplicate name | Rule applied |
| T-331 | P1 | merchant | Merchant onboarding | Geolocation for store if any | Set pin | Saved |
| T-332 | P2 | merchant | Merchant onboarding | Onboarding help/contact | Open contact | Works |
| T-333 | P1 | merchant | Merchant onboarding | Abandoned onboarding user | Partial data | Can resume |
| T-334 | P0 | merchant | Merchant onboarding | Merchant shell tabs after onboard | Tabs | Clients/promos/etc |
| T-335 | P1 | merchant | Merchant onboarding | Storefront empty after onboard | Open storefront | Editable empty state |
| T-336 | P0 | merchant | Merchant CRM, promos, rappels, settings | Promotions list loads | Open promotions | List |
| T-337 | P0 | merchant | Merchant CRM, promos, rappels, settings | Create promotion | Fill → save | Created |
| T-338 | P0 | merchant | Merchant CRM, promos, rappels, settings | Edit promotion | Edit → save | Updated |
| T-339 | P0 | merchant | Merchant CRM, promos, rappels, settings | Delete promotion | Delete confirm | Removed |
| T-340 | P1 | merchant | Merchant CRM, promos, rappels, settings | Promotion date range validation | End before start | Error |
| T-341 | P1 | merchant | Merchant CRM, promos, rappels, settings | Promotion segment targeting | Pick segment | Saved |
| T-342 | P1 | client | Merchant CRM, promos, rappels, settings | Promotion visible matching segment | Client in segment | Sees promo |
| T-343 | P1 | client | Merchant CRM, promos, rappels, settings | Promotion hidden wrong segment | Out of segment | Not shown |
| T-344 | P1 | merchant | Merchant CRM, promos, rappels, settings | Promo analytics views | Open analytics | Counts |
| T-345 | P1 | merchant | Merchant CRM, promos, rappels, settings | Promo empty state | No promos | CTA create |
| T-346 | P0 | merchant | Merchant CRM, promos, rappels, settings | Merchant stats screen loads | Open stats | Charts/numbers |
| T-347 | P1 | merchant | Merchant CRM, promos, rappels, settings | Stats period filters | Change period | Updates |
| T-348 | P1 | merchant | Merchant CRM, promos, rappels, settings | Stats offline | Offline | Error |
| T-349 | P0 | merchant | Merchant CRM, promos, rappels, settings | Partners list | Open partners | List |
| T-350 | P0 | merchant | Merchant CRM, promos, rappels, settings | Add partner | Add merchant partner | Saved |
| T-351 | P0 | merchant | Merchant CRM, promos, rappels, settings | Remove partner | Remove | Gone |
| T-352 | P1 | merchant | Merchant CRM, promos, rappels, settings | Partner search | Search | Uses merchants query |
| T-353 | P1 | client | Merchant CRM, promos, rappels, settings | Partners show on store profile | Open store | Partners section |
| T-354 | P1 | merchant | Merchant CRM, promos, rappels, settings | Partner duplicate add | Add twice | Prevented |
| T-355 | P0 | merchant | Merchant CRM, promos, rappels, settings | Merchant settings hub | Open settings | All entries |
| T-356 | P0 | merchant | Merchant CRM, promos, rappels, settings | Profile summary | Open summary | Data shown |
| T-357 | P0 | merchant | Merchant CRM, promos, rappels, settings | Identification security | Open security | Actions work |
| T-358 | P0 | merchant | Merchant CRM, promos, rappels, settings | Data privacy consent toggle | Toggle analyticsConsent | Firestore update |
| T-359 | P0 | merchant | Merchant CRM, promos, rappels, settings | Data export request | Request export | data_export_requests / portable export |
| T-360 | P0 | merchant | Merchant CRM, promos, rappels, settings | Portable data download | Download JSON | Share sheet file |
| T-361 | P1 | merchant | Merchant CRM, promos, rappels, settings | Account preferences merchant | Open prefs | Works |
| T-362 | P1 | merchant | Merchant CRM, promos, rappels, settings | Storefront links screen | CRUD links | OK |
| T-363 | P1 | merchant | Merchant CRM, promos, rappels, settings | Identity edit validation | Bad data | Error |
| T-364 | P1 | merchant | Merchant CRM, promos, rappels, settings | Merchant notifications hub | Open hub | Quota label if any |
| T-365 | P1 | merchant | Merchant CRM, promos, rappels, settings | Weekly quota disabled launch | quota flag false | Unlimited send |
| T-366 | P1 | merchant | Merchant CRM, promos, rappels, settings | Weekly quota enabled free plan | Enable flag + free | Block after 5 |
| T-367 | P1 | merchant | Merchant CRM, promos, rappels, settings | Paid plan ignores quota | Paid plan | Always can send |
| T-368 | P0 | merchant | Merchant CRM, promos, rappels, settings | Send manual notification | Compose → send | Client receives; sent log |
| T-369 | P1 | merchant | Merchant CRM, promos, rappels, settings | Send notification no recipients | Empty segment | Error |
| T-370 | P1 | merchant | Merchant CRM, promos, rappels, settings | Notification templates CRUD | Create/edit/delete template | OK |
| T-371 | P0 | merchant | Merchant CRM, promos, rappels, settings | Rappels screen loads | Open rappels | Sections |
| T-372 | P0 | merchant | Merchant CRM, promos, rappels, settings | Scheduled notifications create | Schedule future | Created |
| T-373 | P1 | merchant | Merchant CRM, promos, rappels, settings | Scheduled notifications cancel | Cancel | Removed/cancelled |
| T-374 | P0 | merchant | Merchant CRM, promos, rappels, settings | Notifications auto triggers grid | Open auto | Wired triggers selectable |
| T-375 | P1 | merchant | Merchant CRM, promos, rappels, settings | Unwired trigger visitDetected excluded | Check selectable list | visitDetected not selectable |
| T-376 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable birthday auto notif | Enable + template | Fires on DOB path |
| T-377 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable new follower auto notif | Client follows | Merchant/client notif path |
| T-378 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable segment change auto notif | Segment changes | Fires |
| T-379 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable passage validated auto notif | Validate | Fires |
| T-380 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable inactive return auto notif | Inactive returns | Fires |
| T-381 | P0 | merchant | Merchant CRM, promos, rappels, settings | Enable reward available/near | Progress | Fires |
| T-382 | P1 | merchant | Merchant CRM, promos, rappels, settings | Exceptional closure notif | Trigger | Fires |
| T-383 | P1 | merchant | Merchant CRM, promos, rappels, settings | New partner notif | Add partner | Fires |
| T-384 | P1 | merchant | Merchant CRM, promos, rappels, settings | Connection anniversary notif | Anniversary | Fires |
| T-385 | P1 | merchant | Merchant CRM, promos, rappels, settings | Alertes section | Open rappels alertes | Lists alerts |
| T-386 | P1 | merchant | Merchant CRM, promos, rappels, settings | Pending clients rappels | Pending rows | Actions |
| T-387 | P1 | merchant | Merchant CRM, promos, rappels, settings | Sent notifications history | Open history | limit pagination |
| T-388 | P2 | merchant | Merchant CRM, promos, rappels, settings | Stats TODOs smoke | Open stats | No crash despite TODOs |
| T-389 | P2 | merchant | Merchant CRM, promos, rappels, settings | Promotions TODOs smoke | Open promos | No crash |
| T-390 | P1 | merchant | Merchant CRM, promos, rappels, settings | Merchant contact Yuztoo | Open contact | Send/works |
| T-391 | P1 | merchant | Merchant CRM, promos, rappels, settings | Employment history if used | Open employment history | OK |
| T-392 | P1 | merchant | Merchant CRM, promos, rappels, settings | Client list SystemUI | Bars | Merchant dark/cream rules |
| T-393 | P1 | merchant | Merchant CRM, promos, rappels, settings | Settings SystemUI | Bars | OK |
| T-394 | P2 | merchant | Merchant CRM, promos, rappels, settings | Merchant shell memory | Navigate all tabs | Stable |
| T-395 | P1 | merchant | Merchant CRM, promos, rappels, settings | Promo image upload | Add image | OK |
| T-396 | P1 | merchant | Merchant CRM, promos, rappels, settings | Invalid promo image | Huge file | Error |
| T-397 | P0 | merchant | Merchant CRM, promos, rappels, settings | CRM after new follower live | Client follows while CRM open | List updates via snapshots |
| T-398 | P1 | merchant | Merchant CRM, promos, rappels, settings | Overrides manual segment | Set override | Persists in merchants/.../clients |
| T-399 | P1 | merchant | Merchant CRM, promos, rappels, settings | Gratification defaults | No config | defaults used |
| T-400 | P0 | client | Notifications, profile, messages | Notifications list loads | Open | Up to 50 latest |
| T-401 | P0 | client | Notifications, profile, messages | Mark notification read | Tap | Unread clears |
| T-402 | P1 | client | Notifications, profile, messages | Mark all read if available | Mark all | All read |
| T-403 | P1 | client | Notifications, profile, messages | Empty notifications | None | Empty state |
| T-404 | P1 | client | Notifications, profile, messages | Notification deep link to store | Tap | Opens store |
| T-405 | P1 | client | Notifications, profile, messages | Notification deep link to loyalty | Tap | Opens loyalty |
| T-406 | P1 | client | Notifications, profile, messages | FCM token registered | Login + allow push | Token doc written |
| T-407 | P1 | client | Notifications, profile, messages | FCM token refresh | Reinstall/refresh | Token updated |
| T-408 | P1 | client | Notifications, profile, messages | FCM token cleared on logout | Logout | Token removed/disabled |
| T-409 | P0 | client | Notifications, profile, messages | Push received in foreground | Send test | In-app handling |
| T-410 | P0 | client | Notifications, profile, messages | Push received in background | Send test | Tray → open app |
| T-411 | P1 | client | Notifications, profile, messages | Push received killed state | Kill → push → open | Routes correctly |
| T-412 | P1 | client | Notifications, profile, messages | Notifications pull refresh | Refresh | OK |
| T-413 | P2 | client | Notifications, profile, messages | Notifications pagination edge | Exactly 50 | OK |
| T-414 | P0 | client | Notifications, profile, messages | Personal info edit name | Save | Updated |
| T-415 | P0 | client | Notifications, profile, messages | Personal info edit photo | Upload | photoUrl updated |
| T-416 | P1 | client | Notifications, profile, messages | Personal info DOB edit | Change DOB | Saved |
| T-417 | P1 | client | Notifications, profile, messages | Personal info city edit | Change city | Discovery updates |
| T-418 | P1 | client | Notifications, profile, messages | Personal info validation | Empty name | Error |
| T-419 | P0 | client | Notifications, profile, messages | Client profile menu entries | Open each | Navigate OK |
| T-420 | P1 | client | Notifications, profile, messages | Account preferences toggles | Toggle prefs | Persisted |
| T-421 | P1 | client | Notifications, profile, messages | Legal document CGU | Open | Renders |
| T-422 | P1 | client | Notifications, profile, messages | Legal document privacy | Open | Renders |
| T-423 | P1 | client | Notifications, profile, messages | Yuztoo contact send | Submit form | Success/error handled |
| T-424 | P1 | client | Notifications, profile, messages | Messages screen opens | Open messages | Shows UI (mock OK) |
| T-425 | P1 | client | Notifications, profile, messages | Messages conversation select | Tap thread | Detail or stub |
| T-426 | P2 | client | Notifications, profile, messages | Messages mock data documented | QA note | Not production data |
| T-427 | P1 | client | Notifications, profile, messages | Profile SystemUI | Bars | White/client |
| T-428 | P1 | client | Notifications, profile, messages | Block user safety | Block | Safety repo write |
| T-429 | P1 | client | Notifications, profile, messages | Unblock user | Unblock | Restored |
| T-430 | P1 | merchant | Notifications, profile, messages | Merchant messages entry | Open | Role-specific |
| T-431 | P2 | client | Notifications, profile, messages | Notification flood | Many pushes | App stable |
| T-432 | P1 | client | Notifications, profile, messages | Wrong role notification ignored | Merchant notif to client | No crash |
| T-433 | P1 | client | Notifications, profile, messages | Notification permission re-prompt | Settings | Can enable later |
| T-434 | P1 | client | Notifications, profile, messages | Personal info offline save | Offline | Error |
| T-435 | P1 | client | Notifications, profile, messages | Photo upload progress | Upload | Indicator |
| T-436 | P1 | client | Notifications, profile, messages | Photo upload cancel | Cancel | No corrupt profile |
| T-437 | P2 | client | Notifications, profile, messages | Very large photo | 20MB | Compressed or error |
| T-438 | P1 | client | Notifications, profile, messages | Profile cache refresh after edit | Edit → home | New name shown |
| T-439 | P1 | dual | Notifications, profile, messages | Notifications for both roles | Switch roles | Relevant lists |
| T-440 | P2 | client | Notifications, profile, messages | Messages SystemUI | Bars | OK |
| T-441 | P1 | client | Notifications, profile, messages | Open notification without network | Offline tap | Error |
| T-442 | P1 | client | Notifications, profile, messages | Delete notification if supported | Delete | Removed |
| T-443 | P2 | client | Notifications, profile, messages | Notification HTML/special chars | Weird title | Renders safe |
| T-444 | P1 | client | Notifications, profile, messages | Segment matching promo notif | Segment match | Receives |
| T-445 | P1 | client | Notifications, profile, messages | Segment mismatch no promo notif | Mismatch | Does not receive |
| T-446 | P0 | client | Notifications, profile, messages | Security / password change if any | Change password | Works or N/A |
| T-447 | P1 | merchant | Notifications, profile, messages | Identification security actions | 2FA/password if any | Works |
| T-448 | P1 | client | Notifications, profile, messages | Employment history screen | Open if linked | OK |
| T-449 | P2 | client | Notifications, profile, messages | Profile rapid navigation | Spam tabs | Stable |
| T-450 | P1 | client | Notifications, profile, messages | App badge count | Unread | Badge updates |
| T-451 | P1 | client | Notifications, profile, messages | Clear badge on read | Read all | Badge 0 |
| T-452 | P2 | client | Notifications, profile, messages | Notification locale French | Content | FR |
| T-453 | P1 | guest | Notifications, profile, messages | Guest notifications blocked | Open | Login gate |
| T-454 | P1 | client | Notifications, profile, messages | Data privacy from client if exposed | Open | Consent works |
| T-455 | P0 | any | Cross-cutting, permissions, BG, security | Airplane mode cold start | Offline launch | No crash; retry UI |
| T-456 | P0 | any | Cross-cutting, permissions, BG, security | Recover online after offline | Offline → online | Data refreshes |
| T-457 | P0 | any | Cross-cutting, permissions, BG, security | App background 5 min resume | Background → foreground | State OK; streams reconnect |
| T-458 | P0 | any | Cross-cutting, permissions, BG, security | App background 1 hour resume | Long background | Session OK or reauth clean |
| T-459 | P1 | any | Cross-cutting, permissions, BG, security | OS kills app under memory | Open many apps → return | Recovers to safe screen |
| T-460 | P1 | any | Cross-cutting, permissions, BG, security | Firestore permission-denied surfaces | Force rules deny | User-visible error |
| T-461 | P1 | any | Cross-cutting, permissions, BG, security | Firestore unavailable | Break network to Google | Timeout handling |
| T-462 | P0 | any | Cross-cutting, permissions, BG, security | Crashlytics non-fatal not freeze UI | Trigger handled error | UI continues |
| T-463 | P1 | any | Cross-cutting, permissions, BG, security | Concurrent dual device login | Phone + tablet same user | Both work or documented |
| T-464 | P1 | any | Cross-cutting, permissions, BG, security | Clock change while using | Change device time | Cooldown/cooldown sensible |
| T-465 | P1 | any | Cross-cutting, permissions, BG, security | Low storage photo upload | Fill disk | Error |
| T-466 | P1 | any | Cross-cutting, permissions, BG, security | iOS Simulator smoke all main tabs client | Walk tabs | No crash |
| T-467 | P1 | any | Cross-cutting, permissions, BG, security | iOS Simulator smoke merchant tabs | Walk tabs | No crash |
| T-468 | P1 | any | Cross-cutting, permissions, BG, security | Android device smoke client | Walk tabs | No crash |
| T-469 | P1 | any | Cross-cutting, permissions, BG, security | Android device smoke merchant | Walk tabs | No crash |
| T-470 | P1 | any | Cross-cutting, permissions, BG, security | Android 12+ BT permissions | BLE flows | Prompts correct |
| T-471 | P1 | any | Cross-cutting, permissions, BG, security | iOS BT permissions | BLE flows | Prompts correct |
| T-472 | P1 | any | Cross-cutting, permissions, BG, security | Location permission discovery proche | Allow/deny | OK |
| T-473 | P1 | any | Cross-cutting, permissions, BG, security | Camera permission QR | Allow/deny | OK |
| T-474 | P1 | any | Cross-cutting, permissions, BG, security | Photos permission upload | Allow/deny | OK |
| T-475 | P1 | any | Cross-cutting, permissions, BG, security | Notification permission | Allow/deny | OK |
| T-476 | P0 | any | Cross-cutting, permissions, BG, security | No debug simulate in release | Release build | Hidden |
| T-477 | P1 | any | Cross-cutting, permissions, BG, security | Hot restart mid BLE | Dev only | Stops advertising/scan cleanly |
| T-478 | P2 | any | Cross-cutting, permissions, BG, security | Accessibility font scale 1.5 | All main screens | Usable |
| T-479 | P2 | any | Cross-cutting, permissions, BG, security | VoiceOver/TalkBack smoke | Auth + home | Labels |
| T-480 | P1 | any | Cross-cutting, permissions, BG, security | Deep link unknown route | Bad link | Fallback home/error |
| T-481 | P1 | any | Cross-cutting, permissions, BG, security | App upgrade migrate | Install old → upgrade | No data loss |
| T-482 | P1 | any | Cross-cutting, permissions, BG, security | Clear app data re-onboard | Clear → open | Onboarding again |
| T-483 | P0 | any | Cross-cutting, permissions, BG, security | Security: client cannot read other user private | Rules test | Denied |
| T-484 | P0 | any | Cross-cutting, permissions, BG, security | Security: client cannot write merchant loyalty | Rules test | Denied |
| T-485 | P0 | any | Cross-cutting, permissions, BG, security | Security: merchant cannot read unrelated users bulk | Rules test | Denied |
| T-486 | P1 | any | Cross-cutting, permissions, BG, security | Functions auto_notification stress | Burst events | No duplicate spam beyond rules |
| T-487 | P1 | any | Cross-cutting, permissions, BG, security | Functions passage auto confirm alignment | QR auto no amount | Matches Dart policy |
| T-488 | P1 | any | Cross-cutting, permissions, BG, security | Quota core sync Flutter↔Functions | Compare flags | Same default |
| T-489 | P2 | any | Cross-cutting, permissions, BG, security | Performance discovery scroll | 100+ merchants | < jank threshold |
| T-490 | P2 | any | Cross-cutting, permissions, BG, security | Performance CRM 500 clients | Large follower set | Acceptable or paginate need |
| T-491 | P1 | any | Cross-cutting, permissions, BG, security | Battery BLE broadcast 30 min | Broadcast long | Reasonable drain; stop works |
| T-492 | P1 | any | Cross-cutting, permissions, BG, security | Battery BLE scan 30 min | Scan long | Stop works |
| T-493 | P2 | any | Cross-cutting, permissions, BG, security | Dark/light OS setting | Toggle OS appearance | App theme coherent |
| T-494 | P1 | any | Cross-cutting, permissions, BG, security | Locale FR default | Fresh install | French UI |
| T-495 | P2 | any | Cross-cutting, permissions, BG, security | Tablet layout smoke | iPad if supported | Usable |
| T-496 | P1 | any | Cross-cutting, permissions, BG, security | Store listing build number | About/settings | Version visible if coded |
| T-497 | P0 | any | Cross-cutting, permissions, BG, security | Payment/subscription N/A launch | Free plan paths | No paywall crash |
| T-498 | P1 | any | Cross-cutting, permissions, BG, security | Edge swipe back iOS | Swipe | Pops correctly |
| T-499 | P1 | any | Cross-cutting, permissions, BG, security | Android predictive back | Back gesture | OK |
| T-500 | P1 | merchant | Loyalty, passage, QR, BLE | Validate passage with zero amount when required | Submit 0 | Rejected |

## Suggested execution order
1. All **P0 Auth** + **P0 Loyalty E2E** + **P0 Security rules**
2. Client shell smoke + Discovery + Follow
3. Merchant onboarding + CRM + E-fidélité config
4. Rappels / FCM / auto triggers
5. BLE/QR permissions matrix on real devices
6. P1 leftovers → P2

## Notes
- `messages_screen` uses mock conversations — scenarios still required; mark bugs as “mock” vs “prod”.
- Large screens (`store_profile`, `onboarding_flow`) get extra stability pads.
- Scale scenarios (CRM 500 clients, discovery 200 cap) document known risk, not necessarily current bugs.
