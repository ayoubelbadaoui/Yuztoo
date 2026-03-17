import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../auth/core/domain/entities/user_profile_basics.dart';

/// Profile avatar (gold-bordered circle) + personal user info text.
/// Loads personal user data from Firestore (email, phone, city, displayName).
/// Separate from business/merchant profile - this is the user's personal account info.
/// Allows user to select and save personal profile picture.
class ProfileAvatarSection extends ConsumerStatefulWidget {
  const ProfileAvatarSection({super.key});

  @override
  ConsumerState<ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends ConsumerState<ProfileAvatarSection> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;

  void _loadProfileImageFromCache(String? imagePath) {
    if (!mounted) return;
    
    if (imagePath == null || imagePath.isEmpty) {
      if (_profileImageFile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _profileImageFile = null;
            });
          }
        });
      }
      return;
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      if (_profileImageFile?.path != file.path) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _profileImageFile = file;
            });
          }
        });
      }
    } else if (_profileImageFile != null) {
      // File doesn't exist anymore, clear it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _profileImageFile = null;
          });
        }
      });
    }
  }

  Future<void> _showImagePickerSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.bgMain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MerchantColors.bgMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: MerchantColors.textGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Changer la photo de profil',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PickerOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  _PickerOption(
                    icon: Icons.camera_alt,
                    label: 'Caméra',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        setState(() {
          _profileImageFile = file;
        });
        
        // Save to cache
        await _saveProfileImageToCache(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfileImageToCache(String imagePath) async {
    final authState = ref.read(auth_providers.authStateProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    // Save personal profile picture to SharedPreferences (separate from merchant cache)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_personal_profile_image_$userId', imagePath);
    
    // Invalidate provider to refresh UI
    ref.invalidate(_personalProfileImageProvider(userId));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(auth_providers.authStateProvider);
    
    // Only load data if user is authenticated
    if (authState is! Authenticated) {
      return _buildLoadingState();
    }

    final userId = authState.user.id;
    
    // Load user profile basics from Firestore (email, phone, city)
    final profileBasicsAsync = ref.watch(
      _userProfileBasicsProvider(userId),
    );
    
    // Load personal profile image (separate from merchant business profile)
    final personalImagePathAsync = ref.watch(
      _personalProfileImageProvider(userId),
    );

    // Load profile image from cache when it updates
    final imagePath = personalImagePathAsync.valueOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileImageFromCache(imagePath);
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── avatar circle (tappable) ──
          GestureDetector(
            onTap: () => _showImagePickerSheet(context),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.navyCard,
                border: Border.all(color: MerchantColors.gold, width: 3),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Show image if available, otherwise show icon
                  if (_profileImageFile != null)
                    ClipOval(
                      child: Image.file(
                        _profileImageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.person,
                              color: MerchantColors.gold,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.person,
                        color: MerchantColors.gold,
                        size: 48,
                      ),
                    ),
                  // Overlay to indicate it's tappable
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── info lines ──
          Expanded(
            child: profileBasicsAsync.when(
              data: (profileBasics) {
                // Extract PERSONAL user data (not business/merchant data)
                final name = authState.user.displayName ?? 
                           'Utilisateur';
                final email = profileBasics?.email ?? 
                            authState.user.email ?? 
                            '';
                final phone = profileBasics?.phone ?? 
                            authState.user.phoneNumber ?? 
                            '';
                final city = profileBasics?.city ?? '';
                // Note: Address is NOT shown here - that's business info, not personal

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (city.isNotEmpty) _infoLine(city),
                    if (phone.isNotEmpty) _infoLine('Tel: $phone'),
                    if (email.isNotEmpty) _infoLine(email),
                    if (name == 'Utilisateur' && 
                        email.isEmpty && 
                        phone.isEmpty && 
                        city.isEmpty)
                      _infoLine('Chargement...', style: TextStyle(
                        color: MerchantColors.textGrey.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      )),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chargement...',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoLine('Chargement des données...', style: TextStyle(
                    color: MerchantColors.textGrey.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  )),
                ],
              ),
              error: (error, stack) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilisateur',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _infoLine('Impossible de charger les données', style: TextStyle(
                    color: Colors.red.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // Show image picker even in loading state
              final authState = ref.read(auth_providers.authStateProvider);
              if (authState is Authenticated) {
                _showImagePickerSheet(context);
              }
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.navyCard,
                border: Border.all(color: MerchantColors.gold, width: 3),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_profileImageFile != null)
                    ClipOval(
                      child: Image.file(
                        _profileImageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.person,
                              color: MerchantColors.gold,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.person,
                        color: MerchantColors.gold,
                        size: 48,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chargement...',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: style ?? GoogleFonts.outfit(
          fontSize: 13,
          color: MerchantColors.textGrey,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Provider for loading user profile basics from Firestore
final _userProfileBasicsProvider = FutureProvider.family<
    UserProfileBasics?, String>((ref, userId) async {
  final getBasics = ref.read(auth_providers.getUserProfileBasicsProvider);
  final result = await getBasics.call(userId);
  return result.fold(
    (_) => null, // On error, return null (will show fallback)
    (basics) => basics,
  );
});

/// Provider for loading personal profile image (separate from merchant business profile)
final _personalProfileImageProvider = FutureProvider.family<String?, String>(
  (ref, userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_personal_profile_image_$userId');
  },
);

/// Image picker option widget with merchant colors
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.navyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MerchantColors.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: MerchantColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: MerchantColors.darkOverlay, 
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

