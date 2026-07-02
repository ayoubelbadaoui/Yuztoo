import 'dart:async';
import 'dart:io' show Platform;

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
import '../../client_home/application/providers.dart' as client_home_providers;
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/proximity_list_avatar.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../followed_merchants/application/providers.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../application/active_validation_providers.dart';
import '../application/client_loyalty_providers.dart';
import 'widgets/merchant_passage_debug_simulate_sheet.dart'
    show isMerchantPassageDebugEnabled;
import '../domain/entities/active_validation_request.dart';
import '../domain/failures/ble_passage_failure.dart';
import '../domain/loyalty_passage_program_policy.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';

/// One merchant phone advertising [BleProximityService.merchantBeaconServiceUuid].
class _NearbyMerchant {
  _NearbyMerchant({
    required this.device,
    required this.rssi,
    this.merchantId,
    this.displayName,
    this.logoUrl,
    this.resolvingName = false,
  });

  final BluetoothDevice device;
  final int rssi;
  final String? merchantId;
  final String? displayName;
  final String? logoUrl;
  final bool resolvingName;

  _NearbyMerchant copyWith({
    BluetoothDevice? device,
    int? rssi,
    String? merchantId,
    String? displayName,
    String? logoUrl,
    bool? resolvingName,
  }) =>
      _NearbyMerchant(
        device: device ?? this.device,
        rssi: rssi ?? this.rssi,
        merchantId: merchantId ?? this.merchantId,
        displayName: displayName ?? this.displayName,
        logoUrl: logoUrl ?? this.logoUrl,
        resolvingName: resolvingName ?? this.resolvingName,
      );
}

const int _kMerchantListMinRssi = -95;

/// Followed merchants the client can pick when no BLE beacon is visible (e.g.
/// iPhone merchant without beacon or out of range).
final bleFollowedMerchantsForPickProvider =
    FutureProvider.autoDispose<List<Merchant>>((ref) async {
  final ids = await ref.watch(
    client_home_providers.followedMerchantIdsForCurrentUserProvider.future,
  );
  if (ids.isEmpty) return const <Merchant>[];
  final result =
      await ref.read(merchantRepositoryProvider).getMerchantsByIds(ids);
  return result.fold((_) => const <Merchant>[], (merchants) {
    return merchants.where(isAutomaticPassageAllowedForMerchant).toList();
  });
});

/// Actions for the client BLE scan permission dialog.
enum _ClientBleScanPermissionAction {
  cancel,
  requestNow,
  openSettings,
}

/// Client-side BLE passage handoff.
///
/// Advertises this client's Firebase UID for the merchant scan, and **scans
/// for merchants** who have opened validation so the client can pick their
/// commerce from a list (writes UID to the merchant beacon).
class ClientBleBroadcastScreen extends ConsumerStatefulWidget {
  const ClientBleBroadcastScreen({super.key});

  @override
  ConsumerState<ClientBleBroadcastScreen> createState() =>
      _ClientBleBroadcastScreenState();
}

