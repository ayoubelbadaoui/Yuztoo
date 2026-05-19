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
import '../../../core/shared/widgets/snackbar.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';
import '../application/providers.dart' as merchant_providers;
import '../domain/entities/merchant.dart';

/// Minimum RSSI to show a client in the manual list (several metres on
/// many phones — much more forgiving than the old "phones touching" bar).
const int _kListMinRssi = -92;

/// When RSSI stays at or above this level, we auto-start validation after
/// [_kAutoProximityHits] consecutive readings (optional shortcut).
const int _kAutoProximityRssi = -54;

const int _kAutoProximityHits = 3;

class _NearbyYuztooClient {
  _NearbyYuztooClient({required this.device, required this.rssi});

  final BluetoothDevice device;
  final int rssi;
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

  /// Hits for optional auto-validation when phones are very close.
  final Map<DeviceIdentifier, int> _autoProximityHits = {};

  /// True when this commerce is advertising the merchant beacon (so the
  /// client can select us from their list).
  bool _merchantBeaconActive = false;

  // Prevent re-triggering after a validation attempt.
  bool _triggered = false;

  /// E-Fidélité off — BLE passage validation is not offered.
  bool _loyaltyFideliteDisabled = false;

  bool _loyaltyLive(Merchant m) =>
      m.loyaltyEnabled &&
      (m.loyaltyProgram?.programEnabled ?? m.loyaltyEnabled);

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

    _loyaltyFideliteDisabled = !_loyaltyLive(widget.merchant);

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
    unawaited(ref.read(bleProximityProvider.notifier).resumeShellMerchantScan());
    _radarController.dispose();
    _glowController.dispose();
    _scanSub?.cancel();
    unawaited(BleProximityService.stopMerchantScan());
    unawaited(BleProximityService.stopMerchantBeacon());
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

