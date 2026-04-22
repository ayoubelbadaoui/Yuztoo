import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../application/providers.dart';
import 'widgets/cities_section.dart';
import 'widgets/profile_avatar_section.dart';
import 'widgets/yuztoo_card_box.dart';

part 'account_preferences_screen.part.dart';

/// "Profil" / account preferences screen.
/// All data from Firestore/auth: profile, completion %, cities.
class AccountPreferencesScreen extends ConsumerStatefulWidget {
  const AccountPreferencesScreen({
    super.key,
    this.onBack,
    this.onCreateProAccount,
  });

  final VoidCallback? onBack;
  /// Called when the client taps "Créer un compte pro" to start merchant onboarding.
  final VoidCallback? onCreateProAccount;

  @override
  ConsumerState<AccountPreferencesScreen> createState() =>
      _AccountPreferencesScreenState();
}

class _AccountPreferencesScreenState extends ConsumerState<AccountPreferencesScreen> {
  @override
  Widget build(BuildContext context) => _buildAccountPreferencesBody(context);
}
