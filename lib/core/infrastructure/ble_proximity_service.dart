import 'dart:async';
import 'dart:typed_data';

import 'package:ble_peripheral/ble_peripheral.dart' as peripheral;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // ─── Client (Peripheral) ───────────────────────────────────────────────────

  /// Starts advertising the Yuztoo service and exposes [clientId] via a
  /// readable GATT characteristic. Returns true if advertising started OK.
  static Future<bool> startClientBroadcast(String clientId) async {
    try {
      // On Android 12+ BLUETOOTH_ADVERTISE is a dangerous permission that must
      // be granted at runtime before startAdvertising can be called. Calling
      // startAdvertising without it throws a SecurityException that kills the
      // process before Dart's try/catch can handle it.
      final advertise = await Permission.bluetoothAdvertise.request();
      if (!advertise.isGranted) return false;
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
      return true;
    } catch (_) {
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

  // ─── Merchant (Central) ────────────────────────────────────────────────────

  /// Reads the **current** runtime-permission status without prompting the
  /// user. Use this before showing your own in-app activation dialog — that
  /// way the OS permission popup doesn't appear unsolicited when the user
  /// taps "Valider un passage".
  static Future<MerchantPermissionStatus> merchantPermissionStatus() async {
    final scan = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    if (scan.isGranted && connect.isGranted) {
      return MerchantPermissionStatus.granted;
    }
    if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
      return MerchantPermissionStatus.permanentlyDenied;
    }
    if (scan.isRestricted || connect.isRestricted) {
      return MerchantPermissionStatus.restricted;
    }
    return MerchantPermissionStatus.denied;
  }

  /// Requests the Android 12+ runtime permissions needed for the merchant
  /// scan flow:
  ///   - BLUETOOTH_SCAN  — needed before `FlutterBluePlus.startScan`
  ///   - BLUETOOTH_CONNECT — needed before `device.connect()` (GATT read)
  ///
  /// This **does** pop the OS permission prompt. Only call it after the user
  /// has explicitly agreed to activate Bluetooth in your in-app dialog —
  /// otherwise the OS popup appears out of nowhere when they tap the
  /// "Valider un passage" button.
  ///
  /// Returns true when both are granted. On iOS both calls resolve to
  /// granted because there's no equivalent runtime gate — the global
  /// `NSBluetoothAlwaysUsageDescription` prompt is handled when the BLE
  /// stack is first touched.
  static Future<bool> requestMerchantPermissions() async {
    final scan = await Permission.bluetoothScan.request();
    if (!scan.isGranted) return false;
    final connect = await Permission.bluetoothConnect.request();
    if (!connect.isGranted) return false;
    return true;
  }

  /// Opens the system Settings page for the app so the user can flip the
  /// Bluetooth permission switch manually. Use this when
  /// [merchantPermissionStatus] returns `permanentlyDenied` — `.request()`
  /// won't help there.
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
    try {
      await device.connect(timeout: const Duration(seconds: 6));
      final services = await device.discoverServices();
      final service = services.cast<BluetoothService?>().firstWhere(
            (s) => s!.serviceUuid == Guid(serviceUuid),
            orElse: () => null,
          );
      if (service == null) {
        await device.disconnect();
        return null;
      }
      final char = service.characteristics.cast<BluetoothCharacteristic?>().firstWhere(
            (c) => c!.characteristicUuid == Guid(clientIdCharUuid),
            orElse: () => null,
          );
      if (char == null) {
        await device.disconnect();
        return null;
      }
      final bytes = await char.read();
      await device.disconnect();
      return String.fromCharCodes(bytes);
    } catch (_) {
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
      return state == BluetoothAdapterState.on;
    } catch (_) {
      return false;
    }
  }
}
