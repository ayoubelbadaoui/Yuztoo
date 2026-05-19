import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_proximity_service.dart';
import 'logger_service.dart';

/// RSSI threshold for background "nearby client" detection (~30–80 cm on
/// many phones). Tighter than a manual list tap but looser than the old
/// -45 dBm "phones touching" bar so real-world passes still work.
const int kBleRssiThreshold = -58;

/// Consecutive scan emissions that must exceed [kBleRssiThreshold] before
/// detection fires — prevents a single noisy spike from triggering.
const int kBleRequiredHits = 3;

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
typedef BleMerchantPermissionsGrantedFn = Future<bool> Function();

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
    BleMerchantPermissionsGrantedFn? merchantPermissionsGranted,
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
        _merchantPermissionsGranted = merchantPermissionsGranted ??
            (() async {
              final s = await BleProximityService.merchantPermissionStatus();
              return s == MerchantPermissionStatus.granted;
            }),
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const BleProximityState());

  final BleStartBroadcastFn _startBroadcast;
  final BleIsAvailableFn _isAvailable;
  final BleReadClientIdFn _readClientId;
  final BleStartScanFn _startScan;
  final BleScanResultsStreamFn _scanResultsStream;
  final BleStopScanFn _stopScan;
  final BleMerchantPermissionsGrantedFn _merchantPermissionsGranted;
  final FirebaseFirestore _firestore;

  final _detectedController =
      StreamController<BleClientDetection>.broadcast();

  /// Emits one [BleClientDetection] per detected client (merchant mode only).
  /// After handling the event, call [resetAfterDetection] to arm the next one.
  Stream<BleClientDetection> get detections => _detectedController.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<DeviceIdentifier, int> _hitCount = {};
  bool _triggered = false;

  /// When positive, the shell merchant scan is paused (e.g. [MerchantBleScanScreen]
  /// owns the radio exclusively) — [resetAfterDetection] will not restart scan.
  int _shellScanSuspendCount = 0;

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
  ///
  /// **Permissions**: this method *checks* the Android 12+ runtime
  /// permissions but does **not** prompt the user. If the permissions are
  /// missing, the scan stays idle and the caller is responsible for asking
  /// the user to activate them via the in-app dialog (see
  /// [BleProximityService.merchantPermissionStatus] +
  /// [BleProximityService.requestMerchantPermissions]). This avoids the OS
  /// permission popup appearing unsolicited when the merchant just logs in.
  Future<void> startAsMerchant() async {
    LoggerService.logInfo('BLE notifier.startAsMerchant — begin');
    await _stopInternal();
    final available = await _isAvailable();
    if (!mounted || !available) {
      LoggerService.logInfo(
        'BLE notifier.startAsMerchant — abort: adapter unavailable',
        context: <String, Object?>{'available': available, 'mounted': mounted},
      );
      return;
    }
    final permitted = await _merchantPermissionsGranted();
    if (!mounted || !permitted) {
      LoggerService.logInfo(
        'BLE notifier.startAsMerchant — abort: permissions not granted (silent)',
        context: <String, Object?>{
          'permitted': permitted,
          'mounted': mounted,
        },
      );
      return;
    }
    try {
      _startScan();
    } catch (e, st) {
      LoggerService.logError(
        'BLE notifier.startAsMerchant — FlutterBluePlus.startScan threw',
        error: e,
        stackTrace: st,
      );
      return;
    }
    _scanSub = _scanResultsStream().listen(
      _onScanResult,
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'BLE notifier.startAsMerchant — scanResults stream error',
          error: e,
          stackTrace: st,
        );
      },
    );
    state = const BleProximityState(
        mode: BleProximityMode.merchant, isRunning: true);
    LoggerService.logInfo('BLE notifier.startAsMerchant — scan running');
  }

  /// Pauses the global merchant scan while a dedicated screen (e.g.
  /// [MerchantBleScanScreen]) runs its own [FlutterBluePlus.startScan].
  /// Pair with [resumeShellMerchantScan] in [dispose].
  Future<void> suspendShellMerchantScan() async {
    _shellScanSuspendCount++;
    if (_shellScanSuspendCount == 1) {
      await _stopScan();
      await _scanSub?.cancel();
      _scanSub = null;
      _hitCount.clear();
      _triggered = false;
    }
  }

  /// Resumes the shell scan after [suspendShellMerchantScan].
  Future<void> resumeShellMerchantScan() async {
    if (_shellScanSuspendCount > 0) {
      _shellScanSuspendCount--;
    }
    if (_shellScanSuspendCount < 0) {
      _shellScanSuspendCount = 0;
    }
    if (!mounted) return;
    if (_shellScanSuspendCount != 0) return;
    if (state.mode != BleProximityMode.merchant || !state.isRunning) return;
    try {
      _startScan();
    } catch (e, st) {
      LoggerService.logError(
        'BLE notifier.resumeShellMerchantScan — startScan threw',
        error: e,
        stackTrace: st,
      );
      return;
    }
    _scanSub?.cancel();
    _scanSub = _scanResultsStream().listen(
      _onScanResult,
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'BLE notifier.resumeShellMerchantScan — scanResults stream error',
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  /// Stops all BLE activity and resets to idle.
  Future<void> stop() => _stopInternal();

  /// Re-arms detection after the merchant's confirmation sheet is dismissed.
  /// Restarts the scan so the next client can trigger a new detection event.
  void resetAfterDetection() {
    if (!mounted) return;
    _triggered = false;
    _hitCount.clear();
    if (state.mode == BleProximityMode.merchant && _shellScanSuspendCount == 0) {
      _startScan();
      _scanSub?.cancel();
      // Always pass `onError:` — an unhandled stream error here would
      // bubble out to the Zone error handler and surface as Flutter's red
      // error screen. Logging is enough; the next scan tick will try again.
      _scanSub = _scanResultsStream().listen(
        _onScanResult,
        onError: (Object e, StackTrace st) {
          LoggerService.logError(
            'BLE notifier.resetAfterDetection — scanResults stream error',
            error: e,
            stackTrace: st,
          );
        },
      );
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  void _onScanResult(List<ScanResult> results) {
    if (_triggered) return;
    // Log a compact snapshot of the strongest device per emission so the
    // user can see WHY no detection is happening: phones too far (RSSI
    // below the -45 dBm threshold) vs. no Yuztoo devices visible at all.
    if (results.isNotEmpty) {
      final strongest = results
          .reduce((a, b) => a.rssi >= b.rssi ? a : b);
      LoggerService.logDebug(
        'BLE scan result tick',
        context: <String, Object?>{
          'count': results.length,
          'strongestRssi': strongest.rssi,
          'strongestId': strongest.device.remoteId.str,
          'threshold': kBleRssiThreshold,
          'aboveThreshold': strongest.rssi >= kBleRssiThreshold,
        },
      );
    }
    for (final r in results) {
      if (shouldTrigger(_hitCount, r.device.remoteId, r.rssi)) {
        _triggered = true;
        LoggerService.logInfo(
          'BLE notifier — proximity threshold reached, resolving device',
          context: <String, Object?>{
            'deviceId': r.device.remoteId.str,
            'rssi': r.rssi,
            'hits': _hitCount[r.device.remoteId],
          },
        );
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
    _shellScanSuspendCount = 0;
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
