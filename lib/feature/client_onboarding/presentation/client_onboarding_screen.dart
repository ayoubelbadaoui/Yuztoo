import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/utils/cities.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/infrastructure/user_repository_provider.dart';
import '../../merchant_onboarding/application/widgets.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../storage/application/providers.dart' as storage_providers;
import '../../auth/signup/presentation/widgets/city_selection_modal.dart';

part 'client_onboarding_screen.part.dart';

/// Two-step client onboarding after signup: full name, then profile photo (optional).
class ClientOnboardingScreen extends ConsumerStatefulWidget {
  const ClientOnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  ConsumerState<ClientOnboardingScreen> createState() =>
      _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends ConsumerState<ClientOnboardingScreen> {
  static const _totalSteps = 4;

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _canProceedName = false;
  String? _selectedCity;
  String? _localImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillName());
  }

  void _prefillName() {
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth is! Authenticated) return;
    final existing = auth.user.displayName?.trim();
    if (existing != null && existing.isNotEmpty) {
      _nameController.text = existing;
      _onNameChanged();
    }
  }

  void _onNameChanged() {
    final ok = _nameController.text.trim().isNotEmpty;
    if (ok != _canProceedName) setState(() => _canProceedName = ok);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _pageController.dispose();
    _nameController.dispose();
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
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _localImagePath = picked.path);
    }
  }

  Future<void> _finish({required bool skipPhoto}) async {
    if (_isSaving) return;
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final uid = authState.user.id;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    String? photoUrl;
    final path = _localImagePath?.trim();
    if (!skipPhoto && path != null && path.isNotEmpty) {
      final upload = await ref.read(storage_providers.uploadClientAvatarProvider).call(
            filePath: path,
            uid: uid,
          );
      photoUrl = upload.fold((_) => null, (u) => u);
      if (photoUrl == null && mounted) {
        showErrorSnackbar(
          context,
          'Échec du téléversement de la photo. Réessayez ou passez cette étape.',
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final repo = ref.read(userRepositoryProvider);
    final result = await repo.completeClientProfile(
      uid: uid,
      displayName: name,
      city: _selectedCity?.trim().isEmpty == true ? null : _selectedCity,
      photoUrl: photoUrl,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        if (!mounted) return;
        showErrorSnackbar(context, failure.message);
        setState(() => _isSaving = false);
      },
      (_) async {
        try {
          final u = firebase_auth.FirebaseAuth.instance.currentUser;
          await u?.updateDisplayName(name);
          if (photoUrl != null && photoUrl.isNotEmpty) {
            await u?.updatePhotoURL(photoUrl);
          }
        } catch (_) {}
        await ref.read(authControllerProvider.notifier).refreshAuthState();
        if (!mounted) return;
        setState(() => _isSaving = false);
        widget.onComplete();
      },
    );
  }

  void _onCitySelected(String city) {
    setState(() => _selectedCity = city);
  }

  @override
  Widget build(BuildContext context) {
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
          if (!didPop) _goBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top),
                  _buildProgressBar(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom,
                      ),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildWelcomeStep(),
                          _buildNameStep(),
                          _buildCityStep(),
                          _buildPhotoStep(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSaving ? _buildLoadingOverlay() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
