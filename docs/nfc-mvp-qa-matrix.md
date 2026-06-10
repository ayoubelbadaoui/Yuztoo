# NFC MVP — QA matrix

Manual checklist run on physical devices before shipping the NFC MVP. Hardware reference: **NTAG213** transparent adhesive 25 mm, 13.56 MHz (NDEF Type 2).

> Stickers must be NDEF-formatted and unlocked when shipped. The
> defensive guards in `NfcService.writeVitrineUrl` surface clear French
> errors for `ndefAvailable=false`, `ndefWritable=false`, and oversized
> URLs — capture any failure case in the **Notes** column.

## Merchant programming

| Device | OS | Status | Notes |
|---|---|---|---|
| iPhone (A‑series, NFC capable) | iOS 15.x | ☐ | Reader sheet labelled "Approchez votre téléphone…" |
| iPhone | iOS 16.x | ☐ | |
| iPhone | iOS 17.x | ☐ | |
| iPhone | iOS 18.x | ☐ | |
| Pixel / Samsung mid-range | Android 10 | ☐ | |
| Pixel / Samsung mid-range | Android 12 | ☐ | |
| Pixel / Samsung flagship | Android 14 | ☐ | |

For each row above:

- [ ] `Programmer un badge NFC` button visible on `MerchantQRCodeScreen`.
- [ ] Tag write succeeds → success toast in French.
- [ ] Re-read the freshly programmed tag with another phone (different brand if possible) → opens the merchant vitrine in the app.
- [ ] Same merchantId can be programmed onto two NTAG213 stickers; both lead to the same vitrine.
- [ ] Locked NTAG213 (manually permanently locked) → friendly French error; no crash.
- [ ] Tag held at suboptimal distance (1 cm air gap) → 2-second retry succeeds, no double-write.

## Client read — in-app NFC scanner

| Device | OS | Status | Notes |
|---|---|---|---|
| iPhone | iOS 15.x | ☐ | Reader sheet uses `NFCReaderUsageDescription` copy. |
| iPhone | iOS 18.x | ☐ | |
| Android (mid-range) | 12 | ☐ | |
| Android (flagship) | 14 | ☐ | |

For each row above:

- [ ] `qr_scanner_screen` toggle to NFC mode → "Approchez votre téléphone…" prompt.
- [ ] Reads a programmed NTAG213 → vitrine opens.
- [ ] Reads a fresh / non-programmed sticker → French message "Ce badge NFC est vide…".
- [ ] Reads a non-Yuztoo URL tag → French message "Ce badge ne pointe pas vers une vitrine Yuztoo."
- [ ] User cancels reader → no error toast.

## Client read — passive tap (Universal Link / App Links)

| Device | OS | Status | Notes |
|---|---|---|---|
| iPhone | iOS 15+ | ☐ | App installed → tag tap routes through `app_links`. |
| iPhone (no Yuztoo) | iOS 15+ | ☐ | Tag tap → Safari → web landing → App Store CTA. |
| Android | 10+ | ☐ | App installed → autoVerify=true, no chooser. |
| Android (no Yuztoo) | 10+ | ☐ | Tag tap → Chrome → web landing → Play Store CTA. |

- [ ] Logged-out tap → vitrine accessible without forced login (NFC MVP behavior).
- [ ] Logged-in follower + automatic mode → silent visit + gold celebration overlay within ~1 s.
- [ ] Logged-in follower + manual mode → live "validation en cours" banner, merchant queue gets the request.
- [ ] Re-tap within 1 hour → cooldown snackbar, no double increment.
- [ ] Cold-start while signing up → tag merchantId persisted in SharedPreferences; vitrine opens once onboarding completes (24h TTL).

## Edge cases

- [ ] Multiple tags in the antenna field at once → iOS sheet shows multi-tag message; Android picks one.
- [ ] NFC disabled in OS settings → friendly French message in scanner; programming button shows "NFC non disponible".
- [ ] Bluetooth still works as a fallback (BLE proximity validation untouched by this MVP).
- [ ] Merchant's `display_name` change after the tag was programmed → notifications and storefront show the new name (URL is keyed on `merchantId`, not name).

## Sticker batch QA (ops)

- [ ] Lot tested: ____________
- [ ] Sample size: __ / 25
- [ ] Pass rate ≥ 95 %.
- [ ] Capture any failed sticker in `docs/nfc-mvp-bad-stickers.md` with batch number.

## Out of scope

- Phone-as-badge (HCE) — never planned.
- Per-tag analytics or `nfc_tags` collection.
- Custom NDEF messages per tag.
- Anti-fraud beyond the 1 hour cooldown.
