part of 'personal_information_screen.dart';

extension _PersonalInformationScreenUi on PersonalInformationScreen {
  Widget _buildPersonalInformationScaffold(
    BuildContext context, {
    required String fullName,
    required String email,
    required String phone,
    required String city,
    required int completionPercent,
    bool hasPhoto = false,
  }) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
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
            Container(
              color: MerchantColors.bgHeader,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: MerchantColors.bgHeader,
                    border: Border(
                      bottom: BorderSide(
                        color: MerchantColors.gold.withValues(
                            alpha: MerchantColors.goldBorderStronger),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: MerchantColors.gold, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: MerchantColors.gold,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informations personnelles',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: MerchantColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityCard(fullName, email, phone),
                    const SizedBox(height: 24),
                    Text(
                      'Villes connectées',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MerchantColors.textWhite,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _CitiesWidget(),
                    const SizedBox(height: 24),
                    // Yuztoo card visual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0B2540), Color(0xFF0E2A44)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: MerchantColors.gold.withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFFF5F5F5),
                                    Color(0xFFD4A017),
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  'yuztoo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: MerchantColors.gold.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: MerchantColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    avatarInitial(fullName.isNotEmpty ? fullName : 'U'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: MerchantColors.gold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            fullName.isNotEmpty ? fullName : 'Client Yuztoo',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: MerchantColors.textWhite,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Carte Fidélité · Membre',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Profil complété à',
                          style: GoogleFonts.outfit(
                            color: MerchantColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: completionPercent == 100
                                ? MerchantColors.gold
                                : MerchantColors.bgHeader,
                            borderRadius: BorderRadius.circular(14),
                            border: completionPercent < 100
                                ? Border.all(
                                    color: MerchantColors.gold
                                        .withValues(alpha: 0.5))
                                : null,
                          ),
                          child: Text(
                            '$completionPercent%',
                            style: GoogleFonts.outfit(
                              color: completionPercent == 100
                                  ? MerchantColors.bgHeader
                                  : MerchantColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completionPercent / 100.0,
                        minHeight: 6,
                        backgroundColor:
                            MerchantColors.gold.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completionPercent == 100
                              ? MerchantColors.gold
                              : MerchantColors.gold.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    if (!hasPhoto) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: MerchantColors.gold.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Ajoute une photo de profil pour compléter à 100\u202f%',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: MerchantColors.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: -2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Créer un compte pro',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: MerchantColors.bgHeader,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(String name, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarInitial(name),
              style: GoogleFonts.outfit(
                color: MerchantColors.textWhite,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tél : $phone',
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textLightGrey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitiesWidget extends ConsumerStatefulWidget {
  const _CitiesWidget();

  @override
  ConsumerState<_CitiesWidget> createState() => _CitiesWidgetState();
}

class _CitiesWidgetState extends ConsumerState<_CitiesWidget> {
  void _openAddCityPicker(BuildContext context, String uid, List<String> current) {
    final available = frenchCities
        .where((c) => !current.any((x) => x.toLowerCase() == c.toLowerCase()))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MerchantColors.gold.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    'Ajouter une ville connectée',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                ),
                Flexible(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: available.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: MerchantColors.gold.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (_, i) {
                      final city = available[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          final newList = [...current, city];
                          final result = await ref
                              .read(setConnectedCitiesProvider)
                              .call(uid: uid, cities: newList);
                          if (!context.mounted) return;
                          result.fold(
                            (f) => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(f.message)),
                            ),
                            (_) => ref.invalidate(connectedCitiesProvider(uid)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: MerchantColors.gold.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                city,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: MerchantColors.textWhite,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: MerchantColors.gold.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeCity(String uid, String cityName, List<String> current) async {
    if (current.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez avoir au moins une ville.')),
      );
      return;
    }
    final updated = current.where((c) => c != cityName).toList();
    final result = await ref
        .read(setConnectedCitiesProvider)
        .call(uid: uid, cities: updated);
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) => ref.invalidate(connectedCitiesProvider(uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final uid = authState.user.id;
    final cities = ref.watch(connectedCitiesProvider(uid)).value ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...cities.map(
          (name) => _buildPill(name, uid, cities),
        ),
        GestureDetector(
          onTap: () => _openAddCityPicker(context, uid, cities),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MerchantColors.gold, width: 2),
            ),
            child: const Icon(Icons.add_rounded, color: MerchantColors.gold, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String name, String uid, List<String> current) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MerchantColors.bgHeader,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeCity(uid, name, current),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: MerchantColors.bgHeader, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
