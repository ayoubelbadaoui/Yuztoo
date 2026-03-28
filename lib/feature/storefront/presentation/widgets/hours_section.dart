import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../application/providers.dart';
import '../../domain/entities/business_hours.dart';
import 'day_row.dart';
import 'exceptional_closure_card.dart';
import 'storefront_colors.dart';

/// Hours section – thin orchestrator.
///
/// Delegates UI to:
///  • [DayRow]                – individual day toggle + inline editor
///  • [ExceptionalClosureCard] – exceptional closure toggle
///
/// Handles confirmations dialogs inline.
class HoursSection extends ConsumerWidget {
  const HoursSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessHours = ref.watch(businessHoursProvider);
    final notifier = ref.read(businessHoursProvider.notifier);
    final hasClosure = businessHours.hasExceptionalClosure;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildDaysCard(context, businessHours, notifier, hasClosure),
          const SizedBox(height: 20),
          ExceptionalClosureCard(
            isEnabled: hasClosure,
            onToggle: (enabled) => _showExceptionalClosureConfirmation(
                context, enabled, () => notifier.toggleExceptionalClosure(enabled)),
          ),
          const SizedBox(height: 24),
          _SaveHoursButton(ref: ref),
        ],
      ),
    );
  }

  // ── section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.schedule_rounded,
            color: StorefrontColors.primaryGold,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Horaires d\'ouverture',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: StorefrontColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── days card ──────────────────────────────────────────────────────────────

  Widget _buildDaysCard(BuildContext context, BusinessHours businessHours,
      dynamic notifier, bool hasClosure) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < businessHours.allDays.length; i++) ...[
            DayRow(
              dayHours: businessHours.allDays[i],
              isDisabled: hasClosure,
              onToggle: (enabled) => _handleToggle(
                  context, notifier, businessHours.allDays[i], enabled),
              onSave: (slots) => notifier.updateDayHours(
                  businessHours.allDays[i].dayName, slots),
            ),
            if (i < businessHours.allDays.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey[100],
              ),
          ],
        ],
      ),
    );
  }

  // ── toggle handlers ────────────────────────────────────────────────────────

  void _handleToggle(
      BuildContext context, dynamic notifier, DayHours dayHours, bool enabled) {
    if (enabled && dayHours.isClosed) {
      _showConfirmation(
        context,
        title: 'Ouvrir ${dayHours.dayName}',
        message: 'Êtes-vous sûr de vouloir ouvrir ${dayHours.dayName} ?',
        info: 'Des horaires par défaut (8h - 12h et 14h - 18h) seront ajoutés.',
        icon: Icons.access_time,
        color: StorefrontColors.primaryGold,
        confirmFg: StorefrontColors.navyDark,
        onConfirm: () => notifier.toggleDay(dayHours.dayName, true),
      );
    } else if (!enabled && !dayHours.isClosed) {
      _showConfirmation(
        context,
        title: 'Fermer ${dayHours.dayName}',
        message: 'Êtes-vous sûr de vouloir fermer ${dayHours.dayName} ?',
        info:
            'Les horaires seront supprimés et le jour sera marqué comme fermé.',
        icon: Icons.event_busy,
        color: Colors.red,
        confirmFg: Colors.white,
        onConfirm: () => notifier.toggleDay(dayHours.dayName, false),
      );
    } else {
      notifier.toggleDay(dayHours.dayName, enabled);
    }
  }

  void _showExceptionalClosureConfirmation(
      BuildContext context, bool isActivating, VoidCallback onConfirm) {
    _showConfirmation(
      context,
      title: isActivating
          ? 'Activer la fermeture exceptionnelle'
          : 'Désactiver la fermeture exceptionnelle',
      message: isActivating
          ? 'Êtes-vous sûr de vouloir activer la fermeture exceptionnelle ?'
          : 'Êtes-vous sûr de vouloir désactiver la fermeture exceptionnelle ?',
      info: isActivating
          ? 'Tous les horaires réguliers seront désactivés.'
          : 'Tous les horaires réguliers seront réactivés.',
      icon: isActivating
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline,
      color: isActivating ? Colors.orange : StorefrontColors.primaryGold,
      confirmFg: isActivating ? Colors.white : StorefrontColors.navyDark,
      onConfirm: onConfirm,
    );
  }

  // ── confirmation dialog ────────────────────────────────────────────────────

  void _showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required String info,
    required IconData icon,
    required Color color,
    required Color confirmFg,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(info,
                        style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuler',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: confirmFg,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Button to save business hours to Firestore.
class _SaveHoursButton extends ConsumerStatefulWidget {
  const _SaveHoursButton({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_SaveHoursButton> createState() => _SaveHoursButtonState();
}

class _SaveHoursButtonState extends ConsumerState<_SaveHoursButton> {
  bool _saving = false;

  Future<void> _saveHours() async {
    final authState = widget.ref.read(auth_providers.authStateProvider);
    if (authState is! Authenticated) return;

    setState(() => _saving = true);
    final merchantId = authState.user.id;
    final businessHours = widget.ref.read(businessHoursProvider);
    final hoursMap = businessHours.toMap();

    final updateStorefront = widget.ref.read(merchant_providers.updateStorefrontProvider);
    final result = await updateStorefront.call(
      merchantId: merchantId,
      hours: hoursMap,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        widget.ref.invalidate(storefrontProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horaires enregistrés'),
            backgroundColor: StorefrontColors.primaryGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : _saveHours,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined, size: 20),
        label: Text(_saving ? 'Enregistrement...' : 'Enregistrer les horaires'),
        style: ElevatedButton.styleFrom(
          backgroundColor: StorefrontColors.primaryGold,
          foregroundColor: StorefrontColors.navyDark,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
