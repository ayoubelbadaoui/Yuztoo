import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/city_search_sheet.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../application/providers.dart';

/// Bottom sheet to create an association; the merchant becomes its
/// administrator and first member.
Future<void> showCreateAssociationSheet(
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
    builder: (_) => _CreateAssociationSheet(merchant: merchant),
  );
}

class _CreateAssociationSheet extends ConsumerStatefulWidget {
  const _CreateAssociationSheet({required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<_CreateAssociationSheet> createState() =>
      _CreateAssociationSheetState();
}

class _CreateAssociationSheetState
    extends ConsumerState<_CreateAssociationSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late final TextEditingController _cityCtrl =
      TextEditingController(text: widget.merchant.city);
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final commune = await showCitySearchSheet(
      context,
      title: 'Ville de l\'association',
      selectedCity: _cityCtrl.text.trim(),
      backgroundColor: MerchantColors.bgMain,
    );
    if (commune == null || !mounted) return;
    setState(() => _cityCtrl.text = commune.name);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(merchantAssociationRepositoryProvider).createAssociation(
            founderMerchantId: widget.merchant.id,
            founderName: widget.merchant.displayName?.trim().isNotEmpty == true
                ? widget.merchant.displayName!.trim()
                : widget.merchant.name,
            name: name,
            city: _cityCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            founderLogoUrl: widget.merchant.logoUrl,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnackbar(context, 'Association créée');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackbar(context, 'Impossible de créer l\'association.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                'Créer une association',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vous en serez l\'administrateur : les autres commerces '
                'demanderont à vous rejoindre et vous validerez leur demande.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _Field(
                controller: _nameCtrl,
                label: 'Nom de l\'association',
                hint: 'Ex. : Les commerçants du centre-ville',
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _cityCtrl,
                label: 'Ville',
                hint: 'Choisir une ville',
                readOnly: true,
                onTap: _pickCity,
                suffixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: MerchantColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _descCtrl,
                label: 'Description (optionnel)',
                hint: 'Quelques mots sur votre association',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _nameCtrl.text.trim().isEmpty || _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MerchantColors.gold,
                    foregroundColor: MerchantColors.bgMain,
                    disabledBackgroundColor:
                        MerchantColors.gold.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MerchantColors.bgMain,
                          ),
                        )
                      : Text(
                          'Créer l\'association',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool autofocus;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: MerchantColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          onTap: onTap,
          style: GoogleFonts.outfit(fontSize: 13.5, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            hintStyle: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: MerchantColors.navyCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      ],
    );
  }
}
