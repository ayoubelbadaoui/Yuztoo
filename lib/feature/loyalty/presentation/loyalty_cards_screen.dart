import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/app_logo.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/presentation/user_display_helpers.dart';

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

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fidélité',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNotifications,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: MerchantColors.gold,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactLines extends StatelessWidget {
  const _ContactLines({required this.email, required this.phone});

  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.outfit(
      fontSize: 13,
      height: 1.45,
      color: MerchantColors.textGrey,
    );
    return Column(
      children: [
        Text(email, textAlign: TextAlign.center, style: style),
        if (phone != '—') ...[
          const SizedBox(height: 6),
          Text(phone, textAlign: TextAlign.center, style: style),
        ],
      ],
    );
  }
}

class _AdvantageIntro extends StatelessWidget {
  const _AdvantageIntro({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final gold = GoogleFonts.outfit(
      color: MerchantColors.gold,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      height: 1.5,
    );
    final base = GoogleFonts.outfit(
      fontSize: 15,
      height: 1.5,
      color: MerchantColors.textLightGrey,
    );

    if (count == 0) {
      return Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(
              text:
                  'Aucun avantage enregistré pour le moment sur votre carte fidélité ',
            ),
            TextSpan(text: 'Yuztoo', style: gold),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    if (count == 1) {
      return Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Déjà '),
            TextSpan(text: '1', style: gold),
            const TextSpan(
              text: ' avantage obtenu grâce à votre carte fidélité ',
            ),
            TextSpan(text: 'Yuztoo', style: gold),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Déjà '),
          TextSpan(text: '$count', style: gold),
          const TextSpan(
            text: ' avantages obtenus grâce à votre carte fidélité ',
          ),
          TextSpan(text: 'Yuztoo', style: gold),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Placeholder card — replace image asset when final art is ready.
class _LoyaltyCardPlaceholder extends StatelessWidget {
  const _LoyaltyCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: AspectRatio(
          aspectRatio: 0.72,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.35),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MerchantColors.bgHeader,
                  MerchantColors.bgMain.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppLogo(
                  size: 100,
                  fallback: Icon(
                    Icons.location_on_rounded,
                    size: 56,
                    color: MerchantColors.gold.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'yuztoo',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'pour eux, pour vous',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textLightGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstructionLines extends StatelessWidget {
  const _InstructionLines();

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.outfit(
      fontSize: 14,
      height: 1.65,
      color: MerchantColors.textLightGrey,
    );
    return Column(
      children: [
        Text(
          'Présente simplement ton téléphone',
          textAlign: TextAlign.center,
          style: style,
        ),
        const SizedBox(height: 8),
        Text(
          'Chaque passage compte',
          textAlign: TextAlign.center,
          style: style,
        ),
        const SizedBox(height: 8),
        Text(
          'Un cadeau après 5, 10 ou 20 passages.',
          textAlign: TextAlign.center,
          style: style,
        ),
      ],
    );
  }
}

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter({required this.passagesUntilReward});

  final int passagesUntilReward;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.outfit(
      fontSize: 14,
      height: 1.5,
      color: MerchantColors.textLightGrey,
    );
    final gold = GoogleFonts.outfit(
      fontSize: 14,
      height: 1.5,
      color: MerchantColors.gold,
      fontWeight: FontWeight.w700,
    );

    if (passagesUntilReward <= 0) {
      return Text(
        'Vos passages chez un commerçant partenaire s’afficheront ici après une visite.',
        textAlign: TextAlign.center,
        style: base,
      );
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Plus que '),
          TextSpan(
            text: '$passagesUntilReward',
            style: gold,
          ),
          const TextSpan(
            text:
                ' passages chez votre commerçant avant la prochaine récompense',
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
