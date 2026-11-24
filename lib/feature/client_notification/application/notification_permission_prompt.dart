import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/infrastructure/permission_request_queue.dart';

/// « Soft ask » for push notifications, the way large apps do it.
///
/// iOS shows its system prompt only once per install; asked cold on first
/// launch (before signup, with no context) most people tap « Ne pas
/// autoriser » and pushes are lost for good. Instead the app explains the
/// benefit at a meaningful moment (end of onboarding / first time on the
/// home screen) and only then triggers the system prompt. « Plus tard » is
/// respected: offered again at most [maxOffers] times, [cooldown] apart.
class NotificationPermissionPrompt {
  const NotificationPermissionPrompt._();

  static const int maxOffers = 3;
  static const Duration cooldown = Duration(days: 7);
  static const _kOffers = 'notif_soft_ask_offers';
  static const _kLastOfferMs = 'notif_soft_ask_last_ms';

  /// Pure decision, unit-tested.
  static bool shouldOffer({
    required AuthorizationStatus status,
    required bool isIOS,
    required int offersSoFar,
    required DateTime? lastOffer,
    required DateTime now,
  }) {
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      return false;
    }
    // iOS never shows the system prompt again after a refusal: offering would
    // only nag. (Android reports « denied » before the first ask on 13+.)
    if (isIOS && status == AuthorizationStatus.denied) return false;
    if (offersSoFar >= maxOffers) return false;
    if (lastOffer != null && now.difference(lastOffer) < cooldown) {
      return false;
    }
    return true;
  }

  /// Shows the explanation sheet when [shouldOffer] says so. Calls
  /// [onGranted] (e.g. register the FCM token) after an accepted prompt.
  static Future<void> maybeOffer(
    BuildContext context, {
    required bool forMerchant,
    required Future<void> Function() onGranted,
  }) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final prefs = await SharedPreferences.getInstance();
      final offers = prefs.getInt(_kOffers) ?? 0;
      final lastMs = prefs.getInt(_kLastOfferMs);
      final offer = shouldOffer(
        status: settings.authorizationStatus,
        isIOS: Platform.isIOS,
        offersSoFar: offers,
        lastOffer:
            lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
        now: DateTime.now(),
      );
      if (!offer || !context.mounted) return;

      await prefs.setInt(_kOffers, offers + 1);
      await prefs.setInt(_kLastOfferMs, DateTime.now().millisecondsSinceEpoch);

      final accepted = await showNotificationSoftAskSheet(
        context,
        forMerchant: forMerchant,
      );
      if (!accepted) return;

      final result = await PermissionRequestQueue.run(
        () => messaging.requestPermission(alert: true, badge: true, sound: true),
      );
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await onGranted();
      }
    } catch (_) {
      // Never let the soft ask break navigation.
    }
  }
}

/// The explanation sheet. Returns true on « Activer les notifications ».
Future<bool> showNotificationSoftAskSheet(
  BuildContext context, {
  required bool forMerchant,
}) async {
  const gold = Color(0xFFD4A017);
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF152A40),
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active_rounded, color: gold, size: 48),
          const SizedBox(height: 16),
          Text(
            forMerchant
                ? 'Ne manquez aucun client'
                : 'Ne ratez aucune offre',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            forMerchant
                ? 'Soyez prévenu dès qu\'un client demande une validation de '
                    'passage ou interagit avec votre vitrine.'
                : 'Recevez les promotions, les rappels et les récompenses de '
                    'vos commerces préférés. Vous choisissez ce que vous '
                    'recevez, et vous pouvez changer d\'avis à tout moment.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: const Color(0xFF0E2A44),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Activer les notifications',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Plus tard',
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
