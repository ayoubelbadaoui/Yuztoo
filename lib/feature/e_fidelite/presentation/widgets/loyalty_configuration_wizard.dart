import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/e_fidelite_providers.dart';
import '../../application/loyalty_program_editing_notifier.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';

part 'loyalty_configuration_wizard.part.dart';

/// Guided questionnaire for the merchant loyalty program (presentation only).
class LoyaltyConfigurationWizard extends ConsumerStatefulWidget {
  const LoyaltyConfigurationWizard({super.key});

  @override
  ConsumerState<LoyaltyConfigurationWizard> createState() =>
      _LoyaltyConfigurationWizardState();
}

class _LoyaltyConfigurationWizardState
    extends ConsumerState<LoyaltyConfigurationWizard> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const int _pageCount = 7;

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

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(loyaltyProgramEditingProvider);
    final notifier = ref.read(loyaltyProgramEditingProvider.notifier);
    final summary = config.clientSummaryText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepDots(current: _pageIndex, total: _pageCount),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _pageIndex = i),
            children: [
              _WizardPageBody(
                stepIndex: 0,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _ActivationStep(
                  enabled: config.programEnabled,
                  onChanged: notifier.setProgramEnabled,
                ),
              ),
              _WizardPageBody(
                stepIndex: 1,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _TriggerStep(
                  value: config.triggerType,
                  onChanged: notifier.setTriggerType,
                ),
              ),
              _WizardPageBody(
                stepIndex: 2,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _ThresholdStep(config: config, notifier: notifier),
              ),
              _WizardPageBody(
                stepIndex: 3,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _RewardStep(config: config, notifier: notifier),
              ),
              _WizardPageBody(
                stepIndex: 4,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _ConditionsStep(config: config, notifier: notifier),
              ),
              _WizardPageBody(
                stepIndex: 5,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _ValidationStep(
                  value: config.passageValidation,
                  onChanged: notifier.setPassageValidation,
                ),
              ),
              _WizardPageBody(
                stepIndex: 6,
                pageCount: _pageCount,
                summaryText: summary,
                onGoTo: _goTo,
                child: _ClientAmountStep(config: config, notifier: notifier),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
