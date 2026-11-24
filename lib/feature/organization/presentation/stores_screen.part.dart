part of 'stores_screen.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: MerchantColors.textGrey,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Multi-store is shown with sample data until it is wired to Firestore.
class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MerchantColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_rounded,
            color: MerchantColors.gold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aperçu · données d\'exemple. Chaque point de vente aura sa '
              'propre vitrine. Les gérants invitée·s accéderont aux PDV '
              'qui leur sont assignés depuis leur compte.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.goldLight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({bool highlighted = false}) => BoxDecoration(
      color: MerchantColors.navyCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: MerchantColors.gold.withValues(alpha: highlighted ? 0.9 : 0.2),
        width: highlighted ? 1.5 : 1,
      ),
    );

class _GoldOutlinedButton extends StatelessWidget {
  const _GoldOutlinedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label:
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: MerchantColors.gold,
        side: BorderSide(color: MerchantColors.gold.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GoldFilledButton extends StatelessWidget {
  const _GoldFilledButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: MerchantColors.gold,
        foregroundColor: MerchantColors.bgHeader,
        disabledBackgroundColor: MerchantColors.gold.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.demo, required this.onLoyaltyTap});

  final MultiStoreDemoState demo;
  final VoidCallback onLoyaltyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: MerchantColors.gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demo.brandName,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Enseigne · ${demo.stores.length} points de vente',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onLoyaltyTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MerchantColors.bgMain,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.loyalty_rounded,
                    color: MerchantColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loyaltyModeLabel(demo.loyaltyMode),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Modifier',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MerchantColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkStats extends StatelessWidget {
  const _NetworkStats({required this.demo});

