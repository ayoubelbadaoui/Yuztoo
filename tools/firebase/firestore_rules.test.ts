/**
 * Yuztoo — Firestore Security Rules Unit Tests
 *
 * Runs against a live Firestore emulator (started by `firebase emulators:exec`).
 * Tests every allow/deny rule in firestore.rules.
 */

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import * as fs from "fs";
import * as path from "path";

// ── Helpers ───────────────────────────────────────────────────────────────────

const PROJECT_ID = "demo-yuztoo";
const RULES_PATH = path.resolve(__dirname, "../../firestore.rules");

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 9555,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// ── Convenience constructors ──────────────────────────────────────────────────

function authDb(uid: string) {
  return testEnv.authenticatedContext(uid).firestore();
}
function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

// Pre-seed a merchant document (owner = ownerUid) using admin bypass.
async function seedMerchant(merchantId: string, ownerUid: string, extra: Record<string, unknown> = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection("merchants").doc(merchantId).set({
      owner_uid: ownerUid,
      name: "Test Merchant",
      ...extra,
    });
  });
}

// Pre-seed a user document.
async function seedUser(userId: string, extra: Record<string, unknown> = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection("users").doc(userId).set({
      roles: { client: true, merchant: false, provider: false },
      onboarding: { client: "completed", merchant: "not_started" },
      ...extra,
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. phone_index
// ─────────────────────────────────────────────────────────────────────────────

describe("phone_index", () => {
  test("unauthenticated can GET a phone doc", async () => {
    await assertSucceeds(anonDb().collection("phone_index").doc("+33600000000").get());
  });

  test("unauthenticated CANNOT LIST phone_index", async () => {
    await assertFails(anonDb().collection("phone_index").limit(5).get());
  });

  test("signed-in user can CREATE their own phone doc", async () => {
    const db = authDb("user1");
    await assertSucceeds(
      db.collection("phone_index").doc("+33600000001").set({ uid: "user1" })
    );
  });

  test("signed-in user CANNOT CREATE phone doc with different uid", async () => {
    const db = authDb("user1");
    await assertFails(
      db.collection("phone_index").doc("+33600000002").set({ uid: "user2" })
    );
  });

  test("CANNOT UPDATE an existing phone doc", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("phone_index").doc("+33600000003").set({ uid: "user1" });
    });
    const db = authDb("user1");
    await assertFails(db.collection("phone_index").doc("+33600000003").update({ uid: "user1" }));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. users
// ─────────────────────────────────────────────────────────────────────────────

describe("users", () => {
  const validUser = {
    roles: { client: true, merchant: false, provider: false },
    onboarding: { client: "not_started", merchant: "not_started" },
  };

  test("user can GET their own document", async () => {
    await seedUser("alice");
    await assertSucceeds(authDb("alice").collection("users").doc("alice").get());
  });

  test("user CANNOT GET another user's document", async () => {
    await seedUser("alice");
    await assertFails(authDb("bob").collection("users").doc("alice").get());
  });

  test("unauthenticated CANNOT GET a user document", async () => {
    await seedUser("alice");
    await assertFails(anonDb().collection("users").doc("alice").get());
  });

  test("user CANNOT LIST users", async () => {
    await assertFails(authDb("alice").collection("users").limit(10).get());
  });

  test("user CAN CREATE their own document with valid shape", async () => {
    const db = authDb("alice");
    await assertSucceeds(db.collection("users").doc("alice").set(validUser));
  });

  test("CANNOT CREATE user document with invalid roles shape", async () => {
    const db = authDb("alice");
    await assertFails(
      db.collection("users").doc("alice").set({
        roles: { client: true }, // missing merchant + provider
        onboarding: { client: "not_started", merchant: "not_started" },
      })
    );
  });

  test("CANNOT set status to non-active value on create", async () => {
    const db = authDb("alice");
    await assertFails(
      db.collection("users").doc("alice").set({ ...validUser, status: "banned" })
    );
  });

  test("CAN set status to 'active' on create", async () => {
    const db = authDb("alice");
    await assertSucceeds(
      db.collection("users").doc("alice").set({ ...validUser, status: "active" })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. users/{userId}/followed_merchants
// ─────────────────────────────────────────────────────────────────────────────

describe("users/followed_merchants", () => {
  test("user can READ their own followed_merchants", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merchant1")
        .set({ merchant_id: "merchant1", followed_at: new Date() });
    });
    await assertSucceeds(
      authDb("alice")
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merchant1")
        .get()
    );
  });

  test("user CANNOT READ another user's followed_merchants", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merchant1")
        .set({ merchant_id: "merchant1" });
    });
    await assertFails(
      authDb("bob")
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merchant1")
        .get()
    );
  });

  test("merchant owner can READ collection-group followed_merchants docs for their merchant", async () => {
    // Seed: alice follows "merch-owner1" (whose owner_uid = "owner1")
    await seedMerchant("merch-owner1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merch-owner1")
        .set({ merchant_id: "merch-owner1", followed_at: new Date() });
    });
    // owner1 reads collection-group
    await assertSucceeds(
      authDb("owner1")
        .collectionGroup("followed_merchants")
        .where("merchant_id", "==", "merch-owner1")
        .get()
    );
  });

  test("non-owner CANNOT READ collection-group followed_merchants for another merchant", async () => {
    await seedMerchant("merch-other", "owner2");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("followed_merchants")
        .doc("merch-other")
        .set({ merchant_id: "merch-other", followed_at: new Date() });
    });
    // "hacker" is not the owner of merch-other
    await assertFails(
      authDb("hacker")
        .collectionGroup("followed_merchants")
        .where("merchant_id", "==", "merch-other")
        .get()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. merchants
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants", () => {
  test("unauthenticated can READ a merchant document", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(anonDb().collection("merchants").doc("merch1").get());
  });

  test("owner can UPDATE their merchant document", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .update({ name: "Updated Name" })
    );
  });

  test("non-owner CANNOT UPDATE another merchant's document", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("hacker")
        .collection("merchants")
        .doc("merch1")
        .update({ name: "Hacked" })
    );
  });

  test("client can increment ONLY connected-clients counter on merchant doc", async () => {
    await seedMerchant("merch1", "owner1", {
      rappels_monthly_connected_clients: 0,
      rappels_monthly_connected_ym: "2026-04",
    });
    await assertSucceeds(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .update({
          rappels_monthly_connected_clients: 1,
          rappels_monthly_connected_ym: "2026-04",
          owner_uid: "owner1", // must not change
        })
    );
  });

  test("client CANNOT update other fields on merchant doc", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .update({ name: "Hacked" })
    );
  });

  test("client can increment ONLY validated-passage counter on merchant doc", async () => {
    await seedMerchant("merch1", "owner1", {
      rappels_monthly_validated_passages: 0,
      rappels_monthly_validated_ym: "2026-04",
    });
    await assertSucceeds(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .update({
          rappels_monthly_validated_passages: 1,
          rappels_monthly_validated_ym: "2026-04",
          owner_uid: "owner1",
        })
    );
  });

  test("CANNOT DELETE a merchant document", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(authDb("owner1").collection("merchants").doc("merch1").delete());
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. merchants/{id}/promotions
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/promotions", () => {
  test("unauthenticated can READ a promotion", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "10% off", view_count: 0 });
    });
    await assertSucceeds(
      anonDb()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .get()
    );
  });

  test("merchant owner can CREATE a promotion", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "20% off", view_count: 0 })
    );
  });

  test("non-owner CANNOT CREATE a promotion", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("hacker")
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "Hacked promo" })
    );
  });

  test("signed-in client can increment ONLY view_count on a promotion", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "10% off", view_count: 0 });
    });
    await assertSucceeds(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .update({ view_count: 1 })
    );
  });

  test("client CANNOT modify promotion title", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "10% off", view_count: 0 });
    });
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .update({ title: "Hacked title" })
    );
  });

  test("unauthenticated CANNOT increment view_count", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "10% off", view_count: 0 });
    });
    await assertFails(
      anonDb()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .update({ view_count: 1 })
    );
  });

  test("merchant owner can DELETE a promotion", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .set({ title: "10% off", view_count: 0 });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("promotions")
        .doc("promo1")
        .delete()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 5b. merchants/{id}/profile_views — storefront view counters
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/profile_views", () => {
  // The path is intentionally "{date}_{uid}" so the rule can derive both
  // the calendar day and the writer identity from the doc id alone.
  const today = "2026-05-26";
  const docFor = (uid: string, date: string = today) => `${date}_${uid}`;
  const okPayload = (uid: string, date: string = today) => ({
    date,
    viewer_uid: uid,
    updated_at: new Date(),
  });

  test("signed-in viewer can CREATE their own marker for today", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .set(okPayload("alice"))
    );
  });

  test("repeated set on the same marker is idempotent (allowed)", async () => {
    await seedMerchant("merch1", "owner1");
    const ref = authDb("alice")
      .collection("merchants")
      .doc("merch1")
      .collection("profile_views")
      .doc(docFor("alice"));
    await assertSucceeds(ref.set(okPayload("alice")));
    await assertSucceeds(ref.set(okPayload("alice")));
  });

  test("anonymous CANNOT write a profile-view marker", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      anonDb()
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("ghost"))
        .set(okPayload("ghost"))
    );
  });

  test("viewer CANNOT impersonate another uid in the doc id", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        // Writer is alice but the doc id claims bob's marker.
        .doc(docFor("bob"))
        .set(okPayload("bob"))
    );
  });

  test("viewer CANNOT spoof a different viewer_uid in the payload", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .set({ ...okPayload("alice"), viewer_uid: "bob" })
    );
  });

  test("merchant owner CANNOT inflate their own counter (self-view)", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("owner1"))
        .set(okPayload("owner1"))
    );
  });

  test("malformed date string is rejected", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc("26-05-2026_alice")
        .set({
          date: "26-05-2026",
          viewer_uid: "alice",
          updated_at: new Date(),
        })
    );
  });

  test("extra unexpected field is rejected (tight shape)", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .set({ ...okPayload("alice"), is_admin: true })
    );
  });

  test("merchant owner can READ profile_views (analytics)", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .set(okPayload("alice"));
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .get()
    );
  });

  test("non-owner CANNOT READ profile_views (privacy)", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .set(okPayload("alice"));
    });
    // Even alice (the viewer who wrote the marker) is not allowed to
    // read it back — the analytics audience is the merchant only.
    await assertFails(
      authDb("alice")
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .get()
    );
    await assertFails(
      anonDb()
        .collection("merchants")
        .doc("merch1")
        .collection("profile_views")
        .doc(docFor("alice"))
        .get()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. merchants/{id}/pending_clients
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/pending_clients", () => {
  test("client can CREATE their own pending_client entry", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .doc("client1")
        .set({ followed_at: new Date() })
    );
  });

  test("client CANNOT CREATE a pending_client entry for another user", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .doc("client2") // different user
        .set({ followed_at: new Date() })
    );
  });

  test("merchant owner can READ pending_clients", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .doc("client1")
        .set({ followed_at: new Date() });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .get()
    );
  });

  test("non-owner CANNOT READ pending_clients", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("hacker")
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .get()
    );
  });

  test("merchant owner can DELETE a pending_client", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .doc("client1")
        .set({ followed_at: new Date() });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("pending_clients")
        .doc("client1")
        .delete()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 7. merchants/{id}/auto_notifications
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/auto_notifications", () => {
  test("owner can CREATE an auto_notification", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("auto_notifications")
        .doc("n1")
        .set({ trigger: "3_days", message: "Come back!" })
    );
  });

  test("non-owner CANNOT CREATE an auto_notification", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("hacker")
        .collection("merchants")
        .doc("merch1")
        .collection("auto_notifications")
        .doc("n1")
        .set({ trigger: "3_days", message: "Hacked!" })
    );
  });

  test("anyone can READ auto_notifications", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("auto_notifications")
        .doc("n1")
        .set({ trigger: "3_days" });
    });
    await assertSucceeds(
      anonDb()
        .collection("merchants")
        .doc("merch1")
        .collection("auto_notifications")
        .doc("n1")
        .get()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 8. merchants/{id}/sent_notifications
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/sent_notifications", () => {
  test("owner can CREATE a sent_notification (history record)", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .add({ message: "Hello clients!", sent_at: new Date() })
    );
  });

  test("owner can READ sent_notifications", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .get()
    );
  });

  test("non-owner CANNOT READ sent_notifications", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("hacker")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .get()
    );
  });

  test("signed-in client can increment ONLY open_count on a sent_notification", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .set({ text: "Hello", sent_count: 10, open_count: 0 });
    });
    await assertSucceeds(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .update({ open_count: 1 })
    );
  });

  test("merchant owner can update ONLY sent_count on a sent_notification", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .set({ text: "Hello", sent_count: 0, open_count: 0 });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .update({ sent_count: 5 })
    );
  });

  test("client CANNOT modify sent_notification text", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .set({ text: "Hello", sent_count: 1, open_count: 0 });
    });
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("sn1")
        .update({ text: "Hacked" })
    );
  });

  test("CANNOT DELETE a sent_notification", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("notif1")
        .set({ message: "hello" });
    });
    await assertFails(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("sent_notifications")
        .doc("notif1")
        .delete()
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 9. users/{id}/notifications
// ─────────────────────────────────────────────────────────────────────────────

describe("users/notifications", () => {
  test("user can READ their own notifications", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .set({ message: "Hi", is_read: false });
    });
    await assertSucceeds(
      authDb("alice")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .get()
    );
  });

  test("user CANNOT READ another user's notifications", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .set({ message: "Hi", is_read: false });
    });
    await assertFails(
      authDb("bob")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .get()
    );
  });

  test("signed-in user can CREATE notification without merchant_id (legacy path)", async () => {
    await assertSucceeds(
      authDb("any-user")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({ message: "Special offer!", is_read: false, created_at: new Date() })
    );
  });

  test("merchant owner can CREATE notification with their merchant_id", async () => {
    await seedMerchant("merch-owned", "owner-a");
    await assertSucceeds(
      authDb("owner-a")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({
          merchant_id: "merch-owned",
          merchant_name: "Legit Shop",
          message: "Promo",
          is_read: false,
          created_at: new Date(),
        })
    );
  });

  test("non-owner CANNOT CREATE notification impersonating another merchant_id", async () => {
    await seedMerchant("merch-victim", "owner-victim");
    await assertFails(
      authDb("attacker")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({
          merchant_id: "merch-victim",
          merchant_name: "Fake Shop",
          message: "Spam",
          is_read: false,
          created_at: new Date(),
        })
    );
  });

  test("signed-in user CAN CREATE with merchant_id empty string", async () => {
    await assertSucceeds(
      authDb("any-user")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({
          merchant_id: "",
          message: "Legacy",
          is_read: false,
          created_at: new Date(),
        })
    );
  });

  test("unauthenticated CANNOT CREATE notifications", async () => {
    await assertFails(
      anonDb()
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({ message: "Spam", is_read: false })
    );
  });

  test("user can UPDATE (mark as read) their own notification", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .set({ message: "Hi", is_read: false });
    });
    await assertSucceeds(
      authDb("alice")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .doc("n1")
        .update({ is_read: true })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 10. merchants/{id}/loyalty_clients
// ─────────────────────────────────────────────────────────────────────────────

describe("merchants/loyalty_clients", () => {
  test("client CANNOT create their own loyalty entry (merchant-only create)", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 0,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
        })
    );
  });

  test("merchant owner CAN CREATE a loyalty entry on first validation", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
          first_visit_at: new Date(),
          last_passage_at: new Date(),
        })
    );
  });

  test("client CANNOT create loyalty entry with validated_passages > 1 initially", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 5, // > 1 not allowed on create
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
        })
    );
  });

  test("merchant owner can READ all loyalty_clients", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .get()
    );
  });

  test("other clients CANNOT READ loyalty_clients list", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("otherClient")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .get()
    );
  });

  // ── Cooldown enforcement (security-critical) ──────────────────────────────
  //
  // A client whose device clock is tampered to think hours have passed must
  // NOT be able to bypass the 1-hour cooldown. The rule compares
  // `request.time` (server time) to the stored `last_passage_at`. These tests
  // simulate the attack by seeding `last_passage_at` to "just now" via admin
  // bypass and then attempting a client-side additive write.

  test("client CANNOT increment validated_passages inside the 1h cooldown", async () => {
    await seedMerchant("merch1", "owner1");
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
          // Anchor set to "now" — well inside the 1h window.
          last_passage_at: new Date(),
          first_visit_at: new Date(),
        });
    });
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set(
          {
            validated_passages: 2, // would be allowed by the +1 cap, but cooldown blocks
            pending_passages: 0,
            cumulative_spend_euros: 0,
            updated_at: new Date(),
            last_passage_at: new Date(),
          },
          { merge: true }
        )
    );
  });

  test("merchant owner CAN increment when last_passage_at is older than 1 hour", async () => {
    await seedMerchant("merch1", "owner1");
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: twoHoursAgo,
          last_passage_at: twoHoursAgo,
          first_visit_at: twoHoursAgo,
        });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set(
          {
            validated_passages: 2,
            pending_passages: 0,
            cumulative_spend_euros: 0,
            updated_at: new Date(),
            last_passage_at: new Date(),
          },
          { merge: true }
        )
    );
  });

  test("merchant owner CAN increment inside 1h when passage_cooldown_enabled is false", async () => {
    await seedMerchant("merch1", "owner1", { passage_cooldown_enabled: false });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
          last_passage_at: new Date(),
          first_visit_at: new Date(),
        });
    });
    await assertSucceeds(
      authDb("owner1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set(
          {
            validated_passages: 2,
            pending_passages: 0,
            cumulative_spend_euros: 0,
            updated_at: new Date(),
            last_passage_at: new Date(),
          },
          { merge: true }
        )
    );
  });

  test("client CANNOT bypass cooldown by omitting last_passage_at on an additive write", async () => {
    // The new-event branch of the rule requires the client SDK to ALSO stamp
    // last_passage_at — otherwise a client could increment a counter without
    // touching the anchor, leaving the next write's cooldown check on a
    // stale (older) timestamp and effectively halving the cooldown each
    // successive write.
    await seedMerchant("merch1", "owner1");
    const justNow = new Date();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: justNow,
          last_passage_at: new Date(Date.now() - 2 * 60 * 60 * 1000),
          first_visit_at: new Date(Date.now() - 2 * 60 * 60 * 1000),
        });
    });
    // Cooldown has lapsed (anchor was 2h ago), so the write itself is permitted,
    // but the client omits last_passage_at from the update payload. The rule
    // must reject this — additive writes are required to refresh the anchor.
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set(
          {
            validated_passages: 2,
            pending_passages: 0,
            cumulative_spend_euros: 0,
            updated_at: justNow,
            // last_passage_at intentionally absent
          },
          { merge: true }
        )
    );
  });

  test("client CANNOT create loyalty doc recording a passage without last_passage_at", async () => {
    // Defense-in-depth: if the very first write also records a passage,
    // the anchor MUST be set. Otherwise an attacker creates the doc with
    // validated_passages: 1 and no anchor, then re-writes immediately.
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 1,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
          // last_passage_at intentionally absent
        })
    );
  });

  test("client CANNOT create an empty loyalty seed doc (merchant-only create)", async () => {
    await seedMerchant("merch1", "owner1");
    await assertFails(
      authDb("client1")
        .collection("merchants")
        .doc("merch1")
        .collection("loyalty_clients")
        .doc("client1")
        .set({
          validated_passages: 0,
          pending_passages: 0,
          cumulative_spend_euros: 0,
          updated_at: new Date(),
        })
    );
  });
});

