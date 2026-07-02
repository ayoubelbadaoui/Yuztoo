import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef/ndef.dart' as ndef;

/// In-process fake for `flutter_nfc_kit/method` used by [NfcService] tests.
final class NfcMethodChannelFake {
  NfcMethodChannelFake() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static const MethodChannel channel = MethodChannel('flutter_nfc_kit/method');

  String availability = 'available';
  NFCTag pollTag = _defaultWritableTag();
  List<ndef.NDEFRecord> readRecords = const [];
  Object? pollError;
  Object? readError;
  Object? writeError;

  final List<String> calls = <String>[];
  int? lastPollTechnologies;
  String? lastWrittenNdefJson;
  String? lastFinishErrorMessage;
  String? lastFinishSuccessMessage;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _onMethodCall);
  }

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  Future<Object?> _onMethodCall(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'getNFCAvailability':
        return availability;
      case 'poll':
        if (pollError != null) throw pollError!;
        final args = call.arguments as Map<Object?, Object?>;
        lastPollTechnologies = args['technologies'] as int?;
        return jsonEncode(pollTag.toJson());
      case 'readNDEF':
        if (readError != null) throw readError!;
        final raws = readRecords
            .map((r) => r.toRaw().toJson())
            .toList(growable: false);
        return jsonEncode(raws);
      case 'writeNDEF':
        if (writeError != null) throw writeError!;
        final args = call.arguments as Map<Object?, Object?>;
        lastWrittenNdefJson = args['data'] as String?;
        return null;
      case 'finish':
        final args = call.arguments as Map<Object?, Object?>;
        lastFinishErrorMessage = args['iosErrorMessage'] as String?;
        lastFinishSuccessMessage = args['iosAlertMessage'] as String?;
        return null;
      default:
        throw MissingPluginException('No fake for ${call.method}');
    }
  }

  static NFCTag _defaultWritableTag() => NFCTag(
        NFCTagType.mifare_ultralight,
        '041234567890AB',
        'ISO 14443-3 (Type A)',
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        true,
        null,
        137,
        true,
        false,
        null,
        null,
      );

  static NFCTag tagWith({
    bool? ndefAvailable,
    bool? ndefWritable,
    int? ndefCapacity,
  }) {
    final base = _defaultWritableTag();
    return NFCTag(
      base.type,
      base.id,
      base.standard,
      base.atqa,
      base.sak,
      base.historicalBytes,
      base.protocolInfo,
      base.applicationData,
      base.hiLayerResponse,
      base.manufacturer,
      base.systemCode,
      base.dsfId,
      ndefAvailable ?? base.ndefAvailable,
      base.ndefType,
      ndefCapacity ?? base.ndefCapacity,
      ndefWritable ?? base.ndefWritable,
      base.ndefCanMakeReadOnly,
      base.webUSBCustomProbeData,
      base.mifareInfo,
    );
  }

  ndef.NDEFRecord? decodeLastWrittenUriRecord() {
    final raw = lastWrittenNdefJson;
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    if (list.isEmpty) return null;
    final first = NDEFRawRecord.fromJson(
      Map<String, dynamic>.from(list.first as Map),
    );
    return NDEFRecordConvert.fromRaw(first);
  }
}
