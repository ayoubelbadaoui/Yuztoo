import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/back_button.dart';
import '../../../core/shared/widgets/city_search_sheet.dart';
import '../application/multi_store_demo.dart';
import '../domain/entities/organization.dart';
import '../domain/entities/organization_member.dart';

part 'stores_screen.part.dart';
part 'team_screen.part.dart';

/// Points de vente of the enseigne: totals, active store switch, add a store.
class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key, this.onBack, this.onOpenVitrine});

  final VoidCallback? onBack;

  /// Opens the merchant storefront for the selected (active) PDV.
  final VoidCallback? onOpenVitrine;

  static const _overlay = SystemUiOverlayStyle(
    statusBarColor: MerchantColors.bgHeader,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: MerchantColors.bgMain,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(multiStoreDemoProvider);
    final notifier = ref.read(multiStoreDemoProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlay,
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScreenHeader(title: 'Points de vente', onBack: onBack),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  children: [
                    const _PreviewBanner(),
                    const SizedBox(height: 12),
                    _BrandCard(
                      demo: demo,
                      onLoyaltyTap: () => _showLoyaltySheet(context, ref),
                    ),
                    const SizedBox(height: 16),
                    _NetworkStats(demo: demo),
                    const SizedBox(height: 24),
                    const _SectionLabel('VOS POINTS DE VENTE'),
                    const SizedBox(height: 10),
                    for (final store in demo.stores)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoreTile(
                          store: store,
                          brandName: demo.brandName,
                          isActive: store.id == demo.activeStoreId,
                          onTap: () {
                            if (store.id == demo.activeStoreId) return;
                            notifier.switchTo(store.id);
                            _snack(
                              context,
                              'Vous gérez maintenant ${demo.storeName(store)}',
                            );
                          },
                          onToggleOnline: () => notifier.toggleOnline(store.id),
                          onOpenVitrine: onOpenVitrine == null
                              ? null
                              : () {
                                  notifier.switchTo(store.id);
                                  onOpenVitrine!();
                                },
                        ),
                      ),
                    const SizedBox(height: 4),
                    _GoldOutlinedButton(
                      icon: Icons.add_business_rounded,
                      label: 'Ajouter un point de vente',
                      onPressed: () => _showAddStoreSheet(context, ref),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('ÉQUIPE'),
                    const SizedBox(height: 10),
                    _TeamEntry(
                      memberCount: demo.members.length,
                      pendingCount:
                          demo.members.where((m) => m.isPending).length,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => TeamScreen(
                            onBack: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: MerchantColors.navyCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

String loyaltyModeLabel(LoyaltyMode mode) => switch (mode) {
      LoyaltyMode.shared => 'Carte commune à tous les points de vente',
      LoyaltyMode.perStore => 'Une carte par point de vente',
    };

/// Header row shared by the multi-store screens.
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          if (onBack != null)
            YBackButton(onPressed: onBack!)
          else
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
