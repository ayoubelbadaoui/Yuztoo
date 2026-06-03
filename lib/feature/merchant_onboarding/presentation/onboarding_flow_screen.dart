import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/shared/widgets/cupertino_dob_picker.dart';
import '../../../../core/shared/widgets/time_slot_picker.dart';
import '../../../../core/utils/cities.dart';
import '../../../../core/utils/email_validator.dart';
import '../../../../core/utils/image_pick_with_source.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../application/providers.dart';
import '../domain/entities/merchant_category.dart';
import '../application/onboarding_flow_provider.dart';
import '../../storefront/domain/entities/business_hours.dart';
import 'widgets/merchant_onboarding_colors.dart';
import 'widgets/category_card.dart';
import '../../auth/signup/presentation/widgets/city_selection_modal.dart';

part 'onboarding_flow_screen.part.dart';

/// Full flow: Welcome(0), OwnerInfo(1), Name(2), MerchantType(3), City(4), Image(5), Address(6), Description(7), Hours(8), Ready(9)
const _totalSteps = 10;

/// Client-upgrade flow (skipPersonalInfo=true): Welcome(0), Name(1), MerchantType(2), City(3), Address(4), Description(5), Hours(6), Ready(7)
const _totalStepsSkipPersonal = 8;

/// Uber Eats / Glovo-style multi-step merchant onboarding.
class MerchantOnboardingFlowScreen extends ConsumerStatefulWidget {
  const MerchantOnboardingFlowScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
    this.isPostSignup = false,
    this.skipPersonalInfo = false,
    /// When set with [isPostSignup], the final button **only** awaits this (e.g. create
    /// merchant in Firestore). Do not fire-and-forget [onComplete] for the same work —
    /// otherwise routing can unmount the screen before signup city is read from `/users`.
    this.onPostSignupPersist,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;

  /// When true, last step shows "Accéder à mon commerce" instead of "Créer mon compte".
  final bool isPostSignup;

  /// When true, personal steps (owner info + logo) are removed from the flow
  /// because the user already provided them during client onboarding.
  final bool skipPersonalInfo;

  /// Optional: awaited on the last step when [isPostSignup] is true (full persist path).
  final Future<void> Function()? onPostSignupPersist;

  @override
  ConsumerState<MerchantOnboardingFlowScreen> createState() =>
      _MerchantOnboardingFlowScreenState();
}

