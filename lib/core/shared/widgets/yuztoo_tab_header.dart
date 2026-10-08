import 'package:flutter/material.dart';

import '../constants/merchant_colors.dart';
import 'yuztoo_gradient_title.dart';

/// Header of every bottom-nav tab (client and merchant): title on the left,
/// optional compact actions on the right, one fixed height everywhere.
class YuztooTabHeader extends StatelessWidget {
  const YuztooTabHeader({
    super.key,
    required this.title,
    this.titleTrailing,
    this.actions = const [],
    this.bottom,
    this.backgroundColor = MerchantColors.bgHeader,
    this.borderColor,
  });

  /// Height of the title row, excluding the status bar and [bottom].
  static const double rowHeight = 32;

  static const double titleFontSize = 20;

  final Widget title;

  /// Shown right after the title (e.g. a count badge).
  final Widget? titleTrailing;

  final List<Widget> actions;

  /// Extra content under the title row, inside the header (e.g. filter chips).
  final Widget? bottom;

  final Color backgroundColor;
  final Color? borderColor;

  /// Gradient tab title at the shared header size.
  static Widget gradientTitle(String text) => YuztooGradientTitle(
        text,
        fontSize: titleFontSize,
        fontWeight: FontWeight.w700,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor ??
                MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: SizedBox(
                height: rowHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(child: title),
                          if (titleTrailing != null) ...[
                            const SizedBox(width: 8),
                            titleTrailing!,
                          ],
                        ],
                      ),
                    ),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// Compact icon button sized to fit [YuztooTabHeader.rowHeight].
class YuztooHeaderAction extends StatelessWidget {
  const YuztooHeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = MerchantColors.gold,
    this.outlined = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  /// Circle border, used for the account-switch shortcut.
  final bool outlined;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: YuztooTabHeader.rowHeight,
        height: YuztooTabHeader.rowHeight,
        alignment: Alignment.center,
        decoration: outlined
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              )
            : null,
        child: Icon(icon, color: color, size: outlined ? 17 : 21),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
