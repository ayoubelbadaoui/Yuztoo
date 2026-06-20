import {
  AUTO_NOTIFICATION_TRIGGERS,
  autoNotificationSegmentMatches,
  compareNotificationsBySpecificity,
  filterEnabledNotificationsForTrigger,
  isBirthdayToday,
  isMerchantAutoNotificationsEnabled,
  isSegmentSpecificAudience,
  parisCalendarDayFromDate,
  parseDobToMD,
  resolveMerchantPublicName,
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

describe("auto_notification_core — Paris calendar day", () => {
  test("uses Europe/Paris calendar day, not UTC", () => {
    // 2026-02-28 22:30 UTC → 23:30 Paris — still Feb 28 locally.
    const utcEvening = new Date("2026-02-28T22:30:00.000Z");
    expect(parisCalendarDayFromDate(utcEvening)).toEqual({
      md: "02-28",
      year: 2026,
    });
  });

  test("scheduled 09:00 Paris run resolves same calendar day", () => {
    const nineParis = new Date("2026-05-07T07:00:00.000Z"); // 09:00 CEST
    expect(parisCalendarDayFromDate(nineParis)).toEqual({
      md: "05-07",
      year: 2026,
    });
  });
});

// Birthday notifications must be guarded against ambiguous DOB strings — see
// the parseDobToMD docs in auto_notification_core.ts. Every shape the wild
// could throw at us belongs in this table so the property "Bon anniversaire
// ne doit être envoyée qu'aux gens dont c'est l'anniversaire" stays bullet-
// proof against future schema drift.
describe("auto_notification_core — birthday strict format", () => {
  const may7 = new Date("2026-05-07T12:00:00+02:00");

  test("parseDobToMD strict: YYYY-MM-DD only", () => {
    expect(parseDobToMD("1990-05-07")).toBe("05-07");
  });

  test("parseDobToMD strict: ISO timestamp with T accepted", () => {
    expect(parseDobToMD("1990-05-07T00:00:00")).toBe("05-07");
    expect(parseDobToMD("1990-05-07T00:00:00.000Z")).toBe("05-07");
  });

  test("parseDobToMD strict: ISO date with space separator accepted", () => {
    expect(parseDobToMD("1990-05-07 00:00:00")).toBe("05-07");
  });

  test("parseDobToMD strict: trims surrounding whitespace", () => {
    expect(parseDobToMD("  1990-05-07  ")).toBe("05-07");
  });

  test("parseDobToMD strict: rejects DD/MM/YYYY", () => {
    expect(parseDobToMD("07/05/1990")).toBeNull();
  });

  test("parseDobToMD strict: rejects bare MM-DD (no year)", () => {
    expect(parseDobToMD("05-07")).toBeNull();
  });

  test("parseDobToMD strict: rejects junk ending in today's MM-DD", () => {
    // The ambiguous-suffix bug — a corrupted string accidentally ending in
    // today's MM-DD must NOT trigger a birthday notification.
    expect(parseDobToMD("garbage05-07")).toBeNull();
    expect(parseDobToMD("197905-07")).toBeNull();
  });

  test("parseDobToMD strict: rejects empty / whitespace", () => {
    expect(parseDobToMD("")).toBeNull();
    expect(parseDobToMD("   ")).toBeNull();
  });

  test("parseDobToMD strict: rejects out-of-range month/day", () => {
    expect(parseDobToMD("1990-13-07")).toBeNull();
    expect(parseDobToMD("1990-00-07")).toBeNull();
    expect(parseDobToMD("1990-05-32")).toBeNull();
    expect(parseDobToMD("1990-05-00")).toBeNull();
  });

  test("isBirthdayToday: ISO timestamp DOB still matches", () => {
    expect(isBirthdayToday("1990-05-07T00:00:00", "05-07", may7)).toBe(true);
  });

  test("isBirthdayToday: junk DOB ending in today's MD does NOT match", () => {
    expect(isBirthdayToday("garbage05-07", "05-07", may7)).toBe(false);
    expect(isBirthdayToday("05-07", "05-07", may7)).toBe(false);
  });

  test("isBirthdayToday: DD/MM/YYYY does NOT accidentally match", () => {
    // Even when the day/month happen to spell today's MD, the format is
    // rejected because we never want to guess.
    expect(isBirthdayToday("07/05/1990", "05-07", may7)).toBe(false);
  });

  test("isBirthdayToday: empty / whitespace DOB → false", () => {
    expect(isBirthdayToday("", "05-07", may7)).toBe(false);
    expect(isBirthdayToday("   ", "05-07", may7)).toBe(false);
  });

  test("isBirthdayToday: invalid month/day → false (safe default)", () => {
    expect(isBirthdayToday("1990-13-07", "05-07", may7)).toBe(false);
    expect(isBirthdayToday("1990-05-32", "05-07", may7)).toBe(false);
  });

  test("shouldSendBirthdayThisYear: malformed DOB never sends", () => {
    expect(
      shouldSendBirthdayThisYear("garbage05-07", "05-07", may7, undefined)
    ).toBe(false);
    expect(
      shouldSendBirthdayThisYear("07/05/1990", "05-07", may7, undefined)
    ).toBe(false);
    expect(
      shouldSendBirthdayThisYear("", "05-07", may7, undefined)
    ).toBe(false);
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

describe("auto_notification_core — audience specificity", () => {
  test("isSegmentSpecificAudience: 'Certains clients' with segments → true", () => {
    expect(
      isSegmentSpecificAudience({
        audience: "Certains clients",
        target_segments: ["vip"],
      })
    ).toBe(true);
  });

  test("isSegmentSpecificAudience: 'Certains clients' with empty segments → false", () => {
    expect(
      isSegmentSpecificAudience({
        audience: "Certains clients",
        target_segments: [],
      })
    ).toBe(false);
  });

  test("isSegmentSpecificAudience: 'Certains clients' with undefined segments → false", () => {
    expect(
      isSegmentSpecificAudience({ audience: "Certains clients" })
    ).toBe(false);
  });

  test("isSegmentSpecificAudience: 'Tous mes clients' with segments still → false", () => {
    // Defensive: even if a malformed doc lists segments, broadcast wins.
    expect(
      isSegmentSpecificAudience({
        audience: "Tous mes clients",
        target_segments: ["vip"],
      })
    ).toBe(false);
  });

  test("compareNotificationsBySpecificity: narrow before broad", () => {
    const broad = { data: () => ({ audience: "Tous mes clients" }) };
    const narrow = {
      data: () => ({ audience: "Certains clients", target_segments: ["vip"] }),
    };
    const sorted = [broad, narrow].sort(compareNotificationsBySpecificity);
    expect(sorted[0]).toBe(narrow);
    expect(sorted[1]).toBe(broad);
  });

  test("compareNotificationsBySpecificity: stable for equal specificity", () => {
    const a = {
      data: () => ({ audience: "Certains clients", target_segments: ["vip"] }),
    };
    const b = {
      data: () => ({
        audience: "Certains clients",
        target_segments: ["habitue"],
      }),
    };
    const c = { data: () => ({ audience: "Tous mes clients" }) };
    const d = { data: () => ({ audience: "Tous mes clients" }) };
    const sorted = [c, a, d, b].sort(compareNotificationsBySpecificity);
    expect(sorted[0]).toBe(a);
    expect(sorted[1]).toBe(b);
    expect(sorted[2]).toBe(c);
    expect(sorted[3]).toBe(d);
  });
});

describe("resolveMerchantPublicName — name resolution at send time", () => {
  test("prefers display_name over legal name (the rename bug)", () => {
    expect(
      resolveMerchantPublicName({
        name: "Old Boulangerie SAS",
        display_name: "Boulangerie Dupont",
      })
    ).toBe("Boulangerie Dupont");
  });

  test("falls back to legal name when display_name is missing", () => {
    expect(
      resolveMerchantPublicName({ name: "Mon Commerce SARL" })
    ).toBe("Mon Commerce SARL");
  });

  test("falls back to legal name when display_name is empty / whitespace", () => {
    expect(
      resolveMerchantPublicName({ name: "Boulangerie", display_name: "" })
    ).toBe("Boulangerie");
    expect(
      resolveMerchantPublicName({ name: "Boulangerie", display_name: "   " })
    ).toBe("Boulangerie");
  });

  test("trims surrounding whitespace from the resolved name", () => {
    expect(
      resolveMerchantPublicName({ display_name: "  Mon commerce  " })
    ).toBe("Mon commerce");
  });

  test("returns generic fallback for missing / empty data", () => {
    expect(resolveMerchantPublicName(undefined)).toBe("Votre commerce");
    expect(resolveMerchantPublicName({})).toBe("Votre commerce");
    expect(
      resolveMerchantPublicName({ name: "", display_name: "" })
    ).toBe("Votre commerce");
  });

  test("ignores non-string values and falls through gracefully", () => {
    expect(
      resolveMerchantPublicName({
        name: 42 as unknown as string,
        display_name: null as unknown as string,
      })
    ).toBe("Votre commerce");
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
