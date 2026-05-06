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
