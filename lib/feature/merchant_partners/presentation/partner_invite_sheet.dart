import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../application/providers.dart' as partners_providers;
import '../domain/entities/merchant_partner.dart';

/// Full-screen bottom sheet — merchant searches all businesses by name
/// and picks one to add as a partner.
/// Returns the selected [MerchantPartner] or null if dismissed.
class PartnerInviteSheet extends ConsumerStatefulWidget {
  const PartnerInviteSheet({
    super.key,
    required this.merchantId,
    this.initialTypeFilter,
  });

  final String merchantId;
  final String? initialTypeFilter;

  @override
  ConsumerState<PartnerInviteSheet> createState() =>
      _PartnerInviteSheetState();
}

class _PartnerInviteSheetState extends ConsumerState<PartnerInviteSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    setState(() {
      _query = v.trim();
      if (_query.isEmpty) {
        _results = [];
        _loading = false;
      } else {
        _loading = true;
      }
    });
    if (_query.length >= 2) {
      _debounce =
          Timer(const Duration(milliseconds: 350), () => _search(_query));
    }
  }

  Future<void> _search(String q) async {
    try {
      final snap = await partners_providers.searchMerchantsProvider(q);
      if (mounted && _query == q) setState(() => _results = snap);
    } catch (_) {
      if (mounted && _query == q) setState(() => _results = []);
    } finally {
      if (mounted && _query == q) setState(() => _loading = false);
    }
  }

  void _select(Map<String, dynamic> m) {
    final partner = MerchantPartner(
      id: '',
      merchantId: widget.merchantId,
      partnerMerchantId: m['id'] as String,
      partnerName: m['name'] as String,
      partnerLogoUrl: m['logoUrl'] as String?,
      partnerCity: m['city'] as String?,
      partnerMerchantType: m['merchantType'] as String?,
      addedAt: DateTime.now(),
      isPending: false,
    );
    Navigator.of(context).pop(partner);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: MerchantColors.bgMain,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ajouter un partenaire',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Ce commerce apparaîtra dans l\'onglet Recommandés\nde vos clients fidèles.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onChanged,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: Colors.white),
              cursorColor: MerchantColors.gold,
              decoration: InputDecoration(
                hintText: 'Nom du commerce…',
                hintStyle: GoogleFonts.outfit(
                    fontSize: 15, color: MerchantColors.textGrey),
                prefixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: MerchantColors.gold, strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search_rounded,
                        color: MerchantColors.gold, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          _onChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: MerchantColors.textGrey, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: MerchantColors.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: MerchantColors.gold.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: MerchantColors.gold, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Results
          Expanded(
            child: _buildBody(bottom),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double bottomInset) {
    if (_query.isEmpty) {
      return _buildHint(
        icon: Icons.storefront_rounded,
        message: 'Tapez le nom d\'un commerce\npour le trouver',
      );
    }
    if (_query.length < 2) {
      return _buildHint(
        icon: Icons.search_rounded,
        message: 'Continuez à taper…',
      );
    }
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: MerchantColors.gold, strokeWidth: 2),
        ),
      );
    }
    if (_results.isEmpty) {
      return _buildHint(
        icon: Icons.search_off_rounded,
        message: 'Aucun résultat pour\n"$_query"',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 32),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ResultTile(
        data: _results[i],
        onTap: () => _select(_results[i]),
      ),
    );
  }

  Widget _buildHint({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 40,
              color: MerchantColors.gold.withValues(alpha: 0.35)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantColors.textGrey,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '';
    final city = data['city'] as String? ?? '';
    final logoUrl = data['logoUrl'] as String?;
    final type = data['merchantType'] as String?;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 46,
                height: 46,
                color: MerchantColors.gold.withValues(alpha: 0.1),
                child: logoUrl != null && logoUrl.isNotEmpty
                    ? Image.network(logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 13),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (city.isNotEmpty) ...[
                        const Icon(Icons.location_on_rounded,
                            size: 11,
                            color: MerchantColors.textGrey),
                        const SizedBox(width: 3),
                        Text(
                          city,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (type == 'b2b' || type == 'b2c')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                MerchantColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: MerchantColors.gold
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            type == 'b2b' ? 'Pro' : 'Grand public',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MerchantColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Add button
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: MerchantColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(Icons.add_rounded,
                  color: MerchantColors.gold, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Icon(Icons.store_rounded,
      color: MerchantColors.gold, size: 22);
}

/// Compact B2B / B2C badge shown next to a merchant name.
class PartnerMerchantTypeBadge extends StatelessWidget {
  const PartnerMerchantTypeBadge({super.key, required this.type});

  final String? type;

  @override
  Widget build(BuildContext context) {
    if (type != 'b2b' && type != 'b2c') return const SizedBox.shrink();
    final label = type == 'b2b' ? 'B2B' : 'B2C';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MerchantColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: MerchantColors.gold,
        ),
      ),
    );
  }
}
