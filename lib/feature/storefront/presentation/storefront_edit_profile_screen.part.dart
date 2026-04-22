part of 'storefront_edit_profile_screen.dart';

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
  const _BannerEditable({
    required this.imageUrl,
    this.imageFile,
    required this.onTap,
    this.onDelete,
  });
  final String imageUrl;
  final File? imageFile;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
                // Show local file if available, otherwise show network image
                imageFile != null
                    ? Image.file(
                        imageFile!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            size: 42,
                            color: StorefrontColors.textTertiary,
                          ),
                        ),
                      )
                    : Image.network(
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
                // Delete button (only show if image exists)
                if (onDelete != null && (imageFile != null || (!imageUrl.contains('aida-public') && imageUrl.isNotEmpty)))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
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
  const _ProfileEditable({
    required this.imageUrl,
    this.imageFile,
    required this.onTap,
    this.onDelete,
  });
  final String imageUrl;
  final File? imageFile;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
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
                  // Show local file if available, otherwise show network image
                  imageFile != null
                      ? Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 36,
                              color: StorefrontColors.textTertiary,
                            ),
                          ),
                        )
                      : Image.network(
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

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onPlaceSelected,
    this.isRequired = false,
    this.helpText,
    this.isIncomplete = false,
    this.onShowHelp,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPlaceSelected;
  final bool isRequired;
  final String? helpText;
  final bool isIncomplete;
  final void Function(String, String)? onShowHelp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isIncomplete ? Colors.red : StorefrontColors.textSecondary,
                ),
              ),
              if (isRequired && isIncomplete) ...[
                const SizedBox(width: 4),
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
              ],
              if (helpText != null && onShowHelp != null) ...[
                const SizedBox(width: 6),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => onShowHelp!(label, helpText!),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        size: 12,
                        color: StorefrontColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _showGooglePlacesPicker(context),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StorefrontColors.textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.place, color: StorefrontColors.textTertiary),
            suffixIcon: const Icon(Icons.search, color: StorefrontColors.primaryGold),
            hintText: 'Appuyez pour rechercher une adresse',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: StorefrontColors.textTertiary,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                width: isIncomplete ? 1.5 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                width: isIncomplete ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isIncomplete ? Colors.red : StorefrontColors.primaryGold,
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

  void _showGooglePlacesPicker(BuildContext context) {
    // Google Places Autocomplete implementation (DDD: presentation layer)
    // Note: Requires Google Places API key in production
    final searchController = TextEditingController(text: controller.text);
    final suggestions = <String>[];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void searchPlaces(String query) async {
            if (query.trim().isEmpty) {
              setModalState(() => suggestions.clear());
              return;
            }
            // TODO: Call Google Places API for real address suggestions
            setModalState(() => suggestions.clear());
          }
          
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text(
                  'Rechercher une adresse',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tapez une adresse...',
                    prefixIcon: const Icon(Icons.search, color: StorefrontColors.primaryGold),
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
                  ),
                  onChanged: searchPlaces,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      controller.text = value.trim();
                      onPlaceSelected(value.trim());
                      onChanged(value.trim());
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (suggestions.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.place, color: StorefrontColors.primaryGold),
                          title: Text(suggestion),
                          onTap: () {
                            controller.text = suggestion;
                            onPlaceSelected(suggestion);
                            onChanged(suggestion);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  )
                else if (searchController.text.length > 2)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
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
    this.isRequired = false,
    this.helpText,
    this.isIncomplete = false,
    this.onShowHelp,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool isRequired;
  final String? helpText;
  final bool isIncomplete;
  final void Function(String, String)? onShowHelp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isIncomplete ? Colors.red : StorefrontColors.textSecondary,
                ),
              ),
              if (isRequired && isIncomplete) ...[
                const SizedBox(width: 4),
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
              ],
              if (helpText != null && onShowHelp != null) ...[
                const SizedBox(width: 6),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => onShowHelp!(label, helpText!),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        size: 12,
                        color: StorefrontColors.primaryGold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return TextField(
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
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20, color: StorefrontColors.textTertiary),
                            onPressed: () {
                              controller.clear();
                              onChanged('');
                            },
                          )
                        : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                    width: isIncomplete ? 1.5 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                    width: isIncomplete ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red : StorefrontColors.primaryGold,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            );
          },
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
    this.isRequired = false,
    this.helpText,
    this.isIncomplete = false,
    this.onShowHelp,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int minLines;
  final bool isRequired;
  final String? helpText;
  final bool isIncomplete;
  final void Function(String, String)? onShowHelp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isIncomplete ? Colors.red : StorefrontColors.textSecondary,
                ),
              ),
              if (isRequired && isIncomplete) ...[
                const SizedBox(width: 4),
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
              ],
                  if (helpText != null && onShowHelp != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onShowHelp!(label, helpText!),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 12,
                          color: StorefrontColors.primaryGold,
                        ),
                      ),
                    ),
                  ],
            ],
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return TextField(
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
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: StorefrontColors.textTertiary),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                    width: isIncomplete ? 1.5 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red.withValues(alpha: 0.5) : Colors.grey[200]!,
                    width: isIncomplete ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isIncomplete ? Colors.red : StorefrontColors.primaryGold,
                    width: 2,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            );
          },
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
    this.isRequired = false,
    this.helpText,
    this.isIncomplete = false,
    this.onShowHelp,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isRequired;
  final String? helpText;
  final bool isIncomplete;
  final void Function(String, String)? onShowHelp;

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
              value: options.contains(value) ? value : (options.isNotEmpty ? options.first : null),
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

