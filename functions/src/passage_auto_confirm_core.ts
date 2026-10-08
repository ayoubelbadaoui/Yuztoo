/**
 * Pure rules for confirming an `active_validations` session server-side when
 * the merchant runs automatic passage validation. Mirrors
 * `lib/feature/loyalty/domain/loyalty_passage_program_policy.dart`
 * (`isPassageSessionAutoConfirmed`) — keep both in lockstep.
 */

type FirestoreMap = Record<string, unknown>;

export const PASSAGE_COOLDOWN_MS = 60 * 60 * 1000;

function asMap(raw: unknown): FirestoreMap | undefined {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    return raw as FirestoreMap;
  }
  return undefined;
}

function num(map: FirestoreMap, key: string, fallback: number): number {
  const v = map[key];
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

/** Same resolution as the Flutter `merchantPassageValidationIsAutomatic`. */
export function merchantPassageValidationIsAutomatic(
  merchantData: FirestoreMap | undefined
): boolean {
  if (!merchantData) return false;
  const autoToggle = merchantData.rappels_auto_passage_validation;
  if (typeof autoToggle === "boolean") return autoToggle;
  return asMap(merchantData.loyalty_program)?.passage_validation === "automatic";
}

export function isMerchantLoyaltyActive(
  merchantData: FirestoreMap | undefined
): boolean {
  if (!merchantData || merchantData.loyalty_enabled !== true) return false;
  const program = asMap(merchantData.loyalty_program);
  return program ? program.program_enabled === true : true;
}

/** Enrolled terms win (E-Fidélité promise), else the session snapshot. */
export function resolvePassageProgram(
  loyalty: FirestoreMap | undefined,
  session: FirestoreMap
): FirestoreMap {
  const enrolled = asMap(loyalty?.enrolled_loyalty_program);
  if (enrolled && Object.keys(enrolled).length > 0) return enrolled;
  return asMap(session.program_snapshot) ?? {};
}

/** Amount-based programmes need the merchant to type the purchase. */
export function programRequiresSpendAmount(program: FirestoreMap): boolean {
  return (
    program.trigger_type === "purchase_total" ||
    program.reward_kind === "loyalty_points"
  );
}

export function isPassageSessionAutoConfirmed(
  merchantData: FirestoreMap | undefined,
  session: FirestoreMap,
  loyalty: FirestoreMap | undefined
): boolean {
  if (session.source === "ble") return false;
  if (!isMerchantLoyaltyActive(merchantData)) return false;
  if (!merchantPassageValidationIsAutomatic(merchantData)) return false;
  return !programRequiresSpendAmount(resolvePassageProgram(loyalty, session));
}

export function isInsidePassageCooldown(
  lastPassageAtMs: number | null,
  nowMs: number,
  cooldownEnabled: boolean
): boolean {
  if (!cooldownEnabled || lastPassageAtMs == null) return false;
  return nowMs - lastPassageAtMs < PASSAGE_COOLDOWN_MS;
}

/** `rappels_monthly_validated_ym` key, on the merchant's (Paris) calendar. */
export function parisYearMonth(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Paris",
    year: "numeric",
    month: "2-digit",
  }).formatToParts(date);
  const year = parts.find((p) => p.type === "year")?.value ?? "1970";
  const month = parts.find((p) => p.type === "month")?.value ?? "01";
  return `${year}-${month}`;
}

/** Same copy as the Flutter `writePassageValidatedNotification`. */
export function passageValidatedNotification(
  merchantName: string,
  program: FirestoreMap,
  validatedAfter: number
): { title: string; body: string } {
  const needed = num(program, "visits_required", 10);
  return {
    title: `Passage validé chez ${merchantName} ✓`,
    body:
      needed > 0
        ? `Passage validé (${validatedAfter} / ${needed} passages).`
        : "Votre passage a été validé.",
  };
}

export function visitRewardJustUnlocked(
  program: FirestoreMap,
  validatedAfter: number
): boolean {
  const needed = num(program, "visits_required", 10);
  if (needed <= 0) return false;
  return validatedAfter >= needed && validatedAfter - 1 < needed;
}

/** Same copy as the Flutter `writeRewardUnlockedNotification`. */
export function rewardUnlockedNotification(
  merchantName: string,
  program: FirestoreMap
): { title: string; body: string } {
  return {
    title: `Récompense disponible chez ${merchantName} 🎁`,
    body: rewardLabel(program),
  };
}

function rewardLabel(program: FirestoreMap): string {
  switch (program.reward_kind) {
    case "discount_percent":
      return `Remise ${num(program, "discount_next_purchase_percent", 10).toFixed(0)} % sur votre prochain achat.`;
    case "free_product": {
      const label = program.free_product_summary_label;
      return typeof label === "string" && label.trim().length > 0
        ? `Offert : ${label.trim()}`
        : "Produit offert disponible.";
    }
    case "loyalty_points":
      return `Points fidélité crédités (${num(program, "points_per_euro", 1).toFixed(1)} pts/€).`;
    default: {
      const value = num(program, "purchase_voucher_value", 10).toFixed(0);
      const usesPercent = program.purchase_voucher_uses_percent !== false;
      return usesPercent
        ? `Bon d'achat ${value} % disponible.`
        : `Bon d'achat ${value} € disponible.`;
    }
  }
}
