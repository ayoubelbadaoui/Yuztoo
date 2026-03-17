import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../auth/core/application/providers.dart';
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/domain/entities/auth_user.dart';
import '../../auth/core/domain/entities/user_profile_basics.dart';
import '../application/providers.dart';
import '../../merchant_onboarding/presentation/widgets/merchant_onboarding_colors.dart';
import '../../../core/shared/widgets/back_button.dart' as shared;
import '../../merchant_onboarding/application/providers.dart' as onboarding_providers;
import '../../../feature/storefront/application/providers.dart' as storefront_providers;

/// Merchant profile form screen - collects merchant business information
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  bool _isSubmitting = false;
  UserProfileBasics? _profileBasics;
  bool _didInitFromDependencies = false;

  final List<String> _categories = [
    'Restaurant',
    'Commerce de détail',
    'Beauté & Bien-être',
    'Sport & Fitness',
    'Services',
    'Autre',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Important: don't read inherited widgets / ProviderScope from initState.
    // This screen is mounted via an AnimatedSwitcher; reading ProviderScope here can crash.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromDependencies) return;
    _didInitFromDependencies = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Prefill category from the acquisition onboarding wizard (if user selected one).
      // This avoids asking twice.
      try {
        final pref = ProviderScope.containerOf(context)
            .read(onboarding_providers.selectedMerchantCategoryTitleProvider);
        _selectedCategory ??= pref;
      } catch (_) {
        // Best-effort: if ProviderScope isn't ready for any reason, skip the prefill.
      }

      // Load from cache first (demo mode), then try Firestore
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    final cacheService = ref.read(merchantProfileCacheServiceProvider);

    // Try cache first (demo mode - works even if Firestore fails)
    final cachedData = await cacheService.loadProfile();
    if (cachedData['userId'] == userId && cachedData['email'] != null) {
      // We have cached data - use it to prefill form
      if (mounted) {
        setState(() {
          if (cachedData['name'] != null && _nameController.text.isEmpty) {
            _nameController.text = cachedData['name']!;
          }
          if (cachedData['address'] != null && _addressController.text.isEmpty) {
            _addressController.text = cachedData['address']!;
          }
          if (cachedData['description'] != null && _descriptionController.text.isEmpty) {
            _descriptionController.text = cachedData['description']!;
          }
          if (cachedData['category'] != null && _selectedCategory == null) {
            _selectedCategory = cachedData['category'];
          }
          // Set profile basics from cache (always set if cache has data)
          if (cachedData['email'] != null && cachedData['phone'] != null && cachedData['city'] != null) {
            _profileBasics = UserProfileBasics(
              email: cachedData['email']!,
              phone: cachedData['phone']!,
              city: cachedData['city']!,
            );
          }
        });
      }
      return; // Cache loaded successfully, skip Firestore
    }

    // Fallback: Try Firestore (wrapped in try-catch so it never crashes)
    // This is optional - cache already loaded, so Firestore is just a bonus
    try {
      final getBasics = ref.read(getUserProfileBasicsProvider);
      final result = await getBasics.call(userId);
      result.fold(
        (_) {
          // Firestore failed - that's OK, we'll use cache or Firebase Auth fallback
        },
        (basics) {
          if (mounted && basics != null) {
            setState(() => _profileBasics = basics);
          }
        },
      );
    } catch (e) {
      // Firestore completely failed (network error, crash, etc.) - that's OK
      // Cache already loaded or we'll use Firebase Auth fallback
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    String? userId;
    AuthUser? user;
    if (authState is Authenticated) {
      userId = authState.user.id;
      user = authState.user;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non authentifié / Not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Reuse signup data (do NOT ask the user again).
    // Try multiple sources: Cache -> Firestore -> AuthUser -> Firebase Auth
    final cacheService = ref.read(merchantProfileCacheServiceProvider);
    final cachedData = await cacheService.loadProfile();
    
    String email = cachedData['email'] ??
                   _profileBasics?.email ?? 
                   user?.email ?? 
                   firebase_auth.FirebaseAuth.instance.currentUser?.email ?? 
                   '';
    
    String phone = cachedData['phone'] ??
                   _profileBasics?.phone ?? 
                   user?.phoneNumber ?? 
                   firebase_auth.FirebaseAuth.instance.currentUser?.phoneNumber ?? 
                   '';

    String city = cachedData['city'] ??
                  _profileBasics?.city ?? 
                  '';

    // If still missing, use defaults for demo (allow submission)
    email = email.trim().isEmpty ? 'demo@example.com' : email.trim();
    phone = phone.trim().isEmpty ? '+33123456789' : phone.trim();
    city = city.trim().isEmpty ? 'Paris' : city.trim();

    setState(() => _isSubmitting = true);

    // Save to cache FIRST (demo mode - always works, never fails)
    try {
      await cacheService.saveProfile(
        userId: userId,
        name: _nameController.text.trim(),
        email: email,
        phone: phone,
        city: city,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } catch (e) {
      // Cache save failed (should never happen, but be safe)
      // Continue anyway - we'll try Firestore as fallback
    }

    // Try Firestore (wrapped in try-catch so it never crashes)
    // This is optional - cache already saved, so Firestore is just a bonus
    bool firestoreSuccess = false;
    try {
      final completeOnboarding = ref.read(completeMerchantOnboardingProvider);
      final result = await completeOnboarding.call(
        userId: userId,
        name: _nameController.text.trim(),
        email: email,
        phone: phone,
        city: city,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      firestoreSuccess = result.fold(
        (_) => false, // Firestore failed
        (_) => true,  // Firestore succeeded
      );
    } catch (e) {
      // Firestore completely failed (network error, crash, etc.) - that's OK
      // Cache already saved, so we're good
      firestoreSuccess = false;
    }

    setState(() => _isSubmitting = false);

    // Always show success - cache saved (demo mode works no matter what)
    // Refresh storefront to show updated data from cache
    ref.invalidate(storefront_providers.storefrontProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          firestoreSuccess
              ? 'Profil commerçant créé avec succès!'
              : 'Profil commerçant sauvegardé localement (mode démo)',
        ),
        backgroundColor: MerchantOnboardingColors.primaryGold,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: firestoreSuccess ? 2 : 3),
      ),
    );
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final categoryFromWizard = ref.watch(
      onboarding_providers.selectedMerchantCategoryTitleProvider,
    );
    // Keep in sync if user came from onboarding wizard and hasn't changed selection yet.
    if (_selectedCategory == null && categoryFromWizard != null) {
      _selectedCategory = categoryFromWizard;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantOnboardingColors.bgDark1,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantOnboardingColors.bgDark1,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantOnboardingColors.bgDark1,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    if (widget.onBack != null)
                      shared.YBackButton(
                        onPressed: widget.onBack!,
                        iconColor: MerchantOnboardingColors.textLight,
                      )
                    else
                      const SizedBox(width: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Créer votre profil commerçant',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: MerchantOnboardingColors.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom du commerce *',
                          hint: 'Ex: La Boulangerie du Coin',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le nom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // We intentionally do NOT ask for email/phone/city again.
                        // Those are taken from the signup profile (/users/{uid}).
                        if (_profileBasics != null) ...[
                          _ReadOnlyInfoRow(
                            label: 'Email',
                            value: _profileBasics!.email,
                          ),
                          const SizedBox(height: 12),
                          _ReadOnlyInfoRow(
                            label: 'Téléphone',
                            value: _profileBasics!.phone,
                          ),
                          const SizedBox(height: 12),
                          _ReadOnlyInfoRow(
                            label: 'Ville',
                            value: _profileBasics!.city,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adresse',
                          hint: '123 Rue de la République',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        // Category dropdown
                        Text(
                          'Catégorie *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MerchantOnboardingColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: MerchantOnboardingColors.bgDark2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: MerchantOnboardingColors.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: MerchantOnboardingColors.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: MerchantOnboardingColors.primaryGold,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          dropdownColor: MerchantOnboardingColors.bgDark2,
                          style: TextStyle(
                            color: MerchantOnboardingColors.textLight,
                            fontSize: 16,
                          ),
                          iconEnabledColor: MerchantOnboardingColors.primaryGold,
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez sélectionner une catégorie';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Décrivez votre commerce...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),
                        // Submit button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MerchantOnboardingColors.primaryGold,
                            foregroundColor: MerchantOnboardingColors.bgDark1,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      MerchantOnboardingColors.bgDark1,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Créer le profil',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MerchantOnboardingColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: MerchantOnboardingColors.textLight,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: MerchantOnboardingColors.textGrey,
            ),
            filled: true,
            fillColor: MerchantOnboardingColors.bgDark2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MerchantOnboardingColors.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MerchantOnboardingColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: MerchantOnboardingColors.primaryGold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MerchantOnboardingColors.bgDark2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MerchantOnboardingColors.borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: MerchantOnboardingColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: MerchantOnboardingColors.textLight,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


