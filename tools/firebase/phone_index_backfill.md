# One-time `phone_index` backfill

After deploying Firestore rules that add the `phone_index` collection, existing `users` documents may have a `phone` field but no corresponding `phone_index/{normalizedE164}` document. Until backfilled, a second account could theoretically be created with the same phone string as a legacy user (only the transaction + new writes prevent duplicates for new signups).

## What to run

Use the Firebase Admin SDK (Node script, Cloud Shell, or local with service account) to:

1. List all documents in `users` (Admin bypasses security rules).
2. For each document with a non-empty `phone` field, write `phone_index/{trimmedPhone}` with `{ uid: <document id> }` if that index doc does not exist or matches the same `uid`.

Normalize `phone` the same way as the app: **trimmed E.164** (same value as stored in `users.phone` from signup).

## Sketch (Node, Admin SDK)

```javascript
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function backfill() {
  const snap = await db.collection('users').get();
  const batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    const phone = (doc.data().phone || '').trim();
    if (!phone) continue;
    const ref = db.collection('phone_index').doc(phone);
    const existing = await ref.get();
    if (existing.exists && existing.data().uid !== doc.id) {
      console.warn('Conflict', phone, doc.id, existing.data().uid);
      continue;
    }
    if (!existing.exists) batch.set(ref, { uid: doc.id });
    n++;
  }
  await batch.commit();
  console.log('Processed', n);
}
```

Review conflicts manually before committing in production.
