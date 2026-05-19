import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as peripheral;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger_service.dart';

/// Carries information about a client device discovered via BLE scan.
/// The [clientId] is read from the GATT characteristic after connecting;
/// it starts as null until the connection resolves.
class BleDiscoveredDevice {
  BleDiscoveredDevice({required this.device});

  final BluetoothDevice device;

  /// Firebase UID of the broadcasting client. Null while the connection
  /// to read the GATT characteristic is in progress.
  String? clientId;
  bool isConnecting = false;
  bool hasError = false;
}

/// Proximity-based BLE service for passage validation.
///
/// **Architecture**
/// - Client (peripheral): uses `ble_peripheral` to expose a GATT service
///   and advertise the Yuztoo service UUID. The client's Firebase UID is
///   stored in a readable GATT characteristic.
/// - Merchant (central): uses `flutter_blue_plus` to scan for the Yuztoo
///   service UUID, then connects to read the GATT characteristic.
///
/// The merchant never needs the client's UID before tapping a card — the
/// connection happens on demand (tap → connect → read → validate).

/// Status of the Android 12+ runtime permissions the merchant scan needs.
/// Top-level so it can be referenced as `MerchantPermissionStatus.granted`
/// without the `BleProximityService.` prefix from call sites.
enum MerchantPermissionStatus {
  /// Both BLUETOOTH_SCAN and BLUETOOTH_CONNECT are granted — safe to scan.
  granted,

  /// Permission was denied once. The next `.request()` call will pop the
  /// OS prompt (Android — iOS shows the prompt the first time too).
  denied,

  /// Permission was denied twice (or "Don't ask again" was selected).
  /// `.request()` will silently return denied — the only way to enable
  /// it is to send the user to system Settings via `openAppSettings()`.
  permanentlyDenied,

  /// iOS-only: restricted by device policy (parental controls, MDM).
  /// Treated the same as permanentlyDenied for UX purposes.
  restricted,
}

class BleProximityService {
  /// 128-bit service UUID reserved for Yuztoo BLE proximity sessions.
  static const String serviceUuid = '12340000-1234-1000-8000-00805f9b34fb';

  /// Characteristic that holds the client's Firebase UID (UTF-8 encoded).
  static const String clientIdCharUuid =
      '12340001-1234-1000-8000-00805f9b34fb';

  /// Merchant "session" peripheral — advertised while the merchant has the
  /// passage-validation screen open so the **client** can scan, pick this
  /// commerce from a list, and write their UID (merchant continues the flow).
  static const String merchantBeaconServiceUuid =
      '12340010-1234-1000-8000-00805f9b34fb';

  /// Readable: Firestore merchant document id (UTF-8).
  static const String merchantBeaconMerchantIdCharUuid =
      '12340011-1234-1000-8000-00805f9b34fb';

  /// Writable: client's Firebase UID (UTF-8) — merchant app receives a write.
  static const String merchantBeaconClientPickCharUuid =
      '12340012-1234-1000-8000-00805f9b34fb';

  static void Function(String clientUid)? _merchantBeaconWriteHandler;

  // ─── Client (Peripheral) ───────────────────────────────────────────────────

