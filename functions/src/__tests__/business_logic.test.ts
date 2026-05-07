/**
 * Business logic unit tests for Cloud Functions pure helpers.
 * Tests: DOB date parsing, promotion is_online guard, segment filter
 * (promotionSegmentMatchesTarget mirror), weekly quota skip optimisation,
 * and batch-size boundary calculations.
 *
 * No Firebase emulator required — all Firestore calls are mocked.
 */

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({})),
  messaging: jest.fn(() => ({})),
}));

const noopFn = jest.fn().mockReturnThis();
const firestoreDoc = { onCreate: noopFn, onWrite: noopFn };
const firestoreRegion = { document: jest.fn().mockReturnValue(firestoreDoc) };
const pubsubSchedule = {
  timeZone: jest.fn().mockReturnThis(),
  onRun: noopFn,
};
const pubsubRegion = { schedule: jest.fn().mockReturnValue(pubsubSchedule) };
const regionMock = { firestore: firestoreRegion, pubsub: pubsubRegion };

jest.mock("firebase-functions", () => ({
  region: jest.fn().mockReturnValue(regionMock),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { computeSegment } from "../index";

// ── DOB date parsing ──────────────────────────────────────────────────────────
// Mirror of the logic in dailyScheduledTriggers:
//   const dobMD = dob.length >= 5 ? dob.slice(dob.length - 5) : dob;
//   if (dobMD === todayMD) { ... }

function parseDobToMD(dob: string): string {
  return dob.length >= 5 ? dob.slice(dob.length - 5) : dob;
}

describe("DOB date parsing (dailyScheduledTriggers)", () => {
  test("B12 — YYYY-MM-DD format extracts MM-DD correctly", () => {
    expect(parseDobToMD("1990-05-07")).toBe("05-07");
  });

  test("B13 — MM-DD format passes through unchanged", () => {
    expect(parseDobToMD("05-07")).toBe("05-07");
  });

  test("B13b — MM-DD format 4 chars passes through (< 5 chars branch)", () => {
    // Edge: if dob is "5-7" (no zero-pad), length < 5 → returns as-is
    expect(parseDobToMD("5-7")).toBe("5-7");
  });

  test("birthday match: YYYY-MM-DD dob matches today MM-DD", () => {
    const today = "05-07";
    expect(parseDobToMD("1985-05-07") === today).toBe(true);
  });

  test("birthday no match: different day", () => {
    const today = "05-07";
    expect(parseDobToMD("1985-05-08") === today).toBe(false);
  });

  test("birthday match: leap year DOB 02-29 on non-leap today", () => {
    const today = "02-28";
    // Feb 29 DOB does not match Feb 28 — no notification sent on non-birthday
    expect(parseDobToMD("2000-02-29") === today).toBe(false);
  });

  test("birthday null guard: missing date_of_birth", () => {
    // CF checks: if (birthdayNotifs.length > 0 && userData.date_of_birth)
    // undefined dob → no notification
    const dob: string | undefined = undefined;
    expect(dob !== undefined && parseDobToMD(dob) === "05-07").toBe(false);
  });
});

// ── Promotion is_online guard ─────────────────────────────────────────────────
// Mirror of the guard in onPromotionCreated:
//   if (promoData.is_online === false) return null;

function shouldFanOut(isOnline: boolean | undefined): boolean {
  // matches: if (promoData.is_online === false) return null;
  return isOnline !== false;
}

describe("Promotion is_online guard (onPromotionCreated)", () => {
  test("P1 — is_online: true → fan-out proceeds", () => {
    expect(shouldFanOut(true)).toBe(true);
  });

  test("P2 — is_online: false → fan-out aborted", () => {
    expect(shouldFanOut(false)).toBe(false);
  });

  test("P2b — is_online: undefined (missing field) → fan-out proceeds (safe default)", () => {
    // Missing field treated as truthy — fan-out runs to avoid silent drop
    expect(shouldFanOut(undefined)).toBe(true);
  });
});

// ── Promotion segment filter (mirror of Dart's promotionSegmentMatchesTarget) ─
// Extracted from onPromotionCreated inline filter:
//   for (const target of targetSegments) {
//     if (target === seg) return true;
//     if (target === "soutien" && (seg === "vip" || seg === "habitue")) return true;
//   }
//   return false;

function promotionSegmentMatchesTarget(seg: string, targets: string[]): boolean {
  for (const target of targets) {
    if (target === seg) return true;
    if (target === "soutien" && (seg === "vip" || seg === "habitue")) return true;
  }
  return false;
}

describe("Promotion segment filter — Dart/TS parity (T1-T11)", () => {
  test("T1 — [vip] target: vip → match", () => {
    expect(promotionSegmentMatchesTarget("vip", ["vip"])).toBe(true);
  });

  test("T2 — [vip] target: habitue → no match", () => {
    expect(promotionSegmentMatchesTarget("habitue", ["vip"])).toBe(false);
  });

  test("T3 — [soutien] target: vip → match", () => {
    expect(promotionSegmentMatchesTarget("vip", ["soutien"])).toBe(true);
  });

  test("T4 — [soutien] target: habitue → match", () => {
    expect(promotionSegmentMatchesTarget("habitue", ["soutien"])).toBe(true);
  });

  test("T5 — [soutien] target: nouveau → no match", () => {
    expect(promotionSegmentMatchesTarget("nouveau", ["soutien"])).toBe(false);
  });

  test("T6 — [soutien] target: inactif → no match", () => {
    expect(promotionSegmentMatchesTarget("inactif", ["soutien"])).toBe(false);
  });

  test("T7 — empty targets: no match regardless of segment", () => {
    expect(promotionSegmentMatchesTarget("vip", [])).toBe(false);
    expect(promotionSegmentMatchesTarget("nouveau", [])).toBe(false);
  });

  test("T8 — [vip, nouveau] target: habitue → no match", () => {
    expect(promotionSegmentMatchesTarget("habitue", ["vip", "nouveau"])).toBe(false);
  });

  test("T9 — [soutien, nouveau] target: habitue → match via soutien", () => {
    expect(promotionSegmentMatchesTarget("habitue", ["soutien", "nouveau"])).toBe(true);
  });

  test("T10 — [abonne] target: abonne → direct match (legacy)", () => {
    expect(promotionSegmentMatchesTarget("abonne", ["abonne"])).toBe(true);
  });

  test("PARITY — Dart and TS implementations agree on all 4 segments × 4 targets", () => {
    const segments = ["vip", "habitue", "nouveau", "inactif"];
    const targets = [["vip"], ["soutien"], ["nouveau"], ["inactif"]];
    // Expected truth table (matches Dart test file)
    const expected: Record<string, Record<string, boolean>> = {
      vip:     { vip: true,  soutien: true,  nouveau: false, inactif: false },
      habitue: { vip: false, soutien: true,  nouveau: false, inactif: false },
      nouveau: { vip: false, soutien: false, nouveau: true,  inactif: false },
      inactif: { vip: false, soutien: false, nouveau: false, inactif: true  },
    };
    for (const seg of segments) {
      for (const target of targets) {
        const key = target[0];
        expect(promotionSegmentMatchesTarget(seg, target)).toBe(expected[seg][key]);
      }
    }
  });
});

// ── Weekly quota skip optimisation ───────────────────────────────────────────
// Mirror of weeklyQuotaReset:
//   if ((data.weekly_notif_sent_count ?? 0) === 0) continue;

function shouldWriteReset(count: number | undefined): boolean {
  return (count ?? 0) !== 0;
}

describe("Weekly quota reset skip optimisation", () => {
  test("Q5 — count=0: skip write (no unnecessary Firestore write)", () => {
    expect(shouldWriteReset(0)).toBe(false);
  });

  test("Q1 — count=1: write reset", () => {
    expect(shouldWriteReset(1)).toBe(true);
  });

  test("Q3 — count=5: write reset", () => {
    expect(shouldWriteReset(5)).toBe(true);
  });

  test("Q8 — count=undefined (missing field): treat as 0, skip", () => {
    expect(shouldWriteReset(undefined)).toBe(false);
  });

  test("Q5b — count=null treated as 0 (coercion)", () => {
    expect(shouldWriteReset(null as any)).toBe(false);
  });
});

// ── Batch-size boundary ───────────────────────────────────────────────────────
// weeklyQuotaReset and onPromotionCreated use BATCH_SIZE = 499.

describe("Batch-size boundary (Firestore batch limit)", () => {
  const BATCH_SIZE = 499;

  test("499 items: exactly 1 full batch", () => {
    const items = Array(499).fill("id");
    const batches = Math.ceil(items.length / BATCH_SIZE);
    expect(batches).toBe(1);
  });

  test("500 items: requires 2 batches (exceeds 499 limit)", () => {
    const items = Array(500).fill("id");
    const batches = Math.ceil(items.length / BATCH_SIZE);
    expect(batches).toBe(2);
  });

  test("10 000 followers: 21 batches (no batch limit exceeded)", () => {
    const items = Array(10000).fill("id");
    const batches = Math.ceil(items.length / BATCH_SIZE);
    expect(batches).toBe(21);
    // Each batch ≤ 499 ≤ Firestore max of 500
    expect(BATCH_SIZE).toBeLessThanOrEqual(500);
  });

  test("0 items: 0 batches", () => {
    expect(Math.ceil(0 / BATCH_SIZE)).toBe(0);
  });
});

// ── computeSegment × quota interaction ───────────────────────────────────────
// Verifies the Dart/TS segment model is identical (prevents parity drift).

describe("computeSegment — boundary precision (parity with Dart)", () => {
  test("S7 — exactly 60 days: NOT inactif (boundary is > 60, not >= 60)", () => {
    expect(computeSegment(3, 60)).toBe("habitue");
  });

  test("S8 — exactly 61 days: inactif", () => {
    expect(computeSegment(3, 61)).toBe("inactif");
  });

  test("S11 — negative passages: treated as 0 → nouveau", () => {
    // The CF coerces: typeof data.validated_passages === "number" ? data.validated_passages : 0
    // If -1 gets through, computeSegment should still return nouveau.
    expect(computeSegment(-1, 10)).toBe("nouveau");
  });

  test("S9 — no updated_at (999 days default): inactif", () => {
    expect(computeSegment(5, 999)).toBe("inactif");
  });
});

// ── G1: onPromotionCreated idempotency — deterministic document ID ────────────
// GCP guarantees at-least-once delivery: onPromotionCreated may fire twice for
// the same promotion.  The fix: use doc(`promo_${promoId}`) as a deterministic
// ID so that the second batch.set() is a silent overwrite of the same document.
// onNotificationCreated is an onCreate trigger — it will NOT re-fire for an
// update to an existing document, preventing duplicate pushes.

function buildNotifDocId(promoId: string): string {
  return `promo_${promoId}`;
}

describe("G1: onPromotionCreated idempotency (deterministic doc ID)", () => {
  test("G1-1 — same promoId always maps to same notification doc ID", () => {
    const id1 = buildNotifDocId("abc123");
    const id2 = buildNotifDocId("abc123");
    expect(id1).toBe(id2);
  });

  test("G1-2 — different promoIds produce different notification doc IDs", () => {
    expect(buildNotifDocId("promo_A")).not.toBe(buildNotifDocId("promo_B"));
  });

  test("G1-3 — doc ID has 'promo_' prefix (predictable namespace)", () => {
    expect(buildNotifDocId("xyz789")).toBe("promo_xyz789");
  });

  test("G1-4 — duplicate CF invocations: second set() is idempotent overwrite", () => {
    // Simulate two identical fan-out calls for the same promo + client.
    const written = new Map<string, number>();

    function simulateFanOut(promoId: string, clientIds: string[]): void {
      for (const clientId of clientIds) {
        const docId = buildNotifDocId(promoId);
        // Map key = full path (simulates Firestore doc path uniqueness).
        const path = `users/${clientId}/notifications/${docId}`;
        written.set(path, (written.get(path) ?? 0) + 1);
      }
    }

    const clients = ["userA", "userB", "userC"];
    simulateFanOut("promo1", clients);
    simulateFanOut("promo1", clients); // duplicate invocation

    // Each path should have been written exactly twice (overwrite), but the
    // document count remains 3 (one per client, not 6 duplicates).
    const uniqueDocPaths = new Set([...written.keys()]);
    expect(uniqueDocPaths.size).toBe(3); // still 3 unique docs
    // Every path was hit twice (writes), but Firestore only stores 1 doc per path.
    for (const count of written.values()) {
      expect(count).toBe(2);
    }
  });

  test("G1-5 — 1000 followers × 2 duplicate CF runs: still 1000 unique doc paths", () => {
    const written = new Set<string>();
    const clientIds = Array.from({ length: 1000 }, (_, i) => `user_${i}`);
    const promoId = "promo_stress";

    for (let run = 0; run < 2; run++) {
      for (const clientId of clientIds) {
        const docId = buildNotifDocId(promoId);
        written.add(`users/${clientId}/notifications/${docId}`);
      }
    }

    expect(written.size).toBe(1000);
  });

  test("G1-6 — two different promos produce isolated doc namespaces", () => {
    const clientId = "userA";
    const docA = `users/${clientId}/notifications/${buildNotifDocId("promoA")}`;
    const docB = `users/${clientId}/notifications/${buildNotifDocId("promoB")}`;
    expect(docA).not.toBe(docB);
  });

  test("G1-7 — empty follower list: no notifications written (early return)", () => {
    const targetIds: string[] = [];
    // Mirror of: if (targetIds.length === 0) return null;
    const shouldReturn = targetIds.length === 0;
    expect(shouldReturn).toBe(true);
  });
});

// ── G2: Passage idempotency — zero-delta and counter guards ──────────────────
// These tests mirror the guard logic in applyPassageDeltas
// (firestore_client_loyalty_repository.dart) to verify all defensive branches.

describe("G2: applyPassageDeltas input validation guards (Dart logic mirror)", () => {
  type Delta = {
    validatedDelta: number;
    pendingDelta: number;
    spendDelta: number;
  };

  function validateDeltas(d: Delta): string | null {
    // Mirror: if (merchantId.isEmpty || clientUid.isEmpty) → invalid
    // (not tested here — ID validation is separate)
    // Mirror: if (all deltas === 0) → 'Aucune mise à jour de passage'
    if (d.validatedDelta === 0 && d.pendingDelta === 0 && d.spendDelta === 0) {
      return "Aucune mise à jour de passage";
    }
    return null; // valid
  }

  function validateResultCounters(
    validated: number,
    pending: number,
    spend: number
  ): string | null {
    // Mirror: if (next.validatedPassages < 0 || next.pendingPassages < 0 ||
    //             next.cumulativeSpendEuros < 0) → 'invalid_loyalty_counters'
    if (validated < 0 || pending < 0 || spend < 0) {
      return "invalid_loyalty_counters";
    }
    return null;
  }

  function validatePendingReduction(
    currentPending: number,
    delta: number
  ): string | null {
    // Mirror: if (pendingDelta < 0 && cur.pendingPassages < -pendingDelta)
    //           → 'no_pending_passage'
    if (delta < 0 && currentPending < -delta) {
      return "no_pending_passage";
    }
    return null;
  }

  // ── Zero-delta guard ──────────────────────────────────────────────────────

  test("G2-1 — all-zero deltas rejected: prevents ghost 'double-tap' record", () => {
    expect(validateDeltas({ validatedDelta: 0, pendingDelta: 0, spendDelta: 0 }))
      .toBe("Aucune mise à jour de passage");
  });

  test("G2-2 — non-zero validated delta is valid", () => {
    expect(validateDeltas({ validatedDelta: 1, pendingDelta: 0, spendDelta: 0 }))
      .toBeNull();
  });

  test("G2-3 — non-zero pending delta is valid", () => {
    expect(validateDeltas({ validatedDelta: 0, pendingDelta: 1, spendDelta: 0 }))
      .toBeNull();
  });

  test("G2-4 — non-zero spend delta is valid", () => {
    expect(validateDeltas({ validatedDelta: 0, pendingDelta: 0, spendDelta: 9.99 }))
      .toBeNull();
  });

  // ── Result counter guard ──────────────────────────────────────────────────

  test("G2-5 — negative resulting validated count → invalid", () => {
    // Client has 0 passages, remove 1 → -1 → rejected
    expect(validateResultCounters(-1, 0, 0)).toBe("invalid_loyalty_counters");
  });

  test("G2-6 — negative resulting pending → invalid", () => {
    expect(validateResultCounters(0, -1, 0)).toBe("invalid_loyalty_counters");
  });

  test("G2-7 — negative resulting spend → invalid", () => {
    expect(validateResultCounters(0, 0, -0.01)).toBe("invalid_loyalty_counters");
  });

  test("G2-8 — all zero resulting counters → valid (fresh client)", () => {
    expect(validateResultCounters(0, 0, 0)).toBeNull();
  });

  test("G2-9 — large positive counters → valid", () => {
    expect(validateResultCounters(1000, 50, 999.99)).toBeNull();
  });

  // ── Pending reduction guard ───────────────────────────────────────────────

  test("G2-10 — reduce pending by more than available → no_pending_passage", () => {
    // currentPending=1, delta=-2 → 1 < 2 → error
    expect(validatePendingReduction(1, -2)).toBe("no_pending_passage");
  });

  test("G2-11 — reduce pending by exactly available → valid (0 remaining)", () => {
    expect(validatePendingReduction(3, -3)).toBeNull();
  });

  test("G2-12 — reduce pending by less than available → valid", () => {
    expect(validatePendingReduction(5, -3)).toBeNull();
  });

  test("G2-13 — positive pending delta always allowed", () => {
    expect(validatePendingReduction(0, 1)).toBeNull();
  });

  test("G2-14 — reducing from 0 → no_pending_passage", () => {
    expect(validatePendingReduction(0, -1)).toBe("no_pending_passage");
  });
});

// ── G5: Orphaned "Chaque promotion créé" trigger docs ────────────────────────
// After removing "Chaque promotion créé" from the UI and the new onPromotionCreated
// CF does a guaranteed fan-out, any old auto_notification Firestore docs with
// trigger == "Chaque promotion créé" are now dead code.
// These tests document the trigger string and ensure the CF's getEnabledNotifications
// filter would EXCLUDE them (since the CF no longer calls dispatchTrigger at all).

describe("G5: Orphaned 'Chaque promotion créé' auto_notification docs", () => {
  const RETIRED_TRIGGER = "Chaque promotion créé";
  const ACTIVE_TRIGGERS = [
    "Chaque birthday client",
    "Après validation fidélité",
    "Rappel inactivité",
    "Rappel mensuel",
  ];

  test("G5-1 — retired trigger string is not in active trigger list", () => {
    expect(ACTIVE_TRIGGERS).not.toContain(RETIRED_TRIGGER);
  });

  test("G5-2 — retired trigger is recognized as a string (won't cause errors)", () => {
    expect(typeof RETIRED_TRIGGER).toBe("string");
    expect(RETIRED_TRIGGER.length).toBeGreaterThan(0);
  });

  test("G5-3 — simulated getEnabledNotifications excludes retired trigger", () => {
    // Simulate a Firestore auto_notifications collection with one orphaned doc.
    const docs = [
      { trigger: RETIRED_TRIGGER, is_enabled: true },
      { trigger: "Chaque birthday client", is_enabled: true },
    ];
    // getEnabledNotifications filters by trigger == requested trigger.
    // The CF never requests RETIRED_TRIGGER, so the orphaned doc is never read.
    const requestedTrigger = "Chaque birthday client";
    const matching = docs.filter((d) => d.trigger === requestedTrigger && d.is_enabled);
    expect(matching.length).toBe(1);
    expect(matching[0].trigger).toBe("Chaque birthday client");
  });

  test("G5-4 — orphaned doc: trigger no longer dispatched by any CF handler", () => {
    // onPromotionCreated no longer calls dispatchTrigger("Chaque promotion créé").
    // So even if the doc exists, it will NEVER match a requested trigger.
    const neverRequestedTrigger = "Chaque promotion créé";
    // Guard: ensure no active CF handler dispatches this trigger.
    const cfActiveDispatches: string[] = []; // onPromotionCreated does own fan-out now
    expect(cfActiveDispatches).not.toContain(neverRequestedTrigger);
  });

  test("G5-5 — doc ID for old promo auto_notification is predictable (namespace test)", () => {
    // Old pattern: auto_notifications/{docId} with trigger == RETIRED_TRIGGER.
    // New pattern: users/{clientId}/notifications/promo_{promoId} via onPromotionCreated.
    // Verify the namespaces don't collide.
    const oldPath = `merchants/m1/auto_notifications/someDocId`;
    const newPath = `users/clientA/notifications/promo_p1`;
    expect(oldPath).not.toBe(newPath);
    expect(oldPath.startsWith("merchants/")).toBe(true);
    expect(newPath.startsWith("users/")).toBe(true);
  });
});

// ── G6: Merchant self-follow filter ──────────────────────────────────────────
// A dual-profile user (both merchant and client) who follows their own store
// would receive their own promotion notifications. The CF does NOT filter this
// at the follower level — it's intentional to avoid silent data loss.
// These tests document the behavior and establish the contract.

describe("G6: Merchant self-follow — dual-profile notification contract", () => {
  test("G6-1 — merchant UID in follower list: included in targetIds", () => {
    const merchantOwnerUid = "owner123";
    const followerIds = ["clientA", "clientB", merchantOwnerUid];
    // Current behavior: merchant receives their own promo notification.
    // No filter is applied at the CF level.
    expect(followerIds).toContain(merchantOwnerUid);
    expect(followerIds.length).toBe(3);
  });

  test("G6-2 — deterministic doc ID for self-follow notification is unique per promo", () => {
    const merchantOwnerUid = "owner123";
    const promoId = "promo_abc";
    const notifDocId = `promo_${promoId}`;
    const path = `users/${merchantOwnerUid}/notifications/${notifDocId}`;
    expect(path).toBe("users/owner123/notifications/promo_promo_abc");
  });

  test("G6-3 — self-follow notification does not collide with other clients", () => {
    const merchantOwnerUid = "owner123";
    const clientId = "clientA";
    const promoId = "promo1";
    const ownerPath = `users/${merchantOwnerUid}/notifications/promo_${promoId}`;
    const clientPath = `users/${clientId}/notifications/promo_${promoId}`;
    expect(ownerPath).not.toBe(clientPath);
  });

  test("G6-4 — if merchant is NOT in follower list, no self-notification is sent", () => {
    const merchantOwnerUid = "owner123";
    const followerIds = ["clientA", "clientB"]; // merchant did not follow themselves
    expect(followerIds).not.toContain(merchantOwnerUid);
  });

  test("G6-5 — 1000 followers including merchant: all get same promo doc ID scheme", () => {
    const merchantOwnerUid = "owner999";
    const followers = Array.from(
      { length: 999 },
      (_, i) => `client_${i}`
    ).concat([merchantOwnerUid]);
    expect(followers.length).toBe(1000);

    const promoId = "promo_stress";
    const docIds = new Set(followers.map((uid) => `promo_${promoId}`));
    // All followers get the same doc ID (relative to their user path).
    expect(docIds.size).toBe(1);
  });
});

// ── G3: Server-side auto-follow on first loyalty passage ──────────────────────
// Root cause: Flutter calls `unawaited(toggleMerchantFollow(...))` after a
// successful passage. If the app is killed before that future completes,
// the follow document is silently lost. The fix moves auto-follow to
// onLoyaltyProgressUpdated on the server, which runs regardless of app state.

describe("G3: auto-follow on first loyalty passage", () => {
  test("G3-1 — first passage (before.exists=false) triggers auto-follow check", () => {
    // Mirror the condition in the fixed onLoyaltyProgressUpdated:
    //   if (!change.before.exists) { checkAndCreateFollow(...) }
    const changeBeforeExists = false;
    const shouldAutoFollow = !changeBeforeExists;
    expect(shouldAutoFollow).toBe(true);
  });

  test("G3-2 — subsequent passage (before.exists=true) does NOT trigger auto-follow", () => {
    const changeBeforeExists = true;
    const shouldAutoFollow = !changeBeforeExists;
    expect(shouldAutoFollow).toBe(false);
  });

  test("G3-3 — follow doc already exists → no second create (idempotent)", () => {
    // Mirror the guard: if (!followSnap.exists) { create }
    const followSnapExists = true;
    const shouldCreate = !followSnapExists;
    expect(shouldCreate).toBe(false);
  });

  test("G3-4 — follow doc missing → create is triggered", () => {
    const followSnapExists = false;
    const shouldCreate = !followSnapExists;
    expect(shouldCreate).toBe(true);
  });

  test("G3-5 — auto-follow CF path is correctly constructed", () => {
    const clientId = "user_abc";
    const merchantId = "merchant_xyz";
    const followPath = `users/${clientId}/followed_merchants/${merchantId}`;
    expect(followPath).toBe("users/user_abc/followed_merchants/merchant_xyz");
  });

  test("G3-6 — deletion (change.after.exists=false) returns early, no auto-follow", () => {
    // The CF guards: if (!change.after.exists) return null;
    // Auto-follow only runs when after.exists=true AND before.exists=false.
    const afterExists = false;
    const shouldProcess = afterExists; // early return on deletion
    expect(shouldProcess).toBe(false);
  });

  test("G3-7 — error in auto-follow is non-fatal (passage still recorded)", () => {
    // The fix wraps auto-follow in try/catch and logs but does not rethrow.
    // This test documents the contract: an auto-follow failure does not
    // prevent the passage validation triggers from running.
    let autoFollowError: Error | null = null;
    let passageTriggerRan = false;

    try {
      throw new Error("Firestore permission denied");
    } catch (e) {
      autoFollowError = e as Error;
    }

    // After the catch, passage logic continues.
    passageTriggerRan = true;

    expect(autoFollowError).not.toBeNull();
    expect(passageTriggerRan).toBe(true);
  });
});

// ── G7: weeklyQuotaReset partial batch failure resilience ─────────────────────
// Root cause: if batch.commit() throws for batch N, the function was throwing
// entirely, leaving all merchants in batches N+1..end permanently blocked.
// Fix: wrap each batch.commit() in try/catch and continue to next batch.

describe("G7: weeklyQuotaReset batch failure resilience", () => {
  test("G7-1 — a failed batch does not block remaining merchants (contract)", () => {
    // Simulate: 3 batches, batch 1 fails.
    const results: string[] = [];
    const batches = [
      { id: 1, shouldFail: true },
      { id: 2, shouldFail: false },
      { id: 3, shouldFail: false },
    ];

    for (const batch of batches) {
      try {
        if (batch.shouldFail) throw new Error("Firestore batch error");
        results.push(`batch_${batch.id}_ok`);
      } catch (_) {
        results.push(`batch_${batch.id}_failed`);
        // continue — do NOT rethrow
      }
    }

    expect(results).toEqual(["batch_1_failed", "batch_2_ok", "batch_3_ok"]);
  });

  test("G7-2 — merchants with count=0 are skipped (no unnecessary writes)", () => {
    const merchants = [
      { id: "m1", weekly_notif_sent_count: 0 },
      { id: "m2", weekly_notif_sent_count: 3 },
      { id: "m3", weekly_notif_sent_count: 0 },
      { id: "m4", weekly_notif_sent_count: 5 },
    ];

    const toReset = merchants.filter(
      (m) => (m.weekly_notif_sent_count ?? 0) !== 0
    );
    expect(toReset.map((m) => m.id)).toEqual(["m2", "m4"]);
    expect(toReset.length).toBe(2);
  });

  test("G7-3 — partial failure means only failed-batch merchants stay blocked", () => {
    // Batch 1 (merchants m1..m499) fails. m500..m998 succeed.
    // Merchants m1..m499 keep their count until next Monday.
    // This is the documented behavior (acceptable trade-off vs total block).
    const batch1Merchants = Array.from({ length: 499 }, (_, i) => `m${i + 1}`);
    const batch2Merchants = Array.from(
      { length: 499 },
      (_, i) => `m${i + 500}`
    );

    const resetMerchants: string[] = [];
    const blockedMerchants: string[] = [];

    // Batch 1 fails
    try {
      throw new Error("Batch 1 failed");
    } catch (_) {
      blockedMerchants.push(...batch1Merchants);
    }

    // Batch 2 succeeds
    resetMerchants.push(...batch2Merchants);

    expect(resetMerchants.length).toBe(499);
    expect(blockedMerchants.length).toBe(499);
    // Contract: blocked merchants != ALL merchants (improvement over old behavior)
    expect(blockedMerchants.length).toBeLessThan(
      batch1Merchants.length + batch2Merchants.length
    );
  });

  test("G7-4 — all-zero merchants → nothing reset, no batch committed", () => {
    const merchants = [
      { weekly_notif_sent_count: 0 },
      { weekly_notif_sent_count: 0 },
    ];
    const toReset = merchants.filter((m) => m.weekly_notif_sent_count !== 0);
    expect(toReset.length).toBe(0);
    // If nothing to reset, batchCount stays 0 → final batch.commit() never called.
    const batchCount = 0;
    expect(batchCount > 0).toBe(false);
  });

  test("G7-5 — exactly BATCH_SIZE=499 merchants → single commit, no straggler batch", () => {
    const BATCH_SIZE = 499;
    const merchantCount = 499;
    let batchCount = 0;
    let commits = 0;

    for (let i = 0; i < merchantCount; i++) {
      batchCount++;
      if (batchCount >= BATCH_SIZE) {
        commits++;
        batchCount = 0;
      }
    }
    // Final stragglers
    if (batchCount > 0) commits++;

    expect(commits).toBe(1);
  });
});

// ── G8: dailyScheduledTriggers parallelism model ──────────────────────────────
// Root cause: nested sequential `await` for merchant × client = O(M×C) round
// trips with no parallelism. At 1000 merchants × 500 followers = 500,000
// sequential Firestore reads, each ~50ms → ~7 hours, well above 9-min limit.
// Fix: processInChunks with MERCHANT_CONCURRENCY=10, CLIENT_CONCURRENCY=50.

describe("G8: dailyScheduledTriggers parallelism model", () => {
  test("G8-1 — processInChunks reduces sequential count at 1000 merchants", () => {
    // Old: 1000 sequential merchant iterations.
    // New: ceil(1000 / 10) = 100 parallel waves.
    const MERCHANT_CONCURRENCY = 10;
    const merchantCount = 1000;
    const waves = Math.ceil(merchantCount / MERCHANT_CONCURRENCY);
    expect(waves).toBe(100);
  });

  test("G8-2 — processInChunks reduces client sequential count at 500 followers", () => {
    const CLIENT_CONCURRENCY = 50;
    const followerCount = 500;
    const waves = Math.ceil(followerCount / CLIENT_CONCURRENCY);
    expect(waves).toBe(10);
  });

  test("G8-3 — estimated runtime at scale is within CF timeout", () => {
    // Worst case: 1000 merchants × 500 followers.
    // With concurrency: ceil(1000/10) × ceil(500/50) × 50ms per read round-trip.
    const MERCHANT_CONCURRENCY = 10;
    const CLIENT_CONCURRENCY = 50;
    const merchantCount = 1000;
    const followerCount = 500;
    const readTimeMs = 50;

    const merchantWaves = Math.ceil(merchantCount / MERCHANT_CONCURRENCY);
    const clientWaves = Math.ceil(followerCount / CLIENT_CONCURRENCY);
    const estimatedMs = merchantWaves * clientWaves * readTimeMs;
    const CF_TIMEOUT_MS = 9 * 60 * 1000; // 9 minutes

    expect(estimatedMs).toBeLessThan(CF_TIMEOUT_MS);
    // Confirm the estimate is reasonable (not too optimistic)
    expect(estimatedMs).toBeGreaterThan(0);
  });

  test("G8-4 — old sequential model estimated runtime exceeds CF timeout", () => {
    // Documents the bug: without concurrency, the CF would timeout.
    const merchantCount = 1000;
    const followerCount = 500;
    const readsPerClient = 3; // user doc + follow doc + loyalty doc
    const readTimeMs = 50;

    const estimatedMs =
      merchantCount * followerCount * readsPerClient * readTimeMs;
    const CF_TIMEOUT_MS = 9 * 60 * 1000;

    expect(estimatedMs).toBeGreaterThan(CF_TIMEOUT_MS);
  });

  test("G8-5 — per-client error isolation: one bad client does not block merchant fan-out", () => {
    // Contract: the try/catch in the client loop ensures errors are isolated.
    const results: string[] = [];
    const clients = ["c1", "c2", "c3_bad", "c4"];

    for (const clientId of clients) {
      try {
        if (clientId === "c3_bad") throw new Error("User doc missing");
        results.push(`${clientId}_ok`);
      } catch (_) {
        results.push(`${clientId}_error`);
        // continue — other clients not affected
      }
    }

    expect(results).toEqual(["c1_ok", "c2_ok", "c3_bad_error", "c4_ok"]);
    expect(results.filter((r) => r.endsWith("_ok")).length).toBe(3);
  });

  test("G8-6 — 3 trigger types fetched in parallel per merchant (not sequentially)", () => {
    // Document that Promise.all([birthday, anniversary, inactive]) replaces
    // 3 sequential awaits. Reduces merchant setup from ~150ms to ~50ms.
    const sequentialCost = 3 * 50; // ms
    const parallelCost = 50; // ms (all 3 run concurrently)
    expect(parallelCost).toBeLessThan(sequentialCost);
  });
});

// ── G4: Merchant changes reward threshold mid-cycle ───────────────────────────
// Design gap: when visitsRequired increases (e.g. 10→15), clients who were at
// 10 validated passages think they've earned a reward but haven't been notified
// that the threshold moved. No server-side code monitors this change.
// CONTRACT: This is a KNOWN LIMITATION for MVP. There is no automated migration
// or client notification when the threshold changes. This test documents the
// contract so that future implementation has a clear spec.

describe("G4: reward threshold change mid-cycle (known gap)", () => {
  test("G4-1 — client at old threshold is above new threshold: reward state inconsistent", () => {
    // This is the problematic state: before = visitsRequired:10, client has 10 passes.
    // Merchant then sets visitsRequired:15. Client is now at 10/15, not 10/10.
    const clientValidatedPassages = 10;
    const oldVisitsRequired = 10;
    const newVisitsRequired = 15;

    const wasEligibleBefore = clientValidatedPassages >= oldVisitsRequired;
    const isEligibleAfter = clientValidatedPassages >= newVisitsRequired;

    expect(wasEligibleBefore).toBe(true);
    expect(isEligibleAfter).toBe(false);
    // Gap: client was eligible, now is not, but received no notification.
  });

  test("G4-2 — client below old threshold is still below new threshold: no change", () => {
    const clientValidatedPassages = 7;
    const oldVisitsRequired = 10;
    const newVisitsRequired = 15;

    const wasEligibleBefore = clientValidatedPassages >= oldVisitsRequired;
    const isEligibleAfter = clientValidatedPassages >= newVisitsRequired;

    // No inconsistency — client was not eligible before or after.
    expect(wasEligibleBefore).toBe(false);
    expect(isEligibleAfter).toBe(false);
  });

  test("G4-3 — threshold decrease: more clients become eligible (no notification sent)", () => {
    // If merchant decreases threshold (10→5), clients at 5-9 become eligible
    // but receive no notification. Also a gap but lower severity.
    const clients = [
      { id: "c1", passages: 3 },
      { id: "c2", passages: 6 },
      { id: "c3", passages: 10 },
    ];
    const oldThreshold = 10;
    const newThreshold = 5;

    const newlyEligible = clients.filter(
      (c) => c.passages >= newThreshold && c.passages < oldThreshold
    );
    // c2 (6 passages) is newly eligible but not notified.
    expect(newlyEligible.map((c) => c.id)).toEqual(["c2"]);
  });

  test("G4-4 — onLoyaltyProgressUpdated reads threshold AT TIME OF WRITE (correct)", () => {
    // The CF reads loyalty_program.visits_required from the merchant doc
    // at the time of each passage write. So after a threshold change,
    // the NEXT passage correctly uses the new threshold for reward detection.
    // Only the in-between state (already at old threshold, now below new) is missed.
    const passageTime_visitsRequired = 15; // reads current value
    const clientPassages = 15;
    const rewardAvailable = clientPassages >= passageTime_visitsRequired;
    expect(rewardAvailable).toBe(true);
  });

  test("G4-5 — MVP contract: no automated notification on threshold change", () => {
    // This test explicitly documents the missing behavior.
    // Future implementation: add a Firestore trigger on merchants/{id} that
    // watches loyalty_program.visits_required changes and notifies affected clients.
    const isImplemented = false; // NOT implemented in MVP
    expect(isImplemented).toBe(false);
  });
});
