# Meta App Review — kit « Yuztoo - msg »

Goal: move the Meta app from development mode (only app roles/testers can connect)
to **Advanced Access**, so real merchants can connect their Facebook Page and
Instagram professional account to the Yuztoo Sales CRM.

CRM: `https://yuztoo-msg.radnatech.it` · Operator: RADNATECH · Contact: contact@radnatech.io

---

## Status (2026-11-27)

- **Scope for this review:** only the Yuztoo Facebook Page and `@yuztoo` Instagram. Merchant onboarding stays on hold until Advanced Access is granted.
- **Instagram DMs:** customer DMs need Advanced Access for `instagram_manage_messages`. The App Review submission is filled and green; paste the reviewer CRM credentials, then Submit.
- **`@yuztoo`:** keep **Allow access to messages** on under Instagram → Connected tools (otherwise the webhook never delivers inbound DMs).
- **After approval:** rotate the `meta-review@radnatech.io` password (shared in chat for the reviewer). Keep the account until the review is closed.

---

## 1. App settings to fill (App Dashboard)

| Field | Value |
|---|---|
| Privacy Policy URL | `https://yuztoo-msg.radnatech.it/confidentialite/` |
| User data deletion → **Data deletion callback URL** | `https://zdzzmzcoxdogeqydargo.supabase.co/functions/v1/meta-data-deletion` |
| Facebook Login for Business → **Deauthorize callback URL** | `https://zdzzmzcoxdogeqydargo.supabase.co/functions/v1/meta-data-deletion?type=deauthorize` |
| Valid OAuth Redirect URIs | `https://yuztoo-msg.radnatech.it/meta-oauth` |
| App domains | `yuztoo-msg.radnatech.it` |
| Category | Business and pages |
| App icon | Yuztoo logo 1024×1024 |

Also required before review: **Business Verification** of RADNATECH in Business Manager,
and the app in **Live** mode once approved.

### What the callbacks do (`supabase/functions/meta-data-deletion`)

- Meta posts a `signed_request`; we verify its HMAC-SHA256 with `META_APP_SECRET`.
- **Deletion**: deletes every channel the person connected (cascade: page token,
  conversations, messages), logs the request in `meta_data_deletion_requests`, and
  answers `{ url, confirmation_code }`. The URL is the public status page
  `/suppression-donnees/statut/?code=…`.
- **Deauthorize**: disconnects those channels and blanks their tokens. The data stays
  until a deletion request arrives.
- People are matched by the app-scoped user ID saved at connect time
  (`meta_channel_credentials.meta_user_id`, set by `meta-oauth-complete`).
  Channels connected **before** this change have no ID: reconnect them once.

---

## 2. Permissions — justification to paste (one per permission)

Use case for every permission: *« Yuztoo Sales CRM lets the Yuztoo sales team and
the merchants who partner with Yuztoo manage their own Facebook Page and Instagram
professional account from one place: reply to messages, publish and schedule posts
and stories, and answer comments. Only Pages the user selects during Facebook Login
for Business are connected. »*

