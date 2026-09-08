# Security audit — findings and remediation plan

**Audited:** 8 Sep 2026 · **Scope:** `firestore.rules`, `storage.rules`, `functions/src/**`, `admin/**`, Flutter auth/logging layers.

Findings 1–4 were **reproduced against the Firestore emulator**, not inferred from reading the rules. Finding 5 and 6 are configuration facts verified by inspection. Every fix below lives in `firestore.rules` except phase 3 and 4.

The whole cluster has one shape: **the admin CRM and the Cloud Functions are sound, and the client-facing Firestore rules are where the holes are.** The callables re-check the `admin` claim server-side, allowlist every writable field, and audit-log every mutation. The rules, by contrast, have carve-outs that grant more than they were written to grant.

---

## Priority summary

| # | Finding | Severity | Fix cost | Needs app change |
|---|---------|----------|----------|------------------|
| 1 | Notification inbox injection → arbitrary push to any user | **High** | Small | No |
| 2 | Permanent email / phone squatting in the identity indexes | **Med-high** | Small | No |
| 3 | Unauthenticated email/phone → uid oracle | Medium | Medium | Yes (signup) |
| 4 | Merchant counters accept any value from any signed-in user | Medium | Small | No |
| 5 | Full public read on the merchant collection, incl. contact PII | Medium | Large | Yes |
| 6 | App Check not enabled on any surface | Medium | Medium | Yes |
| 7 | Client-controlled `client_display_name` / `program_snapshot` | Low | Small | No |
| 8 | 18 npm advisories in `functions/` (1 critical, 4 high) | Low | Small | No |

Suggested sequencing: **phase 1** = findings 1, 2, 4, 7 (rules-only, no app release needed, ship together). **Phase 2** = finding 6. **Phase 3** = findings 3 and 5 (both need coordinated app changes). **Phase 4** = finding 8.

---

## Phase 1 — rules-only fixes, no app release required

These four are independent of the Flutter clients: they only remove permissions nothing legitimate relies on. They can be deployed with `firebase deploy --only firestore:rules` on their own.

### 1. Notification inbox injection (High)

**What is wrong.** The `create` rule chains its conditions with `||`, so the "no `merchant_id`" branch is never scoped to the inbox owner and `userId` stops mattering — `firestore.rules:206`:

```
    match /users/{userId}/notifications/{notificationId} {
      allow read, update, delete: if isOwner(userId);
      allow create: if isSignedIn()
        && (
          isOwner(userId)
          || !('merchant_id' in request.resource.data)
          || request.resource.data.merchant_id == ''
          || isMerchantOwner(request.resource.data.merchant_id)
        );
```

**Why it matters.** `onNotificationCreated` fires on *any* create at this path and forwards the document's `title` and `body` straight to FCM (`functions/src/index.ts:861`). So the attacker controls the text of a real push notification on a victim's device — a phishing channel with Yuztoo's own icon on it. Targeting needs no prior knowledge: `merchants` is publicly listable and every document carries `owner_uid`, so every merchant uid on the platform is enumerable (see finding 5).

**Reproduced.** A context authenticated as `attacker_uid` successfully wrote `users/victim_uid/notifications/evil1` both by omitting `merchant_id` and by sending it as `''`. Reads back are correctly denied, so it is write-only injection.

**Fix.** Delete the two unscoped branches. Cloud Functions write through the Admin SDK and bypass rules entirely, so the "system/legacy path" the comment protects does not need a rule at all:

```
      allow create: if isSignedIn()
        && (
          isOwner(userId)
          || isMerchantOwner(request.resource.data.get('merchant_id', ''))
        );
```

**Before deploying, confirm no client path writes cross-user notifications.** Grep `lib/` for writes to `notifications` where the target uid is not the current user. The `isOwner(userId)` branch keeps the client-side self-notification-on-scan path working; the `isMerchantOwner` branch keeps merchant fan-out working.

### 2. Permanent email / phone squatting (Med-high)

