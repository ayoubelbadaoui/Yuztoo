import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/presentation/responsive_scroll_body.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/cupertino_dob_picker.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/utils/cities.dart';
import '../../../core/utils/image_crop_utils.dart';
import '../../../core/utils/oauth_profile_photo.dart';
import '../../auth/core/application/oauth_identity_helpers.dart';
import '../../auth/core/application/providers.dart';
import '../../profile/application/providers.dart' show refreshUserProfileCache;
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
  /// Profile photo URL from Google (Firebase Auth `photoURL`). Apple does not
  /// provide a photo — the user takes or picks one on the photo step.
  String? _oauthPhotoUrl;
  bool _isSaving = false;

  bool get _hasPhotoPreview =>
      (_localImagePath != null && _localImagePath!.trim().isNotEmpty) ||
      isUsableOAuthProfilePhotoUrl(_oauthPhotoUrl);

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromAuthUser());
  }

  void _seedFromAuthUser() {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final user = authState.user;
    final url = user.photoUrl?.trim();
    final names = splitOAuthDisplayName(user.displayName);
    setState(() {
      if (isUsableOAuthProfilePhotoUrl(url)) {
        _oauthPhotoUrl = url;
      }
      if (_firstNameController.text.trim().isEmpty &&
          names.firstName != null &&
          names.firstName!.isNotEmpty) {
        _firstNameController.text = names.firstName!;
      }
      if (_lastNameController.text.trim().isEmpty &&
          names.lastName != null &&
          names.lastName!.isNotEmpty) {
        _lastNameController.text = names.lastName!;
      }
      _onNameChanged();
    });
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
    final initial = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showCupertinoDobPicker(
      context: context,
      initial: initial,
      minimum: DateTime(1920),
      maximum: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choisir une photo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textWhite,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: MerchantColors.gold),
                title: Text(
                  'Prendre une photo',
                  style: GoogleFonts.outfit(color: MerchantColors.textWhite),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: MerchantColors.gold),
                title: Text(
                  'Choisir depuis la galerie',
                  style: GoogleFonts.outfit(color: MerchantColors.textWhite),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final cropped = await cropImage(picked.path, ratioX: 1, ratioY: 1);
    if (mounted) setState(() => _localImagePath = cropped ?? picked.path);
  }

  Future<String?> _uploadProfilePhoto(String uid) async {
    final localPath = _localImagePath?.trim();
    if (localPath != null && localPath.isNotEmpty) {
      final upload = await ref
          .read(storage_providers.uploadClientAvatarProvider)
          .call(filePath: localPath, uid: uid);
      return upload.fold((_) => null, (u) => u);
    }

    final oauthUrl = _oauthPhotoUrl?.trim();
    if (!isUsableOAuthProfilePhotoUrl(oauthUrl)) return null;

    final downloaded = await downloadOAuthProfilePhotoToTempFile(oauthUrl!);
    if (downloaded != null) {
      final upload = await ref
          .read(storage_providers.uploadClientAvatarProvider)
          .call(filePath: downloaded, uid: uid);
      final url = upload.fold((_) => null, (u) => u);
      if (url != null) return url;
    }
    // Fallback: keep provider URL in Firestore if download/upload fails.
    return oauthUrl;
  }

  Future<void> _finish({required bool skipPhoto}) async {
    if (_isSaving) return;
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final uid = authState.user.id;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) return;
    if (_selectedDob == null) return;
    final displayName = '$firstName $lastName';

    setState(() => _isSaving = true);

    String? photoUrl;
    if (!skipPhoto && _hasPhotoPreview) {
      photoUrl = await _uploadProfilePhoto(uid);
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
        final auth = ref.read(authControllerProvider);
        if (auth is Authenticated) {
          await refreshUserProfileCache(ref as Ref, uid: auth.user.id);
        }
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
