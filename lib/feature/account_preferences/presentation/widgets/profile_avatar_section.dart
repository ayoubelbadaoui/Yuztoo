import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/user_display_helpers.dart';
import '../../../auth/core/application/providers.dart' show updateAuthUserProfileProvider;
import '../../../storage/application/providers.dart' show uploadClientAvatarProvider;
import '../../application/providers.dart';

part 'profile_avatar_section.part.dart';

/// Profile avatar (gold-bordered circle) + personal user info text.
/// Loads personal user data from Firestore (email, phone, city, displayName).
/// Separate from business/merchant profile - this is the user's personal account info.
/// Allows user to select and save personal profile picture.
class ProfileAvatarSection extends ConsumerStatefulWidget {
  const ProfileAvatarSection({super.key, this.onEditProfile});

  /// Called when the user taps the name / edit-icon to open identification settings.
  final VoidCallback? onEditProfile;

  @override
  ConsumerState<ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends ConsumerState<ProfileAvatarSection> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  bool _isUploading = false;

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
      builder: (context) => _buildImagePickerSheet(context),
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
          _isUploading = true;
        });

        await _saveProfileImageToCache(file.path);
        await _uploadAvatarToCloud(file);
      }
    } catch (e) {
      if (!context.mounted) return;
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
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadAvatarToCloud(File file) async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final uid = authState.user.id;
    final uploadResult = await ref
        .read(uploadClientAvatarProvider)
        .call(filePath: file.path, uid: uid);

    await uploadResult.fold(
      (failure) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo sauvegardée localement (sync cloud échouée)'),
            backgroundColor: MerchantColors.navyCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      (downloadUrl) async {
        await ref
            .read(updateAuthUserProfileProvider)
            .call(photoUrl: downloadUrl);
      },
    );
  }

  Future<void> _saveProfileImageToCache(String imagePath) async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;

    final userId = authState.user.id;
    await ref
        .read(personalProfileImageCacheProvider)
        .saveCachedImagePath(userId, imagePath);
    ref.invalidate(personalProfileImagePathProvider(userId));
  }

  @override
  Widget build(BuildContext context) => _profileAvatarBuild(context);
}