**What is wrong.** Both identity indexes validate the *payload* `uid` against the caller but never check that the **document ID** is an identity the caller owns — `firestore.rules:114`:

```
    match /email_index/{email} {
      allow get: if true;
      allow list: if false;
      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly(['uid'])
        && request.resource.data.uid is string
        && request.resource.data.uid == request.auth.uid
        && !exists(/databases/$(database)/documents/email_index/$(email));
```

**Why it matters.** These indexes are the duplicate-signup guard. Because `update` and `delete` are both `false`, a reservation is permanent from the client side — and `adminCreateClient` rejects on the same check (`crm_clients.ts:270`), so the back-office cannot create the account either. Recovery requires manual Firestore surgery. One throwaway account plus a wordlist can lock out an arbitrary set of emails and phone numbers.

**Reproduced.** `attacker_uid` successfully created `email_index/victim@example.com` and `phone_index/+33612345678`.

**Fix.** Gate the document ID against the caller's verified token identity:

```
    match /email_index/{email} {
      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly(['uid'])
        && request.resource.data.uid == request.auth.uid
        && email == request.auth.token.get('email', '').lower()
        && !exists(/databases/$(database)/documents/email_index/$(email));
      // …
    }

    match /phone_index/{phone} {
      allow create: if isSignedIn()
        && request.resource.data.keys().hasOnly(['uid'])
        && request.resource.data.uid == request.auth.uid
        && phone == request.auth.token.get('phone_number', '')
        && !exists(/databases/$(database)/documents/phone_index/$(phone));
      // …
    }
```

**Ordering caveat to check first.** The token only carries `phone_number` *after* the phone credential is linked, and `email` after email signup. Trace the write order in `firebase_auth_repository.phone.part.dart` and the signup flow: if the index write currently happens *before* `linkWithCredential`, this rule will reject it and the write must move after the link (plus a token refresh). If reordering proves awkward, the fallback is to move both index writes into a callable that derives the ID from `context.auth.token` server-side — strictly better, but a larger change.

**Cleanup.** Before deploying, audit the existing indexes for entries whose `uid`'s Auth record does not carry the matching email/phone. Any mismatch is either a squat or a legacy write and needs manual review.

### 3. Merchant counters accept any value (Medium)

**What is wrong.** The counter carve-outs constrain *which* keys change, never *how* — `firestore.rules:256`:

```
      allow update: if isSignedIn()
        && request.resource.data.owner_uid == resource.data.owner_uid
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['rappels_monthly_connected_clients', 'rappels_monthly_connected_ym']);
```

**Why it matters.** These counters feed the notification quota logic — `processScheduledNotifications` fails sends with `quota_exceeded` — so a stranger can exhaust a merchant's quota or reset it, and corrupt their dashboard KPIs either way. `promotions.view_count` and `sent_notifications.open_count` have the same unbounded shape.

**Reproduced.** `stranger_uid` set `rappels_monthly_validated_passages` to `999999999`, and separately to `-50000`.

**Fix.** Match what the client actually writes. `_incrementMerchantMonthlyCounter` (`firestore_followed_merchants_repository.dart:88`) writes `increment(1)` in the same month and a literal `1` on rollover, so:

```
    function connectedClientsIncrementValid() {
      let r = request.resource.data;
      let o = resource.data;
      return r.rappels_monthly_connected_ym is string
        && r.rappels_monthly_connected_ym.matches('^[0-9]{4}-[0-9]{2}$')
        // Never rewind to an earlier month — that would allow repeated resets.
        && r.rappels_monthly_connected_ym >= o.get('rappels_monthly_connected_ym', '')
        && r.rappels_monthly_connected_clients is int
        && (o.get('rappels_monthly_connected_ym', '') == r.rappels_monthly_connected_ym
              ? r.rappels_monthly_connected_clients
                  == o.get('rappels_monthly_connected_clients', 0) + 1
              : r.rappels_monthly_connected_clients == 1);
    }
```