  /// Starts advertising the Yuztoo service and exposes [clientId] via a
  /// readable GATT characteristic. Returns true if advertising started OK.
  static Future<bool> startClientBroadcast(String clientId) async {
    LoggerService.logInfo(
      'BLE startClientBroadcast — start',
      context: <String, Object?>{
        'clientId': clientId,
        'platform': Platform.operatingSystem,
      },
    );
    try {
      // Android 12+: `BLUETOOTH_ADVERTISE` is a dangerous runtime
      // permission that must be granted before `startAdvertising` —
      // otherwise it throws a SecurityException at the native layer that
      // kills the isolate before Dart can catch it. iOS: skip — the
      // `ble_peripheral` plugin instantiates `CBPeripheralManager` which
      // triggers the system Bluetooth prompt automatically using
      // `NSBluetoothPeripheralUsageDescription` from Info.plist. No
      // permission_handler needed (and using it on iOS silently denies
      // unless we ship a Podfile macro — we don't).
      if (Platform.isAndroid) {
        final advertise = await Permission.bluetoothAdvertise.request();
        LoggerService.logInfo(
          'BLE startClientBroadcast — bluetoothAdvertise result',
          context: <String, Object?>{'status': advertise.toString()},
        );
        if (!advertise.isGranted) return false;
      }
      await peripheral.BlePeripheral.initialize();
      await peripheral.BlePeripheral.clearServices();

      // Wait for the service to be registered before advertising.
      final serviceReady = Completer<void>();
      peripheral.BlePeripheral.setServiceAddedCallback(
        (serviceId, error) {
          if (!serviceReady.isCompleted) {
            if (error == null) {
              serviceReady.complete();
            } else {
              serviceReady.completeError(error.toString());
            }
          }
        },
      );

      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: serviceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: clientIdCharUuid,
              properties: [
                peripheral.CharacteristicProperties.read.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
              ],
              value: Uint8List.fromList(clientId.codeUnits),
            ),
          ],
        ),
      );

      await serviceReady.future.timeout(const Duration(seconds: 5));

      await peripheral.BlePeripheral.startAdvertising(
        services: [serviceUuid],
        localName: 'Yuztoo',
      );
      LoggerService.logInfo(
        'BLE startClientBroadcast — advertising started',
        context: <String, Object?>{'clientId': clientId},
      );
      return true;
    } catch (e, st) {
      LoggerService.logError(
        'BLE startClientBroadcast — failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Stops BLE advertising and clears the registered GATT service.
  static Future<void> stopClientBroadcast() async {
    try {
      await peripheral.BlePeripheral.stopAdvertising();
      await peripheral.BlePeripheral.clearServices();
    } catch (_) {}
  }

  // ─── Merchant beacon (peripheral) — client can scan & pick this commerce ───

  /// Advertises [merchantBeaconServiceUuid] while the merchant validates a
  /// passage. The client app scans for this UUID, then connects and writes
  /// their Firebase UID to [merchantBeaconClientPickCharUuid]; we surface
  /// that via [onClientUidWritten].
  ///
  /// **Do not** call while [startClientBroadcast] is active on the same
  /// device (both use `ble_peripheral`).
  static Future<bool> startMerchantBeacon(
    String merchantDocId, {
    required void Function(String clientUid) onClientUidWritten,
  }) async {
    if (merchantDocId.isEmpty) return false;
    LoggerService.logInfo(
      'BLE startMerchantBeacon — start',
      context: <String, Object?>{
        'merchantDocIdLen': merchantDocId.length,
        'platform': Platform.operatingSystem,
      },
    );
    try {
      if (Platform.isAndroid) {
        final advertise = await Permission.bluetoothAdvertise.request();
        if (!advertise.isGranted) return false;
      }
      _merchantBeaconWriteHandler = onClientUidWritten;

      await peripheral.BlePeripheral.initialize();
      await peripheral.BlePeripheral.clearServices();

      peripheral.BlePeripheral.setWriteRequestCallback(
        (deviceId, characteristicId, offset, value) {
          try {
            if (Guid(characteristicId) !=
                Guid(merchantBeaconClientPickCharUuid)) {
              return null;
            }
          } catch (_) {
            return null;
          }
          if (value == null || value.isEmpty) {
            return peripheral.WriteRequestResult();
          }
          final uid = String.fromCharCodes(value);
          if (uid.isNotEmpty) {
            // Native GATT write callbacks can arrive on a path that must not
            // touch Flutter widgets synchronously (iOS hard-crash risk).
            final trimmed = uid.trim();
            final handler = _merchantBeaconWriteHandler;
            if (handler != null) {
              Future<void>.microtask(() {
                try {
                  handler(trimmed);
                } catch (e, st) {
                  LoggerService.logError(
                    'BLE startMerchantBeacon — onClientUidWritten threw',
                    error: e,
                    stackTrace: st,
                  );
                }
              });
            }
          }
          return peripheral.WriteRequestResult();
        },
      );

      final merchantBytes = Uint8List.fromList(merchantDocId.codeUnits);
      final serviceReady = Completer<void>();
      peripheral.BlePeripheral.setServiceAddedCallback(
        (serviceId, error) {
          if (!serviceReady.isCompleted) {
            if (error == null) {
              serviceReady.complete();
            } else {
              serviceReady.completeError(error.toString());
            }
          }
        },
      );

      await peripheral.BlePeripheral.addService(
        peripheral.BleService(
          uuid: merchantBeaconServiceUuid,
          primary: true,
          characteristics: [
            peripheral.BleCharacteristic(
              uuid: merchantBeaconMerchantIdCharUuid,
              properties: [
                peripheral.CharacteristicProperties.read.index,
              ],
              permissions: [
                peripheral.AttributePermissions.readable.index,
              ],
              value: merchantBytes,
            ),
            peripheral.BleCharacteristic(
              uuid: merchantBeaconClientPickCharUuid,
              properties: [
                peripheral.CharacteristicProperties.write.index,
                peripheral.CharacteristicProperties.writeWithoutResponse.index,
              ],
              permissions: [
                peripheral.AttributePermissions.writeable.index,
              ],
              value: Uint8List(0),
            ),
          ],
        ),
      );

      await serviceReady.future.timeout(const Duration(seconds: 5));

      await peripheral.BlePeripheral.startAdvertising(
        services: [merchantBeaconServiceUuid],
        localName: 'Yuztoo',
      );
      LoggerService.logInfo('BLE startMerchantBeacon — advertising started');
      return true;
    } catch (e, st) {
      LoggerService.logError(
        'BLE startMerchantBeacon — failed',
        error: e,
        stackTrace: st,
      );
      _merchantBeaconWriteHandler = null;
      return false;
    }
  }

  static Future<void> stopMerchantBeacon() async {
    _merchantBeaconWriteHandler = null;
    try {
      peripheral.BlePeripheral.setWriteRequestCallback(
          (deviceId, characteristicId, offset, value) => null);
    } catch (_) {}
    try {
      await peripheral.BlePeripheral.stopAdvertising();
      await peripheral.BlePeripheral.clearServices();
    } catch (_) {}
  }

  /// Client connects to a merchant beacon [device] and writes [clientUid] to
  /// the pick characteristic so the merchant app can continue validation.
  static Future<bool> writeClientUidToMerchantBeacon(
    BluetoothDevice device,
    String clientUid,
  ) async {
    if (clientUid.isEmpty) return false;
    final deviceId = device.remoteId.str;
    LoggerService.logInfo(
      'BLE writeClientUidToMerchantBeacon — connect',
      context: <String, Object?>{'deviceId': deviceId},
    );
    try {
      await device.connect(timeout: const Duration(seconds: 12));
      final services = await device.discoverServices();
      BluetoothService? beacon;
      for (final s in services) {
        if (s.serviceUuid == Guid(merchantBeaconServiceUuid)) {
          beacon = s;
          break;
        }
      }
      if (beacon == null) {
        LoggerService.logError(
          'BLE writeClientUidToMerchantBeacon — beacon service not found',
          error: 'expected_uuid=$merchantBeaconServiceUuid',
        );
        await device.disconnect();
        return false;
      }
      BluetoothCharacteristic? pick;
      for (final c in beacon.characteristics) {
        if (c.characteristicUuid == Guid(merchantBeaconClientPickCharUuid)) {
          pick = c;
          break;
        }
      }
      if (pick == null) {
        LoggerService.logError(
          'BLE writeClientUidToMerchantBeacon — pick characteristic missing',
        );
        await device.disconnect();
        return false;
      }
      final bytes = Uint8List.fromList(clientUid.codeUnits);
      await pick.write(bytes, withoutResponse: false);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await device.disconnect();
      LoggerService.logInfo('BLE writeClientUidToMerchantBeacon — success');
      return true;
    } catch (e, st) {
      LoggerService.logError(
        'BLE writeClientUidToMerchantBeacon — failed',
        error: e,
        stackTrace: st,
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return false;
    }
  }

  // ─── Merchant (Central) ────────────────────────────────────────────────────

  /// Reads the **current** Bluetooth permission status without prompting the
  /// user. Each platform has its own permission system:
  ///
  ///   - **Android 12+** uses `permission_handler` to query the dangerous
  ///     runtime permissions `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`.
  ///
  ///   - **iOS** uses `FlutterBluePlus.adapterState`, which mirrors
  ///     CoreBluetooth's `CBManagerAuthorization` directly. We deliberately
  ///     do NOT call `permission_handler` here — that package requires a
  ///     compile-time macro in the Podfile (`PERMISSION_BLUETOOTH=1`) to
  ///     work on iOS, otherwise it silently returns `denied` for every
  ///     bluetooth permission. Talking to CoreBluetooth directly via
  ///     flutter_blue_plus gives us the real state with no extra setup.
  static Future<MerchantPermissionStatus> merchantPermissionStatus() async {
    if (Platform.isIOS) return _iosBluetoothStatus();
    return _androidBluetoothStatus();
  }

  static Future<MerchantPermissionStatus> _iosBluetoothStatus() async {
    try {
      // `adapterState` reflects CBCentralManager's authorization +
      // power state. On iOS the relevant values are:
      //   - on            → user granted permission + BT is powered on
      //   - unauthorized  → user denied (or restricted by parental controls)
      //   - off           → BT toggled off in Control Center / Settings
      //   - unknown       → CBCentralManager hasn't initialized yet
      final state = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 2));
      final MerchantPermissionStatus mapped;
      switch (state) {
        case BluetoothAdapterState.on:
          mapped = MerchantPermissionStatus.granted;
        case BluetoothAdapterState.unauthorized:
          // iOS doesn't distinguish "denied once" from "permanently denied"
          // — once the user denies, the only way back is via Settings.
          mapped = MerchantPermissionStatus.permanentlyDenied;
        default:
          // off / turningOn / unknown / unavailable — treat as denied so
          // the in-app dialog explains that BT needs to be activated.
          mapped = MerchantPermissionStatus.denied;
      }
      LoggerService.logInfo(
        'BLE merchantPermissionStatus (iOS)',
        context: <String, Object?>{
          'adapterState': state.name,
          'mapped': mapped.name,
        },
      );
      return mapped;
    } catch (e, st) {
      LoggerService.logError(
        'BLE merchantPermissionStatus (iOS) adapter probe failed',
        error: e,
        stackTrace: st,
      );
      return MerchantPermissionStatus.denied;
    }
  }

  static Future<MerchantPermissionStatus> _androidBluetoothStatus() async {
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    final MerchantPermissionStatus mapped;
    if (scan.isGranted && connect.isGranted) {
      mapped = MerchantPermissionStatus.granted;
    } else if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
      mapped = MerchantPermissionStatus.permanentlyDenied;
    } else if (scan.isRestricted || connect.isRestricted) {
      mapped = MerchantPermissionStatus.restricted;
    } else {
      mapped = MerchantPermissionStatus.denied;
    }
    LoggerService.logInfo(
      'BLE merchantPermissionStatus (Android)',
      context: <String, Object?>{
        'scan': scan.toString(),
        'connect': connect.toString(),
        'mapped': mapped.name,
      },
    );
    return mapped;
  }

  /// Triggers the OS Bluetooth permission prompt. Returns true once the
  /// user has actually granted Bluetooth access.
  ///
  ///   - **Android 12+**: requests `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`
  ///     via `permission_handler`, which surfaces the "Devices nearby"
  ///     system dialog.
  ///
  ///   - **iOS**: kicks CoreBluetooth into action with a tiny throwaway
  ///     scan. The instant `CBCentralManager` is touched, iOS surfaces
  ///     its native Bluetooth permission prompt (using the French text
  ///     from `NSBluetoothAlwaysUsageDescription` in Info.plist). We then
  ///     read back the adapter state to see what the user chose. No
  ///     Podfile macros, no `pod install`, no rebuild — works out of the
  ///     box because we're using iOS's first-party permission flow.
  static Future<bool> requestMerchantPermissions() async {
    if (Platform.isIOS) return _iosRequestBluetooth();
    return _androidRequestBluetooth();
  }

  static Future<bool> _iosRequestBluetooth() async {
    LoggerService.logInfo('BLE requestMerchantPermissions (iOS) — start');
    try {
      // 1) Force CBCentralManager to initialize. On iOS this triggers the
      //    system Bluetooth permission prompt the first time, using
      //    `NSBluetoothAlwaysUsageDescription`.
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: const Duration(milliseconds: 250),
      );
      // The startScan above carries its own timeout; calling stopScan
      // ensures we're idle before re-reading the state.
      await FlutterBluePlus.stopScan();
    } catch (e, st) {
      // startScan can throw `BluetoothUnauthorized` when the user has
      // already denied — that's fine, we fall through to the state
      // re-check below and report back accordingly.
      LoggerService.logError(
        'BLE requestMerchantPermissions (iOS) — probe scan threw '
        '(this is normal if previously denied)',
        error: e,
        stackTrace: st,
      );
    }
    // 2) Re-read the adapter state to see what the user just decided.
    //    Allow a longer timeout here because the system prompt UI sits
    //    on top of the scan path until the user taps Allow / Don't allow.
    try {
      final state = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 30));
      final granted = state == BluetoothAdapterState.on;
      LoggerService.logInfo(
        'BLE requestMerchantPermissions (iOS) — done',
        context: <String, Object?>{
          'finalAdapterState': state.name,
          'granted': granted,
        },
      );
      return granted;
    } catch (e, st) {
      LoggerService.logError(
        'BLE requestMerchantPermissions (iOS) — adapter re-read failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  static Future<bool> _androidRequestBluetooth() async {
    LoggerService.logInfo('BLE requestMerchantPermissions (Android) — start');
    final scan = await Permission.bluetoothScan.request();
    LoggerService.logInfo(
      'BLE requestMerchantPermissions (Android) — bluetoothScan result',
      context: <String, Object?>{'status': scan.toString()},
    );
    if (!scan.isGranted) return false;
    final connect = await Permission.bluetoothConnect.request();
    LoggerService.logInfo(
      'BLE requestMerchantPermissions (Android) — bluetoothConnect result',
      context: <String, Object?>{'status': connect.toString()},
    );
    if (!connect.isGranted) return false;
    return true;
  }

  /// Opens the system Settings page for the app so the user can flip the
  /// Bluetooth permission switch manually. Works on both platforms — on
  /// iOS this is the only path back when the user has previously denied,
  /// since iOS won't re-prompt once denied.
  static Future<bool> openSystemBluetoothSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Starts scanning for devices advertising the Yuztoo service UUID.
  /// Each emission is the deduplicated list of discovered [BluetoothDevice]s.
  /// Returns an empty stream immediately if the runtime permissions are not
  /// granted.
  static Stream<List<BluetoothDevice>> startMerchantScan() async* {
    final ok = await requestMerchantPermissions();
    if (!ok) return;
    FlutterBluePlus.startScan(withServices: [Guid(serviceUuid)]);
    final seen = <DeviceIdentifier>{};
    yield* FlutterBluePlus.scanResults.map((results) {
      final out = <BluetoothDevice>[];
      for (final r in results) {
        if (seen.add(r.device.remoteId)) out.add(r.device);
      }
      return out;
    });
  }

  /// Stops the merchant BLE scan.
  static Future<void> stopMerchantScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  /// Connects to [device], reads the clientId GATT characteristic, then
  /// disconnects. Returns null on any error.
  static Future<String?> readClientId(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    LoggerService.logInfo(
      'BLE readClientId — connect',
      context: <String, Object?>{'deviceId': deviceId},
    );
    try {
      await device.connect(timeout: const Duration(seconds: 12));
      final services = await device.discoverServices();
      final service = services.cast<BluetoothService?>().firstWhere(
            (s) => s!.serviceUuid == Guid(serviceUuid),
            orElse: () => null,
          );
      if (service == null) {
        LoggerService.logError(
          'BLE readClientId — Yuztoo service UUID not found on device',
          error: 'expected_uuid=$serviceUuid',
        );
        await device.disconnect();
        return null;
      }
      final char = service.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
            (c) => c!.characteristicUuid == Guid(clientIdCharUuid),
            orElse: () => null,
          );
      if (char == null) {
        LoggerService.logError(
          'BLE readClientId — clientId characteristic not found on device',
          error: 'expected_uuid=$clientIdCharUuid',
        );
        await device.disconnect();
        return null;
      }
      final bytes = await char.read();
      await device.disconnect();
      final result = String.fromCharCodes(bytes);
      LoggerService.logInfo(
        'BLE readClientId — success',
        context: <String, Object?>{
          'deviceId': deviceId,
          'clientUidLength': result.length,
        },
      );
      return result;
    } catch (e, st) {
      LoggerService.logError(
        'BLE readClientId — connect / read failed',
        error: e,
        stackTrace: st,
      );
      try {
        await device.disconnect();
      } catch (_) {}
      return null;
    }
  }

  /// True when the device's Bluetooth adapter is powered on.
  static Future<bool> get isAvailable async {
    try {
      final state = await FlutterBluePlus.adapterState
          .first
          .timeout(const Duration(seconds: 3));
      final available = state == BluetoothAdapterState.on;
      LoggerService.logInfo(
        'BLE isAvailable',
        context: <String, Object?>{
          'adapterState': state.name,
          'available': available,
        },
      );
      return available;
    } catch (e, st) {
      LoggerService.logError(
        'BLE isAvailable — adapter state probe failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
