import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../application/providers.dart';
import '../../domain/entities/business_hours.dart';
import 'day_row.dart';
import 'exceptional_closure_card.dart';
import 'storefront_colors.dart';

part 'hours_section.part.dart';

/// Hours section – thin orchestrator.
///
/// Delegates UI to:
///  • [DayRow]                – individual day toggle + inline editor
///  • [ExceptionalClosureCard] – exceptional closure toggle
///
/// Handles confirmations dialogs inline.
class HoursSection extends ConsumerWidget {
  const HoursSection({
    super.key,
    required this.merchantId,
  });

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _buildHoursSectionBody(context, ref);
}
