import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/shared/constants/merchant_colors.dart';
import '../../../../../core/utils/cities.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';

/// "Villes connectées" – shows only cities stored in DB; add saves to DB.
class CitiesSection extends ConsumerStatefulWidget {
  const CitiesSection({super.key});

  @override
  ConsumerState<CitiesSection> createState() => _CitiesSectionState();
}

class _CitiesSectionState extends ConsumerState<CitiesSection> {
  void _openAddCityPicker(BuildContext context, String uid, List<String> current) {
    final available = frenchCities
        .where((c) => !current.any((x) => x.toLowerCase() == c.toLowerCase()))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ajouter une ville connectée',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: available.length,
                    itemBuilder: (_, i) {
                      final city = available[i];
                      return ListTile(
                        title: Text(
                          city,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          final newList = [...current, city];
                          final setCities =
                              ref.read(auth_providers.setConnectedCitiesProvider);
                          await setCities.call(uid: uid, cities: newList);
                          if (mounted) {
                            ref.invalidate(
                              auth_providers.connectedCitiesProvider(uid),
                            );
                          }
                        },
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(auth_providers.authStateProvider);
    if (authState is! Authenticated) {
      return _buildSection(context, [], null);
    }

    final uid = authState.user.id;
    final citiesAsync = ref.watch(auth_providers.connectedCitiesProvider(uid));

    return citiesAsync.when(
      data: (cities) =>
          _buildSection(context, cities, uid),
      loading: () => _buildSection(context, [], uid),
      error: (_, __) => _buildSection(context, [], uid),
    );
  }

  Widget _buildSection(
    BuildContext context,
    List<String> cities,
    String? uid,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ville(s) connectée(s)',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...cities.map((name) => _buildPill(name)),
              _buildAddButton(uid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: MerchantColors.darkOverlay,
        ),
      ),
    );
  }

  Widget _buildAddButton(String? uid) {
    return GestureDetector(
      onTap: uid == null
          ? null
          : () {
              final cities = ref
                  .read(auth_providers.connectedCitiesProvider(uid))
                  .value ?? [];
              _openAddCityPicker(context, uid, cities);
            },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: MerchantColors.gold, width: 2),
        ),
        child: const Icon(Icons.add, color: MerchantColors.gold, size: 20),
      ),
    );
  }
}
