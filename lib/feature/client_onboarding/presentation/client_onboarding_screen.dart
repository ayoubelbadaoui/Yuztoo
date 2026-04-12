import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/infrastructure/user_repository_provider.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../storage/application/providers.dart' as storage_providers;

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
  static const _totalSteps = 3;

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  int _currentStep = 0;
  bool _canProceedName = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec du téléversement de la photo. Réessayez ou passez cette étape.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final repo = ref.read(userRepositoryProvider);
    final result = await repo.completeClientProfile(
      uid: uid,
      displayName: name,
      photoUrl: photoUrl,
    );

    if (!mounted) return;

    result.fold(
      (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement.'),
            backgroundColor: Colors.red,
          ),
        );
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
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWelcomeStep(),
                        _buildNameStep(),
                        _buildPhotoStep(),
                      ],
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

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: (_currentStep > 0 && !_isSaving) ? _goBack : null,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: MerchantOnboardingColors.primaryGold,
              size: 20,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (_currentStep + 1) / _totalSteps),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: MerchantOnboardingColors.bgDark2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      MerchantOnboardingColors.primaryGold,
                    ),
                    minHeight: 6,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return SizedBox.expand(
      key: const ValueKey('loading'),
      child: Container(
        color: MerchantColors.bgMain,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MerchantOnboardingColors.primaryGold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enregistrement...',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: MerchantOnboardingColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 44,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenue',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Complétez votre profil en quelques étapes pour commencer à utiliser votre espace client.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.5,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Commencer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantOnboardingColors.bgDark2,
              border: Border.all(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: MerchantOnboardingColors.primaryGold,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Comment vous appelez-vous ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: MerchantOnboardingColors.textLight,
            ),
            cursorColor: MerchantOnboardingColors.primaryGold,
            decoration: InputDecoration(
              hintText: 'Ex: Marie Dupont',
              hintStyle: GoogleFonts.outfit(
                color: MerchantOnboardingColors.textGrey,
              ),
              filled: true,
              fillColor: MerchantOnboardingColors.bgDark2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_canProceedName && !_isSaving) ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                disabledBackgroundColor:
                    MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _canProceedName ? 4 : 0,
              ),
              child: Text(
                'Suivant',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _isSaving ? null : _pickPhoto,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantOnboardingColors.bgDark2,
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _localImagePath != null
                  ? Image.file(
                      File(_localImagePath!),
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.add_a_photo_outlined,
                      size: 48,
                      color: MerchantOnboardingColors.primaryGold,
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Photo de profil',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ajoutez une photo depuis la galerie, ou passez cette étape.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 22),
              label: Text(
                'Choisir une photo',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MerchantOnboardingColors.primaryGold,
                side: const BorderSide(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _finish(skipPhoto: _localImagePath == null),
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Terminer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isSaving ? null : () => _finish(skipPhoto: true),
            child: Text(
              'Passer',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MerchantOnboardingColors.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
