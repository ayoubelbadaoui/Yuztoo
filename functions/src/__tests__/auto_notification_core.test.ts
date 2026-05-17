import {
  AUTO_NOTIFICATION_TRIGGERS,
  autoNotificationSegmentMatches,
  filterEnabledNotificationsForTrigger,
  isBirthdayToday,
  isMerchantAutoNotificationsEnabled,
  parseDobToMD,
  shouldSendBirthdayThisYear,
  shouldSendConnectionAnniversary,
  shouldSendInactiveReturn,
  triggersMatch,
  WIRED_AUTO_NOTIFICATION_TRIGGERS,
} from "../auto_notification_core";

describe("auto_notification_core — trigger matching", () => {
  test("canonical trigger matches itself", () => {
    expect(
      triggersMatch(
        AUTO_NOTIFICATION_TRIGGERS.birthday,
        AUTO_NOTIFICATION_TRIGGERS.birthday
      )
    ).toBe(true);
  });

  test("legacy birthday alias matches canonical", () => {
    expect(
      triggersMatch("Chaque birthday client", AUTO_NOTIFICATION_TRIGGERS.birthday)
    ).toBe(true);
  });

  test("retired promotion trigger does not match birthday", () => {
    expect(
      triggersMatch("Chaque promotion créé", AUTO_NOTIFICATION_TRIGGERS.birthday)
    ).toBe(false);
  });

  test("filterEnabledNotificationsForTrigger includes aliases", () => {
    const docs = [
      {
        data: () => ({
          trigger: "Chaque birthday client",
          is_enabled: true,
        }),
      },
      {
        data: () => ({
          trigger: AUTO_NOTIFICATION_TRIGGERS.inactiveReturn,
          is_enabled: true,
        }),
      },
    ];
    const birthday = filterEnabledNotificationsForTrigger(
      docs,
      AUTO_NOTIFICATION_TRIGGERS.birthday
    );
    expect(birthday).toHaveLength(1);
  });
});

describe("auto_notification_core — merchant master toggle", () => {
  test("missing field → enabled (default)", () => {
    expect(isMerchantAutoNotificationsEnabled({})).toBe(true);
  });

  test("explicit false → disabled", () => {
    expect(
      isMerchantAutoNotificationsEnabled({ notifications_auto_enabled: false })
    ).toBe(false);
  });

  test("explicit true → enabled", () => {
    expect(
      isMerchantAutoNotificationsEnabled({ notifications_auto_enabled: true })
    ).toBe(true);
  });

  test("numeric 0 → disabled", () => {
    expect(
      isMerchantAutoNotificationsEnabled({ notifications_auto_enabled: 0 })
    ).toBe(false);
  });
});

describe("auto_notification_core — birthday", () => {
  const may7 = new Date("2026-05-07T12:00:00+02:00");

  test("parseDobToMD from YYYY-MM-DD", () => {
    expect(parseDobToMD("1990-05-07")).toBe("05-07");
  });

  test("isBirthdayToday on exact day", () => {
    expect(isBirthdayToday("1990-05-07", "05-07", may7)).toBe(true);
  });

  test("isBirthdayToday wrong day", () => {
    expect(isBirthdayToday("1990-05-08", "05-07", may7)).toBe(false);
  });

  test("Feb 29 DOB matches Feb 28 in non-leap year", () => {
    const feb28_2025 = new Date("2025-02-28T09:00:00+01:00");
    expect(isBirthdayToday("2000-02-29", "02-28", feb28_2025)).toBe(true);
  });

  test("shouldSendBirthdayThisYear only once per year", () => {
    expect(
      shouldSendBirthdayThisYear("1990-05-07", "05-07", may7, undefined)
    ).toBe(true);
    expect(
      shouldSendBirthdayThisYear("1990-05-07", "05-07", may7, 2026)
    ).toBe(false);
    expect(
      shouldSendBirthdayThisYear("1990-05-07", "05-07", may7, 2025)
    ).toBe(true);
  });

  test("missing DOB → no birthday send", () => {
    expect(shouldSendBirthdayThisYear(undefined, "05-07", may7, undefined)).toBe(
      false
    );
  });
});

describe("auto_notification_core — connection anniversary", () => {
  test("same MD after first year", () => {
    expect(
      shouldSendConnectionAnniversary("03-15", "03-15", 2024, 2026, undefined)
    ).toBe(true);
  });

  test("same year as follow → no send", () => {
    expect(
      shouldSendConnectionAnniversary("03-15", "03-15", 2026, 2026, undefined)
    ).toBe(false);
  });

  test("already sent this year", () => {
    expect(
      shouldSendConnectionAnniversary("03-15", "03-15", 2024, 2026, 2026)
    ).toBe(false);
  });
});

describe("auto_notification_core — inactive return", () => {
  const now = Date.parse("2026-05-07T09:00:00Z");

  test("under 60 days → no", () => {
    expect(shouldSendInactiveReturn(30, undefined, now)).toBe(false);
  });

  test("60+ days, never sent → yes", () => {
    expect(shouldSendInactiveReturn(61, undefined, now)).toBe(true);
  });

  test("60+ days, sent 10 days ago → no (cooldown 30)", () => {
    const tenDaysAgo = now - 10 * 24 * 60 * 60 * 1000;
    expect(shouldSendInactiveReturn(61, tenDaysAgo, now)).toBe(false);
  });

  test("60+ days, sent 31 days ago → yes", () => {
    const thirtyOneDaysAgo = now - 31 * 24 * 60 * 60 * 1000;
    expect(shouldSendInactiveReturn(61, thirtyOneDaysAgo, now)).toBe(true);
  });
});

describe("auto_notification_core — segment filter (Soutien parity)", () => {
  test("soutien target matches vip client", () => {
    expect(autoNotificationSegmentMatches("vip", ["soutien"])).toBe(true);
  });

  test("soutien target matches habitue client", () => {
    expect(autoNotificationSegmentMatches("habitue", ["soutien"])).toBe(true);
  });

  test("soutien does not match nouveau", () => {
    expect(autoNotificationSegmentMatches("nouveau", ["soutien"])).toBe(false);
  });

  test("legacy abonne → nouveau", () => {
    expect(autoNotificationSegmentMatches("nouveau", ["abonne"])).toBe(true);
  });
});

describe("auto_notification_core — wired triggers contract", () => {
  test("all UI trigger labels except visitDetected are wired", () => {
    const uiLabels = [
      AUTO_NOTIFICATION_TRIGGERS.birthday,
      AUTO_NOTIFICATION_TRIGGERS.segmentChange,
      AUTO_NOTIFICATION_TRIGGERS.newFollower,
      AUTO_NOTIFICATION_TRIGGERS.visitDetected,
      AUTO_NOTIFICATION_TRIGGERS.passageValidated,
      AUTO_NOTIFICATION_TRIGGERS.inactiveReturn,
      AUTO_NOTIFICATION_TRIGGERS.rewardAvailable,
      AUTO_NOTIFICATION_TRIGGERS.rewardNear,
      AUTO_NOTIFICATION_TRIGGERS.exceptionalClosure,
      AUTO_NOTIFICATION_TRIGGERS.newPartner,
      AUTO_NOTIFICATION_TRIGGERS.connectionAnniversary,
    ];
    for (const label of uiLabels) {
      if (label === AUTO_NOTIFICATION_TRIGGERS.visitDetected) {
        expect(WIRED_AUTO_NOTIFICATION_TRIGGERS.has(label)).toBe(false);
      } else {
        expect(WIRED_AUTO_NOTIFICATION_TRIGGERS.has(label)).toBe(true);
      }
    }
  });
});
