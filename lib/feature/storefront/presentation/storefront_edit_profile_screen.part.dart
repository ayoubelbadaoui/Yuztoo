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
      backgroundColor: Colors.white,
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
            color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StorefrontColors.textPrimary,
                  ),
                  cursorColor: StorefrontColors.primaryGold,
                  decoration: InputDecoration(
                    hintText: 'Tapez une adresse...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: StorefrontColors.textTertiary,
                    ),
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
    this.maxLines = 1,
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
  final int maxLines;

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
                  maxLines: maxLines,
                  minLines: 1,
                  cursorColor: StorefrontColors.primaryGold,
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
              cursorColor: StorefrontColors.primaryGold,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: StorefrontColors.textPrimary,
              ),
              dropdownColor: Colors.white,
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
        systemNavigationBarColor: StorefrontColors.backgroundLight,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: StorefrontColors.backgroundLight,
        body: Column(
          children: [
            _buildEditHeader(context, state, notifier),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Visuels'),
              const SizedBox(height: 12),
              _BannerEditable(
                imageUrl: state.bannerImageUrl,
                imageFile: _bannerImageFile,
                onTap: () => _showImagePickerSheet(context, title: 'Changer la bannière', isBanner: true),
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
                    onTap: () => _showImagePickerSheet(context, title: 'Photo de profil', isBanner: false),
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
                          'Photo de profil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: StorefrontColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Haute résolution recommandée',
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
              const _SectionTitle('Informations générales'),
              const SizedBox(height: 14),
              _Field(
                label: 'Nom du commerce',
                controller: _nameCtrl,
                onChanged: notifier.setBusinessName,
                isRequired: true,
                isIncomplete: _isFieldIncomplete(state.businessName),
                helpText: 'Le nom de votre commerce est requis. Il sera visible par vos clients.',
                onShowHelp: _showHelpDialog,
              ),
              const SizedBox(height: 14),
              _SelectField(
                label: 'Catégorie',
                value: _getValidCategoryValue(state.category, const [
                  'Café / Bar',
                  'Restaurant / Brasserie',
                  'Restauration rapide',
                  'Boulangerie / Pâtisserie',
                  'Boucherie / Charcuterie',
                  'Poissonnerie',
                  'Fromagerie / Crèmerie',
                  'Confiserie / Chocolatier',
                  'Glacier',
                  'Caviste & Épicerie',
                  'Maraîcher',
                  'Ferme / Produit Locaux',
                  'Artisans marché',
                  'Boutique BIO',
                  'Traiteur',
                ]),
                options: const [
                  'Café / Bar',
                  'Restaurant / Brasserie',
                  'Restauration rapide',
                  'Boulangerie / Pâtisserie',
                  'Boucherie / Charcuterie',
                  'Poissonnerie',
                  'Fromagerie / Crèmerie',
                  'Confiserie / Chocolatier',
                  'Glacier',
                  'Caviste & Épicerie',
                  'Maraîcher',
                  'Ferme / Produit Locaux',
                  'Artisans marché',
                  'Boutique BIO',
                  'Traiteur',
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
              const _SectionTitle('Coordonnées'),
              const SizedBox(height: 14),
              _Field(
                label: 'Téléphone',
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
                // Email is now a required contact field. Existing merchants
                // who finished onboarding before that change may carry the
                // legacy `demo@example.com` placeholder OR have an empty
                // value — both light up `isIncomplete` so they're nudged
                // to set a real address. The text input itself stays
                // editable, validation lives in the save flow.
                label: 'Email professionnel',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                onChanged: notifier.setEmail,
                isRequired: true,
                isIncomplete:
                    EmailValidator.isPlaceholderOrEmpty(state.email) ||
                        !EmailValidator.isValid(state.email),
                helpText:
                    'Adresse email professionnelle de contact. Yuztoo peut '
                    'l\'utiliser pour des communications importantes (facturation, '
                    'support). Visible sur votre vitrine.',
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
                label: 'Site web',
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
                label: 'Adresse',
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
              const SizedBox(height: 14),
              _Field(
                label: 'Bon de bienvenue (1re connexion)',
                controller: _giftCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.card_giftcard_rounded,
                onChanged: notifier.setWelcomeGiftDescription,
                isRequired: false,
                isIncomplete: false,
                helpText: 'Description du bon offert au nouveau client lors de sa première connexion à votre vitrine (ex. : "10 % de remise sur votre 1er achat"). Laisser vide pour désactiver.',
                onShowHelp: _showHelpDialog,
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Galerie / Actualités'),
              const SizedBox(height: 16),
              const _GalleryEditorSection(),
            ],
          ),
        ),
      ),
    ],
  ),
    ),
  );
  }

  Widget _buildEditHeader(
    BuildContext context,
    StorefrontProfileEditState state,
    StorefrontProfileEditNotifier notifier,
  ) {
    return Container(
      color: StorefrontColors.backgroundLight,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: StorefrontColors.backgroundLight,
            border: Border(
              bottom: BorderSide(
                color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: StorefrontColors.primaryGold,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Modifier le profil',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: StorefrontColors.textPrimary,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: state.isSaving
                    ? null
                    : () async {
                        notifier.setBusinessName(_nameCtrl.text);
                        notifier.setDescription(_descCtrl.text);
                        notifier.setPhoneNumber(_phoneCtrl.text);
                        notifier.setCity(_cityCtrl.text);
                        notifier.setWebsiteUrl(_webCtrl.text);
                        notifier.setAddress(_addrCtrl.text);
                        await notifier.save();
                        if (!context.mounted) return;
                        final currentState = ref.read(storefrontProfileEditProvider);
                        if (currentState.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(currentState.errorMessage!,
                                  style: GoogleFonts.outfit(color: Colors.white)),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          ref.read(storefrontProfileEditProvider.notifier).clearError();
                          return;
                        }
                        ref.invalidate(storefrontProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Profil enregistré',
                                style: GoogleFonts.outfit(
                                    color: StorefrontColors.navyDark,
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: StorefrontColors.primaryGold,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                child: AnimatedOpacity(
                  opacity: state.isSaving ? 0.6 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [StorefrontColors.primaryGold, Color(0xFFD4AF37)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: StorefrontColors.navyDark),
                            )
                          : Text(
                              'Enregistrer',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: StorefrontColors.navyDark,
                              ),
                            ),
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

      if (pickedFile == null || !context.mounted) return;
      final cropped = await cropImage(
        pickedFile.path,
        ratioX: isBanner ? 16 : 1,
        ratioY: isBanner ? 9 : 1,
      );
      if (context.mounted) {
        _applyPickedImage(File(cropped ?? pickedFile.path), isBanner);
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

/// Gallery / News image editor — reads current images from [storefrontProvider]
/// and uploads/deletes directly via use cases (same pattern as hours).
class _GalleryEditorSection extends ConsumerStatefulWidget {
  const _GalleryEditorSection();

  @override
  ConsumerState<_GalleryEditorSection> createState() =>
      _GalleryEditorSectionState();
}

class _GalleryEditorSectionState extends ConsumerState<_GalleryEditorSection> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  final Set<String> _deletingUrls = {};

  Future<void> _addImage(String merchantId) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 86,
    );
    if (picked == null || !mounted) return;
    final cropped = await cropImage(picked.path);
    if (!mounted) return;
    setState(() => _isUploading = true);
    try {
      final result = await ref
          .read(storage_providers.uploadNewsImageProvider)
          .call(filePath: cropped ?? picked.path, merchantId: merchantId);

      final url = result.fold((_) => null, (u) => u);
      if (!mounted) return;
      if (url == null) {
        _showSnack('Échec du téléversement');
        return;
      }
      final storefront = ref.read(storefrontProvider).valueOrNull;
      final currentUrls = storefront?.newsImageUrls ?? [];
      final updatedUrls = [...currentUrls, url];
      final saveResult =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                newsImageUrls: updatedUrls,
              );
      saveResult.fold(
        (_) => _showSnack('Échec de la sauvegarde'),
        (_) => ref.invalidate(storefrontProvider),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(String merchantId, String url, List<String> currentUrls) async {
    setState(() => _deletingUrls.add(url));
    try {
      final updatedUrls = currentUrls.where((u) => u != url).toList();
      final result =
          await ref.read(merchant_providers.updateStorefrontProvider).call(
                merchantId: merchantId,
                newsImageUrls: updatedUrls,
              );
      result.fold(
        (_) => _showSnack('Impossible de supprimer l\'image'),
        (_) {
          // Best-effort Storage cleanup — derive the path from the URL segment.
          // URL format: .../o/merchants%2F{id}%2Fnews%2F{file}?...
          try {
            final uri = Uri.parse(url);
            final encoded = uri.pathSegments
                .skipWhile((s) => s != 'o')
                .skip(1)
                .firstOrNull;
            if (encoded != null && encoded.isNotEmpty) {
              final storagePath = Uri.decodeComponent(encoded);
              ref
                  .read(storage_providers.deleteStorageImageProvider)
                  .call(storagePath);
            }
          } catch (_) {
            // Non-fatal: Firestore is already updated.
          }
          ref.invalidate(storefrontProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _deletingUrls.remove(url));
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storefront = ref.watch(storefrontProvider).valueOrNull;
    // Use the merchant id from the resolved storefront, NOT authState.user.id.
    // The linked merchant id may differ from the user's UID (e.g. when the
    // merchant account was created separately and linked later).
    final merchantId = storefront?.id ?? '';
    final urls = storefront?.newsImageUrls ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StorefrontColors.primaryGold.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: StorefrontColors.primaryGold, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Photos actualité',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: StorefrontColors.textPrimary,
                  ),
                ),
              ),
              if (_isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: StorefrontColors.primaryGold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Apparaissent dans la section actualité de votre boutique',
            style: TextStyle(
              fontSize: 12,
              color: StorefrontColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...urls.map((url) => _ImageTile(
                    url: url,
                    isDeleting: _deletingUrls.contains(url),
                    onDelete: merchantId.isEmpty
                        ? null
                        : () => _deleteImage(merchantId, url, urls),
                  )),
              if (!_isUploading)
                _AddImageButton(
                  onTap: merchantId.isEmpty
                      ? null
                      : () => _addImage(merchantId),
                ),
            ],
          ),
          if (urls.isEmpty && !_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Aucune photo pour l\'instant. Ajoutez des images pour attirer vos clients.',
                style: TextStyle(
                  fontSize: 13,
                  color: StorefrontColors.textSecondary.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.url,
    required this.isDeleting,
    this.onDelete,
  });

  final String url;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_outlined,
                    color: StorefrontColors.textSecondary, size: 28),
              ),
            ),
          ),
          if (isDeleting)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            )
          else if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.5),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: StorefrontColors.primaryGold.withValues(alpha: 0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: StorefrontColors.primaryGold.withValues(alpha: 0.8),
                size: 28),
            const SizedBox(height: 4),
            Text(
              'Ajouter',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: StorefrontColors.primaryGold.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
