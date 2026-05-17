/**
 * Pure logic for merchant auto-notifications (Cloud Functions + unit tests).
 * Keep in sync with `lib/feature/rappels/domain/auto_notification_triggers.dart`.
 */

/** Canonical trigger strings (must match Flutter [triggerLabels]). */
export const AUTO_NOTIFICATION_TRIGGERS = {
  birthday: "Date anniversaire client",
  segmentChange: "Changement de Statut client",
  newFollower: "Nouveau client connecté",
  visitDetected: "Visite client détectée",
  passageValidated: "Passage fidélité validé",
  inactiveReturn: "Retour d'un client inactif",
  rewardAvailable: "Récompense disponible",
  rewardNear: "Récompense proche",
  exceptionalClosure: "Fermeture exceptionnelle",
  newPartner: "Nouveau partenaire",
  connectionAnniversary: "Anniversaire de connexion",
} as const;

export type AutoNotificationTrigger =
  (typeof AUTO_NOTIFICATION_TRIGGERS)[keyof typeof AUTO_NOTIFICATION_TRIGGERS];

/** Legacy / mistyped trigger strings stored before UI/CF alignment. */
export const TRIGGER_ALIASES: Record<string, readonly string[]> = {
  [AUTO_NOTIFICATION_TRIGGERS.birthday]: [
    "Chaque birthday client",
    "Date anniversaire",
  ],
  [AUTO_NOTIFICATION_TRIGGERS.connectionAnniversary]: [
    "Anniversaire connexion",
  ],
  [AUTO_NOTIFICATION_TRIGGERS.inactiveReturn]: [
    "Rappel inactivité",
    "Client inactif",
  ],
  [AUTO_NOTIFICATION_TRIGGERS.passageValidated]: [
    "Après validation fidélité",
    "Fidélité validé",
  ],
  [AUTO_NOTIFICATION_TRIGGERS.newFollower]: ["Nouveau client"],
  [AUTO_NOTIFICATION_TRIGGERS.segmentChange]: ["Changement statut"],
  [AUTO_NOTIFICATION_TRIGGERS.rewardAvailable]: ["Récompense dispo"],
  [AUTO_NOTIFICATION_TRIGGERS.rewardNear]: ["Récompense proche"],
  [AUTO_NOTIFICATION_TRIGGERS.exceptionalClosure]: ["Fermeture excep."],
  [AUTO_NOTIFICATION_TRIGGERS.newPartner]: [],
  [AUTO_NOTIFICATION_TRIGGERS.visitDetected]: [],
};

/** Triggers with a live Cloud Function handler (UI should match). */
export const WIRED_AUTO_NOTIFICATION_TRIGGERS: ReadonlySet<string> = new Set([
  AUTO_NOTIFICATION_TRIGGERS.birthday,
  AUTO_NOTIFICATION_TRIGGERS.connectionAnniversary,
  AUTO_NOTIFICATION_TRIGGERS.inactiveReturn,
  AUTO_NOTIFICATION_TRIGGERS.newFollower,
  AUTO_NOTIFICATION_TRIGGERS.passageValidated,
  AUTO_NOTIFICATION_TRIGGERS.rewardAvailable,
  AUTO_NOTIFICATION_TRIGGERS.rewardNear,
  AUTO_NOTIFICATION_TRIGGERS.segmentChange,
  AUTO_NOTIFICATION_TRIGGERS.exceptionalClosure,
  AUTO_NOTIFICATION_TRIGGERS.newPartner,
  // visitDetected — reserved; no handler yet
]);

export const INACTIVE_MIN_DAYS = 60;
export const INACTIVE_COOLDOWN_DAYS = 30;

export function normalizeTrigger(raw: string): string {
  return raw.trim();
}

