/**
 * End-to-end smoke test for the admin CRM.
 *
 * Drives every callable in `functions/src/admin/**` over HTTP exactly the way
 * the browser console does — real Firebase Auth ID tokens, real callable
 * protocol, real Firestore writes. Nothing is stubbed, so a pass here means
 * the console's data path works, not merely that the code compiles.
 *
 * It runs against the emulators, which by then hold a copy of production
 * (`load_prod_snapshot.mjs`). That matters: the demo seed is idealised, while
 * the real data has stores whose owner no longer exists and accounts pointing
 * at stores that were deleted. Those are the shapes that break a CRM.
 *
 * Every mutation is undone before the test exits, so the emulator is left as
 * it was found and the script can be re-run without reloading the snapshot.
 *
 * Usage (with `firebase emulators:start` already running):
 *   cd functions && node scripts/crm_smoke_test.mjs
 */
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:9555";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

import { createRequire } from "module";

const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const PROJECT_ID = "yuztoo";
const REGION = "europe-west1";
const FUNCTIONS_URL = `http://127.0.0.1:5001/${PROJECT_ID}/${REGION}`;
const AUTH_URL = `http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1`;

const ADMIN_EMAIL = "admin@yuztoo.test";
const ADMIN_PASSWORD = "admin1234";
const INTRUDER_EMAIL = "intruder@yuztoo.test";
const INTRUDER_PASSWORD = "intruder1234";

admin.initializeApp({ projectId: PROJECT_ID });
const auth = admin.auth();
const db = admin.firestore();

// ─── tiny harness ────────────────────────────────────────────────────────────

const results = [];
let currentSection = "";

function section(title) {
  currentSection = title;
  console.log(`\n\x1b[1m${title}\x1b[0m`);
}

