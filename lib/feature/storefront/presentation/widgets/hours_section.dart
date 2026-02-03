import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers.dart';
import '../../domain/entities/business_hours.dart';
import 'storefront_colors.dart';
import 'edit_hours_dialog.dart';

/// Hours section showing business hours for each day of the week
class HoursSection extends ConsumerWidget {
  const HoursSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessHours = ref.watch(businessHoursProvider);
    final notifier = ref.read(businessHoursProvider.notifier);
    final hasExceptionalClosure = businessHours.hasExceptionalClosure;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Days list with proper spacing
          ...businessHours.allDays.map((dayHours) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _DayHoursRow(
                  dayHours: dayHours,
                  isDisabled: hasExceptionalClosure, // Disable all days when exceptional closure is active
                  onToggle: (enabled) {
                    if (enabled && dayHours.isClosed) {
                      // Show confirmation when activating a closed day
                      _showActivateDayConfirmation(context, dayHours.dayName, () {
                        notifier.toggleDay(dayHours.dayName, true);
                      });
                    } else if (!enabled && !dayHours.isClosed) {
                      // Show confirmation when deactivating an open day
                      _showDeactivateDayConfirmation(context, dayHours.dayName, () {
                        notifier.toggleDay(dayHours.dayName, false);
                      });
                    } else {
                      // Direct toggle (shouldn't happen, but just in case)
                      notifier.toggleDay(dayHours.dayName, enabled);
                    }
                  },
                  onEdit: () {
                    _showEditHoursDialog(context, ref, dayHours);
                  },
                ),
              )),
          const SizedBox(height: 32),
          // Exceptional closure toggle
          _ExceptionalClosureToggle(
            isEnabled: businessHours.hasExceptionalClosure,
            onToggle: (enabled) {
              if (enabled) {
                // Show confirmation dialog when enabling
                _showExceptionalClosureConfirmation(context, true, () {
                  notifier.toggleExceptionalClosure(true);
                });
              } else {
                // Show confirmation dialog when disabling
                _showExceptionalClosureConfirmation(context, false, () {
                  notifier.toggleExceptionalClosure(false);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditHoursDialog(BuildContext context, WidgetRef ref, DayHours dayHours) {
    showDialog(
      context: context,
      builder: (context) => EditHoursDialog(
        dayHours: dayHours,
        onSave: (timeSlots) {
          final notifier = ref.read(businessHoursProvider.notifier);
          // Update hours
          notifier.updateDayHours(dayHours.dayName, timeSlots);
          // If day was closed and we're adding hours, enable it
          if (!dayHours.isEnabled && timeSlots.isNotEmpty) {
            notifier.toggleDay(dayHours.dayName, true);
          }
        },
      ),
    );
  }

  void _showExceptionalClosureConfirmation(BuildContext context, bool isActivating, VoidCallback onConfirm) {
    final titleText = isActivating ? 'Activer la fermeture exceptionnelle' : 'Désactiver la fermeture exceptionnelle';
    final messageText = isActivating
        ? 'Êtes-vous sûr de vouloir activer la fermeture exceptionnelle ?'
        : 'Êtes-vous sûr de vouloir désactiver la fermeture exceptionnelle ?';
    final infoText = isActivating
        ? 'Tous les horaires réguliers seront désactivés et grisés.'
        : 'Tous les horaires réguliers seront réactivés et redeviendront modifiables.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActivating
                    ? Colors.orange.withValues(alpha: 0.1)
                    : StorefrontColors.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActivating ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isActivating ? Colors.orange : StorefrontColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titleText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              messageText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActivating
                    ? Colors.orange.withValues(alpha: 0.08)
                    : StorefrontColors.primaryGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActivating
                      ? Colors.orange.withValues(alpha: 0.2)
                      : StorefrontColors.primaryGold.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: isActivating ? Colors.orange[700] : StorefrontColors.primaryGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActivating ? Colors.orange[800] : StorefrontColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActivating ? Colors.orange : StorefrontColors.primaryGold,
              foregroundColor: isActivating ? Colors.white : StorefrontColors.navyDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActivateDayConfirmation(BuildContext context, String dayName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time,
                color: StorefrontColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ouvrir $dayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir ouvrir $dayName ?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: StorefrontColors.primaryGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Des horaires par défaut (8h - 12h et 14h - 18h) seront ajoutés. Vous pourrez les modifier ensuite.',
                      style: TextStyle(
                        fontSize: 13,
                        color: StorefrontColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StorefrontColors.primaryGold,
              foregroundColor: StorefrontColors.navyDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeactivateDayConfirmation(BuildContext context, String dayName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.event_busy,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Fermer $dayName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir fermer $dayName ?',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les horaires de ce jour seront supprimés et le jour sera marqué comme fermé.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.dayHours,
    required this.onToggle,
    required this.onEdit,
    this.isDisabled = false,
  });

  final DayHours dayHours;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final isClosed = dayHours.isClosed || isDisabled;
    final textColor = isClosed || isDisabled
        ? StorefrontColors.textSecondary.withValues(alpha: isDisabled ? 0.5 : 1.0)
        : StorefrontColors.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Toggle and day name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: _CustomSwitch(
                value: dayHours.isEnabled,
                onChanged: isDisabled ? null : onToggle,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(
                dayHours.dayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        // Time slots and edit button
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  dayHours.displayText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                    fontStyle: isClosed ? FontStyle.italic : FontStyle.normal,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              // Always show MODIFIER button for symmetry - allow editing even when closed
              Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: GestureDetector(
                  onTap: isDisabled ? null : onEdit, // Disable editing when exceptional closure is active
                  child: Text(
                    'MODIFIER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isClosed || isDisabled
                          ? StorefrontColors.textSecondary.withValues(alpha: isDisabled ? 0.5 : 0.7)
                          : StorefrontColors.primaryGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Container(
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: value
                ? StorefrontColors.primaryGold
                : Colors.grey[200],
          ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 20 : 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 4,
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

class _ExceptionalClosureToggle extends StatelessWidget {
  const _ExceptionalClosureToggle({
    required this.isEnabled,
    required this.onToggle,
  });

  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: StorefrontColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CustomSwitch(
                value: isEnabled,
                onChanged: onToggle,
              ),
              const SizedBox(width: 12),
              Text(
                'Fermeture exceptionnelle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StorefrontColors.textPrimary,
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tous les horaires réguliers sont désactivés',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

