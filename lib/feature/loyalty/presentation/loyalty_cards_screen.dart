import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../auth/core/application/user_display_helpers.dart';
import '../application/providers.dart';

part 'loyalty_cards_screen.part.dart';

/// Client fidélité — real user email / phone from Auth + Firestore (same as profile).
/// Loyalty counts: 0 until a backend source exists.
class LoyaltyCardsScreen extends ConsumerWidget {
  const LoyaltyCardsScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
  });

  static String get path => '/loyalty';

  final VoidCallback onBack;
  final VoidCallback onNotifications;

  /// When loyalty visits are stored in Firestore, wire them here.
  static const int _advantagesFromBackend = 0;
  static const int _passagesUntilRewardFromBackend = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final authState = ref.watch(authStateProvider);

    if (authState is! Authenticated) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Center(
            child: Text(
              'Connectez-vous pour voir votre fidélité.',
              style: GoogleFonts.outfit(color: MerchantColors.textLightGrey),
            ),
          ),
        ),
      );
    }

    final user = authState.user;
    final basics = ref.watch(userProfileBasicsProvider(user.id)).valueOrNull;
    final email = resolveEmail(user, basics);
    final phone = resolvePhone(user, basics);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: MerchantColors.bgHeader,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: MerchantColors.bgHeader,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Column(
            children: [
              _Header(onNotifications: onNotifications),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 88),
                  child: Column(
                    children: [
                      const _AdvantageIntro(count: _advantagesFromBackend),
                      const SizedBox(height: 16),
                      _ContactLines(email: email, phone: phone),
                      const SizedBox(height: 24),
                      const _LoyaltyCardPlaceholder(),
                      const SizedBox(height: 32),
                      const _InstructionLines(),
                      const SizedBox(height: 28),
                      const _ProgressFooter(
                        passagesUntilReward: _passagesUntilRewardFromBackend,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
