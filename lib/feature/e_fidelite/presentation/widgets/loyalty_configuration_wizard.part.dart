part of 'loyalty_configuration_wizard.dart';

/// One scrollable column per step: questionnaire, then client preview, then nav.
class _WizardPageBody extends StatelessWidget {
  const _WizardPageBody({
    required this.stepIndex,
    required this.pageCount,
    required this.summaryText,
    required this.onGoTo,
    required this.child,
  });

  final int stepIndex;
  final int pageCount;
  final String summaryText;
  final void Function(int index) onGoTo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
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
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + kb),
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
              if (stepIndex > 0)
                TextButton(
                  onPressed: () => onGoTo(stepIndex - 1),
                  child: Text(
                    'Précédent',
                    style: GoogleFonts.outfit(color: MerchantColors.gold),
                  ),
                )
              else
                const SizedBox(width: 88),
              const Spacer(),
              Text(
                '${stepIndex + 1} / $pageCount',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const Spacer(),
              if (stepIndex < pageCount - 1)
                TextButton(
                  onPressed: () => onGoTo(stepIndex + 1),
                  child: Text(
                    'Suivant',
                    style: GoogleFonts.outfit(
                      color: MerchantColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(width: 72),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live client-facing copy from [LoyaltyProgramConfig.clientSummaryText].
class _ClientOfferPreview extends StatelessWidget {
  const _ClientOfferPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
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

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == current;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: 0.35),
            ),
          );
        }),
      ),
    );
  }
}

