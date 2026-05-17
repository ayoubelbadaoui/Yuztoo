import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_proximity_service.dart';

/// RSSI threshold for "tap" proximity (~3–5 cm).
/// BLE at ≤5 cm typically reads between -20 and -45 dBm depending on hardware.
const int kBleRssiThreshold = -45;

/// Consecutive scan emissions that must exceed [kBleRssiThreshold] before
/// detection fires — prevents a single noisy spike from triggering.
const int kBleRequiredHits = 2;

/// Resolved information about a nearby client, ready for the confirmation UI.
class BleClientDetection {
  const BleClientDetection({required this.clientId, this.displayName});

  final String clientId;
  final String? displayName;
}

enum BleProximityMode { idle, client, merchant }

class BleProximityState {
  const BleProximityState({
    this.mode = BleProximityMode.idle,
    this.isRunning = false,
  });

  final BleProximityMode mode;
  final bool isRunning;

  @override
  bool operator ==(Object other) =>
      other is BleProximityState &&
      other.mode == mode &&
      other.isRunning == isRunning;

  @override
  int get hashCode => Object.hash(mode, isRunning);
}

// Dependency typedefs — injected so unit tests can mock BLE hardware.
typedef BleStartBroadcastFn = Future<bool> Function(String uid);
typedef BleIsAvailableFn = Future<bool> Function();
typedef BleReadClientIdFn = Future<String?> Function(BluetoothDevice device);
typedef BleStartScanFn = void Function();
typedef BleScanResultsStreamFn = Stream<List<ScanResult>> Function();
typedef BleStopScanFn = Future<void> Function();

/// Manages BLE advertising (client role) and scanning (merchant role) for the
/// entire app session.  Start via [startAsClient] or [startAsMerchant] when
/// the app enters the foreground; call [stop] when it goes to background or
/// the user signs out.
///
/// On the merchant side, subscribe to [detections] — a [BleClientDetection]
/// is emitted each time a client is resolved (GATT read + Firestore lookup).
/// Call [resetAfterDetection] after the merchant dismisses the confirmation
/// sheet so the next client can be detected.
class BleProximityNotifier extends StateNotifier<BleProximityState> {
  BleProximityNotifier({
    BleStartBroadcastFn? startBroadcast,
    BleIsAvailableFn? isAvailable,
    BleReadClientIdFn? readClientId,
    BleStartScanFn? startScan,
    BleScanResultsStreamFn? scanResultsStream,
    BleStopScanFn? stopScan,
    FirebaseFirestore? firestore,
  })  : _startBroadcast =
            startBroadcast ?? BleProximityService.startClientBroadcast,
        _isAvailable = isAvailable ?? (() => BleProximityService.isAvailable),
        _readClientId = readClientId ?? BleProximityService.readClientId,
        _startScan = startScan ??
            (() => FlutterBluePlus.startScan(
                withServices: [Guid(BleProximityService.serviceUuid)])),
        _scanResultsStream =
            scanResultsStream ?? (() => FlutterBluePlus.scanResults),
        _stopScan = stopScan ?? BleProximityService.stopMerchantScan,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const BleProximityState());

  final BleStartBroadcastFn _startBroadcast;
  final BleIsAvailableFn _isAvailable;
  final BleReadClientIdFn _readClientId;
  final BleStartScanFn _startScan;
  final BleScanResultsStreamFn _scanResultsStream;
  final BleStopScanFn _stopScan;
  final FirebaseFirestore _firestore;

  final _detectedController =
      StreamController<BleClientDetection>.broadcast();

  /// Emits one [BleClientDetection] per detected client (merchant mode only).
  /// After handling the event, call [resetAfterDetection] to arm the next one.
  Stream<BleClientDetection> get detections => _detectedController.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<DeviceIdentifier, int> _hitCount = {};
  bool _triggered = false;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Starts BLE advertising so nearby merchant apps can detect this client.
  /// Safe to call repeatedly — stops any existing mode first.
  Future<void> startAsClient(String uid) async {
    if (uid.isEmpty) return;
    await _stopInternal();
    final ok = await _startBroadcast(uid);
    if (!mounted) return;
    if (ok) {
      state = const BleProximityState(
          mode: BleProximityMode.client, isRunning: true);
    }
  }

  /// Starts scanning for nearby Yuztoo clients.
  /// Emits on [detections] when a client passes the RSSI threshold.
  Future<void> startAsMerchant() async {
    await _stopInternal();
    final available = await _isAvailable();
    if (!mounted || !available) return;
    _startScan();
    _scanSub = _scanResultsStream().listen(_onScanResult);
    state = const BleProximityState(
        mode: BleProximityMode.merchant, isRunning: true);
  }

  /// Stops all BLE activity and resets to idle.
  Future<void> stop() => _stopInternal();

  /// Re-arms detection after the merchant's confirmation sheet is dismissed.
  /// Restarts the scan so the next client can trigger a new detection event.
  void resetAfterDetection() {
    if (!mounted) return;
    _triggered = false;
    _hitCount.clear();
    if (state.mode == BleProximityMode.merchant) {
      _startScan();
      _scanSub?.cancel();
      _scanSub = _scanResultsStream().listen(_onScanResult);
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  void _onScanResult(List<ScanResult> results) {
    if (_triggered) return;
    for (final r in results) {
      if (shouldTrigger(_hitCount, r.device.remoteId, r.rssi)) {
        _triggered = true;
        unawaited(_resolveAndEmit(r.device));
        return;
      }
    }
  }

  Future<void> _resolveAndEmit(BluetoothDevice device) async {
    // Stop scan while connecting so RSSI spikes don't re-trigger.
    await _stopScan();
    await _scanSub?.cancel();
    _scanSub = null;

    final clientId = await _readClientId(device);
    if (clientId == null || clientId.isEmpty) {
      resetAfterDetection();
      return;
    }

    String? displayName;
    try {
      final doc =
          await _firestore.collection('users').doc(clientId).get();
      final data = doc.data();
      final raw = (data?['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data!['displayName'] as String).trim()
          : (data?['display_name'] as String?)?.trim();
      if (raw?.isNotEmpty == true) displayName = raw;
    } catch (_) {}

    if (!_detectedController.isClosed) {
      _detectedController
          .add(BleClientDetection(clientId: clientId, displayName: displayName));
    }
  }

  Future<void> _stopInternal() async {
    await BleProximityService.stopClientBroadcast();
    await _stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _hitCount.clear();
    _triggered = false;
    if (mounted) state = const BleProximityState();
  }

  @override
  void dispose() {
    unawaited(_stopInternal());
    _detectedController.close();
    super.dispose();
  }

  // ─── Pure helper — extracted for unit testing ──────────────────────────────

  /// Returns `true` when [deviceId] has exceeded [kBleRssiThreshold] for
  /// [kBleRequiredHits] consecutive readings, incrementing [hitCount] in place.
  /// Returns `false` and removes [deviceId] from [hitCount] when below threshold.
  static bool shouldTrigger(
    Map<DeviceIdentifier, int> hitCount,
    DeviceIdentifier deviceId,
    int rssi,
  ) {
    if (rssi >= kBleRssiThreshold) {
      final count = (hitCount[deviceId] ?? 0) + 1;
      hitCount[deviceId] = count;
      return count >= kBleRequiredHits;
    } else {
      hitCount.remove(deviceId);
      return false;
    }
  }
}

/// App-wide singleton — one instance manages BLE for the entire session.
final bleProximityProvider =
    StateNotifierProvider<BleProximityNotifier, BleProximityState>(
  (ref) => BleProximityNotifier(),
);
