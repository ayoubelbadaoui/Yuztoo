import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/infrastructure/ble_proximity_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../storefront/presentation/widgets/storefront_colors.dart';

/// Client-side BLE broadcast screen.
///
/// Opens the Yuztoo GATT service and starts advertising so the merchant's
/// scan screen can detect this device. The broadcast runs for as long as
/// this screen is open; it stops automatically on pop.
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

    _startBroadcasting();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    BleProximityService.stopClientBroadcast();
    super.dispose();
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
    });
    await BleProximityService.stopClientBroadcast();
    await _startBroadcasting();
    if (!mounted) return;
    setState(() => _retrying = false);
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
                          color: StorefrontColors.primaryGold.withValues(alpha: 0.5),
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
          'Approchez votre téléphone\ndu commerçant',
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
      ],
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
            'Vérifiez que le Bluetooth est activé et que Yuztoo peut diffuser '
            'en Bluetooth (réglages Android : « Appareils à proximité » / '
            'autorisations).',
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
                disabledBackgroundColor: StorefrontColors.primaryGold
                    .withValues(alpha: 0.4),
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

