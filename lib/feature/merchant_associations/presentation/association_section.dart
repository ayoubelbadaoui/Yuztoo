import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../application/providers.dart';
import '../domain/entities/association_member.dart';
import 'association_detail_screen.dart';
import 'create_association_sheet.dart';
import 'join_association_sheet.dart';

/// **Promotions → Association de commerçants.**
///
/// Shows one of three states: no association (create / join), a pending
/// request, or the association the merchant belongs to.
class AssociationSection extends ConsumerWidget {
  const AssociationSection({super.key, required this.merchant});

  final Merchant? merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantId = merchant?.id ?? '';
    if (merchantId.isEmpty) return const SizedBox.shrink();

    final memberships =
        ref.watch(merchantAssociationMembershipsProvider(merchantId));

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Association de commerçants',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded,
                              size: 11, color: MerchantColors.gold),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Vous pouvez rejoindre plusieurs associations',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: MerchantColors.textGrey,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: MerchantColors.gold.withValues(alpha: 0.1),
          ),
          memberships.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
            ),
            error: (_, __) => const _Message(
              text: 'Impossible de charger vos associations.',
            ),
            data: (list) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isEmpty)
                    _NoAssociationActions(merchant: merchant!)
                  else ...[
                    for (final value in list)
                      if (value.member.isPending)
                        _PendingRequest(
                            membership: value, merchant: merchant!)
                      else
                        _MemberOfAssociation(
                            membership: value, merchant: merchant!),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Créer',
                              icon: Icons.add_circle_outline_rounded,
                              filled: false,
                              onTap: () =>
                                  showCreateAssociationSheet(context, merchant!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Rejoindre une autre',
                              icon: Icons.search_rounded,
                              filled: true,
                              onTap: () =>
                                  showJoinAssociationSheet(context, merchant!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          color: MerchantColors.textGrey,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NoAssociationActions extends StatelessWidget {
  const _NoAssociationActions({required this.merchant});

  final Merchant merchant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Regroupez-vous avec les commerces de votre quartier ou de votre '
            'ville pour gagner en visibilité.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Créer',
                  icon: Icons.add_circle_outline_rounded,
                  filled: true,
                  onTap: () => showCreateAssociationSheet(context, merchant),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Rejoindre',
                  icon: Icons.search_rounded,
                  filled: false,
                  onTap: () => showJoinAssociationSheet(context, merchant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingRequest extends ConsumerWidget {
  const _PendingRequest({required this.membership, required this.merchant});

  final MerchantAssociationMembership membership;
  final Merchant merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: MerchantColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.association.name,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Demande envoyée — en attente de validation.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ActionButton(
            label: 'Annuler ma demande',
            icon: Icons.close_rounded,
            filled: false,
            onTap: () async {
              await ref
                  .read(merchantAssociationRepositoryProvider)
                  .removeMember(
                    associationId: membership.association.id,
                    merchantId: merchant.id,
                  );
            },
          ),
        ],
      ),
    );
  }
}

class _MemberOfAssociation extends ConsumerWidget {
  const _MemberOfAssociation({
    required this.membership,
    required this.merchant,
  });

  final MerchantAssociationMembership membership;
  final Merchant merchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final association = membership.association;
    final isFounder = association.isFoundedBy(merchant.id);
    final members =
        ref.watch(associationMembersProvider(association.id)).valueOrNull ??
            const <AssociationMember>[];
    final pendingCount = members.where((m) => m.isPending).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AssociationDetailScreen(
              associationId: association.id,
              viewerMerchantId: merchant.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MerchantColors.gold.withValues(alpha: 0.1),
                  border: Border.all(
                    color: MerchantColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: MerchantColors.gold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      association.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        '${association.memberCount} commerce'
                            '${association.memberCount > 1 ? 's' : ''}',
                        if (isFounder) 'Vous êtes administrateur',
                      ].join(' · '),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFounder && pendingCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: MerchantColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: MerchantColors.bgMain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded,
                  color: MerchantColors.gold, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? MerchantColors.gold.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  MerchantColors.gold.withValues(alpha: filled ? 0.55 : 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: MerchantColors.gold),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
