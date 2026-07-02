import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'
    show
        AndroidScanMode,
        BluetoothDevice,
        DeviceIdentifier,
        FlutterBluePlus,
        Guid,
        ScanResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/infrastructure/ble_proximity_notifier.dart';
import '../../../core/infrastructure/ble_proximity_service.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/proximity_list_avatar.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../loyalty/application/active_validation_providers.dart';
import '../../loyalty/domain/entities/active_validation_request.dart';
import '../../loyalty/domain/loyalty_passage_program_policy.dart';
import '../../loyalty/infrastructure/active_validation_repository_provider.dart';
import '../../loyalty/presentation/merchant_passage_validation_flow.dart';
import '../../loyalty/presentation/widgets/merchant_passage_debug_simulate_sheet.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';
import '../domain/entities/loyalty_program_config.dart';
import '../domain/entities/merchant.dart';

/// Minimum RSSI to show a client in the manual list (several metres on
/// many phones — much more forgiving than the old "phones touching" bar).
const int _kListMinRssi = -92;

class _NearbyYuztooClient {
  _NearbyYuztooClient({
    required this.device,
    required this.rssi,
    this.displayName,
    this.photoUrl,
    this.resolvingName = false,
    this.resolveNameFailed = false,
  });

  final BluetoothDevice device;
  final int rssi;

  /// Loaded from Firestore after a background GATT read of the client UID.
  final String? displayName;
  final String? photoUrl;

  /// True while we are connecting to read the UID / fetch the profile name.
  final bool resolvingName;

  /// True when the background identification attempt failed (BLE read, etc.).
  final bool resolveNameFailed;

  _NearbyYuztooClient withUpdatedRssi(BluetoothDevice newDevice, int newRssi) =>
      _NearbyYuztooClient(
        device: newDevice,
        rssi: newRssi,
        displayName: displayName,
        photoUrl: photoUrl,
        resolvingName: resolvingName,
        resolveNameFailed: resolveNameFailed,
      );

  _NearbyYuztooClient withResolvingStarted() => _NearbyYuztooClient(
        device: device,
        rssi: rssi,
        displayName: displayName,
        photoUrl: photoUrl,
        resolvingName: true,
        resolveNameFailed: resolveNameFailed,
      );

  _NearbyYuztooClient withResolveSucceeded({
    String? name,
    String? photo,
  }) {
    final trimmed = name?.trim();
    final photoTrimmed = photo?.trim();
    return _NearbyYuztooClient(
      device: device,
      rssi: rssi,
      displayName: trimmed != null && trimmed.isNotEmpty ? trimmed : displayName,
      photoUrl: photoTrimmed != null && photoTrimmed.isNotEmpty
          ? photoTrimmed
          : photoUrl,
      resolvingName: false,
      resolveNameFailed: false,
    );
  }

  _NearbyYuztooClient withResolveFailed() => _NearbyYuztooClient(
        device: device,
        rssi: rssi,
        displayName: displayName,
        photoUrl: photoUrl,
        resolvingName: false,
        resolveNameFailed: true,
      );
}

enum _ScanState { waiting, connecting, validating }