class _ActivationStep extends StatelessWidget {
  const _ActivationStep({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Souhaitez-vous activer un programme de fidélité ?',
      child: Column(
        children: [
          _ChoiceTile(
            title: 'Oui',
            selected: enabled,
            onTap: () => onChanged(true),
          ),
          _ChoiceTile(
            title: 'Non',
            selected: !enabled,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TriggerStep extends StatelessWidget {
  const _TriggerStep({
    required this.value,
    required this.onChanged,
  });

  final LoyaltyTriggerType value;
  final ValueChanged<LoyaltyTriggerType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Comment souhaitez-vous récompenser la fidélité ?',
      child: Column(
        children: [
          _ChoiceTile(
            title: 'Nombre de passages',
            subtitle: 'Après X passages validés',
            selected: value == LoyaltyTriggerType.visitCount,
            onTap: () => onChanged(LoyaltyTriggerType.visitCount),
          ),
          _ChoiceTile(
            title: 'Cumul d\'achats',
            subtitle: 'Après un montant total dépensé',
            selected: value == LoyaltyTriggerType.purchaseTotal,
            onTap: () => onChanged(LoyaltyTriggerType.purchaseTotal),
          ),
        ],
      ),
    );
  }
}

class _ThresholdStep extends StatelessWidget {
  const _ThresholdStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (config.triggerType == LoyaltyTriggerType.visitCount) {
      return _StepSection(
        question: 'Nombre de passages requis',
        child: _DropdownCard<int>(
          value: config.visitsRequired,
          items: const [3, 5, 7, 10, 15, 20],
          labelBuilder: (v) => '$v passages',
          onChanged: notifier.setVisitsRequired,
        ),
      );
    }
    return _StepSection(
      question: 'Montant total à atteindre (€)',
      child: _DropdownCard<double>(
        value: _nearest(config.cumulativeSpendRequiredEuros,
            const [30, 50, 75, 100, 150, 200, 300, 500]),
        items: const [30, 50, 75, 100, 150, 200, 300, 500],
        labelBuilder: (v) => '$v €',
        onChanged: notifier.setCumulativeSpendRequiredEuros,
      ),
    );
  }
}

T _nearest<T extends num>(T current, List<T> options) {
  if (options.contains(current)) return current;
  T best = options.first;
  var bestDist = (current - best).abs();
  for (final o in options) {
    final d = (current - o).abs();
    if (d < bestDist) {
      best = o;
      bestDist = d;
    }
  }
  return best;
}

class _RewardStep extends StatelessWidget {
  const _RewardStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Quelle récompense souhaitez-vous offrir ?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _ChoiceTile(
              title: 'Bon d\'achat',
              selected: config.rewardKind == LoyaltyRewardKind.purchaseVoucher,
              onTap: () => notifier.setRewardKind(LoyaltyRewardKind.purchaseVoucher),
            ),
            if (config.rewardKind == LoyaltyRewardKind.purchaseVoucher) ...[
              const SizedBox(height: 8),
              _ChoiceTile(
                title: 'En pourcentage des dépenses',
                selected: config.purchaseVoucherUsesPercent,
                onTap: () => notifier.setPurchaseVoucherUsesPercent(true),
              ),
              _ChoiceTile(
                title: 'Montant fixe (€)',
                selected: !config.purchaseVoucherUsesPercent,
                onTap: () => notifier.setPurchaseVoucherUsesPercent(false),
              ),
              _DropdownCard<double>(
                value: _nearest(
                  config.purchaseVoucherValue,
                  config.purchaseVoucherUsesPercent
                      ? const [5, 10, 15, 20, 25]
                      : const [5, 10, 15, 20, 25, 50],
                ),
                items: config.purchaseVoucherUsesPercent
                    ? const [5, 10, 15, 20, 25]
                    : const [5, 10, 15, 20, 25, 50],
                labelBuilder: (v) => config.purchaseVoucherUsesPercent
                    ? '$v %'
                    : '$v €',
                onChanged: notifier.setPurchaseVoucherValue,
              ),
            ],
            _ChoiceTile(
              title: 'Remise sur le prochain achat',
              subtitle: 'Pourcentage de réduction',
              selected: config.rewardKind == LoyaltyRewardKind.discountPercent,
              onTap: () =>
                  notifier.setRewardKind(LoyaltyRewardKind.discountPercent),
            ),
            if (config.rewardKind == LoyaltyRewardKind.discountPercent)
              _DropdownCard<double>(
                value: _nearest(
                  config.discountNextPurchasePercent,
                  const [5, 10, 15, 20, 25, 30],
                ),
                items: const [5, 10, 15, 20, 25, 30],
                labelBuilder: (v) => '$v %',
                onChanged: notifier.setDiscountNextPurchasePercent,
              ),
            _ChoiceTile(
              title: 'Produit offert',
              subtitle: 'Un article précis, nommé comme sur votre carte',
              selected: config.rewardKind == LoyaltyRewardKind.freeProduct,
              onTap: () => notifier.setRewardKind(LoyaltyRewardKind.freeProduct),
            ),
            if (config.rewardKind == LoyaltyRewardKind.freeProduct)
              _FreeProductRewardPanel(
                initialText: config.freeProductSummaryLabel ?? '',
                onChanged: notifier.setFreeProductSummaryLabel,
              ),
            _ChoiceTile(
              title: 'Points fidélité',
              subtitle: '1 € dépensé = X points',
              selected: config.rewardKind == LoyaltyRewardKind.loyaltyPoints,
              onTap: () =>
                  notifier.setRewardKind(LoyaltyRewardKind.loyaltyPoints),
            ),
            if (config.rewardKind == LoyaltyRewardKind.loyaltyPoints)
              _DropdownCard<double>(
                value: _nearest(config.pointsPerEuro, const [0.5, 1, 2, 5, 10]),
                items: const [0.5, 1, 2, 5, 10],
                labelBuilder: (v) => '$v pt / €',
                onChanged: notifier.setPointsPerEuro,
              ),
        ],
      ),
    );
  }
}

class _ConditionsStep extends StatelessWidget {
  const _ConditionsStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Conditions supplémentaires',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            _ToggleRow(
              label: 'Montant minimum par passage',
              value: config.minimumPerVisitEnabled,
              onChanged: notifier.setMinimumPerVisitEnabled,
            ),
            if (config.minimumPerVisitEnabled)
              _DropdownCard<double>(
                value: _nearest(
                  config.minimumPerVisitEuros ?? 50,
                  const [10, 20, 30, 50, 75, 100],
                ),
                items: const [10, 20, 30, 50, 75, 100],
                labelBuilder: (v) => '$v € minimum',
                onChanged: (v) => notifier.setMinimumPerVisitEuros(v),
              ),
            const SizedBox(height: 16),
            _ToggleRow(
              label: 'La récompense a une durée de validité',
              value: config.rewardValidityEnabled,
              onChanged: notifier.setRewardValidityEnabled,
            ),
            if (config.rewardValidityEnabled)
              _DropdownCard<int>(
                value: _nearest(
                  config.rewardValidityDays ?? 30,
                  const [7, 14, 30, 60, 90, 365],
                ),
                items: const [7, 14, 30, 60, 90, 365],
                labelBuilder: (v) => '$v jours',
                onChanged: (v) => notifier.setRewardValidityDays(v),
              ),
        ],
      ),
    );
  }
}

