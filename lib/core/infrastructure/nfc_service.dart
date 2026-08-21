import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:universal_platform/universal_platform.dart';

import '../config/vitrine_qr_config.dart';
import '../../feature/loyalty/application/analytics/nfc_analytics.dart';

/// Result of an NFC read or write operation.
sealed class NfcResult {
  const NfcResult();
}

final class NfcSuccess extends NfcResult {
  const NfcSuccess({this.merchantId});
  final String? merchantId;
}

final class NfcError extends NfcResult {
  const NfcError(this.message);
  final String message;
}

final class NfcUnavailable extends NfcResult {
  const NfcUnavailable();
}

/// Thin wrapper around flutter_nfc_kit for Yuztoo vitrine NFC operations.
class NfcService {
  /// When true, [isSupported] behaves as on a mobile device (unit tests only).
  @visibleForTesting
  static bool? debugForceMobileNfcSupported;

  /// When set, drives iOS vs Android poll flags (unit tests only).
  @visibleForTesting
  static bool? debugSimulateIos;

  static bool get isSupported =>
      debugForceMobileNfcSupported == true ||
      UniversalPlatform.isAndroid ||
      UniversalPlatform.isIOS;

  static bool get _isIosPlatform =>
      debugSimulateIos ?? UniversalPlatform.isIOS;

  static const NfcAnalytics _analytics = NfcAnalytics();

  /// Native channel shared with [MainActivity]. On Android, our app holds NFC
  /// foreground dispatch so a tap registers a passage instantly. That mode is
  /// mutually exclusive with flutter_nfc_kit's reader session, so we must
  /// suspend it around every active poll/write below and restore it after.
  static const MethodChannel _androidNfcChannel =
      MethodChannel('com.yuztoo.app/nfc');

  static Future<void> _pauseAndroidForegroundDispatch() async {
    if (_isIosPlatform || !UniversalPlatform.isAndroid) return;
    try {
      await _androidNfcChannel.invokeMethod('pauseNfcForegroundDispatch');
    } catch (_) {}
  }

  static Future<void> _resumeAndroidForegroundDispatch() async {
    if (_isIosPlatform || !UniversalPlatform.isAndroid) return;
    try {
      await _androidNfcChannel.invokeMethod('resumeNfcForegroundDispatch');
    } catch (_) {}
  }

  static Map<String, Object?> _platformParams() => <String, Object?>{
        'platform': _isIosPlatform ? 'ios' : 'android',
      };

