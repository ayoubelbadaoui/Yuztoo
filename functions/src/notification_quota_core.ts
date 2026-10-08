/**
 * Manual-notification quota rules, shared by the scheduled-send path.
 * Mirror of `lib/feature/merchant/domain/notification_quota_policy.dart`.
 */

/**
 * Launch phase: unlimited for every merchant. Set to `true` once paid plans
 * go live — the quota then applies to the free plan only. Keep in sync with
 * `kFreePlanWeeklyNotificationQuotaEnabled` in the app.
 */
export const FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED = false;

/** Manual notifications allowed per rolling 7-day window on the free plan. */
export const FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA = 5;

/** Rolling window of the counter (`weekly_notif_reset_at`). */
export const NOTIFICATION_QUOTA_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

/** `subscription_plan` values that are never limited. */
export function isPaidSubscriptionPlan(raw: unknown): boolean {
  const plan = typeof raw === "string" ? raw.trim().toLowerCase() : "";
  return plan === "essentiel" || plan === "premium";
}

export function weeklyNotificationQuotaApplies(
  subscriptionPlan: unknown,
  quotaEnabled = FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED,
): boolean {
  return quotaEnabled && !isPaidSubscriptionPlan(subscriptionPlan);
}

/** True when the merchant has a quota and the current window is used up. */
export function isOverWeeklyNotificationQuota(
  merchantData: {
    subscription_plan?: unknown;
    weekly_notif_sent_count?: unknown;
    weekly_notif_reset_at?: { toMillis(): number } | null;
  },
  nowMs: number,
  quotaEnabled = FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED,
): boolean {
  if (!weeklyNotificationQuotaApplies(merchantData.subscription_plan, quotaEnabled)) {
    return false;
  }
  const resetAt = merchantData.weekly_notif_reset_at;
  const windowOpen =
    !!resetAt && nowMs - resetAt.toMillis() < NOTIFICATION_QUOTA_WINDOW_MS;
  const count = Number(merchantData.weekly_notif_sent_count ?? 0);
  return windowOpen && count >= FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA;
}