| Permission | Where it's used in the CRM | Justification (EN, for the form) |
|---|---|---|
| `pages_show_list` | Channel picker after login (`/me/accounts`) | Lists the Pages the user manages so they can choose which ones to connect to the CRM. |
| `pages_manage_metadata` | Webhook subscription (`/{page}/subscribed_apps`) | Subscribes the connected Page to our webhook so new messages and comments reach the CRM inbox in real time. |
| `pages_messaging` | Inbox: receive and reply to Messenger conversations (`/messages`, `/conversations`) | The Page's team reads and answers customer messages from the CRM inbox. Messages are only sent in reply to a person who wrote first, within the 24-hour window. |
| `instagram_basic` | Shows the IG account name, picture and follower count on the channel card | Identifies the Instagram professional account linked to the Page so the user can see which account they are managing. |
| `instagram_manage_messages` | Inbox: Instagram DMs, history import | The team reads and answers Instagram Direct messages from customers in the CRM inbox. |
| `pages_manage_posts` | Publications: publish and schedule Page posts (`/feed`, `/photos`, `/videos`) | The marketer writes a post once and publishes it now or at a scheduled time on the Page. |
| `instagram_content_publish` | Publications: IG feed posts and stories (`/media`, `/media_publish`, `/stories`) | Same composer publishes the post or story to the linked Instagram account. |
| `publish_video` | Publications with a video on the Page (`/videos`) | Lets the marketer publish a video post on the Page from the composer. |
| `pages_read_engagement` | Publications list: likes, comments count per post | Shows how each published post performs so the team can follow up. |
| `pages_read_user_content` | Comments panel: reads comments on Page posts | Shows the comments people left on the Page's posts so the team can answer them. |
| `pages_manage_engagement` | Comments panel: reply to / hide comments on Page posts | The team replies to or hides comments on their own Page posts from the CRM. |
| `instagram_manage_comments` | Comments panel for IG posts | The team reads, replies to and hides comments on their own Instagram posts. |
| `business_management` | No direct Graph call — needed when Pages are owned by a Business Manager | ⚠️ Only keep it if a test shows `/me/accounts` misses business-owned Pages without it. Otherwise **remove it from `SCOPES`** in `meta-oauth-start`: Meta rejects permissions the screencast doesn't show. |

`public_profile` is granted by default (no review).

---

## 3. Screencasts (one video per group, 1–3 min, English UI captions or voice-over)

Record on `https://yuztoo-msg.radnatech.it` with a **test** Page and IG account.
Show the browser URL bar. Meta wants the full flow: login → grant → feature in use.

**Video A — Connect (pages_show_list, instagram_basic, pages_manage_metadata, business_management)**
1. Log in to the CRM → **Canaux** → « Connecter Facebook / Instagram ».
2. The Facebook Login for Business dialog opens: select the Page and its Instagram account, then show every permission screen.
3. Back in the CRM: the Page and IG cards appear with name, picture and followers, status « Connecté ».

**Video B — Messages (pages_messaging, instagram_manage_messages)**
1. On a phone, send a DM to the test IG account and a Messenger message to the test Page.
2. In the CRM **Boîte de réception**, both conversations appear (Instagram / Facebook tabs) with the sender's name.
3. Reply from the CRM → show the reply arriving on the phone.
4. Show « Importer l'historique » loading older conversations.

**Video C — Publishing (pages_manage_posts, instagram_content_publish, publish_video)**
1. **Publications** → new post, add an image and text, select Page + IG.
2. Publish now → open the Page and the IG account and show the post live.
3. Create a scheduled post and a story → show them in the calendar, then live once published.
4. Publish one video post to the Page.

**Video D — Comments & engagement (pages_read_engagement, pages_read_user_content, pages_manage_engagement, instagram_manage_comments)**
1. From a phone, comment on the published post (Page and IG).
2. In the CRM, open the post → comments panel shows them with the engagement counts.
3. Reply to one comment and hide another → show the result on Facebook / Instagram.

**Reviewer test credentials** (form field): a CRM login dedicated to the reviewer
(owner of a demo workspace), plus a Facebook test user with the test Page.
Never give a real merchant's account.

---

## 4. Before you submit — checklist

- [ ] Migration `20261127090000_meta_data_deletion.sql` applied, then Supabase **advisors** (security + performance) run.
- [ ] Edge functions deployed: `meta-data-deletion` (verify_jwt = false), `meta-oauth-complete`.
- [ ] Test the deletion callback with Meta's « Test » button in App Dashboard → returns a code, and the status page shows it.
- [ ] Reconnect existing channels once so their `meta_user_id` is stored.
- [ ] `business_management` kept or removed (see table).
- [ ] Business Verification done.
- [ ] 4 screencasts uploaded, one per permission group.

---

## 5. After Meta approves (do not do during review)

- [ ] **Rotate the password** of `meta-review@radnatech.io` (it was shared in chat for App Review). Keep the account until the review is closed, then rotate or disable it.
- [ ] Confirm Advanced Access is live and merchants can connect Pages / IG without being app testers.
