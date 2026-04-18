import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../../core/utils/cities.dart';
import '../application/providers.dart';
import '../domain/entities/merchant_category.dart';
import '../application/onboarding_flow_provider.dart';
import '../../storefront/domain/entities/business_hours.dart';
import 'widgets/merchant_onboarding_colors.dart';
import 'widgets/category_card.dart';
import '../../auth/signup/presentation/widgets/city_selection_modal.dart';

part 'onboarding_flow_screen.part.dart';

/// Total steps: Welcome(0), Name(1), City(2), Image(3), Address(4), Description(5), Hours(6), Ready(7)
const _totalSteps = 8;

/// Uber Eats / Glovo-style multi-step merchant onboarding.
class MerchantOnboardingFlowScreen extends ConsumerStatefulWidget {
  const MerchantOnboardingFlowScreen({
    super.key,
    required this.onBack,
    required this.onComplete,
    this.isPostSignup = false,
    /// When set with [isPostSignup], the final button **only** awaits this (e.g. create
    /// merchant in Firestore). Do not fire-and-forget [onComplete] for the same work —
    /// otherwise routing can unmount the screen before signup city is read from `/users`.
    this.onPostSignupPersist,
  });

  final VoidCallback onBack;
  final VoidCallback onComplete;

  /// When true, last step shows "Accéder à mon commerce" instead of "Créer mon compte".
  final bool isPostSignup;

  /// Optional: awaited on the last step when [isPostSignup] is true (full persist path).
  final Future<void> Function()? onPostSignupPersist;

  @override
  ConsumerState<MerchantOnboardingFlowScreen> createState() =>
      _MerchantOnboardingFlowScreenState();
}

class _MerchantOnboardingFlowScreenState
    extends ConsumerState<MerchantOnboardingFlowScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goNext() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep < _totalSteps - 1) {
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
    return _currentStep == 3 || // Image
        _currentStep == 5 || // Description
        _currentStep == 6; // Hours
  }

  Future<void> _persistMerchantOnboardingCompleted() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    await ref.read(markMerchantOnboardingCompletedProvider).call(uid);
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
                    _StepName(
                      controller: _nameController,
                      initialValue: data.fullName,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setFullName(v),
                      onNext: _goNext,
                    ),
                    _StepCity(
                      initialValue: data.city,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setCity(v),
                      onNext: _goNext,
                    ),
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
                      websiteController: _websiteController,
                      initialValue: data.address,
                      initialPhone: data.phoneNumber,
                      initialWebsite: data.websiteUrl,
                      onChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setAddress(v),
                      onPhoneChanged: (v) => ref
                          .read(onboardingFlowProvider.notifier)
                          .setPhoneNumber(v),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios),
            color: MerchantOnboardingColors.primaryGold,
            iconSize: 20,
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: MerchantOnboardingColors.bgDark2,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MerchantOnboardingColors.primaryGold,
                ),
                minHeight: 6,
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

