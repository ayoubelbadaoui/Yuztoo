/**
 * Hard / stress tests for auto-notification production logic.
 * Simulates double cron runs, legacy data, segment matrix, and toggle edge cases.
 */
import {
  AUTO_NOTIFICATION_TRIGGERS,
  autoNotificationSegmentMatches,
  filterEnabledNotificationsForTrigger,
  isBirthdayToday,
  isMerchantAutoNotificationsEnabled,
  shouldSendBirthdayThisYear,
  shouldSendConnectionAnniversary,
  shouldSendInactiveReturn,
  triggersMatch,
  WIRED_AUTO_NOTIFICATION_TRIGGERS,
} from "../auto_notification_core";
import { computeSegment } from "../index";

const doc = (trigger: string, enabled = true) => ({
  data: () => ({ trigger, is_enabled: enabled }),
});

describe("HARD: auto-notification production stability", () => {
  describe("H1 — merchant master toggle must gate everything", () => {
    const cases: Array<[unknown, boolean]> = [
      [undefined, false],
      [{}, true],
      [{ notifications_auto_enabled: true }, true],
      [{ notifications_auto_enabled: false }, false],
      [{ notifications_auto_enabled: 0 }, false],
      [{ notifications_auto_enabled: "false" }, true], // only strict false disables
    ];
    test.each(cases)("merchant data %j → enabled=%s", (data, expected) => {
      expect(
        isMerchantAutoNotificationsEnabled(data as Record<string, unknown> | undefined)
      ).toBe(expected);
    });
  });

  describe("H2 — legacy trigger alias matrix (production Firestore drift)", () => {
    test("legacy birthday alias matches", () => {
      expect(
        triggersMatch("Chaque birthday client", AUTO_NOTIFICATION_TRIGGERS.birthday)
      ).toBe(true);
    });
    test("retired promo trigger does not match birthday", () => {
      expect(
        triggersMatch("Chaque promotion créé", AUTO_NOTIFICATION_TRIGGERS.birthday)
      ).toBe(false);
    });
    test("inactive legacy alias matches", () => {
      expect(
        triggersMatch("Rappel inactivité", AUTO_NOTIFICATION_TRIGGERS.inactiveReturn)
      ).toBe(true);
    });
    test("passage legacy alias matches", () => {
      expect(
        triggersMatch(
          "Après validation fidélité",
          AUTO_NOTIFICATION_TRIGGERS.passageValidated
        )
      ).toBe(true);
    });

    test("filter returns only matching enabled docs among noise", () => {
      const docs = [
        doc("Chaque promotion créé"),
        doc("Chaque birthday client"),
        doc(AUTO_NOTIFICATION_TRIGGERS.birthday),
        doc(AUTO_NOTIFICATION_TRIGGERS.inactiveReturn),
        doc(AUTO_NOTIFICATION_TRIGGERS.birthday, false),
      ];
      const birthday = filterEnabledNotificationsForTrigger(
        docs,
        AUTO_NOTIFICATION_TRIGGERS.birthday
      );
      expect(birthday).toHaveLength(2);
    });
  });

  describe("H3 — birthday idempotency (double cron / retry)", () => {
    const today = new Date("2026-05-07T09:00:00+02:00");
    const todayMD = "05-07";
    const dob = "1992-05-07";

    test("first run on birthday → send", () => {
      expect(
        shouldSendBirthdayThisYear(dob, todayMD, today, undefined)
      ).toBe(true);
    });

    test("second run same day same year → no send", () => {
      expect(
        shouldSendBirthdayThisYear(dob, todayMD, today, 2026)
      ).toBe(false);
    });

    test("next calendar year → send again", () => {
      expect(
        shouldSendBirthdayThisYear(dob, todayMD, today, 2025)
      ).toBe(true);
    });

    test("wrong day never sends even without prior send", () => {
      expect(
        shouldSendBirthdayThisYear(dob, "05-08", today, undefined)
      ).toBe(false);
    });
  });

  describe("H4 — inactive anti-spam (was daily spam in prod)", () => {
    const now = Date.parse("2026-06-01T09:00:00Z");

    test("day 59 inactive → no", () => {
      expect(shouldSendInactiveReturn(59, undefined, now)).toBe(false);
    });
    test("day 60 inactive first time → yes", () => {
      expect(shouldSendInactiveReturn(60, undefined, now)).toBe(true);
    });
    test("day 90 inactive, notified 10 days ago → no", () => {
      const tenDaysAgo = now - 10 * 86400000;
      expect(shouldSendInactiveReturn(90, tenDaysAgo, now)).toBe(false);
    });
    test("day 90 inactive, notified 31 days ago → yes", () => {
      const thirtyOneDaysAgo = now - 31 * 86400000;
      expect(shouldSendInactiveReturn(90, thirtyOneDaysAgo, now)).toBe(true);
    });
  });

  describe("H5 — connection anniversary edge years", () => {
    test("same calendar year as follow → never", () => {
      expect(
        shouldSendConnectionAnniversary("03-01", "03-01", 2026, 2026, undefined)
      ).toBe(false);
    });
    test("second year, not yet sent → yes", () => {
      expect(
        shouldSendConnectionAnniversary("03-01", "03-01", 2025, 2026, undefined)
      ).toBe(true);
    });
    test("second year, already sent this year → no", () => {
      expect(
        shouldSendConnectionAnniversary("03-01", "03-01", 2025, 2026, 2026)
      ).toBe(false);
    });
  });

  describe("H6 — segment filter exhaustive (auto notif parity with promos)", () => {
    const segments = ["vip", "habitue", "nouveau", "inactif"] as const;
    const targets = [
      [],
      ["vip"],
      ["habitue"],
      ["nouveau"],
      ["inactif"],
      ["soutien"],
      ["abonne"],
      ["vip", "nouveau"],
      ["soutien", "nouveau"],
    ];

    for (const seg of segments) {
      for (const t of targets) {
        test(`seg=${seg} targets=${JSON.stringify(t)}`, () => {
          const result = autoNotificationSegmentMatches(seg, t);
          if (t.length === 0) {
            expect(result).toBe(true);
            return;
          }
          const viaSoutien =
            t.includes("soutien") &&
            (seg === "vip" || seg === "habitue");
          const viaAbonne = t.includes("abonne") && seg === "nouveau";
          const viaDirect = t.includes(seg);
          expect(result).toBe(viaSoutien || viaAbonne || viaDirect);
        });
      }
    }
  });

  describe("H7 — segment transition triggers (loyalty → CRM)", () => {
    test("passage 2→3 crosses habitue threshold", () => {
      expect(computeSegment(2, 0)).toBe("nouveau");
      expect(computeSegment(3, 0)).toBe("habitue");
    });
    test("61 days idle → inactif overrides vip passages", () => {
      expect(computeSegment(15, 61)).toBe("inactif");
    });
    test("9→10 passages crosses vip", () => {
      expect(computeSegment(9, 10)).toBe("habitue");
      expect(computeSegment(10, 10)).toBe("vip");
    });
  });

  describe("H8 — leap year birthday window", () => {
    test("Feb 29 DOB on Feb 28 2025", () => {
      const d = new Date("2025-02-28T09:00:00+01:00");
      expect(isBirthdayToday("2000-02-29", "02-28", d)).toBe(true);
    });
    test("Feb 29 DOB on Feb 28 2024 leap year → exact match only", () => {
      const d = new Date("2024-02-28T09:00:00+01:00");
      // 02-28 is not 02-29; leap year doesn't use fallback on 28th
      expect(isBirthdayToday("2000-02-29", "02-28", d)).toBe(false);
    });
    test("Feb 29 DOB on Feb 29 2024", () => {
      const d = new Date("2024-02-29T09:00:00+01:00");
      expect(isBirthdayToday("2000-02-29", "02-29", d)).toBe(true);
    });
  });

  describe("H9 — wired triggers contract vs UI", () => {
    test("every canonical trigger except visitDetected is wired", () => {
      for (const t of Object.values(AUTO_NOTIFICATION_TRIGGERS)) {
        if (t === AUTO_NOTIFICATION_TRIGGERS.visitDetected) {
          expect(WIRED_AUTO_NOTIFICATION_TRIGGERS.has(t)).toBe(false);
        } else {
          expect(WIRED_AUTO_NOTIFICATION_TRIGGERS.has(t)).toBe(true);
        }
      }
    });
  });
});
