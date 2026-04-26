import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../feature/discovery/presentation/discovery_screen.dart';

/// A 5-tab shell shown to unauthenticated (guest) users.
///
/// The Découvrir tab is functional; the other four are locked preview states
/// that nudge the guest to create an account.
class GuestShellScreen extends StatefulWidget {
  const GuestShellScreen({
    super.key,
    required this.onSignUp,
    required this.onSignIn,
    required this.onStoreSelect,
    required this.onBack,
  });

  final VoidCallback onSignUp;
  final VoidCallback onSignIn;
  final ValueChanged<String> onStoreSelect;
  final VoidCallback onBack;

  @override
  State<GuestShellScreen> createState() => _GuestShellScreenState();
}

class _GuestShellScreenState extends State<GuestShellScreen> {
  int _activeIndex = 1; // default: Découvrir tab

  static const _tabs = [
    _GuestTab(id: 'home', label: 'Accueil', icon: Icons.home_outlined),
    _GuestTab(id: 'discovery', label: 'Découvrir', icon: Icons.search),
    _GuestTab(id: 'notifications', label: 'Alertes', icon: Icons.notifications_none_rounded),
    _GuestTab(id: 'loyalty', label: 'Fidélité', icon: Icons.star_border),
    _GuestTab(id: 'profile', label: 'Profil', icon: Icons.person_outline),
  ];

  static const _lockedMessages = <String, (String, String)>{
    'home': (
      'Votre carnet de commerces vous attend',
      'Créez un compte pour suivre vos commerces préférés et retrouver leur actualité.',
    ),
    'notifications': (
      'Ne ratez plus aucune offre',
      'Recevez les alertes et promotions en temps réel de vos commerces favoris.',
    ),
    'loyalty': (
      'Cumulez des passages et montez en grade',
      'Nouveau → Soutien → Habitué → VIP : débloquez des avantages exclusifs.',
    ),
    'profile': (
      'Votre espace personnel',
      'Gérez vos villes, préférences et historique depuis votre profil.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_activeIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: currentTab.id == 'discovery'
            ? DiscoveryScreen(
                onBack: widget.onBack,
                onNotifications: () => setState(() => _activeIndex = 2),
                onStoreSelect: widget.onStoreSelect,
              )
            : _LockedTabBody(
                tabId: currentTab.id,
                title: _lockedMessages[currentTab.id]!.$1,
                subtitle: _lockedMessages[currentTab.id]!.$2,
                onSignUp: widget.onSignUp,
                onSignIn: widget.onSignIn,
              ),
        bottomNavigationBar: _GuestBottomNav(
          activeIndex: _activeIndex,
          tabs: _tabs,
          onTabTap: (index) => setState(() => _activeIndex = index),
        ),
      ),
    );
  }
}

// ── Locked tab body ─────────────────────────────────────────────────────────

class _LockedTabBody extends StatelessWidget {
  const _LockedTabBody({
    required this.tabId,
    required this.title,
    required this.subtitle,
    required this.onSignUp,
    required this.onSignIn,
  });

  final String tabId;
  final String title;
  final String subtitle;
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred skeleton cards suggesting real content
        IgnorePointer(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 60,
              16,
              0,
            ),
            itemCount: 5,
            itemBuilder: (_, i) {
              final opacity = (1.0 - i * 0.16).clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Opacity(
                  opacity: opacity,
                  child: _SkeletonCard(tabId: tabId, index: i),
                ),
              );
            },
          ),
        ),

        // Gradient fade-out
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MerchantColors.bgMain.withValues(alpha: 0.0),
                  MerchantColors.bgMain.withValues(alpha: 0.82),
                  MerchantColors.bgMain,
                ],
                stops: const [0.0, 0.35, 0.65],
              ),
            ),
          ),
        ),

        // Lock overlay
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MerchantColors.gold.withValues(alpha: 0.1),
                      border: Border.all(
                        color: MerchantColors.gold.withValues(
                            alpha: MerchantColors.goldBorderStronger),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: MerchantColors.gold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // INVITÉ badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: MerchantColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'INVITÉ',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: MerchantColors.bgHeader,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.textWhite,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: MerchantColors.textLightGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign-up CTA
                  GestureDetector(
                    onTap: onSignUp,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: MerchantColors.gold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'Créer un compte',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MerchantColors.bgHeader,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign-in link
                  GestureDetector(
                    onTap: onSignIn,
                    child: Text(
                      'Déjà un compte ? Se connecter',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Skeleton card variants per tab ─────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.tabId, required this.index});

  final String tabId;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tabId == 'home' ? 110 : 88,
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: tabId == 'home' ? 56 : 46,
            height: tabId == 'home' ? 56 : 46,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(tabId == 'home' ? 10 : 23),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bar([140.0, 110.0, 160.0, 90.0, 120.0][index], 11,
                    MerchantColors.textGrey.withValues(alpha: 0.2)),
                const SizedBox(height: 6),
                _bar([90.0, 70.0, 100.0, 60.0, 80.0][index], 9,
                    MerchantColors.textGrey.withValues(alpha: 0.13)),
                if (tabId == 'home') ...[
                  const SizedBox(height: 6),
                  _bar([110.0, 80.0, 130.0, 70.0, 95.0][index], 9,
                      MerchantColors.textGrey.withValues(alpha: 0.1)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double w, double h, Color color) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ── Guest bottom navigation ─────────────────────────────────────────────────

class _GuestBottomNav extends StatelessWidget {
  const _GuestBottomNav({
    required this.activeIndex,
    required this.tabs,
    required this.onTabTap,
  });

  final int activeIndex;
  final List<_GuestTab> tabs;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        border: Border(
          top: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == activeIndex;
              final isDiscovery = tab.id == 'discovery';

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    width: isActive ? 40 : 0,
                                    height: isActive ? 40 : 0,
                                    decoration: BoxDecoration(
                                      color: MerchantColors.gold,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  Icon(
                                    tab.icon,
                                    color: isActive
                                        ? MerchantColors.bgHeader
                                        : MerchantColors.gold
                                            .withValues(alpha: 0.6),
                                    size: 24,
                                  ),
                                  if (!isDiscovery && !isActive)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 9,
                                        color: MerchantColors.gold
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tab.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: MerchantColors.gold.withValues(
                                    alpha: isActive ? 1.0 : 0.6),
                                letterSpacing: 0.1,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GuestTab {
  const _GuestTab({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
