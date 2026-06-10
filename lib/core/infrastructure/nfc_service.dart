import 'dart:convert';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:universal_platform/universal_platform.dart';

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
  static bool get isSupported =>
      UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  static const NfcAnalytics _analytics = NfcAnalytics();

  static Map<String, Object?> _platformParams() => <String, Object?>{
        'platform': UniversalPlatform.isIOS ? 'ios' : 'android',
      };

  /// Check if NFC hardware is available and enabled on this device.
  static Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
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
    _analytics.logEvent(
      NfcAnalyticsEvent.tagReadAttempt,
      parameters: _platformParams(),
    );
    try {
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: alertMessage,
        iosMultipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
      );

      final records = await FlutterNfcKit.readNDEFRecords();

      // Distinguish empty / non-Yuztoo / bad URL: the user-visible French
      // message changes accordingly so a fresh sticker is not confused
      // with a tag programmed for a different app.
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
          final merchantId = _tryParseMerchantId(url);
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
          final merchantId = _tryParseMerchantId(text);
          if (merchantId != null) {
            await FlutterNfcKit.finish(iosAlertMessage: 'Tag lu !');
            _analytics.logEvent(
              NfcAnalyticsEvent.tagReadSuccess,
              parameters: _platformParams(),
            );
            return NfcSuccess(merchantId: merchantId);
          }
        } else {
          // Try raw payload as UTF-8 URL.
          final payload = record.payload;
          if (payload != null && payload.isNotEmpty) {
            final raw = utf8.decode(payload, allowMalformed: true);
            final merchantId = _tryParseMerchantId(raw);
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
      if (msg.contains('cancel') || msg.contains('Cancel')) {
        _analytics.logEvent(
          NfcAnalyticsEvent.tagReadCancelled,
          parameters: _platformParams(),
        );
        return const NfcError('Lecture annulée.');
      }
      _analytics.logEvent(
        NfcAnalyticsEvent.tagReadError,
        parameters: <String, Object?>{
          ..._platformParams(),
          'reason': msg,
        },
      );
      return NfcError('Impossible de lire le tag NFC : $msg');
    }
  }

  /// Write the Yuztoo vitrine URL for [merchantId] to the next NFC tag presented.
  ///
  /// Works on iOS and Android. Three guards run after `poll()` and before
  /// the actual write so the user gets a French explanation instead of a
  /// raw stack trace:
  ///
  /// 1. [tag.ndefAvailable] — fresh tags that have never been NDEF-formatted
  ///    will fail `writeNDEFRecords` with an opaque message; we surface
  ///    "Ce badge n'est pas formaté NDEF" instead.
  /// 2. [tag.ndefWritable] — locked / read-only tags (NTAG21x can be
  ///    permanently locked) get a friendly message and we don't even try.
  /// 3. [tag.ndefCapacity] — NTAG213 has 137 bytes of NDEF user memory.
  ///    The vitrine URL fits comfortably for any reasonable merchantId,
  ///    but we still check so an outsized merchantId surfaces a clear
  ///    error rather than a partial write.
  static Future<NfcResult> writeVitrineUrl(
    String merchantId, {
    String alertMessage = 'Approchez votre téléphone de la carte/sticker NFC',
  }) async {
    if (!isSupported) return const NfcUnavailable();
    if (merchantId.isEmpty) return const NfcError('Identifiant commerce manquant.');

    final url = 'https://yuztoo.app/vitrine/$merchantId';
    _analytics.logEvent(
      NfcAnalyticsEvent.tagWriteAttempt,
      parameters: <String, Object?>{
        ..._platformParams(),
        'merchant_id': merchantId,
      },
    );

    try {
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: alertMessage,
        iosMultipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
        readIso14443A: true,
        readIso14443B: true,
        readIso15693: true,
        readIso18092: true,
      );

      // Defensive check 1 — non-NDEF tag.
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

      // Defensive check 2 — read-only tag.
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

      // Defensive check 3 — encoded NDEF message exceeds the tag's capacity.
      // The NDEF wrapper for a single URI record adds a small header (~10
      // bytes) on top of the URL bytes; we leave a generous margin.
      final encodedSize = url.length + 16;
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

      await FlutterNfcKit.writeNDEFRecords([
        ndef.UriRecord.fromString(url),
      ]);

      await FlutterNfcKit.finish(iosAlertMessage: 'Badge programmé !');
      _analytics.logEvent(
        NfcAnalyticsEvent.tagWriteSuccess,
        parameters: <String, Object?>{
          ..._platformParams(),
          'merchant_id': merchantId,
        },
      );
      return const NfcSuccess();
    } catch (e) {
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Erreur d\'écriture.');
      } catch (_) {}
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('Cancel')) {
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
      _analytics.logEvent(
        NfcAnalyticsEvent.tagWriteError,
        parameters: <String, Object?>{
          ..._platformParams(),
          'reason': msg,
        },
      );
      return NfcError('Impossible de programmer le badge : $msg');
    }
  }

  /// Parses a Yuztoo vitrine URL and returns the merchant ID, or null.
  static String? _tryParseMerchantId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null) return null;

    if (uri.scheme == 'yuztoo' && uri.host == 'vitrine') {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segs.isNotEmpty) return segs.first;
    }

    if (uri.scheme == 'https' || uri.scheme == 'http') {
      final host = uri.host.toLowerCase();
      if (host == 'yuztoo.app' || host == 'www.yuztoo.app') {
        final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segs.length >= 2 && segs[0] == 'vitrine') return segs[1];
      }
    }

    return null;
  }
}
