part of 'store_profile_screen.dart';

/// Light vitrine system bars: dark icons on white header / cream page.
///
/// Android 15+ draws edge-to-edge and ignores `systemNavigationBarColor`, so
/// the navigation buttons sit directly on the page and must be dark here.
const SystemUiOverlayStyle _storeProfileOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.white,
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// Pinned white top bar of the client vitrine: back, business name, safety
/// menu. Always solid so the name stays readable whatever the banner image.
class _StoreProfileTopBar extends StatelessWidget {
  const _StoreProfileTopBar({
    required this.title,
    required this.onBack,
    this.onMore,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMore;

  /// Bar height below the status bar (8 + 40 + 8).
  static const double contentHeight = 56;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _storeProfileOverlayStyle,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.of(context).padding.top + 8,
          12,
          8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            _StoreProfileTopBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: 'Retour',
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (onMore != null)
              _StoreProfileTopBarButton(
                icon: Icons.more_vert_rounded,
                semanticLabel: 'Plus d\'options',
                onTap: onMore!,
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _StoreProfileTopBarButton extends StatelessWidget {
  const _StoreProfileTopBarButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: StorefrontColors.navyDark.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: StorefrontColors.navyDark, size: 20),
        ),
      ),
    );
  }
}
