import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant_partners/application/providers.dart'
    as partners_providers;
import '../application/providers.dart';
import '../domain/entities/association_member.dart';

Future<void> _showAddMemberSheet(
  BuildContext context,
  WidgetRef ref, {
  required String associationId,
  required Set<String> existingIds,
}) async {
  final ctrl = TextEditingController();
  var results = <Map<String, dynamic>>[];
  var loading = false;
  Timer? debounce;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MerchantColors.bgHeader,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> runSearch(String q) async {
            try {
              final snap = await partners_providers.searchMerchantsProvider(q);
              if (!ctx.mounted) return;
              setModal(() {
                results = snap
                    .where((m) => !existingIds.contains(m['id'] as String? ?? ''))
                    .toList();
                loading = false;
              });
            } catch (_) {
              if (!ctx.mounted) return;
              setModal(() {
                results = [];
                loading = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ajouter un commerce',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.outfit(color: Colors.white),
                  cursorColor: MerchantColors.gold,
                  decoration: InputDecoration(
                    hintText: 'Nom du commerce…',
                    hintStyle: GoogleFonts.outfit(
                      color: MerchantColors.textGrey,
                    ),
                    filled: true,
                    fillColor: MerchantColors.navyCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MerchantColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    debounce?.cancel();
                    final q = v.trim();
                    if (q.length < 2) {
                      setModal(() {
                        results = [];
                        loading = false;
                      });
                      return;
                    }
                    setModal(() => loading = true);
                    debounce = Timer(
                      const Duration(milliseconds: 350),
                      () => runSearch(q),
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: MerchantColors.gold,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (results.isEmpty)
                  Text(
                    ctrl.text.trim().length < 2
                        ? 'Tapez au moins 2 caractères.'
                        : 'Aucun commerce trouvé.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textGrey,
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final m = results[i];
                        final id = (m['id'] as String?) ?? '';
                        final name = (m['display_name'] as String?) ??
                            (m['name'] as String?) ??
                            id;
                        final city = (m['city'] as String?) ?? '';
                        final logo = (m['logoUrl'] as String?) ??
                            (m['logo_url'] as String?);
                        return ListTile(
                          title: Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: city.isEmpty
                              ? null
                              : Text(
                                  city,
                                  style: GoogleFonts.outfit(
                                    color: MerchantColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                          onTap: () async {
                            if (id.isEmpty) return;
                            await ref
                                .read(merchantAssociationRepositoryProvider)
                                .addMemberAsFounder(
                                  associationId: associationId,
                                  merchantId: id,
                                  merchantName: name,
                                  merchantLogoUrl: logo,
                                  merchantCity: city,
                                );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            showSuccessSnackbar(
                              context,
                              '$name ajouté à l\'association',
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
  debounce?.cancel();
  ctrl.dispose();
}

/// Association page for a member merchant.
///
/// The founder additionally gets the pending join requests with approve /
/// refuse actions and can remove a member.
class AssociationDetailScreen extends ConsumerWidget {
  const AssociationDetailScreen({
    super.key,
    required this.associationId,
    required this.viewerMerchantId,
  });

  final String associationId;
  final String viewerMerchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership =
        ref.watch(merchantAssociationMembershipProvider(viewerMerchantId));
    final association = membership.valueOrNull?.association;
    final isFounder = association?.isFoundedBy(viewerMerchantId) ?? false;
    final members =
        ref.watch(associationMembersProvider(associationId)).valueOrNull ??
            const <AssociationMember>[];
    final pending = members.where((m) => m.isPending).toList();
    final approved = members.where((m) => m.isApproved).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        appBar: AppBar(
          backgroundColor: MerchantColors.bgHeader,
          foregroundColor: Colors.white,
          title: Text(
            association?.name ?? 'Association',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            if (association?.description?.isNotEmpty ?? false) ...[
              Text(
                association!.description!,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textLightGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (isFounder && pending.isNotEmpty) ...[
              _SectionLabel(
                label: 'Demandes en attente',
                count: pending.length,
              ),
              const SizedBox(height: 10),
              ...pending.map(
                (member) => _MemberTile(
                  member: member,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Accepter',
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF4ADE80)),
                        onPressed: () async {
                          await ref
                              .read(merchantAssociationRepositoryProvider)
                              .approveMember(
                                associationId: associationId,
                                merchantId: member.merchantId,
                              );
                          if (!context.mounted) return;
                          showSuccessSnackbar(
                            context,
                            '${member.merchantName} a rejoint l\'association',
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Refuser',
                        icon: Icon(Icons.cancel_rounded,
                            color: Colors.red.shade400),
                        onPressed: () => ref
                            .read(merchantAssociationRepositoryProvider)
                            .removeMember(
                              associationId: associationId,
                              merchantId: member.merchantId,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _SectionLabel(label: 'Commerces membres', count: approved.length),
            const SizedBox(height: 10),
            if (isFounder) ...[
              OutlinedButton.icon(
                onPressed: () => _showAddMemberSheet(
                  context,
                  ref,
                  associationId: associationId,
                  existingIds: approved.map((m) => m.merchantId).toSet()
                    ..add(viewerMerchantId),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(
                  'Ajouter un commerce',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantColors.gold,
                  side: BorderSide(
                    color: MerchantColors.gold.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (approved.isEmpty)
              Text(
                'Aucun commerce membre pour l\'instant.',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: MerchantColors.textGrey,
                ),
              )
            else
              ...approved.map(
                (member) => _MemberTile(
                  member: member,
                  isAdmin: association?.isFoundedBy(member.merchantId) ?? false,
                  trailing: isFounder && member.merchantId != viewerMerchantId
                      ? IconButton(
                          tooltip: 'Retirer',
                          icon: Icon(Icons.delete_outline_rounded,
                              color: Colors.red.shade400, size: 20),
                          onPressed: () => ref
                              .read(merchantAssociationRepositoryProvider)
                              .removeMember(
                                associationId: associationId,
                                merchantId: member.merchantId,
                              ),
                        )
                      : null,
                ),
              ),
            const SizedBox(height: 28),
            if (!isFounder)
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(merchantAssociationRepositoryProvider)
                      .removeMember(
                        associationId: associationId,
                        merchantId: viewerMerchantId,
                      );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.logout_rounded,
                    size: 18, color: Colors.red.shade400),
                label: Text(
                  'Quitter l\'association',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: MerchantColors.textLightGrey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: MerchantColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    this.trailing,
    this.isAdmin = false,
  });

  final AssociationMember member;
  final Widget? trailing;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MerchantColors.gold.withValues(alpha: 0.12),
            backgroundImage: (member.merchantLogoUrl?.isNotEmpty ?? false)
                ? NetworkImage(member.merchantLogoUrl!)
                : null,
            child: (member.merchantLogoUrl?.isNotEmpty ?? false)
                ? null
                : const Icon(Icons.storefront_outlined,
                    color: MerchantColors.gold, size: 18),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (member.merchantCity?.isNotEmpty ?? false)
                      member.merchantCity!,
                    if (isAdmin) 'Administrateur',
                  ].join(' · '),
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
