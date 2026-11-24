import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../application/providers.dart';
import '../domain/entities/merchant_association.dart';

/// Bottom sheet to search associations by name or city and request to join.
Future<void> showJoinAssociationSheet(
  BuildContext context,
  Merchant merchant,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: MerchantColors.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _JoinAssociationSheet(merchant: merchant),
  );
}

class _JoinAssociationSheet extends ConsumerStatefulWidget {
  const _JoinAssociationSheet({required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<_JoinAssociationSheet> createState() =>
      _JoinAssociationSheetState();
}

class _JoinAssociationSheetState extends ConsumerState<_JoinAssociationSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  bool _sending = false;
  List<MerchantAssociation> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _loading = query.length >= 2;
      if (query.isEmpty) _results = const [];
    });
    if (query.length < 2) return;
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    final results = await ref
        .read(merchantAssociationRepositoryProvider)
        .searchAssociations(query);
    if (!mounted || _query != query) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _requestToJoin(MerchantAssociation association) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(merchantAssociationRepositoryProvider).requestToJoin(
            associationId: association.id,
            merchantId: widget.merchant.id,
            merchantName: widget.merchant.displayName?.trim().isNotEmpty == true
                ? widget.merchant.displayName!.trim()
                : widget.merchant.name,
            merchantLogoUrl: widget.merchant.logoUrl,
            merchantCity: widget.merchant.city,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnackbar(
        context,
        'Demande envoyée à « ${association.name} »',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showErrorSnackbar(context, 'Impossible d\'envoyer la demande.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MerchantColors.textGrey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Rejoindre une association',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cherchez par nom ou par ville. L\'administrateur de '
                'l\'association validera votre demande.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Nom de l\'association ou ville',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 13,
                    color: MerchantColors.textGrey.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: MerchantColors.gold, size: 20),
                  filled: true,
                  fillColor: MerchantColors.navyCard,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: MerchantColors.gold.withValues(alpha: 0.22),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: MerchantColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(child: _buildResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MerchantColors.gold,
            ),
          ),
        ),
      );
    }
    if (_query.length < 2) {
      return _hint('Saisissez au moins 2 caractères.');
    }
    if (_results.isEmpty) {
      return _hint(
        'Aucune association trouvée. Vous pouvez créer la vôtre.',
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: MerchantColors.gold.withValues(alpha: 0.1),
      ),
      itemBuilder: (_, index) {
        final association = _results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.1),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(Icons.groups_rounded,
                color: MerchantColors.gold, size: 18),
          ),
          title: Text(
            association.name,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            [
              if (association.city.isNotEmpty) association.city,
              '${association.memberCount} commerce'
                  '${association.memberCount > 1 ? 's' : ''}',
            ].join(' · '),
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: MerchantColors.textGrey,
            ),
          ),
          trailing: TextButton(
            onPressed: _sending ? null : () => _requestToJoin(association),
            child: Text(
              'Demander',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          color: MerchantColors.textGrey,
          height: 1.45,
        ),
      ),
    );
  }
}
