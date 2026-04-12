import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/user_display_helpers.dart';
import '../application/providers.dart';

part 'personal_information_screen.part.dart';

class PersonalInformationScreen extends ConsumerWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState is Authenticated ? authState.user : null;
    final basics = user == null
        ? null
        : ref.watch(userProfileBasicsProvider(user.id)).valueOrNull;
    final storefront = user == null
        ? null
        : ref.watch(storefrontProvider).valueOrNull;

    final fullName = user == null ? 'Utilisateur' : resolveDisplayName(user, basics);
    final email = user == null ? '—' : resolveEmail(user, basics);
    final phone = user == null ? '—' : resolvePhone(user, basics);
    final cityRaw = user == null
        ? ''
        : resolveCityForProfile(
            basics,
            isMerchant: user.isMerchant,
            storefront: storefront,
          );
    final city = cityRaw.isNotEmpty ? cityRaw : '—';

    return _buildPersonalInformationScaffold(
      context,
      fullName: fullName,
      email: email,
      phone: phone,
      city: city,
    );
  }
}
