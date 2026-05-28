import '../entities/profile_view_stats.dart';

/// Records storefront views (best-effort, idempotent per viewer/day) and
/// reads aggregated weekly stats for the merchant dashboard.
///
/// Implementations are expected to swallow non-critical I/O failures and
/// log them — this surface MUST NOT crash the UI when the network or the
/// security layer pushes back. Reads degrade to [ProfileViewStats.empty].
///
/// Pure-domain interface — no Firebase / Flutter dependencies.
abstract class ProfileViewRepository {
  /// Record one view of [merchantId] by [viewerId]. The implementation is
  /// expected to:
  ///
  /// * derive a UTC midnight day from [nowUtc] and dedupe per (viewerId,
  ///   day) so multiple opens by the same viewer on the same day count
  ///   as a single view,
  /// * skip writes when [merchantId] equals [viewerId] (a merchant
  ///   previewing their own storefront must not inflate their counter),
  /// * skip writes when either id is empty,
  /// * never throw — failures are logged and the call returns normally.
  Future<void> recordView({
    required String merchantId,
    required String viewerId,
    required DateTime nowUtc,
  });

  /// Read the 7-day sliding window stats for [merchantId] anchored at
  /// [nowUtc]. Returns [ProfileViewStats.empty] on read failure or when
  /// [merchantId] is empty.
  Future<ProfileViewStats> getWeeklyStats({
    required String merchantId,
    required DateTime nowUtc,
  });
}
