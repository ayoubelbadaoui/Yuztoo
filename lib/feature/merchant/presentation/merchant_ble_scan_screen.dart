import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/infrastructure/ble_proximity_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';
import '../application/providers.dart' as merchant_providers;
import '../domain/entities/merchant.dart';

// RSSI threshold for "tap" proximity (~3-5 cm).
// BLE at this distance reads between -20 and -45 dBm depending on hardware;
// -45 is a safe threshold that reliably fires at ≤ 5 cm on most devices.
const int _kTapRssiThreshold = -45;

// How many consecutive scan emissions must exceed the threshold before
// auto-triggering — prevents a single noisy spike from firing validation.
const int _kRequiredHits = 2;

enum _ScanState { waiting, connecting, validating }

/// Merchant-side BLE proximity screen.
///
/// The merchant opens this screen and holds their phone ~3 cm from the client's
/// phone (which must have [ClientBleBroadcastScreen] open). When the signal
/// exceeds [_kTapRssiThreshold] for [_kRequiredHits] consecutive readings the
/// app auto-connects, reads the clientId, and launches the validation flow —
/// no list, no button to tap.
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

  // Per-device consecutive hit counter for debouncing.
  final Map<DeviceIdentifier, int> _hitCount = {};
  // Prevent re-triggering after a validation attempt.
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startScan();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _glowController.dispose();
    _scanSub?.cancel();
    BleProximityService.stopMerchantScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    final available = await BleProximityService.isAvailable;
    if (!mounted) return;
    if (!available) {
      setState(() => _bleUnavailable = true);
      return;
    }

    // Subscribe directly to flutter_blue_plus scan results so we have RSSI.
    FlutterBluePlus.startScan(
        withServices: [Guid(BleProximityService.serviceUuid)]);

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted || _triggered) return;
      for (final r in results) {
        if (r.rssi >= _kTapRssiThreshold) {
          final count = (_hitCount[r.device.remoteId] ?? 0) + 1;
          _hitCount[r.device.remoteId] = count;
          if (count >= _kRequiredHits) {
            _onDeviceTapped(r.device);
            return;
          }
        } else {
          // Reset counter if device moved away.
          _hitCount.remove(r.device.remoteId);
        }
      }
    });
  }

  Future<void> _onDeviceTapped(BluetoothDevice device) async {
    if (_triggered) return;
    _triggered = true;

    HapticFeedback.mediumImpact();
    setState(() => _state = _ScanState.connecting);

    // Stop scanning while we connect.
    await BleProximityService.stopMerchantScan();
    _scanSub?.cancel();

    final clientId = await BleProximityService.readClientId(device);
    if (!mounted) return;

    if (clientId == null || clientId.isEmpty) {
      _reset('Connexion échouée — réessayez.');
      return;
    }

    // Fetch Firestore profile for the amount dialog title.
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

    final needsAmount = widget.merchant.loyaltyProgram
            ?.effectiveAskClientPurchaseAmount ??
        false;

    double? amount;
    if (needsAmount) {
      amount = await _showAmountDialog(displayName);
      if (!mounted) return;
      if (amount == null) {
        // User cancelled — allow retry.
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
            content: Text('Passage validé pour $name ✓'),
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
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _state = _ScanState.waiting;
      _triggered = false;
      _hitCount.clear();
    });
    _startScan();
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
    if (_bleUnavailable) return _buildUnavailable();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRadar(),
        const SizedBox(height: 48),
        _buildStatusText(),
        const SizedBox(height: 16),
        _buildSubtitle(),
      ],
    );
  }

  Widget _buildRadar() {
    final isActive = _state == _ScanState.waiting;
    final isConnecting = _state == _ScanState.connecting ||
        _state == _ScanState.validating;

    return SizedBox(
      width: 240,
      height: 240,
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
      _ScanState.waiting => 'Approchez les téléphones',
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
        'Collez votre téléphone contre celui\ndu client (~3 cm)',
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
              'Vérifiez les réglages de votre téléphone\n(connexion à courte portée activée).',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: MerchantColors.textLightGrey,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
