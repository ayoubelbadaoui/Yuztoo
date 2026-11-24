import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/domain/entities/french_commune.dart';
import '../../../core/presentation/responsive_scroll_body.dart';
import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/cupertino_dob_picker.dart';
import '../../../core/shared/widgets/edge_swipe_back.dart';
import '../../../core/shared/widgets/leave_onboarding_dialog.dart';
import '../../../core/shared/widgets/step_switcher_layout.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../../core/utils/cities.dart';
import '../../../core/utils/city_match.dart';
import '../../../core/utils/image_pick_with_source.dart';
import '../../../core/utils/oauth_profile_photo.dart';
import '../../auth/core/application/oauth_identity_helpers.dart';
import '../../auth/core/application/onboarding_completion_cache.dart';
import '../../auth/core/application/providers.dart';
import '../../profile/application/providers.dart'
    show refreshUserProfileCacheWidget;
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/infrastructure/user_repository_provider.dart';
import '../../merchant_onboarding/application/widgets.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../storage/application/providers.dart' as storage_providers;
import '../application/client_onboarding_draft.dart';
import '../../auth/signup/presentation/widgets/city_selection_modal.dart';

part 'client_onboarding_screen.part.dart';

/// Client onboarding: first + last name required; DOB, city, photo optional.
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

