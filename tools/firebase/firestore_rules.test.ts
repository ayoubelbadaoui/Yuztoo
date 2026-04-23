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

  test("any signed-in user (merchant) can CREATE a notification for a client", async () => {
    await assertSucceeds(
      authDb("merchant-owner")
        .collection("users")
        .doc("alice")
        .collection("notifications")
        .add({ message: "Special offer!", is_read: false, created_at: new Date() })
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
  test("client can CREATE their own loyalty entry with valid values", async () => {
    await seedMerchant("merch1", "owner1");
    await assertSucceeds(
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
});