    // Merchant beacon (CBPeripheralManager via `ble_peripheral`) is a
    // nice-to-have that lets clients pick this commerce from a list on
    // their own phone. On iOS it has been observed to crash the app when
    // first initialised in a session — the native exception leaks out of
    // ble_peripheral's Dart try/catch on some iOS builds and surfaces as
    // a hard exit. We:
    //   • Run it in a separate microtask so any failure can't bring down
    //     the radar / scan flow that's already up.
    //   • Wrap in a guarded try/catch (catches Errors too, not just
    //     Exceptions — the iOS bridge sometimes throws `Error` subtypes).
    //   • Skip entirely on iOS for now: until the upstream crash is
    //     pinned, the scan-only flow on the merchant side is the safer
    //     default. The Android beacon keeps working.
    if (!Platform.isIOS) {
      unawaited(_startBeaconBestEffort());
    } else {
      LoggerService.logInfo(
        'MerchantBleScanScreen — skipping merchant beacon on iOS '
        '(known crash; scan-only mode active)',
      );
    }
  }

  Future<void> _startBeaconBestEffort() async {
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
          'merchant→client picker may be unavailable',
        );
      }
    } catch (e, st) {
      LoggerService.logError(
        'MerchantBleScanScreen — startMerchantBeacon threw (degraded mode: '
        'scan-only)',
        error: e,
        stackTrace: st,
      );
      _merchantBeaconActive = false;
    }
  }

  Future<void> _beginScanSubscription() async {
    try {
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
        'autoProximityRssi': _kAutoProximityRssi,
        'autoHits': _kAutoProximityHits,
        'serviceUuid': BleProximityService.serviceUuid,
      },
    );
  }

  bool _nearbyClientsChanged(Map<DeviceIdentifier, _NearbyYuztooClient> next) {
    if (next.length != _nearbyClients.length) return true;
    for (final e in next.entries) {
      final prev = _nearbyClients[e.key];
      if (prev == null || (prev.rssi - e.value.rssi).abs() > 4) return true;
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

  void _onScanResults(List<ScanResult> results) {
    if (!mounted || _triggered) return;

    final next = <DeviceIdentifier, _NearbyYuztooClient>{};
    for (final r in results) {
      if (!_scanResultHasYuztooClientService(r)) continue;
      if (r.rssi < _kListMinRssi) continue;
      next[r.device.remoteId] =
          _NearbyYuztooClient(device: r.device, rssi: r.rssi);
    }

    if (!_triggered && _nearbyClientsChanged(next)) {
      setState(() {
        _nearbyClients
          ..clear()
          ..addAll(next);
      });
    }

    if (_state != _ScanState.waiting || _triggered) return;

    for (final r in results) {
      if (!_scanResultHasYuztooClientService(r)) continue;
      if (r.rssi >= _kAutoProximityRssi) {
        final n = (_autoProximityHits[r.device.remoteId] ?? 0) + 1;
        _autoProximityHits[r.device.remoteId] = n;
        if (n >= _kAutoProximityHits) {
          _autoProximityHits.clear();
          unawaited(_onDeviceTapped(r.device));
          return;
        }
      } else {
        _autoProximityHits.remove(r.device.remoteId);
      }
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
    if (_triggered) return;
    _triggered = true;
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _state = _ScanState.connecting);

    await BleProximityService.stopMerchantScan();
    _scanSub?.cancel();
    if (_merchantBeaconActive) {
      await BleProximityService.stopMerchantBeacon();
      _merchantBeaconActive = false;
    }

    String? displayName;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();
      final data = doc.data();
      displayName = (data?['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data!['displayName'] as String).trim()
          : (data?['display_name'] as String?)?.trim();
    } catch (_) {}

    if (!mounted) return;

    await _completePassageAfterClientKnown(clientId, displayName);
  }

  Future<void> _onDeviceTapped(BluetoothDevice device) async {
    if (_triggered) return;
    _triggered = true;

    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.connecting);

    await BleProximityService.stopMerchantScan();
    _scanSub?.cancel();
    if (_merchantBeaconActive) {
      await BleProximityService.stopMerchantBeacon();
      _merchantBeaconActive = false;
    }

    final clientId = await BleProximityService.readClientId(device);
    if (!mounted) return;

    if (clientId == null || clientId.isEmpty) {
      _reset('Connexion échouée — réessayez.');
      return;
    }

    String? displayName;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();
      final data = doc.data();
      displayName = (data?['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data!['displayName'] as String).trim()
          : (data?['display_name'] as String?)?.trim();
    } catch (_) {}

    if (!mounted) return;

    await _completePassageAfterClientKnown(clientId, displayName);
  }

  Future<void> _completePassageAfterClientKnown(
    String clientId,
    String? displayName,
  ) async {
    final loyaltyActive = widget.merchant.loyaltyEnabled &&
        (widget.merchant.loyaltyProgram?.programEnabled ??
            widget.merchant.loyaltyEnabled);
    final needsAmount = loyaltyActive &&
        (widget.merchant.loyaltyProgram?.effectiveAskClientPurchaseAmount ??
            false);

    double? amount;
    if (needsAmount) {
      amount = await _showAmountDialog(displayName);
      if (!mounted) return;
      if (amount == null) {
        _reset(null);
        return;
      }
    }

    setState(() => _state = _ScanState.validating);
    HapticFeedback.lightImpact();

    final useCase =
        ref.read(merchant_providers.merchantRecordClientPassageProvider);
    final result = await useCase.call(
      clientUid: clientId,
      merchant: widget.merchant,
      purchaseAmountEuros: amount,
    );

    if (!mounted) return;

    result.fold(
      (failure) => _reset(failure.message),
      (_) {
        HapticFeedback.heavyImpact();
        final name = displayName?.isNotEmpty == true ? displayName! : 'ce client';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Passage validé pour $name ✓',
              style: merchantSnackBarTextOnGold(),
            ),
            backgroundColor: StorefrontColors.primaryGold,
          ),
        );
        Navigator.of(context).pop();
      },
    );
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
      _autoProximityHits.clear();
      _nearbyClients.clear();
    });
    if (!_loyaltyFideliteDisabled && !_bleUnavailable) {
      unawaited(_resumeBleAfterReset());
    }
  }

  Future<void> _resumeBleAfterReset() async {
    await BleProximityService.stopMerchantScan();
    _scanSub?.cancel();
    final ok = await BleProximityService.startMerchantBeacon(
      widget.merchant.id,
      onClientUidWritten: _onClientWroteUidFromTheirPhone,
    );
    if (!mounted) return;
    _merchantBeaconActive = ok;
    await _beginScanSubscription();
  }

  Future<double?> _showAmountDialog(String? clientName) {
    final ctrl = TextEditingController();
    final title = clientName?.isNotEmpty == true
        ? 'Montant — $clientName'
        : 'Montant de l\'achat';
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.outfit(
                color: MerchantColors.textWhite,
                fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: MerchantColors.textWhite),
          decoration: const InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: MerchantColors.textGrey),
            suffixText: '€',
            suffixStyle: TextStyle(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600),
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: MerchantColors.gold)),
            focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: StorefrontColors.primaryGold, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler',
                style: TextStyle(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              final v =
                  double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Valider',
                style: TextStyle(
                    color: StorefrontColors.primaryGold,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
          Text(
            'Valider un passage',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loyaltyFideliteDisabled) {
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
              'E-Fidélité désactivée',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MerchantColors.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Réactivez le programme dans E-Fidélité pour valider des passages '
              'fidélité en boutique avec le Bluetooth.',
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
                  const Icon(Icons.smartphone_rounded,
                      color: StorefrontColors.primaryGold, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Téléphone client',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MerchantColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_rssiLabel(e.rssi)} · ${e.rssi} dBm',
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