extension _StorefrontEditProfileScreenUi on _StorefrontEditProfileScreenState {
  /// Show help dialog (DDD: presentation layer)
  void _showHelpDialog(String fieldName, String helpText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_outline,
                color: StorefrontColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fieldName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          helpText,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: StorefrontColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fermer',
              style: TextStyle(
                color: StorefrontColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileScaffold(
    BuildContext context,
    StorefrontProfileEditState state,
    StorefrontProfileEditNotifier notifier,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: StorefrontColors.backgroundLight,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
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
                      // Flush latest text fields into state so Ville (and others) reach Firestore.
                      notifier.setBusinessName(_nameCtrl.text);
                      notifier.setDescription(_descCtrl.text);
                      notifier.setPhoneNumber(_phoneCtrl.text);
                      notifier.setCity(_cityCtrl.text);
                      notifier.setWebsiteUrl(_webCtrl.text);
                      notifier.setAddress(_addrCtrl.text);
                      await notifier.save();
                      if (!context.mounted) return;
                      
                      // Check for errors
                      final currentState = ref.read(storefrontProfileEditProvider);
                      if (currentState.errorMessage != null) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(currentState.errorMessage!),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        // Clear error message
                        ref.read(storefrontProfileEditProvider.notifier).clearError();
                        return; // Don't navigate away on error
                      }
                      
                      // Success - invalidate storefront provider to refresh with new data
                      ref.invalidate(storefrontProvider);
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
                elevation: 0,
                shadowColor: Colors.transparent,
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
                imageFile: _bannerImageFile,
                onTap: () => _showImagePickerSheet(context, title: 'Change Banner', isBanner: true),
                onDelete: (_bannerImageFile != null || (!state.bannerImageUrl.contains('aida-public') && state.bannerImageUrl.isNotEmpty))
                    ? () async {
                        _clearBannerFile();
                        notifier.setBannerImageUrl('');
                        // Save immediately to clear from cache
                        await notifier.save();
                        if (context.mounted) {
                          ref.invalidate(storefrontProvider);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ProfileEditable(
                    imageUrl: state.profileImageUrl,
                    imageFile: _profileImageFile,
                    onTap: () => _showImagePickerSheet(context, title: 'Profile Photo', isBanner: false),
                    onDelete: (_profileImageFile != null || (!state.profileImageUrl.contains('aida-public') && state.profileImageUrl.isNotEmpty))
                        ? () async {
                            _clearProfileFile();
                            notifier.setProfileImageUrl('');
                            // Save immediately to clear from cache
                            await notifier.save();
                            if (context.mounted) {
                              ref.invalidate(storefrontProvider);
                            }
                          }
                        : null,
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
                isRequired: true,
                isIncomplete: _isFieldIncomplete(state.businessName),
                helpText: 'Le nom de votre commerce est requis. Il sera visible par vos clients.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _SelectField(
                label: 'Category',
                value: _getValidCategoryValue(state.category, const [
                  'Artisan Jewelry',
                  'Handmade Decor',
                  'Fashion Boutique',
                  'Gourmet Food',
                ]),
                options: const [
                  'Artisan Jewelry',
                  'Handmade Decor',
                  'Fashion Boutique',
                  'Gourmet Food',
                ],
                onChanged: (v) => notifier.setCategory(v ?? ''),
                isRequired: true,
                isIncomplete: state.category.isEmpty || _isFieldIncomplete(state.category),
                helpText: 'Sélectionnez la catégorie qui correspond le mieux à votre activité. Cela aide les clients à vous trouver.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _MultilineField(
                label: 'Description',
                controller: _descCtrl,
                onChanged: notifier.setDescription,
                minLines: 4,
                isRequired: false,
                isIncomplete: _isFieldIncomplete(state.description),
                helpText: 'Décrivez votre commerce en quelques lignes. Cette description apparaîtra sur votre vitrine.',
                onShowHelp: _showHelpDialog,
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
                isRequired: true,
                isIncomplete: _isFieldIncomplete(state.phoneNumber),
                helpText: 'Votre numéro de téléphone est requis. Les clients pourront vous contacter directement.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Ville',
                controller: _cityCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.location_city,
                onChanged: notifier.setCity,
                isRequired: true,
                isIncomplete: _isFieldIncomplete(state.city),
                helpText: 'La ville de votre commerce. Cela permet aux clients de vous trouver facilement.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _Field(
                label: 'Website URL',
                controller: _webCtrl,
                keyboardType: TextInputType.url,
                prefixIcon: Icons.language,
                onChanged: notifier.setWebsiteUrl,
                isRequired: false,
                isIncomplete: _isFieldIncomplete(state.websiteUrl),
                helpText: 'Ajoutez l\'URL de votre site web si vous en avez un. Cela permet aux clients de découvrir plus d\'informations sur votre commerce.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _AddressField(
                label: 'Physical Address',
                controller: _addrCtrl,
                onChanged: notifier.setAddress,
                onPlaceSelected: (address) {
                  _addrCtrl.text = address;
                  notifier.setAddress(address);
                },
                isRequired: false,
                isIncomplete: _isFieldIncomplete(state.address),
                helpText: 'Ajoutez l\'adresse physique de votre commerce. Les clients pourront vous localiser facilement.',
                onShowHelp: _showHelpDialog,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showImagePickerSheet(BuildContext context, {required String title, required bool isBanner}) async {
    final source = await showModalBottomSheet<ImageSource>(
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
    );

    if (source == null || !context.mounted) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: isBanner ? 1200 : 800,
        maxHeight: isBanner ? 600 : 800,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        _applyPickedImage(File(pickedFile.path), isBanner);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection de l\'image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

