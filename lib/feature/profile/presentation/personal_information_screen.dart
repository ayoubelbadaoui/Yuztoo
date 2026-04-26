import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/utils/cities.dart';
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

    // Profile completion: 20% each for name, email, phone, city, photo.
    int completionPercent = 0;
    if (fullName != 'Utilisateur' && fullName.isNotEmpty) completionPercent += 20;
    if (email != '—') completionPercent += 20;
    if (phone != '—') completionPercent += 20;
    if (city != '—') completionPercent += 20;
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    if (hasPhoto) completionPercent += 20;

    return _buildPersonalInformationScaffold(
      context,
      fullName: fullName,
      email: email,
      phone: phone,
      city: city,
      completionPercent: completionPercent,
      hasPhoto: hasPhoto,
    );
  }
}