/// Merchant-side BLE passage validation.
///
/// While this screen is open, the commerce advertises a **merchant beacon**
/// so the client can pick this shop from their list. The merchant sees a
/// **live list of nearby client phones** (tap a row to validate) plus an
/// optional auto-trigger when phones stay very close (strong RSSI).
class MerchantBleScanScreen extends ConsumerStatefulWidget {
  const MerchantBleScanScreen({super.key, required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<MerchantBleScanScreen> createState() =>
      _MerchantBleScanScreenState();
}

class _MerchantBleScanScreenState extends ConsumerState<MerchantBleScanScreen>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _glowController;

  StreamSubscription<List<ScanResult>>? _scanSub;
  _ScanState _state = _ScanState.waiting;
  bool _bleUnavailable = false;

  /// Specific reason the screen is showing the unavailable state — surfaced
  /// in the UI so the user (and us, when debugging) can tell apart "BT off"
  /// from "permission denied" from "scan threw an exception".
  String? _bleErrorReason;

  /// Yuztoo client peripherals currently in range (manual pick list).
  final Map<DeviceIdentifier, _NearbyYuztooClient> _nearbyClients = {};

  /// Serializes background [BleProximityService.readClientId] work so we do
  /// not run multiple GATT sessions at once (stack stability).
  Future<void>? _resolveDisplayNameTail;

  /// True when this commerce is advertising the merchant beacon (so the
  /// client can select us from their list).
  bool _merchantBeaconActive = false;

  // Prevent re-triggering after a validation attempt.
  bool _triggered = false;

  /// E-Fidélité off — BLE passage validation is not offered.
  bool _loyaltyFideliteDisabled = false;

  bool _blePassageAllowed(Merchant m) => isAutomaticPassageAllowedForMerchant(m);

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loyaltyFideliteDisabled = !_blePassageAllowed(widget.merchant);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(bleProximityProvider.notifier).suspendShellMerchantScan();
      if (!mounted) return;
      if (_loyaltyFideliteDisabled) return;
      _radarController.repeat();
      _glowController.repeat(reverse: true);
      unawaited(_openBleSession());
    });
  }

  @override
  void dispose() {
    // Capture the notifier before super.dispose() — ref.read is unsafe after.
    final bleNotifier = ref.read(bleProximityProvider.notifier);
    _scanSub?.cancel();
    _scanSub = null;
    // Stop our scan/beacon first, then resume the shell scan. Doing these
    // sequentially avoids a "restart→stop" race on iOS where the shell scan
    // could be torn down by our stopMerchantScan microseconds after starting.
    unawaited(() async {
      try {
        await BleProximityService.stopMerchantScan();
      } catch (_) {}
      try {
        await BleProximityService.stopMerchantBeacon();
      } catch (_) {}
      try {
        await bleNotifier.resumeShellMerchantScan();
      } catch (_) {}
    }());
    _radarController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Bluetooth permissions, merchant beacon (for client-side picker), then scan.
  Future<void> _openBleSession() async {
    final available = await BleProximityService.isAvailable;
    if (!mounted) return;
    if (!available) {
      setState(() {
        _bleUnavailable = true;
        _bleErrorReason =
            'Le Bluetooth est désactivé ou indisponible sur ce téléphone.';
      });
      return;
    }

    final status = await BleProximityService.merchantPermissionStatus();
    if (!mounted) return;
    if (status != MerchantPermissionStatus.granted) {
      final granted = await _promptPermissionActivation(status);
      if (!mounted) return;
      if (!granted) {
        setState(() {
          _bleUnavailable = true;
          _bleErrorReason = _reasonForStatus(status);
        });
        return;
      }
    }

    // Start the scan FIRST — that's the screen's must-have. The merchant
    // can validate by tapping a detected client in the list, and the radar
    // animation tells them something is happening. Without it the screen
    // sits visually frozen if the beacon code below fails.
    await _beginScanSubscription();
    if (!mounted) return;

    unawaited(_startMerchantBeaconCoordinated());
  }

  /// Starts the merchant beacon so clients can pick this store.
  ///
  /// **iOS is skipped entirely.** Running `ble_peripheral`
  /// (CBPeripheralManager) alongside `flutter_blue_plus` (CBCentralManager)
  /// crashes the native iOS app at peripheral init — the crash is in
  /// CoreBluetooth, before any Dart `try/catch` gets a chance to run.
  /// Clients on iOS pick the merchant from « Mes commerces suivis » or the
  /// Firestore active_validations queue instead.
  Future<void> _startMerchantBeaconCoordinated({
    bool ensureScanAfter = false,
  }) async {
    if (Platform.isIOS) {
      LoggerService.logInfo(
        'MerchantBleScanScreen — skipping merchant beacon on iOS '
        '(known CoreBluetooth crash; scan-only mode active)',
      );
      _merchantBeaconActive = false;
      if (ensureScanAfter &&
          mounted &&
          !_bleUnavailable &&
          !_loyaltyFideliteDisabled) {
        await _beginScanSubscription();
      }
      return;
    }

    try {
      final beaconOk = await BleProximityService.startMerchantBeacon(
        widget.merchant.id,
        onClientUidWritten: _onClientWroteUidFromTheirPhone,
      );
      if (!mounted) return;
      _merchantBeaconActive = beaconOk;
      if (!beaconOk) {
        LoggerService.logInfo(
          'MerchantBleScanScreen — merchant beacon did not start; '
          'clients can still use « Mes commerces suivis » or Connexions en attente',
        );
      }
    } catch (e, st) {
      LoggerService.logError(
        'MerchantBleScanScreen — startMerchantBeacon failed',
        error: e,
        stackTrace: st,
      );
      _merchantBeaconActive = false;
    } finally {
      if (ensureScanAfter &&
          mounted &&
          !_bleUnavailable &&
          !_loyaltyFideliteDisabled) {
        await _beginScanSubscription();
      }
    }
  }

  Future<void> _startFlutterBlueScanOnly() async {
    if (Platform.isIOS) {
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleProximityService.serviceUuid)],
      );
    } else {
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleProximityService.serviceUuid)],
        continuousUpdates: true,
        continuousDivisor: 2,
        removeIfGone: const Duration(seconds: 14),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    }
  }

  Future<void> _beginScanSubscription() async {
    try {
      await _startFlutterBlueScanOnly();
    } catch (e, st) {
      LoggerService.logError(
        'MerchantBleScanScreen — FlutterBluePlus.startScan threw',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _bleUnavailable = true;
        _bleErrorReason = 'Impossible de démarrer le scan Bluetooth : $e';
      });
      return;
    }

    _scanSub = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'MerchantBleScanScreen — scan stream error',
          error: e,
          stackTrace: st,
        );
        if (!mounted) return;
        setState(() {
          _bleUnavailable = true;
          _bleErrorReason = 'Erreur du flux de scan Bluetooth : $e';
        });
      },
    );
    LoggerService.logInfo(
      'MerchantBleScanScreen — scan started',
      context: <String, Object?>{
        'listMinRssi': _kListMinRssi,
        'serviceUuid': BleProximityService.serviceUuid,
      },
    );
  }

  bool _nearbyClientsChanged(Map<DeviceIdentifier, _NearbyYuztooClient> next) {
    if (next.length != _nearbyClients.length) return true;
    for (final e in next.entries) {
      final prev = _nearbyClients[e.key];
      if (prev == null) return true;
      if ((prev.rssi - e.value.rssi).abs() > 4) return true;
      if (prev.displayName != e.value.displayName) return true;
      if (prev.photoUrl != e.value.photoUrl) return true;
      if (prev.resolvingName != e.value.resolvingName) return true;
      if (prev.resolveNameFailed != e.value.resolveNameFailed) return true;
    }
    return false;
  }

  bool _scanResultHasYuztooClientService(ScanResult r) {
    final target = Guid(BleProximityService.serviceUuid);
    for (final u in r.advertisementData.serviceUuids) {
      if (u == target) return true;
    }
    return false;
  }

  Future<({String? name, String? photoUrl})> _fetchUserProfile(
    String clientUid,
  ) async {
    if (clientUid.isEmpty) {
      return (name: null, photoUrl: null);
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientUid)
          .get();
      final data = doc.data();
      final fromCamel = (data?['displayName'] as String?)?.trim();
      final fromSnake = (data?['display_name'] as String?)?.trim();
      final name = (fromCamel != null && fromCamel.isNotEmpty)
          ? fromCamel
          : ((fromSnake != null && fromSnake.isNotEmpty) ? fromSnake : null);
      final photo = (data?['photoUrl'] as String?)?.trim();
      return (
        name: name,
        photoUrl: photo != null && photo.isNotEmpty ? photo : null,
      );
    } catch (_) {}
    return (name: null, photoUrl: null);
  }

  void _enqueueResolveClientDisplayName(DeviceIdentifier id) {
    _resolveDisplayNameTail =
        (_resolveDisplayNameTail ?? Future<void>.value()).then((_) async {
      try {
        await _resolveOneClientDisplayName(id);
      } catch (e, st) {
        LoggerService.logError(
          'MerchantBleScanScreen — background client name resolve failed',
          error: e,
          stackTrace: st,
        );
        if (!mounted || _triggered) return;
        setState(() {
          final row = _nearbyClients[id];
          if (row == null) return;
          _nearbyClients[id] = row.withResolveFailed();
        });
      }
    });
  }

  Future<void> _resolveOneClientDisplayName(DeviceIdentifier id) async {
    if (!mounted || _triggered) return;
    final entry = _nearbyClients[id];
    if (entry == null) return;
    if (entry.displayName != null || entry.resolveNameFailed) return;

    await BleProximityService.stopMerchantScan();
    String? clientId;
    try {
      if (!mounted || _triggered) return;
      final refEntry = _nearbyClients[id];
      if (refEntry == null) return;
      clientId = await BleProximityService.readClientId(refEntry.device);
    } catch (e, st) {
      LoggerService.logError(
        'MerchantBleScanScreen — background readClientId failed',
        error: e,
        stackTrace: st,
      );
      clientId = null;
    } finally {
      if (mounted &&
          !_triggered &&
          _state == _ScanState.waiting &&
          !_bleUnavailable &&
          !_loyaltyFideliteDisabled) {
        try {
          await _startFlutterBlueScanOnly();
        } catch (e, st) {
          LoggerService.logError(
            'MerchantBleScanScreen — resume scan after name resolve failed',
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    if (!mounted || _triggered) return;

    if (clientId == null || clientId.trim().isEmpty) {
      setState(() {
        final e = _nearbyClients[id];
        if (e == null) return;
        _nearbyClients[id] = e.withResolveFailed();
      });
      return;
    }

    final profile = await _fetchUserProfile(clientId.trim());
    if (!mounted || _triggered) return;
    setState(() {
      final e = _nearbyClients[id];
      if (e == null) return;
      _nearbyClients[id] = e.withResolveSucceeded(
        name: profile.name,
        photo: profile.photoUrl,
      );
    });
  }

  void _onScanResults(List<ScanResult> results) {
    if (!mounted || _triggered) return;

    final next = <DeviceIdentifier, _NearbyYuztooClient>{};
    for (final r in results) {
      if (!_scanResultHasYuztooClientService(r)) continue;
      if (r.rssi < _kListMinRssi) continue;
      final id = r.device.remoteId;
      final prev = _nearbyClients[id];
      next[id] = prev == null
          ? _NearbyYuztooClient(device: r.device, rssi: r.rssi)
          : prev.withUpdatedRssi(r.device, r.rssi);
    }

    final idsToEnqueue = <DeviceIdentifier>[];
    for (final id in List<DeviceIdentifier>.from(next.keys)) {
      final c = next[id]!;
      if (c.displayName == null && !c.resolveNameFailed && !c.resolvingName) {
        next[id] = c.withResolvingStarted();
        idsToEnqueue.add(id);
      }
    }

    if (!_triggered && _nearbyClientsChanged(next)) {
      setState(() {
        _nearbyClients
          ..clear()
          ..addAll(next);
      });
    }

    for (final id in idsToEnqueue) {
      _enqueueResolveClientDisplayName(id);
    }
  }

  /// Translates a [MerchantPermissionStatus] into the user-visible French
  /// reason shown on the "BLE indisponible" state.
  String _reasonForStatus(MerchantPermissionStatus status) {
    switch (status) {
      case MerchantPermissionStatus.granted:
        return '';
      case MerchantPermissionStatus.permanentlyDenied:
        return 'L\'autorisation Bluetooth a été refusée. Activez-la depuis les réglages de l\'application.';
      case MerchantPermissionStatus.restricted:
        return 'L\'utilisation du Bluetooth est restreinte sur ce téléphone (contrôle parental ou MDM).';
      case MerchantPermissionStatus.denied:
        return 'L\'autorisation Bluetooth n\'a pas été accordée.';
    }
  }

  /// Shows the in-app activation prompt. Returns true once the permission
  /// is actually granted (the user tapped "Activer" AND the system flow
  /// completed). Returns false on cancel or denial.
  ///
  /// When the permission is `permanentlyDenied`, calling `.request()` would
  /// silently return denied — the user must enable it from system Settings.
  /// In that case we send them straight to the app's Settings page via
  /// `openAppSettings()`.
  Future<bool> _promptPermissionActivation(
    MerchantPermissionStatus status,
  ) async {
    final mustOpenSettings =
        status == MerchantPermissionStatus.permanentlyDenied ||
            status == MerchantPermissionStatus.restricted;

    final action = await showDialog<_PermissionPromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Activer le Bluetooth',
          style: GoogleFonts.outfit(
            color: MerchantColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          mustOpenSettings
              ? 'L\'autorisation Bluetooth a été refusée. Activez-la dans les '
                  'réglages de l\'application pour valider un passage à '
                  'proximité.'
              : 'Yuztoo a besoin du Bluetooth pour rechercher le téléphone du '
                  'client et afficher les commerces à proximité. Activez '
                  'l\'autorisation pour continuer.',
          style: GoogleFonts.outfit(
            color: MerchantColors.textGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx)
                .pop(_PermissionPromptAction.cancel),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: MerchantColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              mustOpenSettings
                  ? _PermissionPromptAction.openSettings
                  : _PermissionPromptAction.requestNow,
            ),
            child: Text(
              mustOpenSettings ? 'Ouvrir les réglages' : 'Activer',
              style: GoogleFonts.outfit(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return false;
    switch (action) {
      case null:
      case _PermissionPromptAction.cancel:
        return false;
      case _PermissionPromptAction.openSettings:
        await BleProximityService.openSystemBluetoothSettings();
        // Re-check status when the user comes back from Settings. We
        // don't block here — if they enabled it, the next time they
        // re-open this screen the scan starts cleanly.
        final after = await BleProximityService.merchantPermissionStatus();
        return after == MerchantPermissionStatus.granted;
      case _PermissionPromptAction.requestNow:
        return await BleProximityService.requestMerchantPermissions();
    }
  }

  /// Client picked this commerce on their phone and wrote their Firebase UID
  /// to our merchant beacon — continue the same validation pipeline.
  void _onClientWroteUidFromTheirPhone(String rawUid) {
    final clientId = rawUid.trim();
    if (clientId.isEmpty) return;
    // Never call setState from a raw BLE callback stack (iOS).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _triggered) return;
      unawaited(_validateFromClientBeaconWrite(clientId));
    });
  }

  Future<void> _validateFromClientBeaconWrite(String clientId) async {
    HapticFeedback.mediumImpact();
    final profile = await _fetchUserProfile(clientId);
    if (!mounted) return;
    await _beginValidationForClient(clientId, profile.name);
  }

  Future<void> _onDeviceTapped(BluetoothDevice device) async {
    if (_triggered) return;
    _triggered = true;

    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _state = _ScanState.connecting);
    await _stopBleDiscoveryForValidation();

    final rawClientId = await BleProximityService.readClientId(device);
    if (!mounted) return;

    if (rawClientId == null || rawClientId.isEmpty) {
      _reset('Connexion échouée — réessayez.');
      return;
    }

    final clientId = rawClientId.trim();
    final cached = _nearbyClients[device.remoteId];
    final cachedName = cached?.displayName?.trim();
    final profile = (cachedName != null && cachedName.isNotEmpty)
        ? (name: cachedName, photoUrl: cached?.photoUrl)
        : await _fetchUserProfile(clientId);
    final displayName = profile.name;

    if (!mounted) return;

    await _openValidationForClient(clientId, displayName);
  }

  Future<void> _onPendingBleSessionTapped(ActiveValidationRequest session) async {
    HapticFeedback.mediumImpact();
    await _beginValidationForClient(
      session.clientUid,
      session.clientDisplayName,
    );
  }

  Future<ActiveValidationRequest?> _fetchClientSession(String clientUid) async {
    final repo = ref.read(activeValidationRepositoryProvider);
    return repo
        .watchClientSession(
          merchantId: widget.merchant.id,
          clientUid: clientUid,
        )
        .first;
  }

  /// Stops BLE scan + merchant beacon while a client is being validated.
  Future<void> _stopBleDiscoveryForValidation() async {
    await BleProximityService.stopMerchantScan();
    _scanSub?.cancel();
    if (_merchantBeaconActive) {
      await BleProximityService.stopMerchantBeacon();
      _merchantBeaconActive = false;
    }
  }

  Future<void> _beginValidationForClient(
    String clientId,
    String? displayName,
  ) async {
    if (_triggered) return;
    _triggered = true;
    if (!mounted) return;
    setState(() => _state = _ScanState.connecting);
    await _stopBleDiscoveryForValidation();
    if (!mounted) return;
    await _openValidationForClient(clientId, displayName);
  }

  Future<void> _openValidationForClient(
    String clientId,
    String? displayName,
  ) async {
    if (!mounted) return;
    setState(() => _state = _ScanState.connecting);

    ActiveValidationRequest? session;
    try {
      session = await _fetchClientSession(clientId);
    } catch (_) {
      session = null;
    }

    if (session == null) {
      _reset(
        'Le client doit d\'abord confirmer la connexion sur son téléphone.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _state = _ScanState.validating);

    final opened = await openMerchantPassageValidation(
      ref: ref,
      context: context,
      merchant: widget.merchant,
      session: session,
      connectMerchantBle: true,
    );

    if (!mounted) return;

    if (!opened) {
      _reset(null);
      return;
    }

    final name = displayName?.isNotEmpty == true ? displayName! : 'ce client';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Validation terminée pour $name',
          style: merchantSnackBarTextOnGold(),
        ),
        backgroundColor: StorefrontColors.primaryGold,
      ),
    );
    Navigator.of(context).pop();
  }

  void _reset(String? errorMessage) {
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _state = _ScanState.waiting;
      _triggered = false;
      _nearbyClients.clear();
    });
    if (!_loyaltyFideliteDisabled && !_bleUnavailable) {
      unawaited(_resumeBleAfterReset());
    }
  }

  Future<void> _resumeBleAfterReset() async {
    await _startMerchantBeaconCoordinated(ensureScanAfter: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderAlpha),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: MerchantColors.gold, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Valider un passage',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MerchantColors.textWhite,
              ),
            ),
          ),
          if (isMerchantPassageDebugEnabled)
            IconButton(
              tooltip: 'Simuler client BLE',
              onPressed: () => showMerchantPassageDebugSimulateSheet(
                context,
                merchant: widget.merchant,
              ),
              icon: const Icon(
                Icons.bug_report_outlined,
                color: MerchantColors.gold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loyaltyFideliteDisabled) {
      final live = merchantLiveLoyaltyProgram(widget.merchant);
      final manualMode =
          live.passageValidation == LoyaltyPassageValidation.manual;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.loyalty_outlined,
              size: 56,
              color: MerchantColors.gold.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 20),
            Text(
              manualMode
                  ? 'Validation manuelle'
                  : 'E-Fidélité désactivée',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              manualMode
                  ? 'Les passages se valident depuis « Vos clients » après une '
                      'demande sur la vitrine. Passez en mode automatique dans '
                      'E-Fidélité pour utiliser le Bluetooth.'
                  : 'Réactivez le programme dans E-Fidélité pour valider des '
                      'passages fidélité en boutique avec le Bluetooth.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.5,
                color: MerchantColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }
    if (_bleUnavailable) return _buildUnavailable();

    final pendingBle = ref
            .watch(merchantActiveValidationQueueProvider)
            .valueOrNull
            ?.where((s) => s.isBle && s.isAwaiting)
            .toList() ??
        const <ActiveValidationRequest>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadar(),
              const SizedBox(height: 16),
              _buildStatusText(),
              const SizedBox(height: 8),
              _buildSubtitle(),
            ],
          ),
        ),
        if (pendingBle.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPendingBleSessions(pendingBle),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Clients détectés',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (_state == _ScanState.waiting && _nearbyClients.isEmpty)
                Text(
                  'Recherche…',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _buildNearbyClientsPanel()),
      ],
    );
  }

  Widget _buildPendingBleSessions(List<ActiveValidationRequest> sessions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Connexions BLE en attente',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...sessions.map((session) {
            final name = session.clientDisplayName.trim().isNotEmpty
                ? session.clientDisplayName.trim()
                : 'Client';
            return Material(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                enabled: _state == _ScanState.waiting,
                leading: ProximityListAvatar(
                  imageUrl: session.clientPhotoUrl,
                  label: name,
                  size: 44,
                  fallbackIcon: Icons.person_outline_rounded,
                ),
                title: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'A confirmé la connexion — touchez pour valider',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.gold,
                ),
                onTap: _state == _ScanState.waiting
                    ? () => _onPendingBleSessionTapped(session)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -55) return 'Signal excellent';
    if (rssi >= -70) return 'Signal bon';
    if (rssi >= -85) return 'Signal moyen';
    return 'Signal faible';
  }

  Widget _buildNearbyClientsPanel() {
    if (_state != _ScanState.waiting) {
      return const SizedBox.shrink();
    }
    if (_nearbyClients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Center(
          child: Text(
            'Aucun téléphone client pour le moment.\n\n'
            'Le client doit ouvrir « Valider un passage » sur son application '
            'et activer le Bluetooth. Ensuite, touchez son nom dans la liste '
            'ci-dessous dès qu\'il apparaît — ou rapprochez fortement les deux '
            'téléphones pour une détection automatique.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              height: 1.55,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ),
      );
    }
    final sorted = _nearbyClients.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final e = sorted[index];
        final title = (e.displayName != null && e.displayName!.trim().isNotEmpty)
            ? e.displayName!.trim()
            : 'Téléphone client';
        String subtitle;
        if (e.resolvingName) {
          subtitle = 'Identification… · ${_rssiLabel(e.rssi)} · ${e.rssi} dBm';
        } else if (e.resolveNameFailed) {
          subtitle =
              'Nom indisponible · ${_rssiLabel(e.rssi)} · ${e.rssi} dBm';
        } else {
          subtitle = '${_rssiLabel(e.rssi)} · ${e.rssi} dBm';
        }
        return Material(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _triggered ? null : () => unawaited(_onDeviceTapped(e.device)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  ProximityListAvatar(
                    imageUrl: e.photoUrl,
                    label: title,
                    size: 44,
                    fallbackIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MerchantColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: MerchantColors.textGrey, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadar() {
    final isActive = _state == _ScanState.waiting;
    final isConnecting = _state == _ScanState.connecting ||
        _state == _ScanState.validating;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring 1
          if (isActive)
            AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) {
                final v = _radarController.value;
                return Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0),
                  child: Container(
                    width: 80 + v * 160,
                    height: 80 + v * 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: StorefrontColors.primaryGold, width: 1.5),
                    ),
                  ),
                );
              },
            ),
          // Outer pulsing ring 2 (offset)
          if (isActive)
            AnimatedBuilder(
              animation: _radarController,
              builder: (_, __) {
                final v = (_radarController.value + 0.5) % 1.0;
                return Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0),
                  child: Container(
                    width: 80 + v * 160,
                    height: 80 + v * 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: StorefrontColors.primaryGold.withValues(alpha: 0.4),
                          width: 1),
                    ),
                  ),
                );
              },
            ),
          // Center glowing button
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, child) {
              final glow = isActive ? _glowController.value : 0.0;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StorefrontColors.primaryGold,
                  boxShadow: [
                    BoxShadow(
                      color: StorefrontColors.primaryGold
                          .withValues(alpha: 0.2 + glow * 0.4),
                      blurRadius: 16 + glow * 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: isConnecting
                ? const Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(
                      color: StorefrontColors.navyDark,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.nfc_rounded,
                    color: StorefrontColors.navyDark, size: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    final text = switch (_state) {
      _ScanState.waiting =>
        'Recherche des clients à proximité — touchez un nom dans la liste '
        'ou rapprochez les téléphones',
      _ScanState.connecting => 'Connexion…',
      _ScanState.validating => 'Validation…',
    };
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: MerchantColors.textWhite,
      ),
    );
  }

  Widget _buildSubtitle() {
    final text = switch (_state) {
      _ScanState.waiting =>
        'Sur le téléphone du client : ouvrir « Valider un passage ».\n'
        'Sur votre écran : touchez la ligne du client dès qu\'elle apparaît.',
      _ScanState.connecting => 'Lecture du profil client…',
      _ScanState.validating => 'Enregistrement du passage…',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: MerchantColors.textLightGrey,
        height: 1.6,
      ),
    );
  }

  Widget _buildUnavailable() {
    final reason = _bleErrorReason;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.08),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Icon(Icons.nfc_rounded,
                color: MerchantColors.textGrey, size: 56),
          ),
          const SizedBox(height: 24),
          Text('Validation indisponible',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textWhite)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              reason ??
                  'Vérifiez les réglages de votre téléphone\n(connexion à courte portée activée).',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: MerchantColors.textLightGrey,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          // Quick action: go to system Settings to flip the permission.
          // Useful when the user previously denied — iOS won't re-prompt
          // and on Android the system permission dialog is past its
          // "Don't ask again" point.
          TextButton.icon(
            onPressed: () =>
                BleProximityService.openSystemBluetoothSettings(),
            icon: const Icon(Icons.settings_rounded,
                color: MerchantColors.gold, size: 18),
            label: Text(
              'Ouvrir les réglages',
              style: GoogleFonts.outfit(
                  color: MerchantColors.gold, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outcome of the in-app Bluetooth activation prompt.
enum _PermissionPromptAction {
  /// User dismissed the prompt without granting.
  cancel,

  /// User tapped "Activer" — caller should call `requestMerchantPermissions`
  /// (this is what fires the OS permission dialog).
  requestNow,

  /// User tapped "Ouvrir les réglages" — caller should send them to the
  /// system Settings page because the permission is permanently denied
  /// and `.request()` would silently no-op.
  openSettings,
}
