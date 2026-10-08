import 'entities/merchant_subscription_plan.dart';

/// Launch phase: manual notifications are unlimited for every merchant.
/// Set to `true` once paid plans go live — the quota then applies to the
/// free plan only. Keep in sync with `FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED`
/// in `functions/src/notification_quota_core.ts`.
const bool kFreePlanWeeklyNotificationQuotaEnabled = false;

/// Manual notifications allowed per rolling 7-day window on the free plan.
const int kFreePlanWeeklyNotificationQuota = 5;

/// Whether [plan] is limited to [kFreePlanWeeklyNotificationQuota] manual
/// notifications per rolling week. Paid plans are never limited.
bool weeklyNotificationQuotaApplies(
  MerchantSubscriptionPlan plan, {
  bool quotaEnabled = kFreePlanWeeklyNotificationQuotaEnabled,
}) =>
    quotaEnabled && !plan.isPaid;

/// Notifications counted in the rolling window opened at [resetAt]
/// (0 when no window is open or it is 7+ days old).
int notificationsSentInWindow({
  required int sentCount,
  required DateTime? resetAt,
  DateTime? now,
}) {
  if (resetAt == null) return 0;
  if ((now ?? DateTime.now()).difference(resetAt).inDays >= 7) return 0;
  return sentCount;
}

/// False only when [plan] has a quota and the current window is used up.
bool canSendManualNotification({
  required MerchantSubscriptionPlan plan,
  required int sentCount,
  required DateTime? resetAt,
  DateTime? now,
  bool quotaEnabled = kFreePlanWeeklyNotificationQuotaEnabled,
}) {
  if (!weeklyNotificationQuotaApplies(plan, quotaEnabled: quotaEnabled)) {
    return true;
  }
  return notificationsSentInWindow(
        sentCount: sentCount,
        resetAt: resetAt,
        now: now,
      ) <
      kFreePlanWeeklyNotificationQuota;
}

/// "2/5"-style usage label, or null when [plan] sends are unlimited.
String? manualNotificationQuotaLabel({
  required MerchantSubscriptionPlan plan,
  required int sentCount,
  required DateTime? resetAt,
  DateTime? now,
  bool quotaEnabled = kFreePlanWeeklyNotificationQuotaEnabled,
}) {
  if (!weeklyNotificationQuotaApplies(plan, quotaEnabled: quotaEnabled)) {
    return null;
  }
  const max = kFreePlanWeeklyNotificationQuota;
  final used = notificationsSentInWindow(
    sentCount: sentCount,
    resetAt: resetAt,
    now: now,
  ).clamp(0, max);
  return '$used/$max';
}
