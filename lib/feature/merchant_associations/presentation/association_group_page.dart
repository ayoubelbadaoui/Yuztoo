import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../application/providers.dart';
import '../domain/entities/association_member.dart';
import '../domain/entities/merchant_association.dart';

/// Client-facing group page: the association and every approved member shop.
///
/// Opened from the association row on a merchant vitrine. Tapping a member
/// hands its merchant id back to the caller, which opens that vitrine —
/// keeps this screen free of any routing knowledge.
class AssociationGroupPage extends ConsumerWidget {
  const AssociationGroupPage({
    super.key,
    required this.association,
    this.onOpenMerchant,
  });

  final MerchantAssociation association;

  /// Called with the member's merchant id when a shop row is tapped.
  final ValueChanged<String>? onOpenMerchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref
            .watch(approvedAssociationMembersProvider(association.id))
            .valueOrNull ??
        const <AssociationMember>[];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: Text(
            association.name,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MerchantColors.gold.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: MerchantColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (association.city.isNotEmpty) association.city,
                          '${members.length} commerce'
                              '${members.length > 1 ? 's' : ''}',
                        ].join(' · '),
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (association.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text(
                association.description!,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: const Color(0xFF4A4A4A),
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'LES COMMERCES DE L\'ASSOCIATION',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF8A8A8A),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              Text(
                'Aucun commerce membre pour l\'instant.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF6B6B6B),
                ),
              )
            else
              ...members.map(
                (member) => _ClientMemberTile(
                  member: member,
                  onTap: onOpenMerchant == null
                      ? null
                      : () => onOpenMerchant!.call(member.merchantId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClientMemberTile extends StatelessWidget {
  const _ClientMemberTile({required this.member, this.onTap});

  final AssociationMember member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: MerchantColors.gold.withValues(alpha: 0.12),
                  backgroundImage: (member.merchantLogoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(member.merchantLogoUrl!)
                      : null,
                  child: (member.merchantLogoUrl?.isNotEmpty ?? false)
                      ? null
                      : const Icon(Icons.storefront_outlined,
                          color: MerchantColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.merchantName.isEmpty
                            ? 'Commerce'
                            : member.merchantName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      if (member.merchantCity?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          member.merchantCity!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: MerchantColors.gold, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