Write the mirror function for `rappels_monthly_validated_passages` / `_ym`, and add `is int` plus `== previous + 1` to `view_count` and `open_count`. Do **not** try to parameterize these with a dynamic map index (`r[counterKey]`) — spell out both pairs, since dynamic key indexing on `request.resource.data` is not worth relying on here.

The non-decreasing `_ym` check is the important subtlety: without it an attacker replays a stale month string to force the counter back to 1 at will.

### 4. Client-controlled validation session fields (Low)

`activeValidationSessionPayloadValid` accepts any `client_display_name` string and only checks `program_snapshot is map` — `firestore.rules:395`:

```
    function activeValidationSessionPayloadValid() {
      let r = request.resource.data;
      return r.keys().hasAll(['client_uid', 'client_display_name', 'created_at', 'status', 'program_snapshot'])
        && r.client_display_name is string
```

Both are rendered in the merchant's validation form at the moment they decide to grant a reward, so a client can misrepresent their name and their program terms. Add a length cap on `client_display_name` (say 120) and `client_photo_url`, and pin `program_snapshot` to the keys the merchant form actually reads with `hasOnly([...])` and per-field type checks. Low severity because it takes a human merchant approving a form, but it is cheap to close.

### Verification for phase 1

Add the reproduction cases to `tools/firebase/firestore_rules.test.ts` as **deny** assertions, so each one is a regression test rather than a one-off probe:

- `attacker` create at `users/victim/notifications/*` with no `merchant_id` → `assertFails`
- same with `merchant_id: ''` → `assertFails`
- owner create in own inbox → `assertSucceeds` (do not regress the scan path)
- merchant owner create in a follower's inbox with their own `merchant_id` → `assertSucceeds`
- `attacker` create at `email_index/victim@example.com` and `phone_index/+33…` → `assertFails`
- signup-shaped write where the token identity matches the doc ID → `assertSucceeds`
- stranger setting a counter to `999999999`, to `-50000`, and replaying a stale `_ym` → `assertFails`
- legitimate `+1` in the same month, and `1` on a forward rollover → `assertSucceeds`

Run with `cd tools/firebase && npm run test:rules`. Note that port 9555 is often already held by a running emulator; either reuse it via `FIRESTORE_EMULATOR_HOST=127.0.0.1:9555 npx jest` or stop the existing one.

---

## Phase 2 — App Check (Medium)

There is no `firebase_app_check` in `pubspec.yaml` or anywhere in `lib/`, and the admin guard's gate is opt-in and unset in the repo — `functions/src/admin/guard.ts:37`:

```ts
function appCheckRequired(): boolean {
  return process.env.ADMIN_REQUIRE_APP_CHECK === "true";
}
```

Without attestation, every Firestore path and callable is reachable from a script holding only the public web API key — which is exactly what makes findings 1–4 cheap to automate at scale. The sharpest standalone risk is `sendPhoneVerification` handing a caller-supplied number to `verifyPhoneNumber`: that is an **SMS-pumping fraud vector billed to you**, and it is independent of the rules fixes.

Rollout, in order:

1. Add `firebase_app_check` to the Flutter app; register Play Integrity (Android) and DeviceCheck/App Attest (iOS).
2. Ship the client and let adoption reach near-100% while App Check is in **monitoring** mode in the console — enforcement before adoption locks out existing installs.
3. Enable enforcement for Firestore, Functions, and Storage.
4. Register the admin web app with reCAPTCHA Enterprise, then set `ADMIN_REQUIRE_APP_CHECK=true` in the function environment. The guard already handles it with no code change.
5. Separately, turn on Firebase Auth's SMS region policy and abuse protections — `auth_set_sms_region_policy` restricts which country codes can receive OTPs, which caps pumping exposure even before App Check lands.

---

## Phase 3 — coordinated app + rules changes

### Unauthenticated email/phone → uid oracle (finding 3, Medium)

