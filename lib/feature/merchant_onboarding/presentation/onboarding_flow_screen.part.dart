part of 'onboarding_flow_screen.dart';

// ─── Step widgets ───────────────────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  const _StepWelcome({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StepAvatar(
            icon: Icons.storefront_rounded,
            size: 100,
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenue sur Yuztoo',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Quelques questions pour créer votre profil commerçant.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: MerchantOnboardingColors.textGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
}

/// Reusable "Suivant" button for each step
class _SuivantButton extends StatelessWidget {
  const _SuivantButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MerchantOnboardingColors.primaryGold,
          disabledBackgroundColor:
              MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
          foregroundColor: MerchantOnboardingColors.bgDark1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: enabled ? 4 : 0,
        ),
        child: Text(
          'Suivant',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StepName extends StatefulWidget {
  const _StepName({
    required this.controller,
    required this.initialValue,
    required this.onChanged,
    required this.onNext,
  });

  final TextEditingController controller;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  State<_StepName> createState() => _StepNameState();
}

class _StepNameState extends State<_StepName> {
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
    _canProceed = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final canProceed = widget.controller.text.trim().isNotEmpty;
    if (canProceed != _canProceed) {
      setState(() => _canProceed = canProceed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const _StepAvatar(icon: Icons.badge_outlined, size: 80),
          const SizedBox(height: 32),
          Text(
            'Comment s\'appelle votre commerce ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _TextField(
            controller: widget.controller,
            hint: 'Ex: La Boulangerie du Coin',
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 32),
          _SuivantButton(
            onPressed: _canProceed ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}

class _StepImage extends StatelessWidget {
  const _StepImage({
    required this.imagePath,
    required this.bannerImagePath,
    required this.onPickedLogo,
    required this.onPickedBanner,
    required this.onNext,
    required this.picker,
  });

  final String? imagePath;
  final String? bannerImagePath;
  final ValueChanged<String?> onPickedLogo;
  final ValueChanged<String?> onPickedBanner;
  final VoidCallback onNext;
  final ImagePicker picker;

  Future<void> _pickLogoFromGallery(BuildContext context) async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null && context.mounted) {
      onPickedLogo(picked.path);
    }
  }

  Future<void> _pickBannerFromGallery(BuildContext context) async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (picked != null && context.mounted) {
      onPickedBanner(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = imagePath != null && imagePath!.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _pickLogoFromGallery(context),
            child: _StepAvatar(
              icon: Icons.photo_library_outlined,
              size: 100,
              child: imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        File(imagePath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ajoutez une photo de votre commerce',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Depuis la galerie uniquement — obligatoire',
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
              onPressed: () => _pickLogoFromGallery(context),
              icon: const Icon(Icons.photo_library_outlined, size: 22),
              label: Text(
                'Choisir logo dans la galerie',
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
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ajoutez une image de couverture (optionnel)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MerchantOnboardingColors.textLight,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickBannerFromGallery(context),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.bgDark2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: bannerImagePath == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: MerchantOnboardingColors.primaryGold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choisir une couverture',
                            style: GoogleFonts.outfit(
                              color: MerchantOnboardingColors.textGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Image.file(
                      File(bannerImagePath!),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _pickBannerFromGallery(context),
              icon: const Icon(Icons.image_outlined, size: 20),
              label: Text(
                'Choisir couverture dans la galerie',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MerchantOnboardingColors.primaryGold,
                side: const BorderSide(
                  color: MerchantOnboardingColors.primaryGold,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SuivantButton(onPressed: canProceed ? onNext : null),
        ],
      ),
    );
  }
}

class _StepAddress extends StatefulWidget {
  const _StepAddress({
    required this.controller,
    required this.phoneController,
    required this.websiteController,
    required this.initialValue,
    required this.initialPhone,
    required this.initialWebsite,
    required this.onChanged,
    required this.onPhoneChanged,
    required this.onWebsiteChanged,
    required this.onNext,
  });

  final TextEditingController controller;
  final TextEditingController phoneController;
  final TextEditingController websiteController;
  final String? initialValue;
  final String? initialPhone;
  final String? initialWebsite;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onWebsiteChanged;
  final VoidCallback onNext;

  @override
  State<_StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends State<_StepAddress> {
  bool _canProceed = false;

  String _toFrenchE164(String rawInput) {
    var digits = rawInput.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('33')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.isEmpty ? '' : '+33$digits';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
    if (widget.initialPhone != null) {
      final digits = widget.initialPhone!.replaceAll(RegExp(r'[^\d]'), '');
      var local = digits.startsWith('33') ? digits.substring(2) : digits;
      if (local.startsWith('0')) local = local.substring(1);
      widget.phoneController.text = local;
    }
    if (widget.initialWebsite != null) {
      widget.websiteController.text = widget.initialWebsite!;
    }
    _canProceed = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final canProceed = widget.controller.text.trim().isNotEmpty;
    if (canProceed != _canProceed) {
      setState(() => _canProceed = canProceed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const _StepAvatar(icon: Icons.location_on_outlined, size: 80),
          const SizedBox(height: 32),
          Text(
            'Où se trouve votre commerce ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _TextField(
            controller: widget.controller,
            hint: '123 Rue de la République, Paris',
            maxLines: 2,
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: MerchantOnboardingColors.bgDark2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MerchantOnboardingColors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: MerchantOnboardingColors.borderColor
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Text(
                    '+33',
                    style: GoogleFonts.outfit(
                      color: MerchantOnboardingColors.primaryGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    cursorColor: MerchantOnboardingColors.primaryGold,
                    style: GoogleFonts.outfit(
                      color: MerchantOnboardingColors.textGrey,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '612345678',
                      hintStyle: GoogleFonts.outfit(
                        color: MerchantOnboardingColors.textGrey,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: MerchantOnboardingColors.bgDark2,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (v) => widget.onPhoneChanged(_toFrenchE164(v)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TextField(
            controller: widget.websiteController,
            hint: 'Site web (ex: www.moncommerce.com)',
            onChanged: widget.onWebsiteChanged,
          ),
          const SizedBox(height: 32),
          _SuivantButton(
            onPressed: _canProceed ? widget.onNext : null,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StepCategory extends StatelessWidget {
  const _StepCategory({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onNext,
  });

  final List<MerchantCategory> categories;
  final String? selectedId;
  final void Function(String id, String title) onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canProceed = selectedId != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _StepAvatar(icon: Icons.category_outlined, size: 72),
          const SizedBox(height: 24),
          Text(
            'Quel type de commerce ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              return CategoryCard(
                category: c,
                isSelected: selectedId == c.id,
                onTap: () => onSelected(c.id, c.title),
                animationDelay: i * 50,
              );
            },
          ),
          const SizedBox(height: 24),
          _SuivantButton(
            onPressed: canProceed ? onNext : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StepDescription extends StatefulWidget {
  const _StepDescription({
    required this.controller,
    required this.initialValue,
    required this.onChanged,
    required this.onNext,
  });

  final TextEditingController controller;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  State<_StepDescription> createState() => _StepDescriptionState();
}

class _StepDescriptionState extends State<_StepDescription> {
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
    _canProceed = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final canProceed = widget.controller.text.trim().isNotEmpty;
    if (canProceed != _canProceed) {
      setState(() => _canProceed = canProceed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const _StepAvatar(icon: Icons.description_outlined, size: 80),
          const SizedBox(height: 32),
          Text(
            'Décrivez votre commerce',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 24),
          _TextField(
            controller: widget.controller,
            hint: 'Une boulangerie artisanale au cœur du quartier...',
            maxLines: 4,
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 32),
          _SuivantButton(onPressed: _canProceed ? widget.onNext : null),
        ],
      ),
    );
  }
}

class _StepHours extends StatefulWidget {
  const _StepHours({
    required this.initialHours,
    required this.onChanged,
    required this.onSkip,
    required this.onNext,
  });

  final Map<String, dynamic>? initialHours;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  State<_StepHours> createState() => _StepHoursState();
}

class _StepHoursState extends State<_StepHours> {
  late BusinessHours _hours;

  @override
  void initState() {
    super.initState();
    _hours = BusinessHours.fromMap(widget.initialHours);
  }

  void _updateDay(String dayKey, DayHours updated) {
    setState(() {
      _hours = BusinessHours(
        hasExceptionalClosure: _hours.hasExceptionalClosure,
        monday: dayKey == 'monday' ? updated : _hours.monday,
        tuesday: dayKey == 'tuesday' ? updated : _hours.tuesday,
        wednesday: dayKey == 'wednesday' ? updated : _hours.wednesday,
        thursday: dayKey == 'thursday' ? updated : _hours.thursday,
        friday: dayKey == 'friday' ? updated : _hours.friday,
        saturday: dayKey == 'saturday' ? updated : _hours.saturday,
        sunday: dayKey == 'sunday' ? updated : _hours.sunday,
      );
      widget.onChanged(_hours.toMap());
    });
  }

  void _toggleDay(String dayKey, DayHours day) {
    _updateDay(
        dayKey,
        DayHours(
          dayName: day.dayName,
          isEnabled: !day.isEnabled,
          timeSlots: day.isEnabled
              ? []
              : [
                  const TimeSlot(start: '8h', end: '12h'),
                  const TimeSlot(start: '14h', end: '18h')
                ],
        ));
  }

  void _updateSlots(String dayKey, DayHours day, List<TimeSlot> slots) {
    _updateDay(
        dayKey,
        DayHours(
            dayName: day.dayName, isEnabled: day.isEnabled, timeSlots: slots));
  }

  @override
  Widget build(BuildContext context) {
    final dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final days = _hours.allDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _StepAvatar(icon: Icons.schedule_outlined, size: 72),
          const SizedBox(height: 20),
          Text(
            'Vos horaires d\'ouverture',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: MerchantOnboardingColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Optionnel — ajoutez vos horaires',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantOnboardingColors.textGrey,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: MerchantOnboardingColors.bgDark2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MerchantOnboardingColors.borderColor),
            ),
            child: Column(
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  _OnboardingDayRow(
                    dayHours: days[i],
                    onToggle: () => _toggleDay(dayKeys[i], days[i]),
                    onSave: (slots) => _updateSlots(dayKeys[i], days[i], slots),
                  ),
                  if (i < days.length - 1)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: MerchantOnboardingColors.borderColor,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SuivantButton(onPressed: widget.onNext),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Passer',
              style: GoogleFonts.outfit(
                color: MerchantOnboardingColors.textGrey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Compact day row for onboarding – dark theme.
class _OnboardingDayRow extends StatefulWidget {
  const _OnboardingDayRow({
    required this.dayHours,
    required this.onToggle,
    required this.onSave,
  });

  final DayHours dayHours;
  final VoidCallback onToggle;
  final ValueChanged<List<TimeSlot>> onSave;

  @override
  State<_OnboardingDayRow> createState() => _OnboardingDayRowState();
}

class _OnboardingDayRowState extends State<_OnboardingDayRow> {
  bool _expanded = false;
  final List<TextEditingController> _startCtrls = [];
  final List<TextEditingController> _endCtrls = [];

  bool get _hasSlots =>
      widget.dayHours.isEnabled && widget.dayHours.timeSlots.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _OnboardingDayRow old) {
    super.didUpdateWidget(old);
    if (!_expanded) _syncControllers();
  }

  void _syncControllers() {
    _disposeControllers();
    for (final slot in widget.dayHours.timeSlots) {
      _startCtrls.add(TextEditingController(text: slot.start));
      _endCtrls.add(TextEditingController(text: slot.end));
    }
  }

  void _disposeControllers() {
    for (final c in _startCtrls) {
      c.dispose();
    }
    for (final c in _endCtrls) {
      c.dispose();
    }
    _startCtrls.clear();
    _endCtrls.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _toggleExpand() {
    if (!_hasSlots) return;
    setState(() {
      if (!_expanded) {
        _syncControllers();
        _expanded = true;
      } else {
        _expanded = false;
      }
    });
  }

  void _addSlot() {
    setState(() {
      _startCtrls.add(TextEditingController(text: '8h'));
      _endCtrls.add(TextEditingController(text: '12h'));
    });
  }

  void _removeSlot(int index) {
    if (_startCtrls.length <= 1) return;
    setState(() {
      _startCtrls[index].dispose();
      _endCtrls[index].dispose();
      _startCtrls.removeAt(index);
      _endCtrls.removeAt(index);
    });
  }

  void _saveChanges() {
    final slots = <TimeSlot>[];
    for (int i = 0; i < _startCtrls.length; i++) {
      final s = _startCtrls[i].text.trim();
      final e = _endCtrls[i].text.trim();
      if (s.isNotEmpty && e.isNotEmpty) {
        slots.add(TimeSlot(start: s, end: e));
      }
    }
    if (slots.isNotEmpty) widget.onSave(slots);
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _hasSlots ? _toggleExpand : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggle,
                  child: Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.dayHours.isEnabled
                          ? MerchantOnboardingColors.primaryGold
                          : MerchantOnboardingColors.bgDark1,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          left: widget.dayHours.isEnabled ? 22 : 4,
                          right: widget.dayHours.isEnabled ? 4 : 22,
                        ),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.dayHours.dayName,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MerchantOnboardingColors.textLight,
                  ),
                ),
                const Spacer(),
                _hasSlots
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.dayHours.displayText,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantOnboardingColors.textGrey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: MerchantOnboardingColors.textGrey,
                          ),
                        ],
                      )
                    : Text(
                        'Fermé',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: MerchantOnboardingColors.textGrey,
                        ),
                      ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _expanded ? _buildEditor() : const SizedBox.shrink(),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MerchantOnboardingColors.bgDark1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MerchantOnboardingColors.borderColor),
        ),
        child: Column(
          children: [
            for (int i = 0; i < _startCtrls.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startCtrls[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: MerchantOnboardingColors.textLight,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        filled: true,
                        fillColor: MerchantOnboardingColors.bgDark2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '8h',
                        hintStyle: GoogleFonts.outfit(
                            color: MerchantOnboardingColors.textGrey),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward,
                        size: 14, color: MerchantOnboardingColors.textGrey),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _endCtrls[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: MerchantOnboardingColors.textLight,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        filled: true,
                        fillColor: MerchantOnboardingColors.bgDark2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '18h',
                        hintStyle: GoogleFonts.outfit(
                            color: MerchantOnboardingColors.textGrey),
                      ),
                    ),
                  ),
                  if (_startCtrls.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeSlot(i),
                      child: Icon(Icons.close,
                          size: 18, color: Colors.red.shade300),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addSlot,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.primaryGold
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: MerchantOnboardingColors.primaryGold
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add,
                        size: 18, color: MerchantOnboardingColors.primaryGold),
                    const SizedBox(width: 6),
                    Text(
                      'Ajouter un créneau',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MerchantOnboardingColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MerchantOnboardingColors.bgDark1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepReady extends StatefulWidget {
  const _StepReady({
    required this.onComplete,
    this.isPostSignup = false,
    this.onPostSignupPersistMerchantReady,
  });

  final VoidCallback onComplete;
  final bool isPostSignup;
  final Future<void> Function()? onPostSignupPersistMerchantReady;

  @override
  State<_StepReady> createState() => _StepReadyState();
}

class _StepReadyState extends State<_StepReady> {
  bool _isLoading = false;

  Future<void> _handleComplete() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    if (widget.isPostSignup) {
      await widget.onPostSignupPersistMerchantReady?.call();
    }
    widget.onComplete();

    // Safety reset: if user remains on the same step (e.g. save error),
    // re-enable the button so they can retry.
    await Future<void>.delayed(const Duration(seconds: 8));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StepAvatar(
            icon: Icons.check_circle_outline,
            size: 100,
            color: MerchantOnboardingColors.primaryGold,
          ),
          const SizedBox(height: 32),
          Text(
            'Prêt !',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MerchantOnboardingColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isPostSignup
                ? 'Accédez à votre compte commerce'
                : 'Créez votre compte pour commencer',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: MerchantOnboardingColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantOnboardingColors.primaryGold,
                disabledBackgroundColor: MerchantOnboardingColors.primaryGold
                    .withValues(alpha: 0.55),
                foregroundColor: MerchantOnboardingColors.bgDark1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MerchantOnboardingColors.bgDark1,
                        ),
                      ),
                    )
                  : Text(
                      widget.isPostSignup
                          ? 'Accéder à mon compte commerce'
                          : 'Créer mon compte',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ─────────────────────────────────────────────────────────

class _StepAvatar extends StatelessWidget {
  const _StepAvatar({
    required this.icon,
    this.size = 80,
    this.color,
    this.child,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = color ?? MerchantOnboardingColors.primaryGold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withValues(alpha: 0.15),
        border: Border.all(color: c, width: 2),
      ),
      child: child ??
          Icon(
            icon,
            size: size * 0.45,
            color: c,
          ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: MerchantOnboardingColors.primaryGold,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.outfit(
        fontSize: 16,
        color: MerchantOnboardingColors.textLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: MerchantOnboardingColors.textGrey,
        ),
        filled: true,
        fillColor: MerchantOnboardingColors.bgDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: MerchantOnboardingColors.primaryGold,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
