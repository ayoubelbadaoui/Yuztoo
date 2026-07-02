part of 'e_fidelite_screen.dart';

/// Compact "edit everything from one screen" form for an existing loyalty
/// programme. Replaces the step-by-step wizard when the merchant taps
/// "Modifier le programme" from the recap: every option is a single dropdown
/// (or a toggle), so a tweak is one tap instead of walking the whole wizard.
class LoyaltyQuickEditForm extends ConsumerStatefulWidget {
  const LoyaltyQuickEditForm({super.key});

  @override
  ConsumerState<LoyaltyQuickEditForm> createState() =>
      _LoyaltyQuickEditFormState();
}

class _LoyaltyQuickEditFormState extends ConsumerState<LoyaltyQuickEditForm> {
  late final TextEditingController _freeProductController;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(loyaltyProgramEditingProvider);
    _freeProductController =
        TextEditingController(text: cfg.freeProductSummaryLabel ?? '');
  }

  @override
  void dispose() {
    _freeProductController.dispose();
    super.dispose();
  }

  LoyaltyProgramEditingNotifier get _notifier =>
      ref.read(loyaltyProgramEditingProvider.notifier);

  static String _fmt(num n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  static List<int> _withInt(List<int> base, int current) {
    final s = <int>{...base, if (current > 0) current}.toList()..sort();
    return s;
  }

  static List<double> _withDouble(List<double> base, double current) {
    final s = <double>{...base, if (current > 0) current}.toList()..sort();
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(loyaltyProgramEditingProvider);
    final isVisit = config.triggerType == LoyaltyTriggerType.visitCount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuickEditSwitchTile(
            icon: Icons.power_settings_new_rounded,
            label: 'Programme actif',
            helper: config.programEnabled
                ? 'Visible sur votre vitrine.'
                : 'Masqué : aucune offre côté client.',
            value: config.programEnabled,
            onChanged: (v) => _notifier.setProgramEnabled(v),
          ),

          _sectionLabel('Condition pour gagner'),
          _QuickEditDropdownTile<LoyaltyTriggerType>(
            icon: Icons.flag_rounded,
            label: 'Déclencheur',
            helper: 'Comment le client débloque la récompense.',
            value: config.triggerType,
            items: const [
              DropdownMenuItem(
                value: LoyaltyTriggerType.visitCount,
                child: Text('Nombre de passages'),
              ),
              DropdownMenuItem(
                value: LoyaltyTriggerType.purchaseTotal,
                child: Text('Montant d\'achats cumulé'),
              ),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setTriggerType(v);
            },
          ),
          if (isVisit)
            _QuickEditDropdownTile<int>(
              icon: Icons.repeat_rounded,
              label: 'Passages requis',
              helper: 'Visites validées avant la récompense.',
              value: config.visitsRequired,
              items: [
                for (final n in _withInt(
                    const [3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20, 25, 30],
                    config.visitsRequired))
                  DropdownMenuItem(value: n, child: Text('$n passages')),
              ],
              onChanged: (v) {
                if (v != null) _notifier.setVisitsRequired(v);
              },
            )
          else
            _QuickEditDropdownTile<double>(
              icon: Icons.euro_rounded,
              label: 'Montant cumulé requis',
              helper: 'Total d\'achats avant la récompense.',
              value: config.cumulativeSpendRequiredEuros,
              items: [
                for (final n in _withDouble(
                    const [50, 100, 150, 200, 250, 300, 500, 1000],
                    config.cumulativeSpendRequiredEuros))
                  DropdownMenuItem(value: n, child: Text('${_fmt(n)} €')),
              ],
              onChanged: (v) {
                if (v != null) _notifier.setCumulativeSpendRequiredEuros(v);
              },
            ),

          _sectionLabel('Récompense'),
          _QuickEditDropdownTile<LoyaltyRewardKind>(
            icon: Icons.card_giftcard_rounded,
            label: 'Type de récompense',
            value: config.rewardKind,
            items: const [
              DropdownMenuItem(
                value: LoyaltyRewardKind.purchaseVoucher,
                child: Text('Bon d\'achat'),
              ),
              DropdownMenuItem(
                value: LoyaltyRewardKind.discountPercent,
                child: Text('Remise %'),
              ),
              DropdownMenuItem(
                value: LoyaltyRewardKind.freeProduct,
                child: Text('Produit offert'),
              ),
              DropdownMenuItem(
                value: LoyaltyRewardKind.loyaltyPoints,
                child: Text('Points fidélité'),
              ),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setRewardKind(v);
            },
          ),
          ..._rewardValueFields(config),

          _sectionLabel('Validation des passages'),
          _QuickEditDropdownTile<LoyaltyPassageValidation>(
            icon: Icons.verified_rounded,
            label: 'Mode de validation',
            helper: config.passageValidation ==
                    LoyaltyPassageValidation.automatic
                ? 'Le passage est validé automatiquement au scan.'
                : 'Vous validez chaque passage depuis Rappels.',
            value: config.passageValidation,
            items: const [
              DropdownMenuItem(
                value: LoyaltyPassageValidation.automatic,
                child: Text('Automatique'),
              ),
              DropdownMenuItem(
                value: LoyaltyPassageValidation.manual,
                child: Text('Manuelle'),
              ),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setPassageValidation(v);
            },
          ),

          _sectionLabel('Options'),
          _QuickEditSwitchTile(
            icon: Icons.price_check_rounded,
            label: 'Minimum par passage',
            helper: 'Exiger un montant d\'achat minimum par visite.',
            value: config.minimumPerVisitEnabled,
            onChanged: (v) {
              _notifier.setMinimumPerVisitEnabled(v);
              if (v &&
                  (config.minimumPerVisitEuros == null ||
                      config.minimumPerVisitEuros! <= 0)) {
                _notifier.setMinimumPerVisitEuros(50);
              }
            },
          ),
          if (config.minimumPerVisitEnabled)
            _QuickEditDropdownTile<double>(
              icon: Icons.euro_rounded,
              label: 'Montant minimum',
              value: (config.minimumPerVisitEuros ?? 50)
                  .clamp(1, 1e6)
                  .toDouble(),
              items: [
                for (final n in _withDouble(const [5, 10, 20, 30, 50, 100],
                    (config.minimumPerVisitEuros ?? 50).toDouble()))
                  DropdownMenuItem(value: n, child: Text('${_fmt(n)} €')),
              ],
              onChanged: (v) {
                if (v != null) _notifier.setMinimumPerVisitEuros(v);
              },
            ),
          _QuickEditSwitchTile(
            icon: Icons.event_busy_rounded,
            label: 'Validité de la récompense',
            helper: 'Limiter la durée d\'utilisation après obtention.',
            value: config.rewardValidityEnabled,
            onChanged: (v) {
              _notifier.setRewardValidityEnabled(v);
              if (v &&
                  (config.rewardValidityDays == null ||
                      config.rewardValidityDays! <= 0)) {
                _notifier.setRewardValidityDays(30);
              }
            },
          ),
          if (config.rewardValidityEnabled)
            _QuickEditDropdownTile<int>(
              icon: Icons.schedule_rounded,
              label: 'À utiliser sous',
              value: (config.rewardValidityDays ?? 30).clamp(1, 3650),
              items: [
                for (final n in _withInt(const [7, 15, 30, 60, 90, 180, 365],
                    config.rewardValidityDays ?? 30))
                  DropdownMenuItem(value: n, child: Text('$n jours')),
              ],
              onChanged: (v) {
                if (v != null) _notifier.setRewardValidityDays(v);
              },
            ),
          if (!config.clientMustEnterPurchaseAmount)
            _QuickEditSwitchTile(
              icon: Icons.edit_note_rounded,
              label: 'Demander le montant au client',
              helper: 'Le client saisit son montant d\'achat à chaque passage.',
              value: config.optionalAskClientPurchaseAmount,
              onChanged: (v) =>
                  _notifier.setOptionalAskClientPurchaseAmount(v),
            ),

          const SizedBox(height: 24),
          _ClientPreviewCard(text: config.clientSummaryText),
        ],
      ),
    );
  }

  List<Widget> _rewardValueFields(LoyaltyProgramConfig config) {
    switch (config.rewardKind) {
      case LoyaltyRewardKind.purchaseVoucher:
        return [
          _QuickEditDropdownTile<bool>(
            icon: Icons.tune_rounded,
            label: 'Valeur du bon',
            value: config.purchaseVoucherUsesPercent,
            items: const [
              DropdownMenuItem(value: true, child: Text('En pourcentage (%)')),
              DropdownMenuItem(value: false, child: Text('En euros (€)')),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setPurchaseVoucherUsesPercent(v);
            },
          ),
          _QuickEditDropdownTile<double>(
            icon: config.purchaseVoucherUsesPercent
                ? Icons.percent_rounded
                : Icons.euro_rounded,
            label: 'Montant du bon',
            value: config.purchaseVoucherValue.clamp(0.5, 1000).toDouble(),
            items: [
              for (final n in _withDouble(
                  config.purchaseVoucherUsesPercent
                      ? const [5, 10, 15, 20, 25, 30, 50]
                      : const [5, 10, 15, 20, 25, 50, 100],
                  config.purchaseVoucherValue))
                DropdownMenuItem(
                  value: n,
                  child: Text(
                    config.purchaseVoucherUsesPercent
                        ? '${_fmt(n)} %'
                        : '${_fmt(n)} €',
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setPurchaseVoucherValue(v);
            },
          ),
        ];
      case LoyaltyRewardKind.discountPercent:
        return [
          _QuickEditDropdownTile<double>(
            icon: Icons.percent_rounded,
            label: 'Remise',
            helper: 'Sur le prochain achat.',
            value: config.discountNextPurchasePercent.clamp(0.5, 100).toDouble(),
            items: [
              for (final n in _withDouble(const [5, 10, 15, 20, 25, 30, 50],
                  config.discountNextPurchasePercent))
                DropdownMenuItem(value: n, child: Text('${_fmt(n)} %')),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setDiscountNextPurchasePercent(v);
            },
          ),
        ];
      case LoyaltyRewardKind.freeProduct:
        return [
          _QuickEditFieldTile(
            icon: Icons.redeem_rounded,
            label: 'Produit offert',
            helper: 'Décrivez ce que le client reçoit.',
            controller: _freeProductController,
            hintText: 'Ex : un café offert',
            onChanged: (v) => _notifier.setFreeProductSummaryLabel(v),
          ),
        ];
      case LoyaltyRewardKind.loyaltyPoints:
        return [
          _QuickEditDropdownTile<double>(
            icon: Icons.stars_rounded,
            label: 'Points par euro',
            helper: 'Points crédités pour 1 € dépensé.',
            value: config.pointsPerEuro.clamp(0.1, 1000).toDouble(),
            items: [
              for (final n in _withDouble(
                  const [0.5, 1, 2, 3, 5, 10], config.pointsPerEuro))
                DropdownMenuItem(value: n, child: Text('${_fmt(n)} pt / €')),
            ],
            onChanged: (v) {
              if (v != null) _notifier.setPointsPerEuro(v);
            },
          ),
        ];
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MerchantColors.gold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Shared card chrome for every quick-edit row.
class _QuickEditTileShell extends StatelessWidget {
  const _QuickEditTileShell({
    required this.icon,
    required this.label,
    required this.trailing,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: MerchantColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper!,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: MerchantColors.textLightGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _QuickEditDropdownTile<T> extends StatelessWidget {
  const _QuickEditDropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _QuickEditTileShell(
      icon: icon,
      label: label,
      helper: helper,
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 168),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: MerchantColors.bgMain,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isDense: true,
            isExpanded: true,
            dropdownColor: MerchantColors.bgHeader,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: MerchantColors.gold,
            ),
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickEditSwitchTile extends StatelessWidget {
  const _QuickEditSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _QuickEditTileShell(
      icon: icon,
      label: label,
      helper: helper,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: MerchantColors.bgHeader,
        activeTrackColor: MerchantColors.gold,
        inactiveThumbColor: MerchantColors.textLightGrey,
        inactiveTrackColor: MerchantColors.bgMain,
      ),
    );
  }
}

class _QuickEditFieldTile extends StatelessWidget {
  const _QuickEditFieldTile({
    required this.icon,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.helper,
    this.hintText,
  });

  final IconData icon;
  final String label;
  final String? helper;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: MerchantColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (helper != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        helper!,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: MerchantColors.textLightGrey,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
            cursorColor: MerchantColors.gold,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.outfit(
                fontSize: 13.5,
                color: MerchantColors.textLightGrey,
              ),
              filled: true,
              fillColor: MerchantColors.bgMain,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: MerchantColors.gold, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientPreviewCard extends StatelessWidget {
  const _ClientPreviewCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: MerchantColors.bgHeader.withValues(alpha: 0.55),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded,
                  size: 16, color: MerchantColors.gold),
              const SizedBox(width: 6),
              Text(
                'Aperçu côté client',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
