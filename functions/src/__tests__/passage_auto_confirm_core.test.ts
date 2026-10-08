import {
  PASSAGE_COOLDOWN_MS,
  isInsidePassageCooldown,
  isPassageSessionAutoConfirmed,
  parisYearMonth,
  passageValidatedNotification,
  programRequiresSpendAmount,
  resolvePassageProgram,
  rewardUnlockedNotification,
  visitRewardJustUnlocked,
} from "../passage_auto_confirm_core";

const visitProgram = {
  program_enabled: true,
  trigger_type: "visit_count",
  visits_required: 5,
  reward_kind: "purchase_voucher",
  purchase_voucher_value: 10,
  purchase_voucher_uses_percent: true,
  passage_validation: "automatic",
};

// La Boutique Des Lunetiers, production, 30 Sep 2026.
const lunetiersProgram = {
  program_enabled: true,
  trigger_type: "purchase_total",
  cumulative_spend_required_euros: 150,
  reward_kind: "purchase_voucher",
  purchase_voucher_value: 10,
  purchase_voucher_uses_percent: true,
  passage_validation: "automatic",
};

function merchant(program: Record<string, unknown>, extra = {}) {
  return {
    loyalty_enabled: true,
    rappels_auto_passage_validation: true,
    loyalty_program: program,
    ...extra,
  };
}

function session(program: Record<string, unknown>, extra = {}) {
  return { status: "awaiting", program_snapshot: program, ...extra };
}

describe("isPassageSessionAutoConfirmed", () => {
  it("confirms an automatic visit-count vitrine session", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(visitProgram),
        session(visitProgram),
        undefined
      )
    ).toBe(true);
  });

  it("never confirms an amount-based programme, even in automatic mode", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(lunetiersProgram),
        session(lunetiersProgram),
        undefined
      )
    ).toBe(false);
  });

  it("leaves BLE sessions to the merchant device", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(visitProgram),
        session(visitProgram, { source: "ble" }),
        undefined
      )
    ).toBe(false);
  });

  it("does not confirm in manual mode", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(visitProgram, { rappels_auto_passage_validation: false }),
        session(visitProgram),
        undefined
      )
    ).toBe(false);
  });

  it("does not confirm when loyalty is switched off", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(visitProgram, { loyalty_enabled: false }),
        session(visitProgram),
        undefined
      )
    ).toBe(false);
  });

  it("honours the client's enrolled amount-based terms over the snapshot", () => {
    expect(
      isPassageSessionAutoConfirmed(
        merchant(visitProgram),
        session(visitProgram),
        { enrolled_loyalty_program: lunetiersProgram }
      )
    ).toBe(false);
  });
});

describe("resolvePassageProgram", () => {
  it("prefers the enrolled programme", () => {
    expect(
      resolvePassageProgram(
        { enrolled_loyalty_program: lunetiersProgram },
        session(visitProgram)
      ).trigger_type
    ).toBe("purchase_total");
  });

  it("falls back to the session snapshot", () => {
    expect(
      resolvePassageProgram(undefined, session(visitProgram)).trigger_type
    ).toBe("visit_count");
  });
});

describe("programRequiresSpendAmount", () => {
  it("is true for purchase totals and loyalty points", () => {
    expect(programRequiresSpendAmount(lunetiersProgram)).toBe(true);
    expect(
      programRequiresSpendAmount({ ...visitProgram, reward_kind: "loyalty_points" })
    ).toBe(true);
    expect(programRequiresSpendAmount(visitProgram)).toBe(false);
  });
});

describe("isInsidePassageCooldown", () => {
  const now = Date.UTC(2026, 9, 7, 12, 0, 0);

  it("blocks a second passage within the hour", () => {
    expect(isInsidePassageCooldown(now - 10 * 60 * 1000, now, true)).toBe(true);
  });

  it("allows once the hour has passed", () => {
    expect(isInsidePassageCooldown(now - PASSAGE_COOLDOWN_MS, now, true)).toBe(false);
  });

  it("allows when the merchant disabled the cooldown or on first visit", () => {
    expect(isInsidePassageCooldown(now - 1000, now, false)).toBe(false);
    expect(isInsidePassageCooldown(null, now, true)).toBe(false);
  });
});

describe("parisYearMonth", () => {
  it("uses the Paris calendar across a UTC month boundary", () => {
    // 30 Sep 23:30 UTC is already 1 Oct in Paris (UTC+2).
    expect(parisYearMonth(new Date(Date.UTC(2026, 8, 30, 23, 30)))).toBe("2026-10");
  });
});

describe("notifications", () => {
  it("matches the app's passage copy", () => {
    expect(passageValidatedNotification("Shop", visitProgram, 3)).toEqual({
      title: "Passage validé chez Shop ✓",
      body: "Passage validé (3 / 5 passages).",
    });
  });

  it("detects the passage that crosses the threshold only once", () => {
    expect(visitRewardJustUnlocked(visitProgram, 4)).toBe(false);
    expect(visitRewardJustUnlocked(visitProgram, 5)).toBe(true);
    expect(visitRewardJustUnlocked(visitProgram, 6)).toBe(false);
  });

  it("labels the reward like the app", () => {
    expect(rewardUnlockedNotification("Shop", visitProgram)).toEqual({
      title: "Récompense disponible chez Shop 🎁",
      body: "Bon d'achat 10 % disponible.",
    });
  });
});