class _MerchantOnboardingFlowScreenState
    extends ConsumerState<MerchantOnboardingFlowScreen> {
  final _pageController = PageController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _effectiveTotalSteps =>
      widget.skipPersonalInfo ? _totalStepsSkipPersonal : _totalSteps;

  void _goNext() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep < _effectiveTotalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      widget.onBack();
    }
  }

  void _handleSystemBack() {
    // On optional steps, phone back behaves like "Passer".
    if (_isOptionalStep()) {
      _goNext();
      return;
    }
    _goBack();
  }

  bool _isOptionalStep() {
    if (widget.skipPersonalInfo) {
      // 0 Welcome · 1 Name · 2 MerchantType · 3 City
      // 4 Address · 5 Description (optional) · 6 Hours (optional) · 7 Ready
      return _currentStep == 5 || _currentStep == 6;
    }
    // 0 Welcome · 1 OwnerInfo · 2 Name · 3 MerchantType · 4 City
    // 5 Image (optional) · 6 Address · 7 Description (optional) · 8 Hours (optional) · 9 Ready
    return _currentStep == 5 || _currentStep == 7 || _currentStep == 8;
  }

  Future<void> _persistMerchantOnboardingCompleted() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(markMerchantOnboardingCompletedProvider).call(uid);
  }

  /// Best-effort auth-email lookup for prefilling the contact-email field.
  /// Returns null when Firebase is not initialised (e.g. widget tests that
  /// build the onboarding screen without `Firebase.initializeApp()`) — in
  /// that case the merchant just types the email manually.
  String? _authEmailForPrefill() {
    try {
      final auth = ref.read(authStateProvider);
      return auth is Authenticated ? auth.user.email : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingFlowProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgMain,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleSystemBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StepWelcome(onNext: _goNext),
                    if (!widget.skipPersonalInfo)
                      _StepOwnerInfo(
                        firstNameController: _ownerFirstNameController,
                        lastNameController: _ownerLastNameController,
                        initialFirstName: data.ownerFirstName,
                        initialLastName: data.ownerLastName,
                        initialDob: data.ownerDateOfBirth,
                        onFirstNameChanged: (v) => ref
                            .read(onboardingFlowProvider.notifier)
                            .setOwnerFirstName(v),
                        onLastNameChanged: (v) => ref
                            .read(onboardingFlowProvider.notifier)
                            .setOwnerLastName(v),
                        onDobChanged: (d) => ref
                            .read(onboardingFlowProvider.notifier)
                            .setOwnerDateOfBirth(d),
                        onNext: _goNext,
                      ),
                    _StepName(
                      controller: _nameController,
                      initialValue: data.fullName,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setFullName(v),
                      onNext: _goNext,
                    ),
                    _StepMerchantType(
                      value: data.merchantType,
                      onChanged: (v) {
                        ref
                            .read(onboardingFlowProvider.notifier)
                            .setMerchantType(v);
                      },
                      onNext: _goNext,
                    ),
                    _StepCity(
                      initialValue: data.city,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setCity(v),
                      onNext: _goNext,
                    ),
                    if (!widget.skipPersonalInfo)
                      _StepImage(
                        imagePath: data.imagePath,
                        bannerImagePath: data.bannerImagePath,
                        onPickedLogo: (p) => ref
                            .read(onboardingFlowProvider.notifier)
                            .setImagePath(p),
                        onPickedBanner: (p) => ref
                            .read(onboardingFlowProvider.notifier)
                            .setBannerImagePath(p),
                        onNext: _goNext,
                        picker: _imagePicker,
                      ),
                    _StepAddress(
                      controller: _addressController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      websiteController: _websiteController,
                      initialValue: data.address,
                      initialPhone: data.phoneNumber,
                      initialEmail:
                          data.contactEmail ?? _authEmailForPrefill(),
                      initialWebsite: data.websiteUrl,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setAddress(v),
                      onPhoneChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setPhoneNumber(v),
                      onEmailChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setContactEmail(v),
                      onWebsiteChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setWebsiteUrl(v),
                      onNext: _goNext,
                    ),
                    _StepDescription(
                      controller: _descriptionController,
                      initialValue: data.description,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setDescription(v),
                      onNext: _goNext,
                    ),
                    _StepHours(
                      initialHours: data.hoursJson,
                      onChanged: (h) =>
                          ref.read(onboardingFlowProvider.notifier).setHours(h),
                      onSkip: _goNext,
                      onNext: _goNext,
                    ),
                    _StepReady(
                      onComplete: widget.onComplete,
                      isPostSignup: widget.isPostSignup,
                      postSignupAwaitFullPersistOnly:
                          widget.isPostSignup && widget.onPostSignupPersist != null,
                      onPostSignupPersistMerchantReady: widget.isPostSignup
                          ? (widget.onPostSignupPersist ??
                              _persistMerchantOnboardingCompleted)
                          : null,
                    ),
                  ],
                ),
              ),
              _buildBottomBar(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    // Hide progress bar on Welcome step
    if (_currentStep == 0) return const SizedBox.shrink();

    // iOS-native: 44pt nav region, chevron-only back (no bordered circle),
    // 2px hairline progress indicator. Matches the chrome we use on the
    // category + subcategory screens so every screen of the merchant
    // onboarding flow has identical top-bar visuals.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _goBack,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: MerchantOnboardingColors.primaryGold,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _effectiveTotalSteps,
                backgroundColor: MerchantOnboardingColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MerchantOnboardingColors.primaryGold,
                ),
                minHeight: 2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildBottomBar(MerchantOnboardingData data) {
    return const SizedBox.shrink();
  }
}

