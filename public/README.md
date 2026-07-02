# Yuztoo Hosting

Static assets served from `https://yuztoo.app`. Deployed by:

```bash
firebase deploy --only hosting
```

## Layout

| Path | Purpose |
|---|---|
| `/` | Marketing landing (`index.html`). |
| `/aide` | Help centre FAQ (`aide.html`). |
| `/vitrine/{merchantId}` | NFC tag landing (rewritten by `firebase.json` to `/vitrine.html`). Detects iOS / Android, fires the `yuztoo://` deep link, falls back to App Store / Play Store. |
| `/.well-known/apple-app-site-association` | Universal Links handshake for iOS. |
| `/apple-app-site-association` | Same content; some older iOS versions probe the bare path. Both files MUST stay in sync. |
| `/.well-known/assetlinks.json` | App Links handshake for Android. **Has SHA256 placeholders — see below.** |

## Pre-deploy checklist

1. **Replace the Play Store SHA256 placeholder in `.well-known/assetlinks.json`.**
   - `REPLACE_WITH_PLAY_STORE_APP_SIGNING_SHA256` → Play Console → Setup → App
     integrity → "App signing key certificate" → SHA-256 certificate fingerprint.
   - The second entry (`A8:8D:91:16:…:65:90`) is the **debug keystore** SHA256
     used for `flutter run --release` sideloads on QA devices. It's safe to
     ship — debug keys are public-by-construction. Drop it from the array
     once you no longer sideload Yuztoo for testing.
2. Verify the AASA file at `https://yuztoo.app/.well-known/apple-app-site-association`
   returns `Content-Type: application/json` (not `text/html`). The `firebase.json`
   `headers` block enforces it.
3. Verify the assetlinks file with the official Google statement-list tool
   once the SHA256 is filled in.

## Why two AASA paths?

iOS 14+ checks `/.well-known/apple-app-site-association` first; older iOS
versions checked `/apple-app-site-association`. Serving both maximises
compatibility for at-risk older devices and is the [Apple-recommended
fallback](https://developer.apple.com/documentation/xcode/supporting-associated-domains).