describe("data_export_requests", () => {
  test("owner can CREATE a valid GDPR export request", async () => {
    await assertSucceeds(
      authDb("user1").collection("data_export_requests").doc("user1").set({
        uid: "user1",
        email: "client@example.com",
        requestedAt: new Date(),
        status: "pending",
      })
    );
  });

  test("owner can READ own export request", async () => {
    await assertSucceeds(
      authDb("user1").collection("data_export_requests").doc("user1").set({
        uid: "user1",
        email: "",
        requestedAt: new Date(),
        status: "pending",
      })
    );
    await assertSucceeds(
      authDb("user1").collection("data_export_requests").doc("user1").get()
    );
  });

  test("user CANNOT write export request for another uid", async () => {
    await assertFails(
      authDb("user1").collection("data_export_requests").doc("user2").set({
        uid: "user2",
        email: "",
        requestedAt: new Date(),
        status: "pending",
      })
    );
  });

  test("user CANNOT spoof uid field on own doc path", async () => {
    await assertFails(
      authDb("user1").collection("data_export_requests").doc("user1").set({
        uid: "user2",
        email: "",
        requestedAt: new Date(),
        status: "pending",
      })
    );
  });

  test("user CANNOT add extra fields", async () => {
    await assertFails(
      authDb("user1").collection("data_export_requests").doc("user1").set({
        uid: "user1",
        email: "",
        requestedAt: new Date(),
        status: "pending",
        evil: true,
      })
    );
  });

  test("anon CANNOT create export request", async () => {
    await assertFails(
      anonDb().collection("data_export_requests").doc("user1").set({
        uid: "user1",
        email: "",
        requestedAt: new Date(),
        status: "pending",
      })
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// active_validations (BLE handshake)
// ─────────────────────────────────────────────────────────────────────────────

const kProgramSnapshot = {
  program_enabled: true,
  trigger_type: "visit_count",
  visits_required: 10,
  cumulative_spend_required_euros: 100,
  reward_kind: "purchase_voucher",
  purchase_voucher_uses_percent: true,
  purchase_voucher_value: 10,
  discount_next_purchase_percent: 10,
  points_per_euro: 1,
  minimum_per_visit_enabled: false,
  reward_validity_enabled: false,
  passage_validation: "automatic",
  optional_ask_client_purchase_amount: false,
};

function activeValidationRef(merchantId: string, clientUid: string) {
  return authDb(clientUid)
    .collection("merchants")
    .doc(merchantId)
    .collection("active_validations")
    .doc(clientUid);
}

describe("active_validations BLE create", () => {
  const merchantId = "merchant-ble";
  const clientUid = "client-ble";

  beforeEach(async () => {
    await seedMerchant(merchantId, "owner-ble", { loyalty_enabled: true });
    await seedUser(clientUid);
  });

  test("client CAN create BLE session with required fields", async () => {
    await assertSucceeds(
      activeValidationRef(merchantId, clientUid).set({
        client_uid: clientUid,
        client_display_name: "Alice",
        created_at: new Date(),
        status: "awaiting",
        program_snapshot: kProgramSnapshot,
        source: "ble",
        client_ble_connected_at: new Date(),
        merchant_display_name: "Café Test",
      })
    );
  });

  test("client CANNOT create BLE session without client_ble_connected_at", async () => {
    await assertFails(
      activeValidationRef(merchantId, clientUid).set({
        client_uid: clientUid,
        client_display_name: "Alice",
        created_at: new Date(),
        status: "awaiting",
        program_snapshot: kProgramSnapshot,
        source: "ble",
        merchant_display_name: "Café Test",
      })
    );
  });

  test("client CANNOT create vitrine session with BLE-only keys", async () => {
    await assertFails(
      activeValidationRef(merchantId, clientUid).set({
        client_uid: clientUid,
        client_display_name: "Alice",
        created_at: new Date(),
        status: "awaiting",
        program_snapshot: kProgramSnapshot,
        client_ble_connected_at: new Date(),
      })
    );
  });

  test("client CAN create vitrine session without BLE fields", async () => {
    await assertSucceeds(
      activeValidationRef(merchantId, clientUid).set({
        client_uid: clientUid,
        client_display_name: "Alice",
        created_at: new Date(),
        status: "awaiting",
        program_snapshot: kProgramSnapshot,
      })
    );
  });

  test("merchant owner CAN simulate BLE session for another client uid", async () => {
    await seedUser("owner-ble");
    await assertSucceeds(
      authDb("owner-ble")
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc(clientUid)
        .set({
          client_uid: clientUid,
          client_display_name: "Alice",
          created_at: new Date(),
          status: "awaiting",
          program_snapshot: kProgramSnapshot,
          source: "ble",
          client_ble_connected_at: new Date(),
          merchant_display_name: "Café Test",
        })
    );
  });

  test("merchant owner CANNOT simulate BLE session for own uid", async () => {
    await seedUser("owner-ble");
    await assertFails(
      authDb("owner-ble")
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc("owner-ble")
        .set({
          client_uid: "owner-ble",
          client_display_name: "Self",
          created_at: new Date(),
          status: "awaiting",
          program_snapshot: kProgramSnapshot,
          source: "ble",
          client_ble_connected_at: new Date(),
          merchant_display_name: "Café Test",
        })
    );
  });
});

describe("active_validations merchant updates", () => {
  const merchantId = "merchant-ble-upd";
  const clientUid = "client-ble-upd";
  const ownerUid = "owner-ble-upd";

  beforeEach(async () => {
    await seedMerchant(merchantId, ownerUid, { loyalty_enabled: true });
    await seedUser(clientUid);
    await seedUser(ownerUid);
  });

  test("merchant CAN mark merchant_ble_connected_at on awaiting BLE session", async () => {
    await activeValidationRef(merchantId, clientUid).set({
      client_uid: clientUid,
      client_display_name: "Alice",
      created_at: new Date(),
      status: "awaiting",
      program_snapshot: kProgramSnapshot,
      source: "ble",
      client_ble_connected_at: new Date(),
    });
    await assertSucceeds(
      authDb(ownerUid)
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc(clientUid)
        .update({ merchant_ble_connected_at: new Date() })
    );
  });

  test("merchant CANNOT complete BLE session without merchant_ble_connected_at", async () => {
    await activeValidationRef(merchantId, clientUid).set({
      client_uid: clientUid,
      client_display_name: "Alice",
      created_at: new Date(),
      status: "awaiting",
      program_snapshot: kProgramSnapshot,
      source: "ble",
      client_ble_connected_at: new Date(),
    });
    await assertFails(
      authDb(ownerUid)
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc(clientUid)
        .update({
          status: "completed",
          completed_at: new Date(),
          result_validated_delta: 1,
          result_spend_delta: 0,
        })
    );
  });

  test("merchant CAN complete BLE session after merchant_ble_connected_at", async () => {
    await activeValidationRef(merchantId, clientUid).set({
      client_uid: clientUid,
      client_display_name: "Alice",
      created_at: new Date(),
      status: "awaiting",
      program_snapshot: kProgramSnapshot,
      source: "ble",
      client_ble_connected_at: new Date(),
    });
    await authDb(ownerUid)
      .collection("merchants")
      .doc(merchantId)
      .collection("active_validations")
      .doc(clientUid)
      .update({ merchant_ble_connected_at: new Date() });
    await assertSucceeds(
      authDb(ownerUid)
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc(clientUid)
        .update({
          status: "completed",
          completed_at: new Date(),
          result_validated_delta: 1,
          result_spend_delta: 0,
        })
    );
  });

  test("merchant CAN complete vitrine session without BLE timestamps", async () => {
    await activeValidationRef(merchantId, clientUid).set({
      client_uid: clientUid,
      client_display_name: "Alice",
      created_at: new Date(),
      status: "awaiting",
      program_snapshot: kProgramSnapshot,
    });
    await assertSucceeds(
      authDb(ownerUid)
        .collection("merchants")
        .doc(merchantId)
        .collection("active_validations")
        .doc(clientUid)
        .update({
          status: "completed",
          completed_at: new Date(),
          result_validated_delta: 1,
          result_spend_delta: 0,
        })
    );
  });
});
