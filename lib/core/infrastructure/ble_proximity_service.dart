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

  /// Starts scanning for devices advertising the Yuztoo service UUID.
  /// Each emission is the deduplicated list of discovered [BluetoothDevice]s.
  /// Returns an empty stream immediately if BLUETOOTH_SCAN is not granted.
  static Stream<List<BluetoothDevice>> startMerchantScan() async* {
    // Android 12+ requires BLUETOOTH_SCAN at runtime before startScan.
    final scan = await Permission.bluetoothScan.request();
    if (!scan.isGranted) return;
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
