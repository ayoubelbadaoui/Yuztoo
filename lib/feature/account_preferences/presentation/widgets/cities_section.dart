import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/shared/constants/merchant_colors.dart';
import '../../../../../core/utils/cities.dart';
import '../../application/providers.dart';

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
      backgroundColor: MerchantColors.navyCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // `filtered` lives in the outer closure so that StatefulBuilder reads
        // the updated reference on each setState call.
        var filtered = available;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Column(
                  children: [
                    // ── Drag handle ──────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: MerchantColors.gold.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        'Ajouter une ville connectée',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // ── Search field ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        autofocus: true,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une ville...',
                          hintStyle: GoogleFonts.outfit(
                            color: MerchantColors.textGrey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: MerchantColors.textGrey,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: MerchantColors.inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (query) {
                          setSheetState(() {
                            filtered = query.trim().isEmpty
                                ? available
                                : available
                                    .where((c) => c
                                        .toLowerCase()
                                        .contains(query.toLowerCase().trim()))
                                    .toList();
                          });
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: MerchantColors.gold.withValues(alpha: 0.12),
                    ),
                    // ── List ─────────────────────────────────────────────────
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Aucune ville trouvée',
                          style: GoogleFonts.outfit(
                            color: MerchantColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final city = filtered[i];
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
                                    ref.read(setConnectedCitiesProvider);
                                final result = await setCities.call(
                                    uid: uid, cities: newList);
                                if (!context.mounted) return;
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          failure.message,
                                          style: GoogleFonts.outfit(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: MerchantColors.navyCard,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  },
                                  (_) {
                                    final auth = ref.read(authStateProvider);
                                    final isMerchant = auth is Authenticated &&
                                        auth.user.isMerchant;
                                    unawaited(refreshUserProfileCacheWidget(
                                      ref,
                                      uid: uid,
                                      isMerchant: isMerchant,
                                      cityChanged: true,
                                    ));
                                  },
                                );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState is! Authenticated) {
      return _buildSection(context, [], null);
    }

    final uid = authState.user.id;
    final citiesAsync = ref.watch(connectedCitiesProvider(uid));

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
            'VILLES CONNECTÉES',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ville(s) où vous êtes visible',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...cities.map((name) => _buildPill(name, uid)),
              _buildAddButton(uid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String name, String? uid) {
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MerchantColors.darkOverlay,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: uid == null ? null : () => _removeCity(uid, name),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: MerchantColors.darkOverlay.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: MerchantColors.darkOverlay, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCity(String uid, String city) async {
    final current =
        ref.read(connectedCitiesProvider(uid)).value ?? [];
    final updated = current.where((c) => c != city).toList();
    final result = await ref.read(setConnectedCitiesProvider).call(
          uid: uid,
          cities: updated,
        );
    if (!context.mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            f.message,
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: MerchantColors.navyCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      (_) {
        final isMerchant = ref.read(authStateProvider) is Authenticated &&
            (ref.read(authStateProvider) as Authenticated).user.isMerchant;
        unawaited(refreshUserProfileCacheWidget(
          ref,
          uid: uid,
          isMerchant: isMerchant,
          cityChanged: true,
        ));
      },
    );
  }

  Widget _buildAddButton(String? uid) {
    return GestureDetector(
      onTap: uid == null
          ? null
          : () {
              final cities = ref
                  .read(connectedCitiesProvider(uid))
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
        child: const Icon(Icons.add_rounded, color: MerchantColors.gold, size: 20),
      ),
    );
  }
}
