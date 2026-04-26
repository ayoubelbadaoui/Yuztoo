import 'dart:convert';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:universal_platform/universal_platform.dart';

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
  static Future<NfcResult> readVitrineMerchantId({
    String alertMessage = 'Approchez votre téléphone du badge NFC',
  }) async {
    if (!isSupported) return const NfcUnavailable();
    try {
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: alertMessage,
        iosMultipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
      );

      final records = await FlutterNfcKit.readNDEFRecords();
      await FlutterNfcKit.finish(iosAlertMessage: 'Tag lu !');

      for (final record in records) {
        if (record is ndef.UriRecord) {
          final url = record.uri?.toString() ?? '';
          final merchantId = _tryParseMerchantId(url);
          if (merchantId != null) {
            return NfcSuccess(merchantId: merchantId);
          }
        } else if (record is ndef.TextRecord) {
          final text = record.text ?? '';
          final merchantId = _tryParseMerchantId(text);
          if (merchantId != null) {
            return NfcSuccess(merchantId: merchantId);
          }
        } else {
          // Try raw payload as UTF-8 URL.
          final payload = record.payload;
          if (payload != null && payload.isNotEmpty) {
            final raw = utf8.decode(payload, allowMalformed: true);
            final merchantId = _tryParseMerchantId(raw);
            if (merchantId != null) {
              return NfcSuccess(merchantId: merchantId);
            }
          }
        }
      }

      await FlutterNfcKit.finish(
          iosErrorMessage: 'Ce badge NFC n\'appartient pas à un commerce Yuztoo.');
      return const NfcError('Ce badge NFC ne contient pas de vitrine Yuztoo.');
    } catch (e) {
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Erreur de lecture.');
      } catch (_) {}
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('Cancel')) {
        return const NfcError('Lecture annulée.');
      }
      return NfcError('Impossible de lire le badge NFC : $msg');
    }
  }

  /// Write the Yuztoo vitrine URL for [merchantId] to the next NFC tag presented.
  static Future<NfcResult> writeVitrineUrl(
    String merchantId, {
    String alertMessage = 'Approchez votre téléphone de la carte/sticker NFC',
  }) async {
    if (!isSupported) return const NfcUnavailable();
    if (merchantId.isEmpty) return const NfcError('Identifiant commerce manquant.');

    final url = 'https://yuztoo.app/vitrine/$merchantId';

    try {
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: alertMessage,
        iosMultipleTagMessage: 'Plusieurs tags détectés — n\'en gardez qu\'un.',
        readIso14443A: true,
        readIso14443B: true,
        readIso15693: true,
        readIso18092: true,
      );

      await FlutterNfcKit.writeNDEFRecords([
        ndef.UriRecord.fromString(url),
      ]);

      await FlutterNfcKit.finish(iosAlertMessage: 'Badge programmé !');
      return const NfcSuccess();
    } catch (e) {
      try {
        await FlutterNfcKit.finish(iosErrorMessage: 'Erreur d\'écriture.');
      } catch (_) {}
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('Cancel')) {
        return const NfcError('Programmation annulée.');
      }
      if (msg.contains('readonly') || msg.contains('Readonly')) {
        return const NfcError('Ce badge NFC est en lecture seule et ne peut pas être programmé.');
      }
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