  final MultiStoreDemoState demo;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('TOUS LES POINTS DE VENTE · CE MOIS'),
        const SizedBox(height: 10),
        Row(
          children: [
            stat('${demo.totalClients}', 'Clients'),
            const SizedBox(width: 10),
            stat('${demo.totalPassages}', 'Passages'),
            const SizedBox(width: 10),
            stat('${demo.totalRewards}', 'Récompenses'),
          ],
        ),
      ],
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.store,
    required this.brandName,
    required this.isActive,
    required this.onTap,
    required this.onToggleOnline,
    this.onOpenVitrine,
  });

  final DemoStore store;
  final String brandName;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleOnline;
  final VoidCallback? onOpenVitrine;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        store.isOnline ? const Color(0xFF3FBF7F) : MerchantColors.textGrey;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(highlighted: isActive),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isActive
                        ? MerchantColors.gold
                        : MerchantColors.textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.label,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${store.address}, ${store.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleOnline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: statusColor),
                          const SizedBox(width: 5),
                          Text(
                            store.isOnline ? 'En ligne' : 'Hors ligne',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat(
                      Icons.people_alt_rounded, '${store.clients}', 'clients'),
                  _miniStat(Icons.qr_code_scanner_rounded,
                      '${store.passagesThisMonth}', 'passages'),
                  _miniStat(Icons.card_giftcard_rounded,
                      '${store.rewardsThisMonth}', 'récomp.'),
                ],
              ),
              if (onOpenVitrine != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onOpenVitrine,
                    icon: const Icon(Icons.storefront_rounded, size: 16),
                    label: Text(
                      isActive
                          ? 'Voir la vitrine de ce PDV'
                          : 'Sélectionner et voir la vitrine',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: MerchantColors.gold,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ] else if (isActive) ...[
                const SizedBox(height: 10),
                Text(
                  'Point de vente actif · vitrine, clients et promotions',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MerchantColors.gold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) => Expanded(
        child: Row(
          children: [
            Icon(icon, size: 14, color: MerchantColors.textGrey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$value $label',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textLightGrey,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TeamEntry extends StatelessWidget {
  const _TeamEntry({
    required this.memberCount,
    required this.pendingCount,
    required this.onTap,
  });

  final int memberCount;
  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              const Icon(Icons.groups_rounded, color: MerchantColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gérants et employés',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      pendingCount > 0
                          ? '$memberCount membres · $pendingCount invitation(s) en attente'
                          : '$memberCount membres',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: MerchantColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sheetTitle(String title, String subtitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textGrey,
            height: 1.4,
          ),
        ),
      ],
    );

InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        color: MerchantColors.textGrey.withValues(alpha: 0.7),
      ),
      prefixIcon: Icon(icon, color: MerchantColors.gold, size: 20),
      filled: true,
      fillColor: MerchantColors.bgMain,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

/// Keeps sheet actions above both the keyboard and the system navigation bar.
double _sheetBottomInset(BuildContext context) =>
    MediaQuery.viewInsetsOf(context).bottom +
    MediaQuery.paddingOf(context).bottom +
    24;

Future<T?> _showDarkSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: builder,
    );

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MerchantColors.bgMain,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? MerchantColors.gold
                : MerchantColors.gold.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? MerchantColors.gold : MerchantColors.textGrey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoyaltySheet(BuildContext context, WidgetRef ref) {
  _showDarkSheet<void>(
    context,
    (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final mode = ref.watch(multiStoreDemoProvider).loyaltyMode;
        final notifier = ref.read(multiStoreDemoProvider.notifier);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, _sheetBottomInset(ctx)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetTitle(
                'Programme de fidélité',
                'Comment vos clients cumulent-ils leurs passages ?',
              ),
              const SizedBox(height: 16),
              _ChoiceTile(
                selected: mode == LoyaltyMode.shared,
                title: 'Carte commune',
                subtitle: 'Un passage dans n\'importe quel point de vente '
                    'compte sur la même carte.',
                onTap: () => notifier.setLoyaltyMode(LoyaltyMode.shared),
              ),
              const SizedBox(height: 10),
              _ChoiceTile(
                selected: mode == LoyaltyMode.perStore,
                title: 'Une carte par point de vente',
                subtitle: 'Chaque point de vente a sa propre carte et ses '
                    'propres récompenses.',
                onTap: () => notifier.setLoyaltyMode(LoyaltyMode.perStore),
              ),
              const SizedBox(height: 20),
              _GoldFilledButton(
                label: 'Valider',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _showAddStoreSheet(BuildContext context, WidgetRef ref) async {
  final added = await _showDarkSheet<String>(
    context,
    (_) => const _AddStoreSheet(),
  );
  if (added != null && context.mounted) {
    _snack(
      context,
      '$added ajouté (hors ligne). Complétez sa vitrine puis mettez-le en ligne.',
    );
  }
}

class _AddStoreSheet extends ConsumerStatefulWidget {
  const _AddStoreSheet();

  @override
  ConsumerState<_AddStoreSheet> createState() => _AddStoreSheetState();
}

class _AddStoreSheetState extends ConsumerState<_AddStoreSheet> {
  final _labelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _city;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final commune = await showCitySearchSheet(
      context,
      title: 'Ville du point de vente',
      selectedCity: _city,
      backgroundColor: MerchantColors.bgMain,
    );
    if (commune != null && mounted) setState(() => _city = commune.name);
  }

  void _submit() {
    final city = _city;
    if (city == null) return;
    final notifier = ref.read(multiStoreDemoProvider.notifier);
    notifier.addStore(
      label: _labelCtrl.text,
      city: city,
      address: _addressCtrl.text,
    );
    final demo = ref.read(multiStoreDemoProvider);
    Navigator.of(context).pop(demo.storeName(demo.activeStore));
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(multiStoreDemoProvider).brandName;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        _sheetBottomInset(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetTitle(
              'Nouveau point de vente',
              'Le logo, la catégorie, la description et les horaires de '
                  '$brand sont repris. Vous pourrez tout ajuster ensuite.',
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _pickCity,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: _inputDecoration(
                  'Ville',
                  Icons.location_city_rounded,
                ),
                child: Text(
                  _city ?? 'Choisir une ville',
                  style: GoogleFonts.outfit(
                    color: _city == null
                        ? MerchantColors.textGrey.withValues(alpha: 0.7)
                        : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelCtrl,
              style: GoogleFonts.outfit(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Nom du point de vente (ex. Centre-ville)',
                Icons.label_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: _inputDecoration('Adresse', Icons.place_rounded),
            ),
            const SizedBox(height: 20),
            _GoldFilledButton(
              label: 'Créer le point de vente',
              onPressed: _city == null ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