class _ClientOnboardingScreenState
    extends ConsumerState<ClientOnboardingScreen> {
  // Welcome + name + dob + city + photo = 5 steps
  static const _totalSteps = 5;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _canProceedName = false;
  DateTime? _selectedDob;
  String? _selectedCity;
  FrenchCommune? _selectedCommune;
  String? _localImagePath;

  /// Profile photo URL from Google (Firebase Auth `photoURL`). Apple does not
  /// provide a photo — the user takes or picks one on the photo step.
  String? _oauthPhotoUrl;
  bool _isSaving = false;

  /// Index of the name step (welcome=0, name=1, …).
  static const _nameStepIndex = 1;

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
    // Runs one frame late, so routing may already have disposed this screen.
    if (!mounted) return;
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
    unawaited(_restoreDraft(user.id));
  }

  /// App killed / phone restarted mid-onboarding: resume where the client
  /// left off instead of « Bienvenue » with empty fields.
  Future<void> _restoreDraft(String uid) async {
    final draft = await ClientOnboardingDraftStore.load(uid);
    if (draft == null || !mounted || _isSaving) return;
    final resumeAt = draft.resumeStep(_totalSteps - 1);
    setState(() {
      if (draft.firstName.trim().isNotEmpty) {
        _firstNameController.text = draft.firstName;
      }
      if (draft.lastName.trim().isNotEmpty) {
        _lastNameController.text = draft.lastName;
      }
      _selectedDob ??= draft.dateOfBirth;
      if (_selectedCity == null && draft.city != null) {
        _selectedCity = draft.city;
        _selectedCommune = draft.commune;
      }
      _localImagePath ??= draft.localImagePath;
      // Only jump if the user hasn't started moving in the meantime.
      if (_currentStep == 0) _currentStep = resumeAt;
    });
    _onNameChanged();
    if (_currentStep == _nameStepIndex) _focusFirstNameAfterStepSettles();
    if (_currentStep == _totalSteps - 1) unawaited(_recoverLostAndroidPhoto());
  }

  /// Android may kill the app while the camera / gallery is open (low-RAM
  /// Samsungs, camera apps are heavy). The draft brings the client back to
  /// the photo step, and image_picker kept the photo they just took: fetch
  /// it instead of making them take it again.
  Future<void> _recoverLostAndroidPhoto() async {
    if (!Platform.isAndroid || _localImagePath != null) return;
    try {
      final lost = await _picker.retrieveLostData();
      final path = lost.file?.path;
      if (lost.isEmpty || path == null || !mounted) return;
      if (!File(path).existsSync()) return;
      setState(() => _localImagePath = path);
      _saveDraft();
    } catch (_) {
      // Nothing recoverable: the client simply picks a photo again.
    }
  }

  Future<void> _leaveOnboarding() async {
    final auth = ref.read(authStateProvider);
    final label = auth is Authenticated
        ? (auth.user.email?.trim().isNotEmpty == true
            ? auth.user.email
            : auth.user.phoneNumber)
        : null;
    final leave = await confirmLeaveOnboarding(context, accountLabel: label);
    if (!leave || !mounted) return;
    _saveDraft();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  void _saveDraft() {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    unawaited(ClientOnboardingDraftStore.save(
      authState.user.id,
      ClientOnboardingDraft(
        step: _currentStep,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _selectedDob,
        city: _selectedCity,
        commune: _selectedCommune,
        localImagePath: _localImagePath,
      ),
    ));
  }

  void _onNameChanged() {
    final ok = _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
    if (ok != _canProceedName) setState(() => _canProceedName = ok);
    if (_currentStep == _nameStepIndex) _saveDraft();
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  /// Only the active step is built (no off-screen PageView TextFields), which
  /// avoids Samsung/Android IME failing to attach to hidden fields.
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildNameStep();
      case 2:
        return _buildDobStep();
      case 3:
        return _buildCityStep();
      case 4:
        return _buildPhotoStep();
      default:
        return _buildWelcomeStep();
    }
  }

  void _focusFirstNameAfterStepSettles() {
    // Wait one frame + short settle so the freshly-mounted TextField is
    // hit-testable before the IME attaches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || _currentStep != _nameStepIndex) return;
        _firstNameFocus.requestFocus();
      });
    });
  }

  void _goNext() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep < _totalSteps - 1) {
      final next = _currentStep + 1;
      setState(() => _currentStep = next);
      _saveDraft();
      if (next == _nameStepIndex) _focusFirstNameAfterStepSettles();
    }
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep > 0) {
      final prev = _currentStep - 1;
      setState(() => _currentStep = prev);
      _saveDraft();
      if (prev == _nameStepIndex) _focusFirstNameAfterStepSettles();
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    // Default to today so the wheel opens on a familiar date instead of
    // an arbitrary "X years ago, January 1". The picker clamps to the
    // configured max (today − 13y) on render — the user adjusts down.
    final initial = _selectedDob ?? now;
    final picked = await showCupertinoDobPicker(
      context: context,
      initial: initial,
      minimum: DateTime(1920),
      maximum: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDob = picked);
      _saveDraft();
    }
  }

  Future<void> _pickPhoto() async {
    final path = await pickImageWithSourceChoice(
      context: context,
      picker: _picker,
      sheetTitle: 'Photo de profil',
      maxWidth: 800,
      cropRatioX: 1,
      cropRatioY: 1,
      cropCircleShape: true,
    );
    if (path == null || !mounted) return;
    setState(() => _localImagePath = path);
    _saveDraft();
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
    if (authState is! Authenticated) {
      // Never a silent no-op on the last button.
      showErrorSnackbar(
        context,
        'Session expirée. Reconnectez-vous puis réessayez.',
      );
      return;
    }

    final uid = authState.user.id;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      // Possible only if the name step was skipped (fast double tap).
      setState(() => _currentStep = _nameStepIndex);
      _focusFirstNameAfterStepSettles();
      return;
    }
    final displayName = '$firstName $lastName';

    setState(() => _isSaving = true);

    String? photoUrl;
    if (!skipPhoto && _hasPhotoPreview) {
      // Offline / very slow network: Storage retries for minutes. Give up
      // after 30s and fall back to the "terminer sans photo" path below.
      photoUrl = await _uploadProfilePhoto(uid)
          .timeout(const Duration(seconds: 30), onTimeout: () => null);
      if (photoUrl == null && mounted) {
        // Drop the failed preview so the CTA falls back to
        // "Terminer sans photo". Without this the only button on the
        // last step retries the same failing upload forever.
        setState(() {
          _localImagePath = null;
          _isSaving = false;
        });
        showErrorSnackbar(
          context,
          'Échec du téléversement de la photo. Vous pouvez terminer sans photo '
          'ou en choisir une autre.',
        );
        return;
      }
    }

    final repo = ref.read(userRepositoryProvider);
    // An offline Firestore write never completes until the server acks, which
    // left a full-screen spinner with back disabled. Stop waiting after 20s;
    // retrying is safe (same idempotent update).
    final result = await () async {
      try {
        return await repo
            .completeClientProfile(
              uid: uid,
              displayName: displayName,
              city:
                  _selectedCity?.trim().isEmpty == true ? null : _selectedCity,
              commune: _selectedCommune,
              photoUrl: photoUrl,
              firstName: firstName,
              lastName: lastName,
              dateOfBirth: _selectedDob,
            )
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        return null;
      }
    }();

    if (!mounted) return;
    if (result == null) {
      setState(() => _isSaving = false);
      showErrorSnackbar(
        context,
        'Connexion trop lente. Vérifiez votre réseau puis réessayez.',
      );
      return;
    }

    result.fold(
      (failure) {
        if (!mounted) return;
        showErrorSnackbar(context, failure.message);
        setState(() => _isSaving = false);
      },
      (_) async {
        // Cosmetic Auth-profile copy (Firestore is already saved): bounded
        // so a flaky network never keeps the overlay up after success.
        try {
          final u = firebase_auth.FirebaseAuth.instance.currentUser;
          await () async {
            await u?.updateDisplayName(displayName);
            if (photoUrl != null && photoUrl.isNotEmpty) {
              await u?.updatePhotoURL(photoUrl);
            }
          }()
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
        // Navigate FIRST, then refresh the auth/profile cache in the
        // background. The previous order (refresh, then navigate)
        // synchronously re-emitted the auth state from `reloadProfile()`
        // mid-await, which dumped the user on splash for the entire
        // 5–30s role-lookup retry window in `_handleAuthenticatedUser`
        // — perceived as "the app is stuck loading after I finish
        // onboarding". The home screen will pick up the refreshed
        // profile values once the unawaited reload lands; in the
        // intervening tens of milliseconds it shows the just-written
        // displayName from cache, which is correct.
        unawaited(OnboardingCompletionCache.markCompleted('client', uid));
        unawaited(ClientOnboardingDraftStore.clear(uid));
        if (!mounted) return;
        setState(() => _isSaving = false);
        widget.onComplete();
        final auth = ref.read(authControllerProvider);
        if (auth is Authenticated) {
          unawaited(refreshUserProfileCacheWidget(ref, uid: auth.user.id));
        }
      },
    );
  }

  void _onCitySelected(String city) {
    if (!mounted) return;
    setState(() {
      _selectedCity = city;
      _selectedCommune = null;
    });
    _saveDraft();
  }

  void _onCommuneSelected(FrenchCommune commune) {
    if (!mounted) return;
    // Details arrive after the sheet closes: ignore them if the user has
    // picked another city meanwhile.
    if (CityMatch.key(_selectedCity ?? '') != CityMatch.key(commune.name)) {
      return;
    }
    setState(() {
      _selectedCity = commune.name;
      _selectedCommune = commune;
    });
    _saveDraft();
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
          // Ignore system back while saving, otherwise the step changes
          // underneath the loading overlay and _finish lands on a
          // different screen than the one the user confirmed.
          if (!didPop && !_isSaving) _goBack();
        },
        child: EdgeSwipeBack(
          enabled: _currentStep > 0 && !_isSaving,
          onBack: _goBack,
          child: Scaffold(
            backgroundColor: MerchantColors.bgMain,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: MediaQuery.viewPaddingOf(context).top),
                    _buildProgressBar(),
                    Expanded(
                      // SafeArea(bottom) keeps Suivant / Passer above Samsung
                      // 3-button / gesture nav; top is handled manually above.
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          layoutBuilder: stepSwitcherLayout,
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentStep),
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSaving
                      ? _buildLoadingOverlay()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
