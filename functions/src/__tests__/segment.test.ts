/**
 * Unit tests for Cloud Functions pure helpers.
 *
 * These tests cover `computeSegment` (segment filtering logic) without
 * requiring a running Firebase emulator or any network calls.
 *
 * The segment logic mirrors the Flutter `ClientSegment` enum in
 * `lib/feature/client_list/domain/entities/merchant_client_row.dart`.
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
const regionMock = {
  firestore: firestoreRegion,
  pubsub: pubsubRegion,
};

jest.mock("firebase-functions", () => ({
  region: jest.fn().mockReturnValue(regionMock),
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn() },
}));

import { computeSegment } from "../index";

// ── helpers ───────────────────────────────────────────────────────────────────

/** Returns a Date exactly `days` ago. */
function daysAgo(days: number): Date {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000);
}

// ── computeSegment ────────────────────────────────────────────────────────────

describe("computeSegment", () => {
  // ── VIP (heartLevel >= 3) ─────────────────────────────────────────────────

  test("heartLevel 3 → vip (regardless of followedAt)", () => {
    expect(computeSegment(3, daysAgo(100))).toBe("vip");
  });

  test("heartLevel 3 → vip even when followed today", () => {
    expect(computeSegment(3, daysAgo(0))).toBe("vip");
  });

  test("heartLevel 4 → vip (above 3)", () => {
    expect(computeSegment(4, null)).toBe("vip");
  });

  // ── Habitué (heartLevel >= 2) ─────────────────────────────────────────────

  test("heartLevel 2 → habitue", () => {
    expect(computeSegment(2, daysAgo(30))).toBe("habitue");
  });

  test("heartLevel 2 → habitue even when followed recently (<14 days)", () => {
    // heartLevel check takes priority over follow recency
    expect(computeSegment(2, daysAgo(5))).toBe("habitue");
  });

  // ── Nouveau (followed < 14 days, heartLevel < 2) ──────────────────────────

  test("heartLevel 1, followed 0 days ago → nouveau", () => {
    expect(computeSegment(1, daysAgo(0))).toBe("nouveau");
  });

  test("heartLevel 1, followed 13 days ago → nouveau", () => {
    expect(computeSegment(1, daysAgo(13))).toBe("nouveau");
  });

  test("heartLevel 0, followed 1 day ago → nouveau", () => {
    expect(computeSegment(0, daysAgo(1))).toBe("nouveau");
  });

  // ── Abonné (default) ──────────────────────────────────────────────────────

  test("heartLevel 1, followed exactly 14 days ago → abonne", () => {
    // Boundary: 14 days is NOT < 14, so falls to abonne.
    expect(computeSegment(1, daysAgo(14))).toBe("abonne");
  });

  test("heartLevel 1, followed 30 days ago → abonne", () => {
    expect(computeSegment(1, daysAgo(30))).toBe("abonne");
  });

  test("heartLevel 1, followedAt null → abonne", () => {
    // No follow date information → treat as long-standing abonné.
    expect(computeSegment(1, null)).toBe("abonne");
  });

  test("heartLevel 0, followedAt null → abonne", () => {
    expect(computeSegment(0, null)).toBe("abonne");
  });

  // ── Priority ordering ─────────────────────────────────────────────────────

  test("heartLevel 3 overrides follow recency → vip not nouveau", () => {
    expect(computeSegment(3, daysAgo(2))).toBe("vip");
  });

  test("heartLevel 2 overrides follow recency → habitue not nouveau", () => {
    expect(computeSegment(2, daysAgo(7))).toBe("habitue");
  });

  // ── Segment key strings match Flutter enum raw values ─────────────────────

  test("segment keys match Flutter ClientSegment raw names", () => {
    // These must match the string keys used in auto_notification.target_segments
    const vip = computeSegment(3, null);
    const habitue = computeSegment(2, null);
    const nouveau = computeSegment(1, daysAgo(1));
    const abonne = computeSegment(1, daysAgo(60));

    expect(vip).toBe("vip");
    expect(habitue).toBe("habitue");
    expect(nouveau).toBe("nouveau");
    expect(abonne).toBe("abonne");
  });
});