async function test(name, fn) {
  try {
    const detail = await fn();
    results.push({ section: currentSection, name, ok: true });
    console.log(`  \x1b[32m✓\x1b[0m ${name}${detail ? `  \x1b[2m${detail}\x1b[0m` : ""}`);
  } catch (e) {
    results.push({ section: currentSection, name, ok: false, error: e });
    console.log(`  \x1b[31m✗\x1b[0m ${name}`);
    console.log(`      \x1b[31m${e.message}\x1b[0m`);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message} — expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

// ─── callable transport ──────────────────────────────────────────────────────

/** Invoke a callable the way the Firebase JS SDK does. */
async function call(name, data, token) {
  const res = await fetch(`${FUNCTIONS_URL}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ data: data ?? {} }),
  });

  const body = await res.json().catch(() => ({}));
  if (body.error) {
    const error = new Error(body.error.message ?? "unknown error");
    error.status = body.error.status ?? `HTTP_${res.status}`;
    throw error;
  }
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return body.result;
}

/** Assert a callable is rejected with a specific gRPC status. */
async function expectRejection(name, data, token, expectedStatus) {
  try {
    await call(name, data, token);
  } catch (e) {
    assertEqual(e.status, expectedStatus, `${name} rejection status`);
    return e.status;
  }
  throw new Error(`${name} unexpectedly succeeded — expected ${expectedStatus}`);
}

/** Exchange a password for an ID token, so claims land in the token. */
async function signIn(email, password) {
  const res = await fetch(`${AUTH_URL}/accounts:signInWithPassword?key=fake-api-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const body = await res.json();
  if (!body.idToken) throw new Error(`sign-in failed for ${email}: ${JSON.stringify(body)}`);
  return { token: body.idToken, uid: body.localId };
}

async function ensureUser(email, password, claims) {
  let record;
  try {
    record = await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    record = await auth.createUser({ email, password });
  }
  await auth.updateUser(record.uid, { password, disabled: false });
  await auth.setCustomUserClaims(record.uid, claims);
  return record.uid;
}

const docData = async (collection, id) =>
  (await db.collection(collection).doc(id).get()).data();

// ─── suite ───────────────────────────────────────────────────────────────────

async function main() {
  console.log("Admin CRM — end-to-end smoke test");
  console.log(`  Functions : ${FUNCTIONS_URL}`);
  console.log(`  Firestore : ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log(`  Auth      : ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);

  await ensureUser(ADMIN_EMAIL, ADMIN_PASSWORD, { admin: true });
  await ensureUser(INTRUDER_EMAIL, INTRUDER_PASSWORD, {});
  const { token: adminToken, uid: adminUid } = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
  const { token: intruderToken } = await signIn(INTRUDER_EMAIL, INTRUDER_PASSWORD);

  const auditBefore = (await db.collection("admin_audit_log").count().get()).data().count;

  // Pick real targets out of the loaded snapshot rather than hardcoding IDs.
  const merchantDocs = (await db.collection("merchants").get()).docs;
  const userDocs = (await db.collection("users").get()).docs;
  assert(merchantDocs.length > 0, "no merchants loaded — run load_prod_snapshot.mjs first");
  assert(userDocs.length > 0, "no users loaded — run load_prod_snapshot.mjs first");

  const targetMerchant = merchantDocs.find((d) => d.data().status === "active") ?? merchantDocs[0];
  const merchantId = targetMerchant.id;
  const merchantName = targetMerchant.data().name;

  // A plain client: no store of its own, so store tests can't collide with it.
  const targetUser =
    userDocs.find((d) => !d.data().merchant_id && d.id !== adminUid) ?? userDocs[0];
  const userId = targetUser.id;

  const createdMerchantIds = [];
  const createdClientIds = [];

  // Captured up front so cleanup can put the real record back exactly, whether
  // or not the test that touched it got as far as reverting.
  const originalUserCity = targetUser.data().city ?? null;

  // ── guards ─────────────────────────────────────────────────────────────────
  section("Access control");

  await test("anonymous call is rejected", () =>
    expectRejection("adminListMerchants", {}, null, "UNAUTHENTICATED"));

  await test("signed-in non-admin is rejected", () =>
    expectRejection("adminListMerchants", {}, intruderToken, "PERMISSION_DENIED"));

  await test("non-admin cannot delete a store", () =>
    expectRejection("adminSoftDeleteMerchant", { merchantId }, intruderToken, "PERMISSION_DENIED"));

  await test("audit log is unreadable from a client", async () => {
    const res = await fetch(
      `http://127.0.0.1:9555/v1/projects/${PROJECT_ID}/databases/(default)/documents/admin_audit_log`
    );
    const body = await res.json();
    assert(Boolean(body.error), "rules allowed a client to list admin_audit_log");
    return "rules deny list";
  });

  // ── dashboard ──────────────────────────────────────────────────────────────
  section("Dashboard");

  await test("adminGetOverview returns real counts", async () => {
    const o = await call("adminGetOverview", {}, adminToken);
    assertEqual(o.merchants.live, merchantDocs.length, "merchants.live");
    assertEqual(o.clients.live, userDocs.length, "clients.live");
    assert(o.merchants.online + o.merchants.offline === o.merchants.live, "online + offline ≠ live");
    return `${o.merchants.live} boutiques (${o.merchants.online} en ligne) · ${o.clients.live} clients`;
  });

  // ── stores: read ───────────────────────────────────────────────────────────
  section("Stores — read");

  await test("adminListMerchants returns the real catalogue", async () => {
    const { items } = await call("adminListMerchants", { limit: 100 }, adminToken);
    assertEqual(items.length, merchantDocs.length, "item count");
    assert(items.every((i) => typeof i.name === "string"), "every row has a name");
    return items.slice(0, 2).map((i) => i.name).join(", ") + ", …";
  });

  await test("pagination walks the whole collection without repeats", async () => {
    const seen = new Set();
    let cursor = null;
    for (let page = 0; page < 20; page += 1) {
      const res = await call("adminListMerchants", { limit: 5, cursor }, adminToken);
      res.items.forEach((i) => seen.add(i.id));
      cursor = res.nextCursor;
      if (!cursor) break;
    }
    assertEqual(seen.size, merchantDocs.length, "unique stores across pages");
    return `${seen.size} stores over pages of 5`;
  });

  await test("prefix search finds a known store", async () => {
    const prefix = merchantName.slice(0, 3).toLowerCase();
    const { items } = await call("adminListMerchants", { search: prefix, limit: 50 }, adminToken);
    assert(items.some((i) => i.id === merchantId), `"${prefix}" did not return ${merchantName}`);
    return `"${prefix}" → ${items.length} hit(s)`;
  });

  await test("status filter returns only online stores", async () => {
    const { items } = await call("adminListMerchants", { status: "active", limit: 100 }, adminToken);
    assert(items.every((i) => i.status === "active"), "a non-active store leaked in");
    return `${items.length} en ligne`;
  });

  await test("invalid status filter is rejected", () =>
    expectRejection("adminListMerchants", { status: "bogus" }, adminToken, "INVALID_ARGUMENT"));

  await test("adminGetMerchant returns the store and its owner", async () => {
    const res = await call("adminGetMerchant", { merchantId }, adminToken);
    assertEqual(res.merchant.id, merchantId, "merchant id");
    return res.owner ? `owner: ${res.owner.email ?? res.owner.uid}` : "owner: none (orphan store)";
  });

  await test("orphan store (owner deleted in prod) does not break the detail view", async () => {
    const orphan = merchantDocs.find((d) => !userDocs.some((u) => u.id === d.data().owner_uid));
    if (!orphan) return "no orphan in snapshot";
    const res = await call("adminGetMerchant", { merchantId: orphan.id }, adminToken);
    assertEqual(res.owner, null, "orphan owner should be null, not an error");
    return `"${orphan.data().name}" → owner null, no crash`;
  });

  await test("unknown store id returns not-found", () =>
    expectRejection("adminGetMerchant", { merchantId: "does-not-exist" }, adminToken, "NOT_FOUND"));

  // ── stores: write ──────────────────────────────────────────────────────────
  section("Stores — mettre en ligne / hors ligne");

  const originalStatus = targetMerchant.data().status;

  await test("taking a store offline persists", async () => {
    await call("adminSetMerchantStatus", { merchantId, status: "inactive" }, adminToken);
    assertEqual((await docData("merchants", merchantId)).status, "inactive", "stored status");
    return `${merchantName} → hors ligne`;
  });

  await test("putting it back online persists", async () => {
    await call("adminSetMerchantStatus", { merchantId, status: "active" }, adminToken);
    assertEqual((await docData("merchants", merchantId)).status, "active", "stored status");
    return `${merchantName} → en ligne`;
  });

  await test("invalid status value is rejected", () =>
    expectRejection("adminSetMerchantStatus", { merchantId, status: "maybe" }, adminToken, "INVALID_ARGUMENT"));

  section("Stores — edit");

  const originalDescription = targetMerchant.data().description ?? null;

  await test("editing an allowlisted field persists", async () => {
    await call(
      "adminUpdateMerchant",
      { merchantId, patch: { description: "SMOKE TEST — description" } },
      adminToken
    );
    assertEqual(
      (await docData("merchants", merchantId)).description,
      "SMOKE TEST — description",
      "description"
    );
    return "description written";
  });

  await test("renaming keeps the search key in sync", async () => {
    await call("adminUpdateMerchant", { merchantId, patch: { name: "SMOKE Rename" } }, adminToken);
    const after = await docData("merchants", merchantId);
    assertEqual(after.name_lowercase, "smoke rename", "name_lowercase");
    const { items } = await call("adminListMerchants", { search: "smoke", limit: 10 }, adminToken);
    assert(items.some((i) => i.id === merchantId), "renamed store not findable by new name");
    await call("adminUpdateMerchant", { merchantId, patch: { name: merchantName } }, adminToken);
    return "name_lowercase + search follow the rename";
  });

  await test("non-allowlisted fields are dropped, not written", async () => {
    const res = await call(
      "adminUpdateMerchant",
      { merchantId, patch: { description: "still fine", owner_uid: "hijacked", status: "active" } },
      adminToken
    );
    assert(res.rejectedFields.includes("owner_uid"), "owner_uid should be rejected");
    assert(res.rejectedFields.includes("status"), "status should be rejected");
    assert((await docData("merchants", merchantId)).owner_uid !== "hijacked", "owner_uid was overwritten!");
    return `dropped: ${res.rejectedFields.join(", ")}`;
  });

  await test("empty patch is rejected", () =>
    expectRejection("adminUpdateMerchant", { merchantId, patch: {} }, adminToken, "INVALID_ARGUMENT"));

  section("Stores — soft delete and restore");

  await test("soft delete flags the store and forces it offline", async () => {
    await call("adminSoftDeleteMerchant", { merchantId, reason: "smoke test" }, adminToken);
    const after = await docData("merchants", merchantId);
    assert(after.deleted_at, "deleted_at not set");
    assertEqual(after.status, "inactive", "status after delete");
    assertEqual(after.status_before_delete, "active", "status_before_delete remembered");
    return "deleted_at set, forced hors ligne";
  });

  await test("deleted store disappears from the active list", async () => {
    const { items } = await call("adminListMerchants", { limit: 100 }, adminToken);
    assert(!items.some((i) => i.id === merchantId), "deleted store still in active list");
    return `${items.length} actifs`;
  });

  await test("deleted store appears in the corbeille", async () => {
    const { items } = await call("adminListMerchants", { listMode: "deleted", limit: 100 }, adminToken);
    assert(items.some((i) => i.id === merchantId), "deleted store missing from corbeille");
    return `${items.length} supprimé(s)`;
  });

  await test("a deleted store cannot be put back online", () =>
    expectRejection("adminSetMerchantStatus", { merchantId, status: "active" }, adminToken, "FAILED_PRECONDITION"));

  await test("deleting twice is refused", () =>
    expectRejection("adminSoftDeleteMerchant", { merchantId }, adminToken, "FAILED_PRECONDITION"));

  await test("restore brings back the previous status", async () => {
    const res = await call("adminRestoreMerchant", { merchantId }, adminToken);
    const after = await docData("merchants", merchantId);
    assertEqual(after.deleted_at, null, "deleted_at cleared");
    assertEqual(after.status, "active", "status restored");
    assertEqual(res.status, "active", "returned status");
    return "back en ligne";
  });

  // ── stores: create ─────────────────────────────────────────────────────────
  section("Stores — create");

  await test("creating a store links it to its owner", async () => {
    const owner = userDocs.find((d) => !d.data().merchant_id && d.id !== adminUid && d.id !== userId);
    if (!owner) return "no unlinked account available in snapshot";
    const res = await call(
      "adminCreateMerchant",
      { ownerUid: owner.id, name: "SMOKE Boutique", city: "Paris" },
      adminToken
    );
    createdMerchantIds.push(res.merchantId);
    const store = await docData("merchants", res.merchantId);
    assertEqual(store.owner_uid, owner.id, "owner_uid");
    assertEqual(store.status, "inactive", "new stores start offline");
    assertEqual((await docData("users", owner.id)).merchant_id, res.merchantId, "owner back-link");
    return `${res.merchantId} → inactive, owner linked`;
  });

  await test("creating a store for an unknown owner is refused", () =>
    expectRejection(
      "adminCreateMerchant",
      { ownerUid: "nobody", name: "X", city: "Y" },
      adminToken,
      "NOT_FOUND"
    ));

  // ── clients ────────────────────────────────────────────────────────────────
  section("Clients — read");

  await test("adminListUsers returns the real client base", async () => {
    const { items } = await call("adminListUsers", { limit: 100 }, adminToken);
    assert(items.length >= userDocs.length, "fewer clients than Firestore holds");
    return `${items.length} clients`;
  });

  await test("client pagination reaches every account", async () => {
    const seen = new Set();
    let cursor = null;
    for (let page = 0; page < 40; page += 1) {
      const res = await call("adminListUsers", { limit: 4, cursor }, adminToken);
      res.items.forEach((i) => seen.add(i.id));
      cursor = res.nextCursor;
      if (!cursor) break;
    }
    assertEqual(seen.size, userDocs.length, "unique clients across pages");
    return `${seen.size} clients over pages of 4`;
  });

  await test("adminGetUser joins Firestore, Auth and the owned store", async () => {
    const res = await call("adminGetUser", { uid: userId }, adminToken);
    assertEqual(res.user.id ?? res.user.uid, userId, "user id");
    return res.auth ? "auth record joined" : "no auth record (Firestore-only account)";
  });

  await test("account whose merchant_id points at a deleted store still loads", async () => {
    const dangling = userDocs.find(
      (d) => d.data().merchant_id && !merchantDocs.some((m) => m.id === d.data().merchant_id)
    );
    if (!dangling) return "no dangling link in snapshot";
    const res = await call("adminGetUser", { uid: dangling.id }, adminToken);
    assertEqual(res.merchant, null, "dangling merchant should resolve to null");
    return `${dangling.id} → merchant null, no crash`;
  });

  section("Clients — block, edit, delete");

  await test("blocking a client disables the Auth account", async () => {
    await call("adminSetUserStatus", { uid: userId, status: "blocked" }, adminToken);
    assertEqual((await docData("users", userId)).status, "blocked", "Firestore status");
    const record = await auth.getUser(userId).catch(() => null);
    if (record) assertEqual(record.disabled, true, "Auth account disabled");
    return record ? "Firestore + Auth both blocked" : "Firestore blocked (no Auth record)";
  });

  await test("unblocking re-enables sign-in", async () => {
    await call("adminSetUserStatus", { uid: userId, status: "active" }, adminToken);
    assertEqual((await docData("users", userId)).status, "active", "Firestore status");
    const record = await auth.getUser(userId).catch(() => null);
    if (record) assertEqual(record.disabled, false, "Auth account re-enabled");
    return "active again";
  });

  await test("editing a client profile field persists", async () => {
    await call("adminUpdateUser", { uid: userId, patch: { city: "SMOKE City" } }, adminToken);
    assertEqual((await docData("users", userId)).city, "SMOKE City", "city");
    return "city written";
  });

  await test("client patch also drops non-allowlisted fields", async () => {
    const res = await call(
      "adminUpdateUser",
      { uid: userId, patch: { city: "SMOKE City 2", roles: { admin: true }, merchant_id: "x" } },
      adminToken
    );
    assert(res.rejectedFields.includes("roles"), "roles should be rejected");
    assert(res.rejectedFields.includes("merchant_id"), "merchant_id should be rejected");
    const after = await docData("users", userId);
    assert(!after.roles?.admin, "roles.admin was written!");
    return `dropped: ${res.rejectedFields.join(", ")}`;
  });

  await test("an admin cannot delete their own account", () =>
    expectRejection("adminSoftDeleteUser", { uid: adminUid }, adminToken, "FAILED_PRECONDITION"));

  await test("soft delete blocks the client and flags the document", async () => {
    await call("adminSoftDeleteUser", { uid: userId, reason: "smoke test" }, adminToken);
    const after = await docData("users", userId);
    assert(after.deleted_at, "deleted_at not set");
    assertEqual(after.status, "blocked", "status after delete");
    return "deleted_at set, access revoked";
  });

  await test("restore returns the client to their previous status", async () => {
    await call("adminRestoreUser", { uid: userId }, adminToken);
    const after = await docData("users", userId);
    assertEqual(after.deleted_at, null, "deleted_at cleared");
    assertEqual(after.status, "active", "status restored");
    return "active again";
  });

  await test("deleting a store owner cascades to their store", async () => {
    const owner = userDocs.find(
      (d) => d.data().merchant_id && merchantDocs.some((m) => m.id === d.data().merchant_id)
    );
    if (!owner) return "no linked owner in snapshot";
    const ownedId = owner.data().merchant_id;

    const res = await call("adminSoftDeleteUser", { uid: owner.id, reason: "cascade check" }, adminToken);
    assertEqual(res.cascadedMerchantId, ownedId, "cascaded merchant id");
    const store = await docData("merchants", ownedId);
    assert(store.deleted_at, "owned store was not soft-deleted");
    assertEqual(store.deleted_via, "owner_cascade", "cascade tag");

    const restore = await call("adminRestoreUser", { uid: owner.id }, adminToken);
    assertEqual(restore.restoredMerchantId ?? ownedId, ownedId, "cascade restore");
    const restored = await docData("merchants", ownedId);
    assertEqual(restored.deleted_at, null, "store not restored with owner");
    return `${ownedId} deleted and restored with its owner`;
  });

  section("Clients — create");

  await test("creating a client provisions Auth, Firestore and the dedup indexes", async () => {
    const email = `smoke-${Date.now()}@yuztoo.test`;
    const res = await call(
      "adminCreateClient",
      { email, firstName: "Smoke", lastName: "Test", city: "Lyon" },
      adminToken
    );
    createdClientIds.push({ uid: res.uid, email });
    assert(await auth.getUser(res.uid), "no Auth account");
    assertEqual((await docData("users", res.uid)).email, email, "user document email");
    assert((await db.collection("email_index").doc(email).get()).exists, "email_index missing");
    assert(res.passwordResetLink, "no password reset link returned");
    return "auth + user + email_index + reset link";
  });

  await test("a duplicate email is refused", async () => {
    const existing = userDocs.find((d) => d.data().email)?.data().email;
    if (!existing) return "no indexed email in snapshot";
    return expectRejection("adminCreateClient", { email: existing }, adminToken, "ALREADY_EXISTS");
  });

  // ── audit ──────────────────────────────────────────────────────────────────
  section("Audit trail");

  await test("every mutation was recorded", async () => {
    const after = (await db.collection("admin_audit_log").count().get()).data().count;
    const written = after - auditBefore;
    assert(written > 0, "no audit entries written");

    const recent = await db
      .collection("admin_audit_log")
      .orderBy("created_at", "desc")
      .limit(written)
      .get();
    const actions = new Set(recent.docs.map((d) => d.data().action));
    for (const expected of [
      "merchant.status_changed",
      "merchant.updated",
      "merchant.soft_deleted",
      "merchant.restored",
      "user.status_changed",
      "user.soft_deleted",
    ]) {
      assert(actions.has(expected), `missing audit action: ${expected}`);
    }
    assert(
      recent.docs.every((d) => d.data().actor_uid === adminUid),
      "an entry is missing its actor"
    );
    return `${written} entries, all attributed to ${ADMIN_EMAIL}`;
  });

  // ── cleanup ────────────────────────────────────────────────────────────────
  section("Cleanup");

  await test("test records removed and originals restored", async () => {
    await db.collection("merchants").doc(merchantId).update({
      status: originalStatus,
      name: merchantName,
      name_lowercase: merchantName.toLowerCase(),
      description: originalDescription,
    });
    await db.collection("users").doc(userId).update({ city: originalUserCity });

    for (const id of createdMerchantIds) {
      const store = await docData("merchants", id);
      if (store?.owner_uid) {
        await db.collection("users").doc(store.owner_uid).update({ merchant_id: null });
      }
      await db.collection("merchants").doc(id).delete();
    }
    for (const { uid, email } of createdClientIds) {
      await db.collection("users").doc(uid).delete();
      await db.collection("email_index").doc(email).delete();
      await auth.deleteUser(uid).catch(() => {});
    }

    const merchantsNow = (await db.collection("merchants").count().get()).data().count;
    const usersNow = (await db.collection("users").count().get()).data().count;
    assertEqual(merchantsNow, merchantDocs.length, "merchant count back to baseline");
    assertEqual(usersNow, userDocs.length, "user count back to baseline");

    // Belt and braces: a forgotten revert would otherwise leave "SMOKE …" sitting
    // on a real record, and the next reader would take it for production data.
    const residue = [];
    for (const collection of ["merchants", "users"]) {
      const snap = await db.collection(collection).get();
      for (const doc of snap.docs) {
        const hit = Object.entries(doc.data()).find(
          ([, v]) => typeof v === "string" && v.includes("SMOKE")
        );
        if (hit) residue.push(`${collection}/${doc.id}.${hit[0]} = ${hit[1]}`);
      }
    }
    assert(residue.length === 0, `test data left behind: ${residue.join("; ")}`);

    return `${merchantsNow} boutiques, ${usersNow} clients, no residue`;
  });

  // ── summary ────────────────────────────────────────────────────────────────
  const failed = results.filter((r) => !r.ok);
  console.log(
    `\n\x1b[1m${results.length - failed.length}/${results.length} passed\x1b[0m` +
      (failed.length ? `  \x1b[31m${failed.length} failed\x1b[0m` : "")
  );
  if (failed.length) {
    for (const f of failed) console.log(`  \x1b[31m✗\x1b[0m ${f.section} › ${f.name}`);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error("\nSuite aborted. Are the emulators running?");
  console.error(error);
  process.exitCode = 1;
});
