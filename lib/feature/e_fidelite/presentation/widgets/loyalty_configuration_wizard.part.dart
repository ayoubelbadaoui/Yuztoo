part of 'loyalty_configuration_wizard.dart';

// ─── Wizard page body ─────────────────────────────────────────────────────────
//
// Scrollable content column (child + client preview) + bottom navigation bar.
// Used by every step in the PageView.

class _WizardPageBody extends StatelessWidget {
  const _WizardPageBody({
    required this.stepIndex,
    required this.pageCount,
    required this.summaryText,
    required this.onGoTo,
    required this.child,
    this.onSave,
    this.saveEnabled = false,
    this.saving = false,
  });

  final int stepIndex;
  final int pageCount;
  final String summaryText;
  final void Function(int index) onGoTo;
  final Widget child;
  final VoidCallback? onSave;
  final bool saveEnabled;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final isLast = stepIndex == pageCount - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 16 + kb),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  const SizedBox(height: 28),
                  _ClientOfferPreview(text: summaryText),
                ],
              ),
            ),
          ),
        ),
        // ── Bottom navigation bar ────────────────────────────────────────────
        Container(
          width: double.infinity,
          // Scaffold resizeToAvoidBottomInset already lifts the body; no
          // extra keyboard offset needed here.
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: MerchantColors.bgMain,
            border: Border(
              top: BorderSide(
                color: MerchantColors.gold.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Précédent — invisible on step 0 to keep layout balanced.
              Opacity(
                opacity: stepIndex > 0 ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: stepIndex <= 0,
                  child: _NavButton(
                    label: 'Précédent',
                    onTap: () => onGoTo(stepIndex - 1),
                    primary: false,
                  ),
                ),
              ),
              const Spacer(),
              if (!isLast)
                _NavButton(
                  label: 'Suivant',
                  onTap: () => onGoTo(stepIndex + 1),
                  primary: true,
                )
              else
                _NavButton(
                  label: saving ? 'En cours…' : 'Enregistrer',
                  onTap: saveEnabled && !saving ? onSave : null,
                  primary: true,
                  icon: saving ? null : Icons.check_rounded,
                  loading: saving,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Pill navigation button ───────────────────────────────────────────────────
//
// primary=true  → gold fill, dark text  (Suivant / Enregistrer)
// primary=false → gold outline, gold text (Précédent)

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.onTap,
    required this.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fgColor = primary
        ? (disabled ? MerchantColors.textLightGrey : MerchantColors.darkOverlay)
        : MerchantColors.gold;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          decoration: BoxDecoration(
            color: primary
                ? (disabled
                    ? MerchantColors.gold.withValues(alpha: 0.35)
                    : MerchantColors.gold)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: primary
                ? null
                : Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MerchantColors.darkOverlay,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 15, color: fgColor),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Client offer preview ─────────────────────────────────────────────────────
//
// Live French copy generated by LoyaltyProgramConfig.clientSummaryText,
// shown at the bottom of every wizard page so the merchant sees the impact
// of their choices in real time.

class _ClientOfferPreview extends StatelessWidget {
  const _ClientOfferPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantColors.gold, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MerchantColors.gold, width: 2),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: MerchantColors.gold,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aperçu côté client',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MerchantColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step progress indicator ──────────────────────────────────────────────────
//
// Animated dot row: past steps → solid gold, active → wide gold pill,
// future → faded. Step title label shown below in uppercase.

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    this.stepTitle,
  });

  final int current;
  final int total;
  final String? stepTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isActive = i == current;
              final isPast = i < current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: (isActive || isPast)
                      ? MerchantColors.gold
                      : MerchantColors.gold.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
          if (stepTitle != null) ...[
            const SizedBox(height: 6),
            Text(
              stepTitle!.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MerchantColors.gold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