  /// Ends an in-flight Core NFC / reader session (safe no-op when idle).
  static Future<void> cancelActiveSession() async {
    if (!isSupported) return;
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  /// Yuztoo stickers are NTAG213 (ISO 14443 Type A). On iOS, polling FeliCa
  /// (ISO 18092) or ISO 15693 without matching Info.plist entitlements makes
  /// Core NFC fail immediately with Code=2 "Missing required entitlement".
  /// Android keeps broader polling for Samsung / multi-protocol readers.
  static Future<NFCTag> _pollVitrineTag({
    required String alertMessage,
    required String multipleTagMessage,
  }) {
    final isIos = _isIosPlatform;
    final pollIso15693 = !isIos;
    final pollIso18092 = !isIos;
    return FlutterNfcKit.poll(
      timeout: const Duration(seconds: 20),
      iosAlertMessage: alertMessage,
      iosMultipleTagMessage: multipleTagMessage,
      readIso14443A: true,
      readIso14443B: true,
      readIso15693: pollIso15693,
      readIso18092: pollIso18092,
    );
  }

  static NfcError? _mapNfcPlatformError(String msg) {
    if (msg.contains('Missing required entitlement')) {
      return const NfcError(
        'NFC indisponible sur cette version de l’app — réinstallez depuis '
        'l’App Store après la prochaine mise à jour.',
      );
    }
    if (msg.contains('406') || msg.contains('active session')) {
      return const NfcError(
        'Une lecture NFC est déjà en cours — réessayez dans quelques secondes.',
      );
    }
    return null;
  }

  /// French explanation when [isAvailable] is false, or null when NFC is ready.
  static Future<String?> unavailableReason() async {
    if (!isSupported) {
      return 'NFC non disponible sur cet appareil.';
    }
    try {
      return switch (await FlutterNfcKit.nfcAvailability) {
        NFCAvailability.available => null,
        NFCAvailability.disabled =>
          'Activez le NFC dans les réglages de votre téléphone.',
        NFCAvailability.not_supported =>
          'NFC non disponible sur cet appareil.',
      };
    } catch (_) {
      return 'NFC non disponible sur cet appareil.';
    }
  }

  /// Check if NFC hardware is available and enabled on this device.
  static Future<bool> isAvailable() async {
    return await unavailableReason() == null;
  }

  /// Read an NDEF tag and extract a Yuztoo vitrine URL.
  /// Returns the merchant ID on success, or an error message.
  ///
  /// Works on iOS and Android — iOS uses the reader entitlement
  /// (`com.apple.developer.nfc.readersession.formats = TAG`) configured
  /// in Runner.entitlements. The "presenting" side is always a passive
  /// NFC badge, never another phone, because iOS cannot emit NDEF.
  static Future<NfcResult> readVitrineMerchantId({
    String alertMessage = 'Approchez votre téléphone',
  }) async {
    if (!isSupported) return const NfcUnavailable();
    final blocked = await unavailableReason();
    if (blocked != null) return NfcError(blocked);

    _analytics.logEvent(
      NfcAnalyticsEvent.tagReadAttempt,
      parameters: _platformParams(),
    );
    await _pauseAndroidForegroundDispatch();
    try {
      await _pollVitrineTag(
        alertMessage: alertMessage,
        multipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
      );

      final records = await FlutterNfcKit.readNDEFRecords();

      if (records.isEmpty) {
        await FlutterNfcKit.finish(
          iosErrorMessage: 'Badge vide.',
        );
        _analytics.logEvent(
          NfcAnalyticsEvent.tagReadEmpty,
          parameters: _platformParams(),
        );
        return const NfcError(
          'Ce badge NFC est vide — il doit être programmé par le commerçant.',
        );
      }

      for (final record in records) {
        if (record is ndef.UriRecord) {
          final url = record.uri?.toString() ?? '';
          final merchantId = VitrineQrConfig.tryParseMerchantId(url);
          if (merchantId != null) {
            await FlutterNfcKit.finish(iosAlertMessage: 'Tag lu !');
            _analytics.logEvent(
              NfcAnalyticsEvent.tagReadSuccess,
              parameters: _platformParams(),
            );
            return NfcSuccess(merchantId: merchantId);
          }
        } else if (record is ndef.TextRecord) {
          final text = record.text ?? '';
          final merchantId = VitrineQrConfig.tryParseMerchantId(text);
          if (merchantId != null) {
            await FlutterNfcKit.finish(iosAlertMessage: 'Tag lu !');
            _analytics.logEvent(
              NfcAnalyticsEvent.tagReadSuccess,
              parameters: _platformParams(),
            );
            return NfcSuccess(merchantId: merchantId);
          }
        } else {
          final payload = record.payload;
          if (payload != null && payload.isNotEmpty) {
            final raw = utf8.decode(payload, allowMalformed: true);
            final merchantId = VitrineQrConfig.tryParseMerchantId(raw);
            if (merchantId != null) {
              await FlutterNfcKit.finish(iosAlertMessage: 'Tag lu !');
              _analytics.logEvent(
                NfcAnalyticsEvent.tagReadSuccess,
                parameters: _platformParams(),
              );
              return NfcSuccess(merchantId: merchantId);
            }
          }
        }
      }

      await FlutterNfcKit.finish(
        iosErrorMessage: 'Badge non Yuztoo.',
      );
      _analytics.logEvent(
        NfcAnalyticsEvent.tagReadInvalid,
        parameters: _platformParams(),
      );
      return const NfcError(
        'Ce badge ne pointe pas vers une vitrine Yuztoo.',
      );
    } catch (e) {
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Erreur de lecture.');
      } catch (_) {}
      final msg = e.toString();
      if (msg.contains('409') ||
          msg.contains('SessionCanceled') ||
          msg.contains('UserCanceled')) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagReadCancelled,
          parameters: _platformParams(),
        );
        return const NfcError('Lecture annulée.');
      }
      final mapped = _mapNfcPlatformError(msg);
      if (mapped != null) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagReadError,
          parameters: <String, Object?>{
            ..._platformParams(),
            'reason': msg,
          },
        );
        return mapped;
      }
      _analytics.logEvent(
        NfcAnalyticsEvent.tagReadError,
        parameters: <String, Object?>{
          ..._platformParams(),
          'reason': msg,
        },
      );
      return NfcError('Impossible de lire le tag NFC : $msg');
    } finally {
      await _resumeAndroidForegroundDispatch();
    }
  }

  /// Write the Yuztoo vitrine URL for [merchantId] to the next NFC tag presented.
  static Future<NfcResult> writeVitrineUrl(
    String merchantId, {
    String alertMessage = 'Approchez votre téléphone de la carte/sticker NFC',
  }) async {
    if (!isSupported) return const NfcUnavailable();
    final blocked = await unavailableReason();
    if (blocked != null) return NfcError(blocked);

    final id = merchantId.trim();
    if (id.isEmpty) return const NfcError('Identifiant commerce manquant.');

    final url = VitrineQrConfig.uriStringForMerchant(id);
    if (url.isEmpty) {
      return const NfcError('Identifiant commerce manquant.');
    }

    _analytics.logEvent(
      NfcAnalyticsEvent.tagWriteAttempt,
      parameters: <String, Object?>{
        ..._platformParams(),
        'merchant_id': id,
      },
    );

    await _pauseAndroidForegroundDispatch();
    try {
      final tag = await _pollVitrineTag(
        alertMessage: alertMessage,
        multipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
      );

      if (tag.ndefAvailable == false) {
        await FlutterNfcKit.finish(
          iosErrorMessage: 'Badge non NDEF.',
        );
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteRejectedNotNdef,
          parameters: _platformParams(),
        );
        return const NfcError(
          'Ce badge n\'est pas compatible NDEF — utilisez un sticker '
          'NTAG213 ou équivalent.',
        );
      }

      if (tag.ndefWritable == false) {
        await FlutterNfcKit.finish(
          iosErrorMessage: 'Badge en lecture seule.',
        );
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteRejectedReadOnly,
          parameters: _platformParams(),
        );
        return const NfcError(
          'Ce badge NFC est en lecture seule et ne peut pas être programmé.',
        );
      }

      final ndefRecord = ndef.UriRecord.fromString(url);
      final encodedSize = ndefRecord.encode().length;
      final capacity = tag.ndefCapacity;
      if (capacity != null && capacity > 0 && encodedSize > capacity) {
        await FlutterNfcKit.finish(
          iosErrorMessage: 'Capacité du badge insuffisante.',
        );
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteRejectedCapacity,
          parameters: <String, Object?>{
            ..._platformParams(),
            'capacity': capacity,
            'required': encodedSize,
          },
        );
        return NfcError(
          'Capacité du badge insuffisante ($capacity octets disponibles '
          'pour $encodedSize requis).',
        );
      }

      await FlutterNfcKit.writeNDEFRecords([ndefRecord]);

      await FlutterNfcKit.finish(iosAlertMessage: 'Badge programmé !');
      _analytics.logEvent(
        NfcAnalyticsEvent.tagWriteSuccess,
        parameters: <String, Object?>{
          ..._platformParams(),
          'merchant_id': id,
        },
      );
      return const NfcSuccess();
    } catch (e) {
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Erreur d\'écriture.');
      } catch (_) {}
      final msg = e.toString();
      if (msg.contains('409') ||
          msg.contains('SessionCanceled') ||
          msg.contains('UserCanceled')) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteCancelled,
          parameters: _platformParams(),
        );
        return const NfcError('Programmation annulée.');
      }
      if (msg.contains('readonly') || msg.contains('Readonly')) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteRejectedReadOnly,
          parameters: _platformParams(),
        );
        return const NfcError(
          'Ce badge NFC est en lecture seule et ne peut pas être programmé.',
        );
      }
      final mapped = _mapNfcPlatformError(msg);
      if (mapped != null) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagWriteError,
          parameters: <String, Object?>{
            ..._platformParams(),
            'reason': msg,
          },
        );
        return mapped;
      }
      _analytics.logEvent(
        NfcAnalyticsEvent.tagWriteError,
        parameters: <String, Object?>{
          ..._platformParams(),
          'reason': msg,
        },
      );
      return NfcError('Impossible de programmer le badge : $msg');
    } finally {
      await _resumeAndroidForegroundDispatch();
    }
  }
}
