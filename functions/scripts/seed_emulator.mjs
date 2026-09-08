/**
 * Seed the local Firebase emulators with an admin account and sample data.
 *
 * Only ever talks to the emulators: the Admin SDK is pointed at them through
 * FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST, which are set below
 * before the SDK initialises. It cannot reach production even by accident.
 *
 * Usage (with `firebase emulators:start` already running):
 *   cd functions && node scripts/seed_emulator.mjs
 *
 * Safe to re-run — existing accounts are reused rather than duplicated.
 */
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:9555";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

import { createRequire } from "module";
const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const PROJECT_ID = "yuztoo";

const ADMIN_EMAIL = "admin@yuztoo.test";
const ADMIN_PASSWORD = "admin1234";

admin.initializeApp({ projectId: PROJECT_ID });
const auth = admin.auth();
const db = admin.firestore();

/** Create the account if missing, then return its uid. */
async function ensureUser({ email, password, displayName }) {
  try {
    const existing = await auth.getUserByEmail(email);
    return existing.uid;
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
  }
  const created = await auth.createUser({ email, password, displayName });
  return created.uid;
}

async function seedAdmin() {
  const uid = await ensureUser({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    displayName: "Admin Yuztoo",
  });
  await auth.setCustomUserClaims(uid, { admin: true });
  console.log(`✓ admin  ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}  (uid ${uid})`);
  return uid;
}

const SAMPLE_CLIENTS = [
  { first: "Camille", last: "Bernard", city: "Nantes" },
  { first: "Yanis", last: "Moreau", city: "Lyon" },
  { first: "Sofia", last: "Lopez", city: "Marseille" },
  { first: "Thomas", last: "Petit", city: "Nantes" },
];

const SAMPLE_STORES = [
  { name: "Boulangerie Saint-Michel", city: "Nantes", status: "active" },
  { name: "Café des Arts", city: "Lyon", status: "active" },
  { name: "Studio Coiffure Elle", city: "Marseille", status: "inactive" },
  { name: "Bistrot du Port", city: "Nantes", status: "active" },
];

async function seedClients() {
  const uids = [];
  for (const [index, client] of SAMPLE_CLIENTS.entries()) {
    const email = `${client.first.toLowerCase()}@yuztoo.test`;
    const phone = `+3360000000${index + 1}`;
    const uid = await ensureUser({
      email,
      password: "client1234",
      displayName: `${client.first} ${client.last}`,
    });

    await db.collection("users").doc(uid).set(
      {
        uid,
        email,
        phone,
        firstName: client.first,
        lastName: client.last,
        displayName: `${client.first} ${client.last}`,
        city: client.city,
        roles: { client: true, merchant: false, provider: false },
        primary_role: "client",
        onboarding: { client: "completed", merchant: "not_started" },
        merchant_id: null,
        status: "active",
        deleted_at: null,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection("email_index").doc(email).set({ uid });
    await db.collection("phone_index").doc(phone).set({ uid });
    uids.push(uid);
  }
  console.log(`✓ ${uids.length} clients`);
  return uids;
}

async function seedStores() {
  for (const [index, store] of SAMPLE_STORES.entries()) {
    const email = `pro${index + 1}@yuztoo.test`;
    const phone = `+3361111111${index + 1}`;
    const ownerUid = await ensureUser({
      email,
      password: "merchant1234",
      displayName: store.name,
    });

    const merchantRef = db.collection("merchants").doc(`seed-store-${index + 1}`);
    await merchantRef.set(
      {
        owner_uid: ownerUid,
        name: store.name,
        name_lowercase: store.name.toLowerCase(),
        display_name: store.name,
        email,
        phone,
        city: store.city,
        description: `Commerce de démonstration à ${store.city}.`,
        status: store.status,
        merchant_type: "commerce",
        deleted_at: null,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection("users").doc(ownerUid).set(
      {
        uid: ownerUid,
        email,
        phone,
        displayName: store.name,
        city: store.city,
        roles: { client: false, merchant: true, provider: true },
        primary_role: "merchant",
        onboarding: { client: "not_started", merchant: "completed" },
        merchant_id: merchantRef.id,
        status: "active",
        deleted_at: null,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection("email_index").doc(email).set({ uid: ownerUid });
    await db.collection("phone_index").doc(phone).set({ uid: ownerUid });
  }
  console.log(`✓ ${SAMPLE_STORES.length} boutiques (+ comptes propriétaires)`);
}

async function main() {
  console.log(`Seeding emulators for project "${PROJECT_ID}"…`);
  console.log(`  Firestore : ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log(`  Auth      : ${process.env.FIREBASE_AUTH_EMULATOR_HOST}\n`);

  await seedAdmin();
  await seedClients();
  await seedStores();

  console.log("\nDone. Sign in to the console with:");
  console.log(`  ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}`);
}

main().catch((error) => {
  console.error("\nSeeding failed. Are the emulators running?");
  console.error(error);
  process.exitCode = 1;
});
