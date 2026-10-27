import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/vitrine_qr_config.dart';
import 'logger_service.dart';

/// Recovers a merchant id after "scan QR → install app" (deferred deep link).
///
/// - **Android:** Play Install Referrer (`vitrine=<id>` written by vitrine.html),
///   with clipboard fallback (landing page copies the https URL).
/// - **iOS:** clipboard (landing page copies the https vitrine URL before the
///   App Store redirect). Checked only once per successful recovery attempt.
class DeferredVitrineLink {
  DeferredVitrineLink._();

  static const _checkedKey = 'deferred_vitrine_link_checked_v1';
  static const _channel = MethodChannel('com.yuztoo.app/install_referrer');

  /// Returns a merchant id once, or null. Safe to call on every cold start.
  ///
  /// On Android, a transient Play Install Referrer failure does **not** burn
  /// the one-shot flag (so the next cold start can retry). Clipboard recovery
  /// or a successful referrer read (even organic / empty) marks the attempt done.
  static Future<String?> consumeOnce() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_checkedKey) == true) return null;

      String? merchantId;
      var markChecked = !Platform.isAndroid;

      if (Platform.isAndroid) {
        final referrer = await _fromPlayInstallReferrer();
        if (referrer.completed) {
          markChecked = true;
          merchantId = referrer.merchantId;
        }
      }

      merchantId ??= await _fromClipboard();
      if (merchantId != null) markChecked = true;

      if (markChecked) {
        await prefs.setBool(_checkedKey, true);
      }

      if (merchantId != null) {
        LoggerService.logInfo(
          'Deferred vitrine link recovered',
          context: {'merchantIdLen': merchantId.length},
        );
      }
      return merchantId;
    } catch (e, st) {
      LoggerService.logError(
        'Deferred vitrine link recovery failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// [completed] is true when the native API answered (string, possibly empty).
  /// False means transient failure — caller should not burn the one-shot flag.
  static Future<({bool completed, String? merchantId})>
      _fromPlayInstallReferrer() async {
    try {
      final raw = await _channel.invokeMethod<String>('getInstallReferrer');
      // Native always returns a String on success (empty = organic / no vitrine).
      return (
        completed: true,
        merchantId: VitrineQrConfig.tryParseMerchantIdFromInstallReferrer(raw),
      );
    } on MissingPluginException {
      return (completed: false, merchantId: null);
    } on PlatformException {
      return (completed: false, merchantId: null);
    }
  }

  static Future<String?> _fromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return null;
      final id = VitrineQrConfig.tryParseMerchantId(text);
      if (id == null) return null;
      // Clear so we don't re-open the same store on a later reinstall check
      // if the flag were ever reset.
      await Clipboard.setData(const ClipboardData(text: ''));
      return id;
    } catch (_) {
      return null;
    }
  }
}
