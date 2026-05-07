/**
 * Unit tests for Cloud Functions pure helpers.
 *
 * These tests cover `computeSegment` (passage-based segment logic) without
 * requiring a running Firebase emulator or any network calls.
 *
 * The segment logic mirrors Flutter's `FirestoreClientLoyaltyRepository._computeSegment`
 * (`lib/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart`).
 *
 * Canonical model:
 *   daysSinceLastVisit > 60  → 'inactif'
 *   validatedPassages >= 10  → 'vip'
 *   validatedPassages >= 3   → 'habitue'
 *   otherwise                → 'nouveau'
 */

// jest.mock must come before any import that touches firebase-admin.
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
const httpsRegion = { onCall: noopFn };
const regionMock: any = {
  firestore: firestoreRegion,
  pubsub: pubsubRegion,
  https: httpsRegion,
};
// Functions that use runWith chain back to the same mock so subsequent
// pubsub/firestore calls keep resolving.
regionMock.runWith = jest.fn().mockReturnValue(regionMock);

jest.mock("firebase-functions", () => ({
  region: jest.fn().mockReturnValue(regionMock),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { computeSegment } from "../index";

// ── computeSegment ────────────────────────────────────────────────────────────

describe("computeSegment", () => {
  // ── Inactif (daysSinceLastVisit > 60) ────────────────────────────────────

  test("61 days since last visit → inactif (regardless of passages)", () => {
    expect(computeSegment(10, 61)).toBe("inactif");
  });

  test("90 days since last visit, 0 passages → inactif", () => {
    expect(computeSegment(0, 90)).toBe("inactif");
  });

  test("999 days (no visit recorded) → inactif", () => {
    expect(computeSegment(5, 999)).toBe("inactif");
  });

  test("exactly 60 days → NOT inactif (boundary inclusive for active)", () => {
    // > 60 triggers inactif; exactly 60 does not.
    expect(computeSegment(0, 60)).toBe("nouveau");
  });

  // ── VIP (validatedPassages >= 10, daysSinceLastVisit <= 60) ──────────────

  test("10 passages, 0 days → vip", () => {
    expect(computeSegment(10, 0)).toBe("vip");
  });

  test("15 passages, 30 days → vip", () => {
    expect(computeSegment(15, 30)).toBe("vip");
  });

  test("10 passages, exactly 60 days → vip (still active)", () => {
    expect(computeSegment(10, 60)).toBe("vip");
  });

  test("10 passages, 61 days → inactif (inactif takes priority over vip)", () => {
    expect(computeSegment(10, 61)).toBe("inactif");
  });

  // ── Habitué (validatedPassages >= 3, daysSinceLastVisit <= 60) ───────────

  test("3 passages, 0 days → habitue", () => {
    expect(computeSegment(3, 0)).toBe("habitue");
  });

  test("9 passages, 45 days → habitue", () => {
    expect(computeSegment(9, 45)).toBe("habitue");
  });

  test("3 passages, 61 days → inactif", () => {
    expect(computeSegment(3, 61)).toBe("inactif");
  });

  // ── Nouveau (validatedPassages < 3, daysSinceLastVisit <= 60) ────────────

  test("0 passages, 0 days → nouveau", () => {
    expect(computeSegment(0, 0)).toBe("nouveau");
  });

  test("2 passages, 30 days → nouveau", () => {
    expect(computeSegment(2, 30)).toBe("nouveau");
  });

  test("0 passages, 60 days → nouveau (boundary)", () => {
    expect(computeSegment(0, 60)).toBe("nouveau");
  });

  // ── Priority: inactif beats all ──────────────────────────────────────────

  test("inactif check happens before vip check", () => {
    // Even with 100 passages, 70 days = inactif.
    expect(computeSegment(100, 70)).toBe("inactif");
  });

  // ── Segment key strings match server-side and Flutter constants ──────────

  test("segment keys match expected string constants", () => {
    expect(computeSegment(0, 90)).toBe("inactif");
    expect(computeSegment(10, 10)).toBe("vip");
    expect(computeSegment(5, 10)).toBe("habitue");
    expect(computeSegment(1, 10)).toBe("nouveau");
  });
});