/** True when [stored] should match a query for [canonicalTrigger]. */
export function triggersMatch(
  stored: string,
  canonicalTrigger: string
): boolean {
  const storedNorm = normalizeTrigger(stored);
  const canonical = normalizeTrigger(canonicalTrigger);
  if (storedNorm === canonical) return true;
  const aliases = TRIGGER_ALIASES[canonical] ?? [];
  return aliases.some((a) => normalizeTrigger(a) === storedNorm);
}

export function isMerchantAutoNotificationsEnabled(
  merchantData: Record<string, unknown> | undefined
): boolean {
  if (!merchantData) return false;
  const v = merchantData.notifications_auto_enabled;
  if (v === false) return false;
  // Falsy-but-not-false values from legacy imports / bad writes must not disable.
  if (v === 0 || v === "0") return false;
  // Matches MerchantDto: missing or true → enabled.
  return true;
}

export function parseDobToMD(dob: string): string {
  const trimmed = dob.trim();
  return trimmed.length >= 5 ? trimmed.slice(trimmed.length - 5) : trimmed;
}

export function isLeapYear(year: number): boolean {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

/**
 * Birthday match for daily job (Europe/Paris calendar day).
 * Feb 29 DOBs also match on Feb 28 in non-leap years.
 */
export function isBirthdayToday(
  dob: string | undefined,
  todayMD: string,
  today: Date
): boolean {
  if (!dob || dob.trim().length === 0) return false;
  const dobMD = parseDobToMD(dob);
  if (dobMD === todayMD) return true;
  if (
    dobMD === "02-29" &&
    todayMD === "02-28" &&
    !isLeapYear(today.getFullYear())
  ) {
    return true;
  }
  return false;
}

export function shouldSendBirthdayThisYear(
  dob: string | undefined,
  todayMD: string,
  today: Date,
  lastBirthdayAutoYear: number | undefined
): boolean {
  if (!isBirthdayToday(dob, todayMD, today)) return false;
  return lastBirthdayAutoYear !== today.getFullYear();
}

export function shouldSendConnectionAnniversary(
  followMD: string,
  todayMD: string,
  followYear: number,
  currentYear: number,
  lastAnniversaryAutoYear: number | undefined
): boolean {
  if (followMD !== todayMD) return false;
  if (currentYear <= followYear) return false;
  return lastAnniversaryAutoYear !== currentYear;
}

export function daysBetween(fromMs: number, toMs: number): number {
  return (toMs - fromMs) / (1000 * 60 * 60 * 24);
}

export function shouldSendInactiveReturn(
  daysSinceLastVisit: number,
  lastInactiveAutoAtMs: number | undefined,
  nowMs: number
): boolean {
  if (daysSinceLastVisit < INACTIVE_MIN_DAYS) return false;
  if (lastInactiveAutoAtMs == null) return true;
  return (
    daysBetween(lastInactiveAutoAtMs, nowMs) >= INACTIVE_COOLDOWN_DAYS
  );
}

/**
 * Segment filter for auto-notifications — parity with Dart
 * `promotionSegmentMatchesTarget` + legacy `abonne` → `nouveau`.
 */
export function autoNotificationSegmentMatches(
  clientSegment: string,
  targetSegments: string[]
): boolean {
  if (targetSegments.length === 0) return true;
  const normalizedTargets = targetSegments.map((t) =>
    t === "abonne" ? "nouveau" : t
  );
  for (const target of normalizedTargets) {
    if (target === clientSegment) return true;
    if (
      target === "soutien" &&
      (clientSegment === "vip" || clientSegment === "habitue")
    ) {
      return true;
    }
  }
  return false;
}

export function filterEnabledNotificationsForTrigger<
  T extends { data: () => Record<string, unknown> }
>(docs: T[], canonicalTrigger: string): T[] {
  return docs.filter((d) => {
    const data = d.data();
    if (data.is_enabled !== true) return false;
    const stored = String(data.trigger ?? "");
    return triggersMatch(stored, canonicalTrigger);
  });
}
