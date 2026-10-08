import {
  FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED,
  isOverWeeklyNotificationQuota,
  isPaidSubscriptionPlan,
} from "../notification_quota_core";

const NOW = Date.UTC(2026, 9, 8, 12, 0, 0);
const DAY = 24 * 60 * 60 * 1000;
const ts = (ms: number) => ({ toMillis: () => ms });

describe("notification quota", () => {
  test("launch phase: quota disabled for everyone", () => {
    expect(FREE_PLAN_WEEKLY_NOTIFICATION_QUOTA_ENABLED).toBe(false);
    expect(
      isOverWeeklyNotificationQuota(
        { weekly_notif_sent_count: 40, weekly_notif_reset_at: ts(NOW - DAY) },
        NOW,
      ),
    ).toBe(false);
  });

  test("paid plans are recognised", () => {
    expect(isPaidSubscriptionPlan("essentiel")).toBe(true);
    expect(isPaidSubscriptionPlan(" Premium ")).toBe(true);
    expect(isPaidSubscriptionPlan("gratuit")).toBe(false);
    expect(isPaidSubscriptionPlan(undefined)).toBe(false);
  });

  describe("once enabled", () => {
    const over = (data: Parameters<typeof isOverWeeklyNotificationQuota>[0]) =>
      isOverWeeklyNotificationQuota(data, NOW, true);

    test("free plan at 5 inside the window is blocked", () => {
      expect(
        over({ weekly_notif_sent_count: 5, weekly_notif_reset_at: ts(NOW - DAY) }),
      ).toBe(true);
    });

    test("free plan at 4 inside the window can send", () => {
      expect(
        over({ weekly_notif_sent_count: 4, weekly_notif_reset_at: ts(NOW - DAY) }),
      ).toBe(false);
    });

    test("expired window (7+ days) frees the quota", () => {
      expect(
        over({ weekly_notif_sent_count: 9, weekly_notif_reset_at: ts(NOW - 7 * DAY) }),
      ).toBe(false);
    });

    test("no window yet can send", () => {
      expect(over({ weekly_notif_sent_count: 9 })).toBe(false);
    });

    test("paid plans are never blocked", () => {
      for (const plan of ["essentiel", "premium"]) {
        expect(
          over({
            subscription_plan: plan,
            weekly_notif_sent_count: 50,
            weekly_notif_reset_at: ts(NOW - DAY),
          }),
        ).toBe(false);
      }
    });
  });
});
