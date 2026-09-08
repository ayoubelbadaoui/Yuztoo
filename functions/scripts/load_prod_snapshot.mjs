/**
 * Load a read-only capture of production into the local emulators.
 *
 * Why this exists: the demo seed ("Boulangerie Saint-Michel" and friends) is
 * idealised — every field populated, every relation intact. Real data is not.
 * It has stores whose owner account no longer exists, accounts pointing at
 * stores that were deleted, and documents missing `city`, `phone` or even
 * `status`. Exercising the CRM against the real shapes is the only way to know
 * it holds up.
 *
 * Direction of travel is one-way. Like `seed_emulator.mjs`, this points the
 * Admin SDK at the emulators before it initialises, so it cannot write to
 * production even by accident. Editing or deleting anything in the console
 * afterwards touches the emulator copy only.
 *
 * The snapshot itself lives in `scripts/.local/` and is gitignored: it holds
 * real customer names, e-mail addresses and phone numbers.
 *
 * Usage (with `firebase emulators:start` already running):
 *   cd functions && node scripts/load_prod_snapshot.mjs
 *
 * Re-running replaces the `merchants` and `users` collections wholesale.
 */
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:9555";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { createRequire } from "module";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const PROJECT_ID = "yuztoo";
const ADMIN_EMAIL = "admin@yuztoo.test";
const ADMIN_PASSWORD = "admin1234";

const here = dirname(fileURLToPath(import.meta.url));
const SNAPSHOT_PATH = join(here, ".local", "prod_snapshot.json");

admin.initializeApp({ projectId: PROJECT_ID });
const auth = admin.auth();
const db = admin.firestore();
const { Timestamp } = admin.firestore;

/** ISO strings in the snapshot become real Timestamps in Firestore. */
const DATE_FIELDS = ["created_at", "updated_at", "deleted_at"];

function toFirestore(record) {
  const { id, ...fields } = record;
  for (const key of DATE_FIELDS) {
    if (typeof fields[key] === "string") {
      fields[key] = Timestamp.fromDate(new Date(fields[key]));
    }
  }
  return { id, fields };
}

/** Delete every document in a collection so re-runs don't leave demo rows. */
async function clearCollection(name) {
  const snapshot = await db.collection(name).get();
  if (snapshot.empty) return 0;
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return snapshot.size;
}

async function loadMerchants(merchants) {
  const batch = db.batch();
  for (const merchant of merchants) {
    const { id, fields } = toFirestore(merchant);
    batch.set(db.collection("merchants").doc(id), {
      deleted_at: null,
      ...fields,
    });
  }
  await batch.commit();

  const online = merchants.filter((m) => m.status === "active").length;
  console.log(
    `✓ ${merchants.length} boutiques (${online} en ligne, ${merchants.length - online} hors ligne)`
  );
}

/**
 * Write the user documents plus the Auth accounts behind them.
 *
 * The Auth account matters: `adminGetUser` reads the Auth record, and
 * block/unblock toggles `disabled` on it. Without these, every client row
 * would look half-broken in the console for reasons that have nothing to do
 * with the data.
 */
async function loadUsers(users) {
  const batch = db.batch();
  let authCreated = 0;

  for (const user of users) {
    const { id, fields } = toFirestore(user);

    batch.set(db.collection("users").doc(id), {
      uid: id,
      deleted_at: null,
      ...fields,
    });

    if (fields.email) {
      batch.set(db.collection("email_index").doc(fields.email), { uid: id });
    }
    if (fields.phone) {
      batch.set(db.collection("phone_index").doc(fields.phone), { uid: id });
    }

    try {
      await auth.getUser(id);
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
      await auth.createUser({
        uid: id,
        ...(fields.email ? { email: fields.email } : {}),
        ...(fields.displayName ? { displayName: fields.displayName } : {}),
      });
      authCreated += 1;
    }
  }

  await batch.commit();
  const merchants = users.filter((u) => u.merchant_id).length;
  console.log(
    `✓ ${users.length} clients (${merchants} liés à une boutique, ${authCreated} comptes Auth créés)`
  );
}

async function ensureAdmin() {
  let uid;
  try {
    uid = (await auth.getUserByEmail(ADMIN_EMAIL)).uid;
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    uid = (
      await auth.createUser({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        displayName: "Admin Yuztoo",
      })
    ).uid;
  }
  await auth.setCustomUserClaims(uid, { admin: true });
  console.log(`✓ admin  ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
}

/** Relations the console has to survive; reported so they aren't a surprise. */
function reportIntegrity({ merchants, users }) {
  const userIds = new Set(users.map((u) => u.id));
  const merchantIds = new Set(merchants.map((m) => m.id));

  const orphanStores = merchants.filter((m) => !userIds.has(m.owner_uid));
  const danglingLinks = users.filter(
    (u) => u.merchant_id && !merchantIds.has(u.merchant_id)
  );

  if (orphanStores.length === 0 && danglingLinks.length === 0) return;

  console.log("\nAnomalies présentes dans les données réelles :");
  for (const store of orphanStores) {
    console.log(`  · boutique "${store.name}" (${store.id}) — propriétaire introuvable`);
  }
  for (const user of danglingLinks) {
    console.log(`  · compte ${user.id} — merchant_id "${user.merchant_id}" inexistant`);
  }
}

async function main() {
  let snapshot;
  try {
    snapshot = JSON.parse(readFileSync(SNAPSHOT_PATH, "utf8"));
  } catch {
    console.error(`Snapshot introuvable : ${SNAPSHOT_PATH}`);
    console.error("Ce fichier est gitignoré (données personnelles réelles).");
    process.exitCode = 1;
    return;
  }

  console.log(`Chargement du snapshot du ${snapshot.capturedAt}`);
  console.log(`  Firestore : ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log(`  Auth      : ${process.env.FIREBASE_AUTH_EMULATOR_HOST}\n`);

  const removed = [];
  for (const name of ["merchants", "users", "email_index", "phone_index"]) {
    removed.push(`${name}: ${await clearCollection(name)}`);
  }
  console.log(`✓ collections vidées (${removed.join(", ")})`);

  await ensureAdmin();
  await loadMerchants(snapshot.merchants);
  await loadUsers(snapshot.users);
  reportIntegrity(snapshot);

  console.log(`\nTerminé. Connectez-vous avec ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
}

main().catch((error) => {
  console.error("\nÉchec du chargement. Les émulateurs sont-ils démarrés ?");
  console.error(error);
  process.exitCode = 1;
});
