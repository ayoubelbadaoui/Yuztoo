part of 'store_profile_screen.dart';

/// Pinned top bar of the client vitrine: back, business name, safety menu.
///
/// [progress] 0 = floating over the banner (white on translucent chips),
/// 1 = solid cream once the banner has scrolled away, so the name stays
/// readable on any banner image.
class _StoreProfileTopBar extends StatelessWidget {
  const _StoreProfileTopBar({
    required this.title,
    required this.onBack,
    this.onMore,
    this.progress = 1,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onMore;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final solid = t >= 0.6;
    final foreground =
        Color.lerp(Colors.white, StorefrontColors.textPrimary, t)!;
    final chip = Colors.black.withValues(alpha: 0.25 * (1 - t));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: solid ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: solid ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: StorefrontColors.navyDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.of(context).padding.top + 8,
          12,
          8,
        ),
        decoration: BoxDecoration(
          color: StorefrontColors.backgroundLight.withValues(alpha: t),
          border: Border(
            bottom: BorderSide(
              color: Colors.black.withValues(alpha: 0.06 * t),
            ),
          ),
        ),
        child: Row(
          children: [
            _StoreProfileTopBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              semanticLabel: 'Retour',
              color: foreground,
              background: chip,
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
                  color: foreground,
                  shadows: t < 0.5
                      ? const [Shadow(color: Color(0x73000000), blurRadius: 6)]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (onMore != null)
              _StoreProfileTopBarButton(
                icon: Icons.more_vert_rounded,
                semanticLabel: 'Plus d\'options',
                color: foreground,
                background: chip,
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
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final Color color;
  final Color background;
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
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
