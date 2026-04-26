import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../auth/core/application/user_display_helpers.dart';
import '../application/client_loyalty_providers.dart';
import '../application/providers.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart' show ClientLoyaltyTier;

part 'loyalty_cards_screen.part.dart';

/// Client fidélité — real per-merchant loyalty cards backed by Firestore.
class LoyaltyCardsScreen extends ConsumerWidget {
  const LoyaltyCardsScreen({
    super.key,
    required this.onBack,
    required this.onNotifications,
    this.onStoreTap,
  });

  static String get path => '/loyalty';

  final VoidCallback onBack;
  final VoidCallback onNotifications;
  /// Called with merchant id when the user taps a loyalty card.
  final ValueChanged<String>? onStoreTap;

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
    final firstName = resolveDisplayName(user, basics).split(' ').first;
    final feedAsync = ref.watch(clientLoyaltyFeedProvider);

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GreetingBlock(
                        firstName: firstName,
                        feedAsync: feedAsync,
                      ),
                      const SizedBox(height: 24),
                      _LoyaltyFeed(
                        feedAsync: feedAsync,
                        onStoreTap: onStoreTap,
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
