import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/presentation/responsive_scroll_body.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/utils/cities.dart';
import '../../../core/utils/image_crop_utils.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/infrastructure/user_repository_provider.dart';
import '../../merchant_onboarding/application/widgets.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../storage/application/providers.dart' as storage_providers;
import '../../auth/signup/presentation/widgets/city_selection_modal.dart';

part 'client_onboarding_screen.part.dart';

/// Client onboarding: first name, last name, date of birth, city, then profile photo.
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
  // Welcome + name + dob + city + photo = 5 steps
  static const _totalSteps = 5;

  final _pageController = PageController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _canProceedName = false;
  DateTime? _selectedDob;
  String? _selectedCity;
  String? _localImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final ok = _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
    if (ok != _canProceedName) setState(() => _canProceedName = ok);
  }

  bool get _canProceedDob => _selectedDob != null;

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      locale: const Locale('fr'),
        builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            onPrimary: Color(0xFF0E2A44),
            surface: Color(0xFF0E2A44),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0B1F33),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final cropped = await cropImage(picked.path, ratioX: 1, ratioY: 1);
    if (mounted) setState(() => _localImagePath = cropped ?? picked.path);
  }

  Future<void> _finish({required bool skipPhoto}) async {
    if (_isSaving) return;
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final uid = authState.user.id;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;
    final displayName = '$firstName $lastName';

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
      displayName: displayName,
      city: _selectedCity?.trim().isEmpty == true ? null : _selectedCity,
      photoUrl: photoUrl,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: _selectedDob,
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
          await u?.updateDisplayName(displayName);
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
                          _buildDobStep(),
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
