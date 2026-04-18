import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/e_fidelite_providers.dart';
import '../../application/loyalty_program_editing_notifier.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';

part 'loyalty_configuration_wizard.part.dart';
part 'loyalty_wizard_primitives.part.dart';
part 'loyalty_wizard_steps.part.dart';
part 'loyalty_wizard_reward_step.part.dart';

/// Guided questionnaire for the merchant loyalty program (presentation only).
class LoyaltyConfigurationWizard extends ConsumerStatefulWidget {
  const LoyaltyConfigurationWizard({
    super.key,
    this.onSave,
    this.saveEnabled = false,
    this.saving = false,
  });

  final VoidCallback? onSave;
  final bool saveEnabled;
  final bool saving;

  @override
  ConsumerState<LoyaltyConfigurationWizard> createState() =>
      _LoyaltyConfigurationWizardState();
}

class _LoyaltyConfigurationWizardState
    extends ConsumerState<LoyaltyConfigurationWizard> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const int _pageCount = 7;

  static const _stepTitles = [
    'Activation',
    'Déclencheur',
    'Seuil',
    'Récompense',
    'Conditions',
    'Validation',
    'Options',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final next = index.clamp(0, _pageCount - 1);
    setState(() => _pageIndex = next);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Auto-advance after a brief delay so the user sees their selection.
  void _autoAdvanceTo(int index) {
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _goTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(loyaltyProgramEditingProvider);
    final notifier = ref.read(loyaltyProgramEditingProvider.notifier);
    final summary = config.clientSummaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepDots(
          current: _pageIndex,
          total: _pageCount,
          stepTitle: _stepTitles[_pageIndex],
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _pageIndex = i),
            children: [
              // Step 0: Activation
              _WizardPageBody(
                stepIndex: 0,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _ActivationStep(
                  enabled: config.programEnabled,
                  onChanged: (v) {
                    final changed = v != config.programEnabled;
                    notifier.setProgramEnabled(v);
                    // "Non" → skip to Options (last step); "Oui" → go to Déclencheur
                    if (changed) _autoAdvanceTo(v ? 1 : 6);
                  },
                ),
              ),
              // Step 1: Trigger type
              _WizardPageBody(
                stepIndex: 1,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _TriggerStep(
                  value: config.triggerType,
                  onChanged: (v) {
                    final changed = v != config.triggerType;
                    notifier.setTriggerType(v);
                    if (changed) _autoAdvanceTo(2);
                  },
                ),
              ),
              // Step 2: Threshold
              _WizardPageBody(
                stepIndex: 2,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _ThresholdStep(config: config, notifier: notifier),
              ),
              // Step 3: Reward
              _WizardPageBody(
                stepIndex: 3,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _RewardStep(config: config, notifier: notifier),
              ),
              // Step 4: Conditions
              _WizardPageBody(
                stepIndex: 4,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _ConditionsStep(config: config, notifier: notifier),
              ),
              // Step 5: Validation
              _WizardPageBody(
                stepIndex: 5,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _ValidationStep(
                  value: config.passageValidation,
                  onChanged: (v) {
                    final changed = v != config.passageValidation;
                    notifier.setPassageValidation(v);
                    if (changed) _autoAdvanceTo(6);
                  },
                ),
              ),
              // Step 6: Client amount (last step)
              _WizardPageBody(
                stepIndex: 6,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                onSave: widget.onSave,
                saveEnabled: widget.saveEnabled,
                saving: widget.saving,
                child: _ClientAmountStep(config: config, notifier: notifier),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
