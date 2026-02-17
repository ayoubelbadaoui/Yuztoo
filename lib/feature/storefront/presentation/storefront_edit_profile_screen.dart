import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/profile_edit_state.dart';
import 'widgets/storefront_colors.dart';

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

  bool _controllersInitialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _webCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _ensureControllers(StorefrontProfileEditState s) {
    if (_controllersInitialized) return;
    _nameCtrl.text = s.businessName;
    _descCtrl.text = s.description;
    _phoneCtrl.text = s.phoneNumber;
    _webCtrl.text = s.websiteUrl;
    _addrCtrl.text = s.address;
    _controllersInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storefrontProfileEditProvider);
    final notifier = ref.read(storefrontProfileEditProvider.notifier);
    _ensureControllers(state);

    return Scaffold(
      backgroundColor: StorefrontColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: StorefrontColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 96,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: StorefrontColors.primaryGold),
          label: const Text(
            'Back',
            style: TextStyle(
              color: StorefrontColors.primaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: StorefrontColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      await notifier.save();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Enregistré'),
                          backgroundColor: StorefrontColors.primaryGold,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: StorefrontColors.primaryGold,
                foregroundColor: StorefrontColors.navyDark,
                elevation: 10,
                shadowColor: StorefrontColors.primaryGold.withValues(alpha: 0.25),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          StorefrontColors.navyDark,
                        ),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Visuals'),
              const SizedBox(height: 12),
              _BannerEditable(
                imageUrl: state.bannerImageUrl,
                onTap: () => _showImagePickerSheet(context, title: 'Change Banner'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ProfileEditable(
                    imageUrl: state.profileImageUrl,
                    onTap: () => _showImagePickerSheet(context, title: 'Profile Photo'),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'High resolution recommended',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: StorefrontColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _SectionTitle('General Information'),
              const SizedBox(height: 14),
              _Field(
                label: 'Business Name',
                controller: _nameCtrl,
                onChanged: notifier.setBusinessName,
              ),
              const SizedBox(height: 14),
              _SelectField(
                label: 'Category',
                value: state.category.isEmpty ? 'Artisan Jewelry' : state.category,
                options: const [
                  'Artisan Jewelry',
                  'Handmade Decor',
                  'Fashion Boutique',
                  'Gourmet Food',
                ],
                onChanged: (v) => notifier.setCategory(v ?? ''),
              ),
              const SizedBox(height: 14),
              _MultilineField(
                label: 'Description',
                controller: _descCtrl,
                onChanged: notifier.setDescription,
                minLines: 4,
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Contact Details'),
              const SizedBox(height: 14),
              _Field(
                label: 'Phone Number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.call,
                onChanged: notifier.setPhoneNumber,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Website URL',
                controller: _webCtrl,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.language,
                onChanged: notifier.setWebsiteUrl,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Physical Address',
                controller: _addrCtrl,
                prefixIcon: Icons.place,
                onChanged: notifier.setAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerSheet(BuildContext context, {required String title}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: StorefrontColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PickerOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _PickerOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: StorefrontColors.primaryGold,
        letterSpacing: 2.4,
      ),
    );
  }
}

class _BannerEditable extends StatelessWidget {
  const _BannerEditable({required this.imageUrl, required this.onTap});
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 128,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 42,
                      color: StorefrontColors.textTertiary,
                    ),
                  ),
                ),
                Container(
                  color: StorefrontColors.navyDark.withValues(alpha: 0.4),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, color: Colors.white),
                      SizedBox(height: 6),
                      Text(
                        'CHANGE BANNER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditable extends StatelessWidget {
  const _ProfileEditable({required this.imageUrl, required this.onTap});
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: GoldGradient.colors,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 36,
                        color: StorefrontColors.textTertiary,
                      ),
                    ),
                  ),
                  Container(
                    color: StorefrontColors.navyDark.withValues(alpha: 0.4),
                    child: const Center(
                      child: Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
            color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: StorefrontColors.primaryGold,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: StorefrontColors.navyDark, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.keyboardType,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.textSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StorefrontColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: StorefrontColors.textTertiary),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: StorefrontColors.primaryGold,
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _MultilineField extends StatelessWidget {
  const _MultilineField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.minLines = 4,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.textSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: minLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StorefrontColors.textPrimary,
            height: 1.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: StorefrontColors.primaryGold,
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: StorefrontColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more,
                color: StorefrontColors.primaryGold,
              ),
              onChanged: onChanged,
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StorefrontColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}


