import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/notification_template.dart';
import '../../infrastructure/notification_template_repository_provider.dart';

/// Result returned to the compose section when the merchant picks a
/// template from [showTemplatesPickerSheet]. Carries everything needed
/// to fill the form: text body, audience, and segment list.
class TemplatePick {
  const TemplatePick({
    required this.text,
    required this.audience,
    required this.segments,
  });

  final String text;
  final String audience;
  final List<String> segments;
}

/// Bottom sheet showing the merchant's saved templates with a live list
/// (deletes/edits from another device update in place). Returns the
/// chosen [TemplatePick] on tap, `null` on dismiss.
Future<TemplatePick?> showTemplatesPickerSheet({
  required BuildContext context,
  required String merchantId,
}) {
  return showModalBottomSheet<TemplatePick>(
    context: context,
    backgroundColor: MerchantColors.navyCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TemplatesPickerSheet(merchantId: merchantId),
  );
}

class _TemplatesPickerSheet extends ConsumerWidget {
  const _TemplatesPickerSheet({required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(notificationTemplateRepositoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: MerchantColors.textLightGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Mes templates',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sélectionnez un template pour pré-remplir votre message.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: MerchantColors.textLightGrey,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: StreamBuilder<List<NotificationTemplate>>(
                stream: repo.watchAll(merchantId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MerchantColors.gold,
                        ),
                      ),
                    );
                  }
                  final items = snap.data ?? const <NotificationTemplate>[];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Aucun template enregistré pour le moment.\n'
                        'Composez un message puis « Enregistrer comme '
                        'template » pour en créer un.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: MerchantColors.textLightGrey,
                          height: 1.5,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TemplateRow(
                      template: items[i],
                      merchantId: merchantId,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateRow extends ConsumerWidget {
  const _TemplateRow({required this.template, required this.merchantId});

  final NotificationTemplate template;
  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(
        TemplatePick(
          text: template.text,
          audience: template.audience,
          segments: template.segments,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MerchantColors.bgMain,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _AudienceBadge(template: template),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.text,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textLightGrey,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: MerchantColors.textGrey, size: 20),
              tooltip: 'Supprimer',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.bgHeader,
        title: Text('Supprimer ce template ?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
        content: Text(
          'Cette action est irréversible.',
          style: GoogleFonts.outfit(
              fontSize: 13, color: MerchantColors.textLightGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer',
                style: GoogleFonts.outfit(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final repo = ref.read(notificationTemplateRepositoryProvider);
    await repo.delete(merchantId: merchantId, templateId: template.id);
  }
}

class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge({required this.template});

  final NotificationTemplate template;

  @override
  Widget build(BuildContext context) {
    final isAll = template.audience == 'Tous mes clients';
    final label = isAll
        ? 'Tous'
        : (template.segments.isEmpty
            ? 'Segment'
            : template.segments.first[0].toUpperCase() +
                template.segments.first.substring(1));
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
          fontWeight: FontWeight.w700,
          color: MerchantColors.gold,
        ),
      ),
    );
  }
}

/// Modal asking for a template name and persisting the current compose
/// state (text + audience + segments) as a new template. Returns true
/// on success so the caller can show a "Template enregistré ✓" snackbar.
Future<bool> showSaveTemplateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String merchantId,
  required String text,
  required String audience,
  required List<String> segments,
}) async {
  final controller = TextEditingController();
  bool saving = false;
  String? error;

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: MerchantColors.bgHeader,
          title: Text(
            'Enregistrer comme template',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donnez un nom à ce template pour le retrouver facilement.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 80,
                style:
                    GoogleFonts.outfit(fontSize: 14, color: Colors.white),
                cursorColor: MerchantColors.gold,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: MerchantColors.navyCard,
                  hintText: 'ex. Promo week-end',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: MerchantColors.textGrey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: MerchantColors.gold.withValues(
                          alpha: MerchantColors.goldBorderAlpha),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: MerchantColors.gold,
                      width: 1.5,
                    ),
                  ),
                  counterStyle: GoogleFonts.outfit(
                      fontSize: 10, color: MerchantColors.textGrey),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    error!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  saving ? null : () => Navigator.of(ctx).pop(false),
              child: Text('Annuler',
                  style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MerchantColors.gold,
                foregroundColor: MerchantColors.darkOverlay,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        error = null;
                        saving = true;
                      });
                      final repo =
                          ref.read(notificationTemplateRepositoryProvider);
                      final t = NotificationTemplate(
                        id: '',
                        name: controller.text.trim(),
                        text: text,
                        audience: audience,
                        segments: segments,
                      );
                      final result = await repo.create(
                          merchantId: merchantId, template: t);
                      if (!ctx.mounted) return;
                      result.fold(
                        (failure) {
                          setState(() {
                            error = failure.message;
                            saving = false;
                          });
                        },
                        (_) => Navigator.of(ctx).pop(true),
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MerchantColors.darkOverlay,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return saved == true;
}
