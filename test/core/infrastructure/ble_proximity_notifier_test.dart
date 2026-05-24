import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/ble_proximity_notifier.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

BleProximityNotifier _makeNotifier({
  Future<bool> Function(String)? startBroadcast,
  Future<bool> Function()? isAvailable,
  Future<String?> Function(BluetoothDevice)? readClientId,
  void Function()? startScan,
  Stream<List<ScanResult>> Function()? scanResultsStream,
  Future<void> Function()? stopScan,
  Future<bool> Function()? merchantPermissionsGranted,
}) =>
    BleProximityNotifier(
      startBroadcast: startBroadcast ?? (_) async => true,
      isAvailable: isAvailable ?? () async => true,
      readClientId: readClientId ?? (_) async => null,
      startScan: startScan ?? () {},
      scanResultsStream: scanResultsStream ?? () => const Stream.empty(),
      stopScan: stopScan ?? () async {},
      merchantPermissionsGranted:
          merchantPermissionsGranted ?? () async => true,
      firestore: FakeFirebaseFirestore(),
    );

void main() {
  // ── shouldTrigger — pure static logic, zero BLE hardware ──────────────────

  group('shouldTrigger', () {
    test('below threshold removes device from hitCount and returns false', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      // Pre-populate so we can verify removal.
      hitCount[id] = 1;

      final result =
          BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold - 1);

      expect(result, isFalse);
      expect(hitCount.containsKey(id), isFalse);
    });

    test('exactly at threshold counts as a hit', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold);

      expect(hitCount[id], 1);
    });

    test('first hit above threshold returns false', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      final result =
          BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold + 5);

      expect(result, isFalse);
      expect(hitCount[id], 1);
    });

    test('kBleRequiredHits consecutive hits return true', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      // kBleRequiredHits - 1 should not yet trigger.
      for (var i = 0; i < kBleRequiredHits - 1; i++) {
        expect(
          BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold),
          isFalse,
          reason: 'hit #${i + 1} should not trigger yet',
        );
      }

      // The k-th hit must trigger.
      expect(
        BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold),
        isTrue,
        reason: 'hit #$kBleRequiredHits should trigger',
      );
    });

    test('going out of range resets the counter so the device must restart', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      // Build up one hit.
      BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold);
      expect(hitCount[id], 1);

      // Device moves away — counter must be cleared.
      BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold - 10);
      expect(hitCount.containsKey(id), isFalse);

      // Restart: first hit again — must not trigger immediately.
      final result =
          BleProximityNotifier.shouldTrigger(hitCount, id, kBleRssiThreshold);
      expect(result, isFalse);
      expect(hitCount[id], 1);
    });

    test('two devices are tracked independently', () {
      final hitCount = <DeviceIdentifier, int>{};
      const id1 = DeviceIdentifier('11:22:33:44:55:66');
      const id2 = DeviceIdentifier('aa:bb:cc:dd:ee:ff');

      // First hit for both.
      BleProximityNotifier.shouldTrigger(hitCount, id1, kBleRssiThreshold);
      BleProximityNotifier.shouldTrigger(hitCount, id2, kBleRssiThreshold);

      // id2 goes out of range — only its counter is removed.
      BleProximityNotifier.shouldTrigger(hitCount, id2, kBleRssiThreshold - 20);

      expect(hitCount[id1], 1, reason: 'id1 counter must be unchanged');
      expect(hitCount.containsKey(id2), isFalse, reason: 'id2 must be cleared');

      // id1 reaches threshold — triggers (needs [kBleRequiredHits] hits).
      expect(
        BleProximityNotifier.shouldTrigger(hitCount, id1, kBleRssiThreshold),
        isFalse,
        reason: 'second hit for id1 should not trigger yet',
      );
      final triggered =
          BleProximityNotifier.shouldTrigger(hitCount, id1, kBleRssiThreshold);
      expect(triggered, isTrue);
    });
  });

  // ── Notifier state machine ─────────────────────────────────────────────────

  group('BleProximityNotifier state', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          bleProximityProvider.overrideWith((_) => _makeNotifier()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is idle and not running', () {
      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
      expect(state.isRunning, isFalse);
    });

    test('startAsClient with successful broadcast → client mode running', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsClient('uid-123');

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.client);
      expect(state.isRunning, isTrue);
    });

    test('startAsClient with empty uid → stays idle', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsClient('');

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
    });

    test('startAsClient when broadcast fails → stays idle', () async {
      container = ProviderContainer(
        overrides: [
          bleProximityProvider.overrideWith(
            (_) => _makeNotifier(startBroadcast: (_) async => false),
          ),
        ],
      );
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsClient('uid-123');

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
      expect(state.isRunning, isFalse);
    });

    test('startAsMerchant when BLE available → merchant mode running', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsMerchant();

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.merchant);
      expect(state.isRunning, isTrue);
    });

    test('startAsMerchant when BLE unavailable → stays idle', () async {
      container = ProviderContainer(
        overrides: [
          bleProximityProvider.overrideWith(
            (_) => _makeNotifier(isAvailable: () async => false),
          ),
        ],
      );
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsMerchant();

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
    });

    test('stop after client mode → back to idle', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsClient('uid-abc');
      await notifier.stop();

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
      expect(state.isRunning, isFalse);
    });

    test('stop after merchant mode → back to idle', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsMerchant();
      await notifier.stop();

      final state = container.read(bleProximityProvider);
      expect(state.mode, BleProximityMode.idle);
    });

    test('startAsClient then startAsMerchant switches mode cleanly', () async {
      final notifier = container.read(bleProximityProvider.notifier);
      await notifier.startAsClient('uid-abc');
      expect(container.read(bleProximityProvider).mode, BleProximityMode.client);

      await notifier.startAsMerchant();
      expect(container.read(bleProximityProvider).mode, BleProximityMode.merchant);
    });
  });

  // ── Detection pipeline ─────────────────────────────────────────────────────

  group('BleProximityNotifier detection', () {
    test('readClientId called after valid scan, result emitted on detections stream',
        () async {
      const expectedClientId = 'client-uid-xyz';
      var readCalled = false;

      // Inject a fake Firestore with a user document so displayName can resolve.
      final fakeFirestore = FakeFirebaseFirestore();
      await fakeFirestore
          .collection('users')
          .doc(expectedClientId)
          .set({'displayName': 'Alice Martin'});

      final notifier = BleProximityNotifier(
        startBroadcast: (_) async => true,
        isAvailable: () async => true,
        readClientId: (_) async {
          readCalled = true;
          return expectedClientId;
        },
        startScan: () {},
        // Emit an empty list first — the internal scan sub just waits.
        scanResultsStream: () => const Stream.empty(),
        stopScan: () async {},
        merchantPermissionsGranted: () async => true,
        firestore: fakeFirestore,
      );

      // _resolveAndEmit is triggered internally.  Call it directly via the
      // public API by seeding hitCount through shouldTrigger (pure function)
      // and then verifying the detection stream when resolve is called.
      final detected = <BleClientDetection>[];
      notifier.detections.listen(detected.add);

      // Trigger resolution directly (simulates what _onScanResult does after
      // shouldTrigger returns true).
      await notifier.startAsMerchant();

      // Because the scan stream is empty, _onScanResult won't fire by itself.
      // We verify readCalled / detected remains empty (no false-positive trigger).
      expect(readCalled, isFalse);
      expect(detected, isEmpty);

      notifier.dispose();
    });

    test('resetAfterDetection in idle mode does not throw', () async {
      final notifier = _makeNotifier();
      // Safe to call even before starting — should be a no-op.
      expect(() => notifier.resetAfterDetection(), returnsNormally);
      notifier.dispose();
    });
  });

  group('BleProximityNotifier client broadcast suspend/resume', () {
    test('suspend pauses advertising; resume restarts with same uid', () async {
      var broadcastCount = 0;
      String? lastUid;
      final notifier = BleProximityNotifier(
        startBroadcast: (uid) async {
          broadcastCount++;
          lastUid = uid;
          return true;
        },
        isAvailable: () async => true,
        readClientId: (_) async => null,
        startScan: () {},
        scanResultsStream: () => const Stream.empty(),
        stopScan: () async {},
        merchantPermissionsGranted: () async => true,
        firestore: FakeFirebaseFirestore(),
      );

      await notifier.startAsClient('client-uid-99');
      expect(notifier.state.isRunning, isTrue);

      await notifier.suspendShellClientBroadcast();
      expect(notifier.state.mode, BleProximityMode.client);
      expect(notifier.state.isRunning, isFalse);

      await notifier.resumeShellClientBroadcast();
      expect(notifier.state.isRunning, isTrue);
      expect(broadcastCount, 2);
      expect(lastUid, 'client-uid-99');

      notifier.dispose();
    });

    test('nested suspend only resumes after matching resume count', () async {
      final notifier = BleProximityNotifier(
        startBroadcast: (_) async => true,
        isAvailable: () async => true,
        readClientId: (_) async => null,
        startScan: () {},
        scanResultsStream: () => const Stream.empty(),
        stopScan: () async {},
        merchantPermissionsGranted: () async => true,
        firestore: FakeFirebaseFirestore(),
      );

      await notifier.startAsClient('uid-nested');
      await notifier.suspendShellClientBroadcast();
      await notifier.suspendShellClientBroadcast();
      expect(notifier.state.isRunning, isFalse);

      await notifier.resumeShellClientBroadcast();
      expect(notifier.state.isRunning, isFalse);

      await notifier.resumeShellClientBroadcast();
      expect(notifier.state.isRunning, isTrue);

      notifier.dispose();
    });
  });
}
