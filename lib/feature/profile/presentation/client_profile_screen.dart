import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import 'personal_information_screen.dart';
import '../application/providers.dart';

part 'client_profile_screen.part.dart';

/// Client profile / settings – same colors and minimalist layout as merchant settings.
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  static String get path => '/client-profile';

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildClientProfileBody(context, l10n);
  }
}