class _ClientBleBroadcastScreenState
    extends ConsumerState<ClientBleBroadcastScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _glowController;

  bool _broadcasting = false;
  bool _bleUnavailable = false;
  bool _retrying = false;

  StreamSubscription<List<ScanResult>>? _merchantScanSub;
  final Map<DeviceIdentifier, _NearbyMerchant> _nearbyMerchants = {};
  bool _merchantScanActive = false;
  bool _pickingMerchant = false;
  String? _merchantActionMessage;

  /// Scan permission refused — show one-tap retry to reopen the permission flow.
  bool _merchantScanPermissionDenied = false;

  /// Merchant id for which a BLE session was started (live status banner).
  String? _connectedMerchantId;
  String? _connectedMerchantLogoUrl;

  Future<void>? _resolveMerchantNameTail;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref
          .read(bleProximityProvider.notifier)
          .suspendShellClientBroadcast();
      if (!mounted) return;
      await _startBroadcasting();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _merchantScanSub?.cancel();
    final connectedMerchantId = _connectedMerchantId;
    if (connectedMerchantId != null) {
      unawaited(_cancelAwaitingBleSession(connectedMerchantId));
    }
    unawaited(_tearDownLocalBleAndResumeShell());
    super.dispose();
  }

  Future<void> _cancelAwaitingBleSession(String merchantId) async {
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return;
    final session =
        ref.read(clientActiveValidationSessionProvider(merchantId)).valueOrNull;
    if (session == null ||
        !session.isAwaiting ||
        session.isExpired ||
        session.isMerchantBleConnected) {
      return;
    }
    await ref.read(cancelActiveValidationProvider).byClient(
          merchantId: merchantId,
          clientUid: auth.user.id,
        );
  }

  Future<void> _tearDownLocalBleAndResumeShell() async {
    await FlutterBluePlus.stopScan();
    await BleProximityService.stopClientBroadcast();
    await ref.read(bleProximityProvider.notifier).resumeShellClientBroadcast();
  }

  Future<void> _startBroadcasting() async {
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return;

    final available = await BleProximityService.isAvailable;
    if (!mounted) return;

    if (!available) {
      setState(() {
        _bleUnavailable = true;
        _broadcasting = false;
      });
      return;
    }

    // A few transient failures are common right after permission grant or when
    // the peripheral stack was used recently — retry before showing "indisponible".
    const maxAttempts = 4;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await BleProximityService.stopClientBroadcast();
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
      final ok = await BleProximityService.startClientBroadcast(auth.user.id);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _broadcasting = true;
          _bleUnavailable = false;
        });
        if (Platform.isIOS) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
          if (!mounted) return;
        }
        unawaited(_startListeningForNearbyMerchants());
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _bleUnavailable = true;
      _broadcasting = false;
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _bleUnavailable = false;
      _broadcasting = false;
      _nearbyMerchants.clear();
      _merchantActionMessage = null;
      _merchantScanPermissionDenied = false;
    });
    _merchantScanSub?.cancel();
    await BleProximityService.stopClientBroadcast();
    await FlutterBluePlus.stopScan();
    await _startBroadcasting();
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  Future<void> _startListeningForNearbyMerchants() async {
    var status = await BleProximityService.merchantPermissionStatus();
    if (!mounted) return;

    if (status != MerchantPermissionStatus.granted) {
      final accepted = await _showClientBleScanPermissionDialog(status);
      if (!mounted) return;
      if (!accepted) {
        setState(() {
          _merchantScanPermissionDenied = true;
          _merchantScanActive = false;
          _merchantActionMessage =
              'Sans l\'autorisation « appareils à proximité », la liste des '
              'commerces ne s\'affiche pas. Vous pouvez quand même rapprocher '
              'votre téléphone de celui du commerçant.';
        });
        return;
      }
      status = await BleProximityService.merchantPermissionStatus();
      if (!mounted) return;
      if (status != MerchantPermissionStatus.granted) {
        setState(() {
          _merchantScanPermissionDenied = true;
          _merchantScanActive = false;
          _merchantActionMessage =
              'La permission n\'est pas encore active. Ouvrez les réglages de '
              'l\'application et autorisez Bluetooth / appareils à proximité '
              'pour Yuztoo, puis touchez « Autoriser » ci-dessous.';
        });
        return;
      }
    }

    await _attachMerchantScanStream();
  }

  /// Second step after permissions are known to be [MerchantPermissionStatus.granted].
  Future<void> _attachMerchantScanStream() async {
    if (!mounted) return;
    setState(() {
      _merchantScanPermissionDenied = false;
    });
    if (Platform.isIOS) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }
    try {
      if (Platform.isIOS) {
        await FlutterBluePlus.startScan(
          withServices: [Guid(BleProximityService.merchantBeaconServiceUuid)],
        );
      } else {
        await FlutterBluePlus.startScan(
          withServices: [Guid(BleProximityService.merchantBeaconServiceUuid)],
          continuousUpdates: true,
          continuousDivisor: 2,
          removeIfGone: const Duration(seconds: 14),
          androidScanMode: AndroidScanMode.lowLatency,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _merchantScanPermissionDenied = true;
        _merchantScanActive = false;
        _merchantActionMessage =
            'Impossible de lancer la recherche Bluetooth. Vérifiez que le '
            'Bluetooth est allumé et réessayez.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _merchantScanActive = true;
      _merchantActionMessage = null;
    });
    _merchantScanSub?.cancel();
    _merchantScanSub = FlutterBluePlus.scanResults.listen(
      _onMerchantScanResults,
      onError: (_, __) {
        if (!mounted) return;
        setState(() {
          _merchantScanPermissionDenied = false;
          _merchantActionMessage =
              'Erreur Bluetooth pendant la recherche de commerces. Réessayez '
              'ou rapprochez-vous du commerçant.';
        });
      },
    );
  }

  Future<bool> _showClientBleScanPermissionDialog(
    MerchantPermissionStatus status,
  ) async {
    final mustOpenSettings =
        status == MerchantPermissionStatus.permanentlyDenied ||
            status == MerchantPermissionStatus.restricted;

    final action = await showDialog<_ClientBleScanPermissionAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Autoriser la recherche Bluetooth',
          style: GoogleFonts.outfit(
            color: MerchantColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          mustOpenSettings
              ? 'Pour afficher les commerces qui valident un passage près de '
                  'vous, activez la recherche d\'appareils Bluetooth dans les '
                  'réglages de l\'application (ou le Bluetooth dans Réglages).'
              : 'Yuztoo a besoin de la permission « appareils à proximité » '
                  '(Bluetooth) pour lister les commerces à côté de vous. '
                  'Touchez Activer, puis acceptez dans la fenêtre du téléphone.',
          style: GoogleFonts.outfit(
            color: MerchantColors.textGrey,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ClientBleScanPermissionAction.cancel),
            child: Text(
              'Plus tard',
              style: GoogleFonts.outfit(color: MerchantColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              mustOpenSettings
                  ? _ClientBleScanPermissionAction.openSettings
                  : _ClientBleScanPermissionAction.requestNow,
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
      case _ClientBleScanPermissionAction.cancel:
        return false;
      case _ClientBleScanPermissionAction.openSettings:
        await BleProximityService.openSystemBluetoothSettings();
        final after = await BleProximityService.merchantPermissionStatus();
        return after == MerchantPermissionStatus.granted;
      case _ClientBleScanPermissionAction.requestNow:
        return await BleProximityService.requestMerchantPermissions();
    }
  }

  Future<void> _retryScanPermissionsFromBanner() async {
    final status = await BleProximityService.merchantPermissionStatus();
    if (!mounted) return;
    if (status == MerchantPermissionStatus.granted) {
      setState(() {
        _merchantScanPermissionDenied = false;
        _merchantActionMessage = null;
      });
      await _attachMerchantScanStream();
      return;
    }
    final ok = await _showClientBleScanPermissionDialog(status);
    if (!mounted) return;
    if (ok) {
      final after = await BleProximityService.merchantPermissionStatus();
      if (!mounted) return;
      if (after == MerchantPermissionStatus.granted) {
        setState(() {
          _merchantScanPermissionDenied = false;
          _merchantActionMessage = null;
        });
        await _attachMerchantScanStream();
      } else {
        setState(() {
          _merchantScanPermissionDenied = true;
          _merchantActionMessage =
              'La permission n\'est toujours pas active. Vérifiez les réglages '
              'de l\'application.';
        });
      }
    } else {
      setState(() {
        _merchantScanPermissionDenied = true;
        _merchantActionMessage =
            'Sans cette autorisation, la liste des commerces ne s\'affiche pas.';
      });
    }
  }

  bool _merchantsNearbyChanged(Map<DeviceIdentifier, _NearbyMerchant> next) {
    if (next.length != _nearbyMerchants.length) return true;
    for (final e in next.entries) {
      final prev = _nearbyMerchants[e.key];
      if (prev == null) return true;
      if ((prev.rssi - e.value.rssi).abs() > 4) return true;
      if (prev.displayName != e.value.displayName) return true;
      if (prev.logoUrl != e.value.logoUrl) return true;
      if (prev.merchantId != e.value.merchantId) return true;
      if (prev.resolvingName != e.value.resolvingName) return true;
    }
    return false;
  }

  bool _scanHasMerchantBeacon(ScanResult r) {
    final g = Guid(BleProximityService.merchantBeaconServiceUuid);
    for (final u in r.advertisementData.serviceUuids) {
      if (u == g) return true;
    }
    return false;
  }

  void _onMerchantScanResults(List<ScanResult> results) {
    if (!mounted || _pickingMerchant) return;
    final next = <DeviceIdentifier, _NearbyMerchant>{};
    final idsToResolve = <DeviceIdentifier>[];
    for (final r in results) {
      if (!_scanHasMerchantBeacon(r)) continue;
      if (r.rssi < _kMerchantListMinRssi) continue;
      final id = r.device.remoteId;
      final prev = _nearbyMerchants[id];
      var entry = prev == null
          ? _NearbyMerchant(device: r.device, rssi: r.rssi)
          : prev.copyWith(device: r.device, rssi: r.rssi);
      if (entry.merchantId == null && !entry.resolvingName) {
        entry = entry.copyWith(resolvingName: true);
        idsToResolve.add(id);
      }
      next[id] = entry;
    }
    if (_merchantsNearbyChanged(next)) {
      setState(() {
        _nearbyMerchants
          ..clear()
          ..addAll(next);
      });
    }
    for (final id in idsToResolve) {
      _enqueueResolveMerchantName(id);
    }
  }

  void _enqueueResolveMerchantName(DeviceIdentifier id) {
    _resolveMerchantNameTail =
        (_resolveMerchantNameTail ?? Future<void>.value()).then((_) async {
      await _resolveOneMerchantName(id);
    });
  }

  Future<void> _resolveOneMerchantName(DeviceIdentifier id) async {
    if (!mounted) return;
    final entry = _nearbyMerchants[id];
    if (entry == null || entry.merchantId != null) return;
    final merchantId =
        await BleProximityService.readMerchantIdFromBeacon(entry.device);
    if (!mounted) return;
    if (merchantId == null || merchantId.isEmpty) {
      setState(() {
        final e = _nearbyMerchants[id];
        if (e == null) return;
        _nearbyMerchants[id] = e.copyWith(resolvingName: false);
      });
      return;
    }
    final merchantResult =
        await ref.read(merchantRepositoryProvider).getMerchantById(merchantId);
    final merchant = merchantResult.fold<Merchant?>(
      (_) => null,
      (m) => m,
    );
    final name = merchant == null
        ? null
        : (merchant.displayName?.trim().isNotEmpty == true
            ? merchant.displayName!.trim()
            : merchant.name);
    if (!mounted) return;
    setState(() {
      final e = _nearbyMerchants[id];
      if (e == null) return;
      _nearbyMerchants[id] = e.copyWith(
        merchantId: merchantId,
        displayName: name,
        logoUrl: merchant?.logoUrl,
        resolvingName: false,
      );
    });
  }

  String? _logoUrlForConnectedMerchant() {
    final cached = _connectedMerchantLogoUrl?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    final id = _connectedMerchantId;
    if (id == null) return null;
    for (final m in _nearbyMerchants.values) {
      final url = m.logoUrl?.trim();
      if (m.merchantId == id && url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  String _merchantTitleForConnected(ActiveValidationRequest? session) {
    final fromSession = session?.merchantDisplayName?.trim();
    if (fromSession != null && fromSession.isNotEmpty) return fromSession;
    final id = _connectedMerchantId;
    if (id == null) return 'Commerce';
    for (final m in _nearbyMerchants.values) {
      if (m.merchantId == id && m.displayName?.trim().isNotEmpty == true) {
        return m.displayName!.trim();
      }
    }
    return 'Commerce';
  }

  String _merchantRssiLabel(int rssi) {
    if (rssi >= -55) return 'Signal excellent';
    if (rssi >= -70) return 'Signal bon';
    if (rssi >= -85) return 'Signal moyen';
    return 'Signal faible';
  }

  List<_NearbyMerchant> _sortedMerchants() {
    final list = _nearbyMerchants.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  Future<bool> _showFollowRequiredDialog(FollowRequiredFailure failure) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        title: Text(
          'Suivre ce commerce',
          style: GoogleFonts.outfit(
            color: MerchantColors.textWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Pour être éligible au système de fidélité, suivez '
          '${failure.merchantDisplayName} avant de valider un passage.',
          style: GoogleFonts.outfit(
            color: MerchantColors.textLightGrey,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler',
                style: TextStyle(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Suivre',
                style: TextStyle(
                    color: StorefrontColors.primaryGold,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  Future<void> _onMerchantRowTap(_NearbyMerchant m) async {
    final merchantId = m.merchantId;
    if (merchantId == null || merchantId.isEmpty) {
      setState(() => _merchantActionMessage =
          'Identification du commerce en cours — réessayez dans un instant.');
      return;
    }

    final merchantResult =
        await ref.read(merchantRepositoryProvider).getMerchantById(merchantId);
    final merchant = merchantResult.fold((_) => null, (x) => x);
    if (!mounted) return;
    if (merchant == null) {
      setState(() => _merchantActionMessage = 'Commerce introuvable.');
      return;
    }

    await _connectToMerchant(
      merchant,
      beaconDevice: m.device,
      logoUrl: m.logoUrl ?? merchant.logoUrl,
    );
  }

  Future<void> _onFollowedMerchantTap(Merchant merchant) async {
    await _connectToMerchant(merchant, logoUrl: merchant.logoUrl);
  }

  Future<void> _connectToMerchant(
    Merchant merchant, {
    BluetoothDevice? beaconDevice,
    String? logoUrl,
  }) async {
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated || _pickingMerchant) return;

    setState(() {
      _pickingMerchant = true;
      _merchantActionMessage = null;
    });

    var sessionResult = await ref.read(initiateBlePassageSessionProvider).call(
          client: auth.user,
          merchant: merchant,
        );

    final followFailure = sessionResult.fold((f) => f, (_) => null);
    if (followFailure is FollowRequiredFailure) {
      final wantsFollow = await _showFollowRequiredDialog(followFailure);
      if (!mounted) return;
      if (!wantsFollow) {
        setState(() => _pickingMerchant = false);
        return;
      }
      await ref.read(toggleMerchantFollowProvider).call(
            userId: auth.user.id,
            merchantId: merchant.id,
            currentlyFollowing: false,
          );
      sessionResult = await ref.read(initiateBlePassageSessionProvider).call(
            client: auth.user,
            merchant: merchant,
          );
    }

    if (!mounted) return;

    await sessionResult.fold(
      (failure) async {
        setState(() {
          _pickingMerchant = false;
          _merchantActionMessage = failure.message;
        });
      },
      (_) async {
        var beaconOk = false;
        if (beaconDevice != null) {
          beaconOk = await BleProximityService.writeClientUidToMerchantBeacon(
            beaconDevice,
            auth.user.id,
          );
        }
        if (!mounted) return;
        setState(() {
          _pickingMerchant = false;
          _connectedMerchantId = merchant.id;
          _connectedMerchantLogoUrl = logoUrl ?? merchant.logoUrl;
          _merchantActionMessage = beaconDevice != null && beaconOk
              ? 'Connexion envoyée. Le commerçant doit confirmer votre passage.'
              : 'Demande envoyée. Le commerçant vous retrouve dans sa liste '
                  '« Connexions BLE en attente ».';
        });
        if (beaconDevice != null && beaconOk) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      },
    );
  }

  String _sessionStatusLabel(ActiveValidationRequest? session) {
    if (session == null) {
      return 'En attente de la confirmation du commerçant…';
    }
    if (session.isCompleted) {
      return 'Passage validé ✓';
    }
    if (session.isCancelled) {
      if (session.cancelReason == 'session_expired') {
        return 'Demande expirée — réessayez près du commerçant.';
      }
      return 'Demande annulée.';
    }
    if (session.isOpened) {
      return 'Le commerçant valide votre passage…';
    }
    if (session.isMerchantBleConnected) {
      return 'Connecté — le commerçant finalise votre passage.';
    }
    return 'Connecté — en attente du commerçant.';
  }

  @override
  Widget build(BuildContext context) {
    final connectedId = _connectedMerchantId;
    if (connectedId != null) {
      ref.listen(
        clientActiveValidationSessionProvider(connectedId),
        (previous, next) {
          final session = next.valueOrNull;
          if (session?.isCompleted == true &&
              previous?.valueOrNull?.isCompleted != true) {
            ref.invalidate(client_home_providers.clientHomeFeedProvider);
            ref.invalidate(clientLoyaltyFeedProvider);
            if (mounted) {
              setState(() {
                _merchantActionMessage = 'Passage validé ✓';
              });
            }
          }
        },
      );
    }

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
              Expanded(
                child: _bleUnavailable
                    ? _buildUnavailable(context)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildBroadcasting(),
                      ),
              ),
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: MerchantColors.gold,
                size: 18,
              ),
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
              tooltip: 'Simuler commerce BLE',
              onPressed: _showClientBleDebugPicker,
              icon: const Icon(
                Icons.bug_report_outlined,
                color: MerchantColors.gold,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showClientBleDebugPicker() async {
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is! Authenticated) return;
    final feed =
        ref.read(client_home_providers.clientHomeFeedProvider).valueOrNull;
    final merchants = feed?.merchants ?? const <Merchant>[];
    if (!mounted) return;
    if (merchants.isEmpty) {
      setState(() => _merchantActionMessage =
          'Aucun commerce dans le carnet — suivez un commerce pour simuler.');
      return;
    }
    final authId = auth.user.id;
    final picked = await showModalBottomSheet<Merchant>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Simuler commerce BLE',
                style: GoogleFonts.outfit(
                  color: MerchantColors.textWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            for (final m in merchants)
              ListTile(
                title: Text(
                  m.displayName?.trim().isNotEmpty == true
                      ? m.displayName!.trim()
                      : m.name,
                  style: GoogleFonts.outfit(color: MerchantColors.textWhite),
                ),
                subtitle: m.id == authId
                    ? Text(
                        'Votre commerce — utilisez un autre compte client',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.orange.shade300,
                        ),
                      )
                    : null,
                enabled: m.id != authId,
                onTap: m.id == authId ? null : () => Navigator.of(ctx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    var sessionResult = await ref.read(initiateBlePassageSessionProvider).call(
          client: auth.user,
          merchant: picked,
        );
    final followFailure = sessionResult.fold((f) => f, (_) => null);
    if (followFailure is FollowRequiredFailure) {
      final wantsFollow = await _showFollowRequiredDialog(followFailure);
      if (!mounted || !wantsFollow) return;
      await ref.read(toggleMerchantFollowProvider).call(
            userId: auth.user.id,
            merchantId: picked.id,
            currentlyFollowing: false,
          );
      sessionResult = await ref.read(initiateBlePassageSessionProvider).call(
            client: auth.user,
            merchant: picked,
          );
    }
    if (!mounted) return;
    sessionResult.fold(
      (f) => setState(() => _merchantActionMessage = f.message),
      (_) => setState(() {
        _connectedMerchantId = picked.id;
        _connectedMerchantLogoUrl = picked.logoUrl;
      }),
    );
  }

  Widget _buildBroadcasting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        // Pulsing rings — same visual language as NFC scan overlay
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring 1
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final v = _pulseController.value;
                  return Opacity(
                    opacity: (1 - v).clamp(0.0, 1.0),
                    child: Container(
                      width: 80 + v * 140,
                      height: 80 + v * 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: StorefrontColors.primaryGold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Outer ring 2 (offset by half)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final v = ((_pulseController.value + 0.5) % 1.0);
                  return Opacity(
                    opacity: (1 - v).clamp(0.0, 1.0),
                    child: Container(
                      width: 80 + v * 140,
                      height: 80 + v * 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: StorefrontColors.primaryGold
                              .withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Center glowing circle
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, child) => Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: StorefrontColors.primaryGold,
                    boxShadow: [
                      BoxShadow(
                        color: StorefrontColors.primaryGold.withValues(
                          alpha: 0.3 + _glowController.value * 0.3,
                        ),
                        blurRadius: 20 + _glowController.value * 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: child,
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  color: StorefrontColors.navyDark,
                  size: 44,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _broadcasting ? 'Prêt' : 'Activation…',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: MerchantColors.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Votre téléphone est visible par le commerçant. '
          'Touchez un commerce pour confirmer la connexion — le commerçant '
          'validera ensuite votre passage.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: MerchantColors.textLightGrey,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        // Info pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderAlpha),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: MerchantColors.textGrey,
                size: 15,
              ),
              const SizedBox(width: 8),
              Text(
                'Gardez l\'écran ouvert',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (_connectedMerchantId != null) ...[
          Builder(
            builder: (context) {
              final session = ref
                  .watch(clientActiveValidationSessionProvider(
                      _connectedMerchantId!))
                  .valueOrNull;
              final merchantTitle = _merchantTitleForConnected(session);
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MerchantColors.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: MerchantColors.gold
                        .withValues(alpha: MerchantColors.goldBorderAlpha),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProximityListAvatar(
                      imageUrl: _logoUrlForConnectedMerchant(),
                      label: merchantTitle,
                      size: 44,
                      fallbackIcon: Icons.storefront_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchantTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _sessionStatusLabel(session),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: MerchantColors.textLightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Commerces à proximité',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
            ),
          ),
        ),
        if (_merchantScanPermissionDenied) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bluetooth_searching_rounded,
                      color: StorefrontColors.primaryGold,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pour voir les commerces à côté de vous, autorisez '
                        'Bluetooth / appareils à proximité pour Yuztoo.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.45,
                          color: MerchantColors.textLightGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _pickingMerchant
                      ? null
                      : () => unawaited(_retryScanPermissionsFromBanner()),
                  style: FilledButton.styleFrom(
                    backgroundColor: StorefrontColors.primaryGold,
                    foregroundColor: StorefrontColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Autoriser la recherche',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickingMerchant
                      ? null
                      : () => BleProximityService.openSystemBluetoothSettings(),
                  child: Text(
                    'Ouvrir les réglages du téléphone',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_merchantActionMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _merchantActionMessage!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.45,
                color: MerchantColors.textLightGrey,
              ),
            ),
          ),
        if (_pickingMerchant)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: StorefrontColors.primaryGold,
                ),
              ),
            ),
          ),
        if (_nearbyMerchants.isEmpty)
          Text(
            _merchantScanPermissionDenied
                ? 'Une fois l\'autorisation accordée, les commerces qui '
                    'valident un passage apparaîtront ici.'
                : _merchantScanActive
                    ? 'Aucun commerce détecté à proximité. Choisissez un '
                        'commerce suivi ci-dessous, ou demandez au commerçant '
                        'd\'ouvrir « Valider un passage ».'
                    : 'Activation de la recherche…',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
          )
        else
          Builder(
            builder: (context) {
              final items = _sortedMerchants();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = items[index];
                  final title = (m.displayName != null &&
                          m.displayName!.trim().isNotEmpty)
                      ? m.displayName!.trim()
                      : (m.resolvingName
                          ? 'Identification…'
                          : 'Commerce à proximité');
                  return Material(
                    color: MerchantColors.navyCard,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickingMerchant
                          ? null
                          : () => unawaited(_onMerchantRowTap(m)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            ProximityListAvatar(
                              imageUrl: m.logoUrl,
                              label: title,
                              size: 44,
                              fallbackIcon: Icons.storefront_outlined,
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
                                    '${_merchantRssiLabel(m.rssi)} · ${m.rssi} dBm · Confirmer',
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
            },
          ),
        _buildFollowedMerchantsPickSection(),
      ],
    );
  }

  Widget _buildFollowedMerchantsPickSection() {
    final nearbyIds = _nearbyMerchants.values
        .map((m) => m.merchantId)
        .whereType<String>()
        .toSet();
    final followedAsync = ref.watch(bleFollowedMerchantsForPickProvider);

    return followedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (merchants) {
        final manual =
            merchants.where((m) => !nearbyIds.contains(m.id)).toList();
        if (manual.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Mes commerces suivis',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Si le Bluetooth ne détecte pas le commerce (ex. iPhone commerçant), '
              'sélectionnez-le ici — le commerçant verra la demande dans sa liste.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                height: 1.45,
                color: MerchantColors.textGrey,
              ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: manual.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final merchant = manual[index];
                final title = merchant.displayName?.trim().isNotEmpty == true
                    ? merchant.displayName!.trim()
                    : merchant.name;
                return Material(
                  color: MerchantColors.navyCard,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickingMerchant
                        ? null
                        : () => unawaited(_onFollowedMerchantTap(merchant)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          ProximityListAvatar(
                            imageUrl: merchant.logoUrl,
                            label: title,
                            size: 44,
                            fallbackIcon: Icons.storefront_outlined,
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
                                  'Confirmer le passage',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: MerchantColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: MerchantColors.textGrey,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnavailable(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
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
            child: const Icon(
              Icons.nfc_rounded,
              color: MerchantColors.textGrey,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Validation indisponible',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vérifiez que le Bluetooth est allumé sur ce téléphone, puis '
            'réessayez.\n\n'
            'Sur Android : dans les réglages de l\'application Yuztoo, '
            'autorisez aussi « Appareils à proximité » / Bluetooth pour que '
            'le commerçant puisse vous détecter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: MerchantColors.textLightGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _retrying ? null : () => unawaited(_retry()),
              style: FilledButton.styleFrom(
                backgroundColor: StorefrontColors.primaryGold,
                foregroundColor: StorefrontColors.navyDark,
                disabledBackgroundColor:
                    StorefrontColors.primaryGold.withValues(alpha: 0.4),
              ),
              child: _retrying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: StorefrontColors.navyDark,
                      ),
                    )
                  : Text(
                      'Réessayer',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _retrying
                ? null
                : () => BleProximityService.openSystemBluetoothSettings(),
            icon: const Icon(
              Icons.settings_rounded,
              color: MerchantColors.gold,
              size: 20,
            ),
            label: Text(
              'Ouvrir les réglages',
              style: GoogleFonts.outfit(
                color: MerchantColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