Both indexes are `allow get: if true`. An unauthenticated request for `email_index/<address>` returns `{ uid: … }` — **reproduced**. That is account-existence disclosure ("is this person a Yuztoo user?") plus the uid needed to target finding 1.

The underlying need is real: signup checks existence *before* the user is authenticated, so a plain `isSignedIn()` gate breaks the flow. Replace the public read with a callable that takes an email or phone, returns **only a boolean**, and never the uid — rate-limited per IP and per App Check token. Then set both index reads to `if false` for clients. This ships after phase 2 so the callable can rely on attestation.

Note that fixing finding 2 does not fix this one, and vice versa: one is about who may *write* an index entry, the other about who may *read* it.

### Merchant collection PII exposure (finding 5, Medium)

`allow read: if true` on `/merchants/{merchantId}` covers `list`, and the document holds `email`, `phone`, `address`, and `owner_uid` (`merchant_dto.dart:150`). Anyone, unauthenticated, can dump every merchant's contact details — a spam/harvest target, and the uid source that makes finding 1 trivially targetable.

Storefront discovery genuinely needs public reads, so the fix is field-level rather than a blanket deny:

- Move `email`, `phone`, and precise `address` into a `merchants/{id}/contact/private` document readable only by the owner and, if the product needs it, signed-in followers.
- Keep the public document to what the vitrine and Découvrir actually render.
- Update `merchant_dto.dart` to read contact fields from the subcollection, and add them to `MERCHANT_EDITABLE_FIELDS` handling in `crm_merchants.ts` so the CRM still edits them.
- Backfill existing merchant documents, then remove the public fields.

This is the largest item in the plan and the only one touching the merchant feature's DTO layer, so it belongs in its own PR with a migration script.

---

## Phase 4 — dependencies (finding 8, Low)

`npm audit --omit=dev` in `functions/` reports 18 vulnerabilities (1 critical, 4 high), all transitive through `firebase-admin` ^12 — two majors behind. Affected: `@grpc/grpc-js` (malformed-request crash), `protobufjs` (code injection via generated `toObject`), `form-data` (CRLF injection), `websocket-driver` (compression resource-limit bypass).

Real exploitability in this codebase is low — these sit on paths reached by trusted Google backends, not attacker-controlled input — so this is hygiene, not an emergency. Run `npm audit fix`, then bump `firebase-admin` to the current major and `firebase-functions` alongside it, and check the v12→v13+ migration notes for the modular-import changes the `admin/` modules already follow. Redeploy and smoke-test the scheduled jobs, which are the code most likely to break on a major bump.

---

## Verified clean

Recorded so a future audit does not re-litigate them:

- **PII never reaches Crashlytics.** `logger_service.dart` redacts `phone`, `phoneNumber`, `email`, `password`, `token`, `firstName`, `lastName` through `_piiKeys` before `recordError`.
- **The admin console holds no database privileges.** `admin/js/api.js` deliberately imports no Firestore SDK; every read and write goes through a callable that re-checks the claim. Adding a Firestore import would silently undo the whole design.
- **The admin console escapes its output.** Every interpolated value passes through `esc()` in `ui.js`; labels and button text use `textContent`.
- **The `admin` claim cannot be escalated from inside the app.** It is minted only by `set_admin_claim.mjs` via the Admin SDK; no rule path or callable can produce it. Destructive callables additionally require a login under 2 hours old.
- **`storage.rules` default-denies** with owner checks, a 5 MB cap, and a MIME allowlist.
- **No HTTP-triggered functions exist** — everything is `onCall`, Firestore-triggered, or pubsub-scheduled, so there is no unauthenticated CORS surface.
- **Production PII snapshots are gitignored** (`functions/scripts/.local/`).
- **The admin console is not deployed** — `firebase.json` serves `public`, not `admin`. If that changes, it needs a CSP and an SRI hash on the Tailwind CDN `<script>` in `admin/index.html:9`.
