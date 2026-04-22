import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/utils/city_input.dart';
import '../application/profile_edit_state.dart';
import '../application/providers.dart';
import 'widgets/storefront_colors.dart';

part 'storefront_edit_profile_screen.part.dart';

class StorefrontEditProfileScreen extends ConsumerStatefulWidget {
  const StorefrontEditProfileScreen({super.key});

  @override
  ConsumerState<StorefrontEditProfileScreen> createState() =>
      _StorefrontEditProfileScreenState();
}

class _StorefrontEditProfileScreenState
    extends ConsumerState<StorefrontEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _controllersInitialized = false;
  File? _bannerImageFile;
  File? _profileImageFile;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _webCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  void _ensureControllers(StorefrontProfileEditState s) {
    // Always sync controllers with state (in case state updates after initialization)
    try {
      if (_nameCtrl.text != s.businessName) _nameCtrl.text = s.businessName;
      if (_descCtrl.text != s.description) _descCtrl.text = s.description;
      if (_phoneCtrl.text != s.phoneNumber) _phoneCtrl.text = s.phoneNumber;
      if (_webCtrl.text != s.websiteUrl) _webCtrl.text = s.websiteUrl;
      if (_addrCtrl.text != s.address) _addrCtrl.text = s.address;
      if (_cityCtrl.text != s.city) _cityCtrl.text = s.city;
      _controllersInitialized = true;
    } catch (e) {
      // If setting text fails, use safe fallbacks
      if (!_controllersInitialized) {
        try {
          _nameCtrl.text = s.businessName.isNotEmpty ? s.businessName : '';
          _descCtrl.text = s.description.isNotEmpty ? s.description : '';
          _phoneCtrl.text = s.phoneNumber.isNotEmpty ? s.phoneNumber : '';
          _webCtrl.text = s.websiteUrl.isNotEmpty ? s.websiteUrl : '';
          _addrCtrl.text = s.address.isNotEmpty ? s.address : '';
          _cityCtrl.text = s.city.isNotEmpty ? s.city : '';
          _controllersInitialized = true;
        } catch (_) {
          // Final fallback - set empty strings
          _nameCtrl.text = '';
          _descCtrl.text = '';
          _phoneCtrl.text = '';
          _webCtrl.text = '';
          _addrCtrl.text = '';
          _cityCtrl.text = '';
          _controllersInitialized = true;
        }
      }
    }
  }

  /// Get valid category value that exists in options list (DDD: presentation layer validation)
  String _getValidCategoryValue(String category, List<String> options) {
    if (category.isEmpty) {
      return options.isNotEmpty ? options.first : 'Artisan Jewelry';
    }
    // Check if category exists in options
    if (options.contains(category)) {
      return category;
    }
    // Fallback to first option if category doesn't match
    return options.isNotEmpty ? options.first : 'Artisan Jewelry';
  }

  /// Load image files from state if they are file paths (DDD: presentation layer handles file loading)
  void _loadImageFilesFromState(StorefrontProfileEditState state) {
    // Always check and update if state has changed (for newly picked images)
    // Load banner image if it's a file path
    if (state.bannerImageUrl.startsWith('file://')) {
      try {
        final path = state.bannerImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync() && (_bannerImageFile?.path != file.path)) {
          if (mounted) {
            setState(() {
              _bannerImageFile = file;
            });
          }
        }
      } catch (_) {
        // File doesn't exist or path is invalid - ignore
      }
    } else if (!state.bannerImageUrl.startsWith('http') && _bannerImageFile != null) {
      // If URL changed to non-file, clear the file
      if (mounted) {
        setState(() {
          _bannerImageFile = null;
        });
      }
    }
    
    // Load profile image if it's a file path
    if (state.profileImageUrl.startsWith('file://')) {
      try {
        final path = state.profileImageUrl.substring(7);
        final file = File(path);
        if (file.existsSync() && (_profileImageFile?.path != file.path)) {
          if (mounted) {
            setState(() {
              _profileImageFile = file;
            });
          }
        }
      } catch (_) {
        // File doesn't exist or path is invalid - ignore
      }
    } else if (!state.profileImageUrl.startsWith('http') && _profileImageFile != null) {
      // If URL changed to non-file, clear the file
      if (mounted) {
        setState(() {
          _profileImageFile = null;
        });
      }
    }
  }

  /// Check if a field value is incomplete (empty or placeholder)
  bool _isFieldIncomplete(String? value) {
    if (value == null) return true;
    final trimmed = value.trim();
    if (trimmed.isEmpty || CityInput.isPlaceholder(trimmed)) return true;
    return trimmed == 'Décrivez votre activité en quelques lignes.' ||
        trimmed == '+33 6 12 34 56 78' ||
        trimmed == 'www.votresite.com' ||
        trimmed == 'Votre adresse' ||
        trimmed == 'Nom du commerce';
  }

  void _clearBannerFile() {
    setState(() => _bannerImageFile = null);
  }

  void _clearProfileFile() {
    setState(() => _profileImageFile = null);
  }

  void _applyPickedImage(File file, bool isBanner) {
    setState(() {
      if (isBanner) {
        _bannerImageFile = file;
      } else {
        _profileImageFile = file;
      }
    });
    final n = ref.read(storefrontProfileEditProvider.notifier);
    if (isBanner) {
      n.setBannerImageUrl('file://${file.path}');
    } else {
      n.setProfileImageUrl('file://${file.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storefrontProfileEditProvider);
    final notifier = ref.read(storefrontProfileEditProvider.notifier);
    _ensureControllers(state);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImageFilesFromState(state);
    });

    return _buildEditProfileScaffold(context, state, notifier);
  }

}
