import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../merchant_onboarding/application/onboarding_flow_provider.dart';
import '../../merchant_onboarding/application/screens.dart';
import '../../merchant_onboarding/application/widgets.dart';

part 'merchant_profile_form_screen.part.dart';

/// Merchant profile – uses the 8-step onboarding flow (avatars, step-by-step).
/// Shown when merchant has no profile yet (after signup or when opening app).
class MerchantProfileFormScreen extends ConsumerStatefulWidget {
  const MerchantProfileFormScreen({
    super.key,
    this.onBack,
    this.onComplete,
  });

  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  @override
  ConsumerState<MerchantProfileFormScreen> createState() =>
      _MerchantProfileFormScreenState();
}

class _MerchantProfileFormScreenState
    extends ConsumerState<MerchantProfileFormScreen> {
  bool _didInit = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillOnboardingFromCache();
    });
  }

  Future<void> _prefillOnboardingFromCache() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    if (cachedData['userId'] != userId) return;

    if (!mounted) return;
    final notifier = ref.read(onboardingFlowProvider.notifier);
    if (cachedData['name'] != null) notifier.setFullName(cachedData['name']!);
    if (cachedData['address'] != null) notifier.setAddress(cachedData['address']!);
    if (cachedData['category'] != null) {
      notifier.setCategory(cachedData['category']!, cachedData['category']!);
    }
    if (cachedData['description'] != null) {
      notifier.setDescription(cachedData['description']!);
    }
    if (cachedData['phone'] != null) {
      notifier.setPhoneNumber(cachedData['phone']!);
    }
    if (cachedData['websiteUrl'] != null) {
      notifier.setWebsiteUrl(cachedData['websiteUrl']!);
    }
  }

  void _setSubmitting(bool value) {
    if (!mounted) return;
    setState(() => _isSubmitting = value);
  }

  @override
  Widget build(BuildContext context) {
    return MerchantOnboardingFlowScreen(
      isPostSignup: true,
      onBack: widget.onBack ?? () {},
      onComplete: () {},
      onPostSignupPersist: _saveFromOnboarding,
    );
  }
}
