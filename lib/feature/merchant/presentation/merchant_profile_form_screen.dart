import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/logger_service.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/utils/email_validator.dart';
import '../../discovery/application/providers.dart'
    show invalidateDiscoveryCatalogWidget;
import '../application/providers.dart';
import '../infrastructure/merchant_city_resolution.dart';
import '../../auth/core/application/onboarding_completion_cache.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../merchant_onboarding/application/merchant_onboarding_draft.dart';
import '../../merchant_onboarding/application/onboarding_flow_provider.dart';
import '../../merchant_onboarding/application/screens.dart';
import '../../merchant_onboarding/application/skip_personal_info_resolution.dart';
import '../../merchant_onboarding/application/widgets.dart';
import '../../profile/application/providers.dart'
    show refreshUserProfileCacheWidget;

part 'merchant_profile_form_screen.part.dart';

/// Merchant profile – uses the 8-step onboarding flow (avatars, step-by-step).
/// Shown when merchant has no profile yet (after signup or when opening app).
class MerchantProfileFormScreen extends ConsumerStatefulWidget {
  const MerchantProfileFormScreen({
    super.key,
    this.onBack,
    this.onComplete,
    this.skipPersonalInfo = false,
  });

  final VoidCallback? onBack;
  final VoidCallback? onComplete;

  /// **Intent** to skip personal steps (owner name, DOB, and logo) when a
  /// client upgrades to merchant. The screen only honors this when the
  /// underlying client profile actually has `firstName`, `lastName`, **and**
  /// `dateOfBirth` populated — otherwise the wizard falls back to showing the
  /// owner-info step so we don't end up with a merchant doc missing identity
  /// fields. See `_effectiveSkipPersonalInfo`.
  final bool skipPersonalInfo;

  @override
  ConsumerState<MerchantProfileFormScreen> createState() =>
      _MerchantProfileFormScreenState();
}

class _MerchantProfileFormScreenState
    extends ConsumerState<MerchantProfileFormScreen> {
  bool _didInit = false;
  bool _isSubmitting = false;

  /// `true` once we've finished resolving the personal-info presence on the
  /// existing client account. While `false`, we render a loading state so the
  /// wizard never flashes the wrong step count (8 vs 10 pages would be
  /// visible to the user).
  bool _basicsResolved = false;

  /// Effective skip flag: `widget.skipPersonalInfo && all-three-present`. When
  /// any personal field is missing on `users/{uid}`, we reset this to `false`
  /// so the user is asked **only** for the missing piece (the step prefills
  /// what's already known).
  bool _effectiveSkipPersonalInfo = false;

  /// Resumed wizard step (app killed mid-onboarding) and draft bookkeeping.
  int _initialStep = 0;
  int _draftStep = 0;
  String? _draftUid;
  bool _draftClosed = false;

  void _saveDraft(MerchantOnboardingData data) {
    final uid = _draftUid;
    if (uid == null || _draftClosed || !_basicsResolved) return;
    MerchantOnboardingDraftStore.save(
      uid,
      MerchantOnboardingDraft(
        data: data,
        step: _draftStep,
        skipPersonalInfo: _effectiveSkipPersonalInfo,
      ),
    );
  }

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
    if (authState is! Authenticated) {
      // No signed-in user — the wizard will redirect anyway, but unblock
      // the build so we don't render the loader forever.
      if (mounted) {
        setState(() {
          _effectiveSkipPersonalInfo = widget.skipPersonalInfo;
          _basicsResolved = true;
        });
      }
      return;
    }

    final userId = authState.user.id;
    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();

    if (!mounted) return;
    final notifier = ref.read(onboardingFlowProvider.notifier);

    if (cachedData['userId'] == userId) {
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

    // For a client upgrading to merchant: pre-fill what we already know AND
    // decide whether the owner-info step can actually be skipped. The skip
    // decision is delegated to a pure function in the application layer
    // (see [resolveMerchantOnboardingSkipPersonalInfo]) so it's unit-tested
    // independently of Flutter widgets.
    String? firstName;
    String? lastName;
    DateTime? dateOfBirth;
    if (widget.skipPersonalInfo) {
      // Bounded: this read gates a full-screen spinner. Offline, fall back to
      // the full wizard (the owner-info step is simply asked again).
      final basicsResult = await _orNullAfter(
        ref.read(auth_providers.getUserProfileBasicsProvider).call(userId),
        _kReadTimeout,
      );
      if (!mounted) return;
      final basics = basicsResult?.fold((_) => null, (b) => b);
      if (basics != null) {
        firstName = basics.firstName?.trim();
        lastName = basics.lastName?.trim();
        dateOfBirth = basics.dateOfBirth;
        if (firstName != null && firstName.isNotEmpty) {
          notifier.setOwnerFirstName(firstName);
        }
        if (lastName != null && lastName.isNotEmpty) {
          notifier.setOwnerLastName(lastName);
        }
        if (dateOfBirth != null) {
          notifier.setOwnerDateOfBirth(dateOfBirth);
        }
        if (basics.city.isNotEmpty) {
          notifier.setCity(basics.city);
        }
      }
    }

    // A saved wizard (app killed mid-onboarding) wins over cache / basics.
    final draft = await MerchantOnboardingDraftStore.load(userId);
    if (!mounted) return;
    if (draft != null) notifier.restore(draft.data);

    setState(() {
      _effectiveSkipPersonalInfo = resolveMerchantOnboardingSkipPersonalInfo(
        requested: widget.skipPersonalInfo,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
      );
      _initialStep = draft?.resumeStep(
            skipPersonalInfo: _effectiveSkipPersonalInfo,
            totalSteps: MerchantOnboardingFlowScreen.stepCount(
              skipPersonalInfo: _effectiveSkipPersonalInfo,
            ),
          ) ??
          0;
      _draftStep = _initialStep;
      _draftUid = userId;
      _basicsResolved = true;
    });
  }

  void _setSubmitting(bool value) {
    if (!mounted) return;
    setState(() => _isSubmitting = value);
  }

  @override
  Widget build(BuildContext context) {
    // If the caller didn't request a skip, no resolution is needed — render
    // the full wizard immediately. This keeps the original signup path
    // (new merchant, not dual-profile) free of any extra latency.
    // Wait for the local draft too (fast, on-device) so a resumed wizard
    // opens directly on the right step with its fields filled.
    if (!_basicsResolved) {
      return const Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Center(
          child: CircularProgressIndicator(color: MerchantColors.gold),
        ),
      );
    }
    ref.listen<MerchantOnboardingData>(
      onboardingFlowProvider,
      (_, next) => _saveDraft(next),
    );
    return MerchantOnboardingFlowScreen(
      isPostSignup: true,
      skipPersonalInfo: _effectiveSkipPersonalInfo,
      initialStep: _initialStep,
      onStepChanged: (step) {
        _draftStep = step;
        _saveDraft(ref.read(onboardingFlowProvider));
      },
      onBack: widget.onBack ?? () {},
      onComplete: () {},
      onPostSignupPersist: _saveFromOnboarding,
    );
  }
}
