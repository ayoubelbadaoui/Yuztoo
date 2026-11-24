#!/usr/bin/env node
/**
 * Backfill `city_keys` on existing merchants (Découvrir city query).
 *
 * The `onMerchantCityKeysSync` trigger keeps the field in sync on every new
 * write; this one-off pass fills the merchants written before it existed.
 * Run it BEFORE releasing the app build that queries `city_keys`, otherwise
 * shops without the field stay out of Découvrir until they are next saved.
 *
 * Usage (build first so ../lib exists):
 *   (cd functions && npm run build)
 *   node functions/scripts/backfill_merchant_city_keys.mjs --project yuztoo --dry-run
 *   node functions/scripts/backfill_merchant_city_keys.mjs --project yuztoo
 *
 * Writes only `city_keys` (never `updated_at`), and only when the key set
 * differs, so it is safe to run again.
 */
import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getFirestore, FieldPath } from 'firebase-admin/firestore';
import { merchantCityKeys, sameKeys } from '../lib/merchant_city_keys_core.js';

const args = process.argv.slice(2);
const projectId = argValue('--project') || 'yuztoo';
const dryRun = args.includes('--dry-run');
const pageSize = 300;

function argValue(flag) {
  const i = args.indexOf(flag);
  return i >= 0 ? args[i + 1] : null;
}

async function main() {
  if (!getApps().length) {
    initializeApp({ credential: applicationDefault(), projectId });
  }
  const db = getFirestore();
  console.log(`Project=${projectId} dryRun=${dryRun}`);

  let scanned = 0;
  let changed = 0;
  let last = null;
  for (;;) {
    let q = db.collection('merchants').orderBy(FieldPath.documentId()).limit(pageSize);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;

    const batch = db.batch();
    let inBatch = 0;
    for (const doc of page.docs) {
      scanned++;
      const data = doc.data();
      const keys = merchantCityKeys(data);
      if (sameKeys(data.city_keys, keys)) continue;
      changed++;
      console.log(`${doc.id}  city=${JSON.stringify(data.city ?? null)}  →  ${JSON.stringify(keys)}`);
      if (!dryRun) {
        batch.update(doc.ref, { city_keys: keys });
        inBatch++;
      }
    }
    if (inBatch > 0) await batch.commit();
    last = page.docs[page.docs.length - 1];
  }

  console.log(`Done. scanned=${scanned} ${dryRun ? 'would update' : 'updated'}=${changed}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