class _ValidationStep extends StatelessWidget {
  const _ValidationStep({
    required this.value,
    required this.onChanged,
  });

  final LoyaltyPassageValidation value;
  final ValueChanged<LoyaltyPassageValidation> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepSection(
      question: 'Comment valider les passages clients ?',
      child: Column(
        children: [
          _ChoiceTile(
            title: 'Automatique',
            selected: value == LoyaltyPassageValidation.automatic,
            onTap: () => onChanged(LoyaltyPassageValidation.automatic),
          ),
          _ChoiceTile(
            title: 'Manuelle',
            subtitle: 'À traiter depuis l\'écran Rappels',
            selected: value == LoyaltyPassageValidation.manual,
            onTap: () => onChanged(LoyaltyPassageValidation.manual),
          ),
        ],
      ),
    );
  }
}

class _ClientAmountStep extends StatelessWidget {
  const _ClientAmountStep({
    required this.config,
    required this.notifier,
  });

  final LoyaltyProgramConfig config;
  final LoyaltyProgramEditingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final forced = config.clientMustEnterPurchaseAmount;
    return _StepSection(
      question: 'Saisie du montant par le client',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (forced)
            Text(
              'Obligatoire avec votre configuration (cumul d\'achats ou points fidélité).',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            )
          else ...[
            Text(
              'Souhaitez-vous que le client saisisse le montant à chaque passage ?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantColors.textLightGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _ToggleRow(
              label: 'Demander le montant de l\'achat',
              value: config.optionalAskClientPurchaseAmount,
              onChanged: notifier.setOptionalAskClientPurchaseAmount,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.question,
    required this.child,
  });

  final String question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          question,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? MerchantColors.gold
                    : MerchantColors.gold.withValues(alpha: 0.35),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textLightGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: MerchantColors.darkOverlay,
            activeTrackColor: MerchantColors.gold,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF6B5B4F),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.5),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: MerchantColors.bgHeader,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            iconEnabledColor: MerchantColors.gold,
            items: items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(labelBuilder(e)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

/// Inset card when « Produit offert » is selected — matches dropdown panels visually.
class _FreeProductRewardPanel extends StatelessWidget {
  const _FreeProductRewardPanel({
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.55),
          ),
          color: MerchantColors.bgHeader.withValues(alpha: 0.35),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: MerchantColors.gold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.redeem_outlined,
                    color: MerchantColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Libellé côté client',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ce texte apparaît dans l’aperçu fidélité et résume l’avantage '
                        '(ex. nom d’un plat, d’une boisson).',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.textLightGrey,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _FreeProductNameField(
              initialText: initialText,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeProductNameField extends StatefulWidget {
  const _FreeProductNameField({
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_FreeProductNameField> createState() => _FreeProductNameFieldState();
}

class _FreeProductNameFieldState extends State<_FreeProductNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void didUpdateWidget(covariant _FreeProductNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 160, top: 48),
      maxLength: 80,
      buildCounter: (
        context, {
        required currentLength,
        required isFocused,
        maxLength,
      }) {
        if (maxLength == null) return null;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$currentLength / $maxLength',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textLightGrey.withValues(alpha: 0.85),
            ),
          ),
        );
      },
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Nom du produit offert',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.outfit(
          color: MerchantColors.gold.withValues(alpha: 0.95),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintText: 'Ex. : Café, pizza margherita, dessert du jour…',
        hintStyle: GoogleFonts.outfit(
          color: MerchantColors.textLightGrey,
          fontSize: 13,
        ),
        filled: true,
        fillColor: MerchantColors.bgMain.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantColors.gold, width: 1.75),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
