part of 'onboarding_flow_screen.dart';

// ─── Shared design helpers ───────────────────────────────────────────────────

/// iOS-pill CTA — solid gold fill, no gradient, no drop shadow. Replaces
/// the previous diagonal-gradient + glow shadow variant which read as
/// decorative ("Material with brand color") rather than as Apple-luxe.
/// Apple's onboarding CTAs (Watch / iCloud / Migration Assistant) are
/// flat single-color pills with tight typography and a soft press-down
/// state — the same recipe we use here.
class _GoldCTAButton extends StatelessWidget {
  const _GoldCTAButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isLoading;
  final double height;

  static const _goldEnabled = MerchantOnboardingColors.primaryGold;
  static const _goldDisabled = Color(0x66D4A017);

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isLoading;
    return GestureDetector(
      onTap: canTap
          ? () {
              HapticFeedback.lightImpact();
              onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: height,
        decoration: BoxDecoration(
          color: canTap ? _goldEnabled : _goldDisabled,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTap
                ? () {
                    HapticFeedback.lightImpact();
                    onTap?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.08),
            highlightColor: Colors.black.withValues(alpha: 0.06),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            MerchantOnboardingColors.bgDark1),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: canTap
                            ? MerchantOnboardingColors.bgDark1
                            : MerchantOnboardingColors.bgDark1
                                .withValues(alpha: 0.45),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gradient ShaderMask title — used in all step headers.
class _GradientTitle extends StatelessWidget {
  const _GradientTitle(this.text);

  final String text;

  static const double fontSize = 22;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [MerchantOnboardingColors.textLight, Color(0xFFD4AF37)],
        stops: [0.45, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Animated avatar icon with gold ring + optional glow.
class _StepAvatar extends StatelessWidget {
  const _StepAvatar({
    required this.icon,
    this.size = 80,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    const c = MerchantOnboardingColors.primaryGold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: 0.18),
            c.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Icon(
        icon,
        size: size * 0.42,
        color: c,
      ),
    );
  }
}

/// Fade + slide-up entry animation for step content.
class _StepEntrance extends StatelessWidget {
  const _StepEntrance({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 480 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, ch) => Transform.translate(
        offset: Offset(0, 28 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: ch),
      ),
      child: child,
    );
  }
}

/// Ghost "skip" text button.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Passer',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: MerchantOnboardingColors.textGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Step widgets ────────────────────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  const _StepWelcome({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepEntrance(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF163352), Color(0xFF0B1F33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 52,
                color: MerchantOnboardingColors.primaryGold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _StepEntrance(
            delayMs: 60,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [MerchantOnboardingColors.textLight, Color(0xFFD4AF37)],
                stops: [0.3, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Bienvenue sur Yuztoo',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StepEntrance(
            delayMs: 100,
            child: Text(
              'Quelques questions rapides pour créer\nvotre vitrine et retrouver vos clients.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          _StepEntrance(
            delayMs: 160,
            child: SizedBox(
              width: double.infinity,
              child: _GoldCTAButton(
                label: 'Commencer',
                onTap: onNext,
                height: 54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable gradient "Suivant" button wrapper for each step.
class _SuivantButton extends StatelessWidget {
  const _SuivantButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _GoldCTAButton(
        label: 'Suivant',
        onTap: onPressed,
        enabled: onPressed != null,
        height: 52,
      ),
    );
  }
}

// ─── Step: Owner identity (firstName, lastName, DOB) ────────────────────────

class _StepOwnerInfo extends StatefulWidget {
  const _StepOwnerInfo({
    required this.firstNameController,
    required this.lastNameController,
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialDob,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onDobChanged,
    required this.onNext,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final String? initialFirstName;
  final String? initialLastName;
  final DateTime? initialDob;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<DateTime?> onDobChanged;
  final VoidCallback onNext;

  @override
  State<_StepOwnerInfo> createState() => _StepOwnerInfoState();
}

class _StepOwnerInfoState extends State<_StepOwnerInfo> {
  DateTime? _dob;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFirstName != null) {
      widget.firstNameController.text = widget.initialFirstName!;
    }
    if (widget.initialLastName != null) {
      widget.lastNameController.text = widget.initialLastName!;
    }
    _dob = widget.initialDob;
    _updateCanProceed();
    widget.firstNameController.addListener(_updateCanProceed);
    widget.lastNameController.addListener(_updateCanProceed);
  }

  @override
  void dispose() {
    widget.firstNameController.removeListener(_updateCanProceed);
    widget.lastNameController.removeListener(_updateCanProceed);
    super.dispose();
  }

  void _updateCanProceed() {
    final can = widget.firstNameController.text.trim().isNotEmpty &&
        widget.lastNameController.text.trim().isNotEmpty &&
        _dob != null;
    if (can != _canProceed) setState(() => _canProceed = can);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    // See client_onboarding_screen.dart::_pickDob for rationale —
    // open on today, clamp to max-allowed (today − 13y).
    final picked = await showCupertinoDobPicker(
      context: context,
      initial: _dob ?? now,
      minimum: DateTime(1920),
      maximum: now.subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
      widget.onDobChanged(picked);
      _updateCanProceed();
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.person_outline_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Vos informations\npersonnelles'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Ces informations restent confidentielles et ne sont pas visibles des clients.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 100,
            child: Row(
              children: [
                Expanded(
                  child: _TextField(
                    controller: widget.firstNameController,
                    hint: 'Prénom',
                    onChanged: widget.onFirstNameChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TextField(
                    controller: widget.lastNameController,
                    hint: 'Nom',
                    onChanged: widget.onLastNameChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StepEntrance(
            delayMs: 130,
            child: GestureDetector(
              onTap: _pickDob,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.bgDark2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _dob != null
                        ? MerchantOnboardingColors.primaryGold.withValues(alpha: 0.6)
                        : MerchantOnboardingColors.primaryGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cake_outlined,
                      color: _dob != null
                          ? MerchantOnboardingColors.primaryGold
                          : MerchantOnboardingColors.textGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dob != null ? _formatDate(_dob!) : 'Date de naissance',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: _dob != null
                            ? Colors.white
                            : MerchantOnboardingColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 160,
            child: _SuivantButton(
              onPressed: _canProceed ? widget.onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.storefront_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Comment s\'appelle\nvotre commerce ?'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Ce nom sera visible par vos clients sur Yuztoo.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 110,
            child: _TextField(
              controller: widget.controller,
              hint: 'Ex: La Boulangerie du Coin',
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 140,
            child: _SuivantButton(
              onPressed: _canProceed ? widget.onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step: B2B / B2C choice ───────────────────────────────────────────────
//
// Spec page 17 follow-through: the Recommandations screen filters
// listings by sphere (B2C — particuliers / B2B — professionnels). That
// filter has signal only if every merchant declares which side they're
// on. This step persists the choice to MerchantOnboardingData and the
// final write hands it to CompleteMerchantOnboarding.
class _StepMerchantType extends StatelessWidget {
  const _StepMerchantType({
    required this.value,
    required this.onChanged,
    required this.onNext,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.groups_2_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('À qui s\'adresse\nvotre commerce ?'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Vos clients principaux. Cela aide les autres commerces à '
              'vous recommander dans la bonne sphère.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 110,
            child: _MerchantTypeOption(
              icon: Icons.person_rounded,
              title: 'Particuliers',
              subtitle: 'Mes clients sont des particuliers (B2C)',
              selected: value == 'b2c',
              onTap: () => onChanged('b2c'),
            ),
          ),
          const SizedBox(height: 12),
          _StepEntrance(
            delayMs: 140,
            child: _MerchantTypeOption(
              icon: Icons.business_center_rounded,
              title: 'Professionnels',
              subtitle: 'Mes clients sont des entreprises (B2B)',
              selected: value == 'b2b',
              onTap: () => onChanged('b2b'),
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 170,
            child: _SuivantButton(
              onPressed: value == null ? null : onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantTypeOption extends StatelessWidget {
  const _MerchantTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? MerchantColors.gold.withValues(alpha: 0.18)
              : MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? MerchantColors.gold
                : MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MerchantColors.gold.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: MerchantColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: MerchantColors.textLightGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: MerchantColors.gold,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _StepCity extends StatefulWidget {
  const _StepCity({
    required this.initialValue,
    required this.onChanged,
    required this.onNext,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  State<_StepCity> createState() => _StepCityState();
}

class _StepCityState extends State<_StepCity> {
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialValue;
  }

  void _openCityPicker() {
    CitySelectionModal.show(
      context,
      cities: frenchCities,
      selectedCity: _selectedCity,
      onCitySelected: (city) {
        setState(() => _selectedCity = city);
        widget.onChanged(city);
      },
      onValidateCity: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasCity = _selectedCity != null && _selectedCity!.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.location_city_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Votre ville'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Vos clients à proximité vous trouveront facilement.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 110,
            child: GestureDetector(
              onTap: _openCityPicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.bgDark2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasCity
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.borderColor,
                    width: hasCity ? 1.5 : 1,
                  ),
                  boxShadow: hasCity
                      ? [
                          BoxShadow(
                            color: MerchantOnboardingColors.primaryGold
                                .withValues(alpha: 0.12),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: hasCity
                          ? MerchantOnboardingColors.primaryGold
                          : MerchantOnboardingColors.textGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasCity ? _selectedCity! : 'Sélectionnez votre ville',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: hasCity ? FontWeight.w600 : FontWeight.w400,
                          color: hasCity
                              ? MerchantOnboardingColors.textLight
                              : MerchantOnboardingColors.textGrey,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: hasCity
                          ? MerchantOnboardingColors.primaryGold
                          : MerchantOnboardingColors.textGrey,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 140,
            child: _SuivantButton(
              onPressed: hasCity ? widget.onNext : null,
            ),
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
    if (picked == null || !context.mounted) return;
    final cropped = await cropImage(picked.path, ratioX: 1, ratioY: 1);
    if (context.mounted) onPickedLogo(cropped ?? picked.path);
  }

  Future<void> _pickBannerFromGallery(BuildContext context) async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    final cropped = await cropImage(picked.path, ratioX: 16, ratioY: 9);
    if (context.mounted) onPickedBanner(cropped ?? picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasLogo = imagePath != null && imagePath!.trim().isNotEmpty;
    final hasBanner = bannerImagePath != null && bannerImagePath!.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo picker
          _StepEntrance(
            child: GestureDetector(
              onTap: () => _pickLogoFromGallery(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasLogo
                      ? Colors.transparent
                      : MerchantOnboardingColors.bgDark2,
                  border: Border.all(
                    color: hasLogo
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.borderColor,
                    width: hasLogo ? 2 : 1.5,
                  ),
                  boxShadow: hasLogo
                      ? [
                          BoxShadow(
                            color: MerchantOnboardingColors.primaryGold
                                .withValues(alpha: 0.3),
                            blurRadius: 18,
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_rounded,
                            color: MerchantOnboardingColors.primaryGold,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Logo',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: MerchantOnboardingColors.textGrey,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Votre identité visuelle'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Un logo soigné attire 3× plus de clients.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantOnboardingColors.textGrey,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Logo pick button
          _StepEntrance(
            delayMs: 100,
            child: GestureDetector(
              onTap: () => _pickLogoFromGallery(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.bgDark2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasLogo
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.borderColor,
                    width: hasLogo ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasLogo
                          ? Icons.check_circle_rounded
                          : Icons.photo_library_rounded,
                      color: MerchantOnboardingColors.primaryGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasLogo
                            ? 'Logo sélectionné — appuyez pour changer'
                            : 'Choisir le logo dans la galerie',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasLogo
                              ? MerchantOnboardingColors.textLight
                              : MerchantOnboardingColors.textGrey,
                        ),
                      ),
                    ),
                    if (!hasLogo)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: MerchantOnboardingColors.textGrey,
                        size: 14,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Banner section
          _StepEntrance(
            delayMs: 130,
            child: Row(
              children: [
                Text(
                  'Image de couverture',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantOnboardingColors.textLight,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Optionnel',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MerchantOnboardingColors.primaryGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StepEntrance(
            delayMs: 150,
            child: GestureDetector(
              onTap: () => _pickBannerFromGallery(context),
              child: Container(
                width: double.infinity,
                height: 108,
                decoration: BoxDecoration(
                  color: MerchantOnboardingColors.bgDark2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasBanner
                        ? MerchantOnboardingColors.primaryGold
                        : MerchantOnboardingColors.borderColor,
                    width: hasBanner ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasBanner
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(bannerImagePath!),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Changer',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.panorama_rounded,
                            size: 28,
                            color: MerchantOnboardingColors.primaryGold,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ajouter une couverture',
                            style: GoogleFonts.outfit(
                              color: MerchantOnboardingColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 170,
            child: _SuivantButton(onPressed: hasLogo ? onNext : null),
          ),
          _StepEntrance(
            delayMs: 190,
            child: _SkipButton(onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _StepAddress extends StatefulWidget {
  const _StepAddress({
    required this.controller,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
    required this.initialValue,
    required this.initialPhone,
    required this.initialEmail,
    required this.initialWebsite,
    required this.onChanged,
    required this.onPhoneChanged,
    required this.onEmailChanged,
    required this.onWebsiteChanged,
    required this.onNext,
  });

  final TextEditingController controller;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController websiteController;
  final String? initialValue;
  final String? initialPhone;
  final String? initialEmail;
  final String? initialWebsite;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onWebsiteChanged;
  final VoidCallback onNext;

  @override
  State<_StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends State<_StepAddress> {
  bool _canProceed = false;
  Timer? _phoneDebounce;

  String _toFrenchE164(String rawInput) {
    var digits = rawInput.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('33')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.isEmpty ? '' : '+33$digits';
  }

  /// "Can proceed" gates on BOTH a non-empty address AND a syntactically
  /// valid email — phone and website remain optional. Email is required
  /// because the auth fallback path used to write `demo@example.com`,
  /// which broke later "real email" flows (Stripe, support, etc.).
  bool _isEmailOk() => EmailValidator.isValid(widget.emailController.text);

  void _recomputeCanProceed() {
    final next = widget.controller.text.trim().isNotEmpty && _isEmailOk();
    if (next != _canProceed) {
      setState(() => _canProceed = next);
    }
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
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      // Pre-fill once on mount. We don't push this back into the
      // onboarding state here — the parent already set it when
      // computing initialEmail, and pushing again would race the user's
      // first edit (they'd see auth email overwritten by the listener).
      final prefill = widget.initialEmail!.trim();
      // Skip the legacy placeholder so the merchant doesn't carry it
      // forward through onboarding.
      if (!EmailValidator.isPlaceholderOrEmpty(prefill)) {
        widget.emailController.text = prefill;
      }
    }
    if (widget.initialWebsite != null) {
      widget.websiteController.text = widget.initialWebsite!;
    }
    _canProceed = widget.controller.text.trim().isNotEmpty && _isEmailOk();
    widget.controller.addListener(_onAddressChange);
    widget.emailController.addListener(_onEmailFieldChange);
  }

  void _schedulePhonePersist(String raw) {
    _phoneDebounce?.cancel();
    _phoneDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.onPhoneChanged(_toFrenchE164(raw));
    });
  }

  void _flushPhonePersist() {
    _phoneDebounce?.cancel();
    widget.onPhoneChanged(_toFrenchE164(widget.phoneController.text));
  }

  @override
  void dispose() {
    _phoneDebounce?.cancel();
    widget.controller.removeListener(_onAddressChange);
    widget.emailController.removeListener(_onEmailFieldChange);
    super.dispose();
  }

  void _onAddressChange() => _recomputeCanProceed();

  void _onEmailFieldChange() => _recomputeCanProceed();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.location_on_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Votre adresse'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Aidez vos clients à vous localiser.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _StepEntrance(
            delayMs: 100,
            child: _TextField(
              controller: widget.controller,
              hint: '123 Rue de la République, Paris',
              maxLines: 2,
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(height: 12),
          // Phone field
          _StepEntrance(
            delayMs: 120,
            child: Container(
              decoration: BoxDecoration(
                color: MerchantOnboardingColors.bgDark2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: MerchantOnboardingColors.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        color: MerchantOnboardingColors.textLight,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Numéro de téléphone professionnel',
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
                      onChanged: _schedulePhonePersist,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Email — required. Prefilled with auth email so most merchants
          // just confirm. Validation runs on every keystroke; the Suivant
          // button stays disabled until the format is valid AND address is
          // non-empty.
          _StepEntrance(
            delayMs: 130,
            child: _TextField(
              controller: widget.emailController,
              hint: 'Email de contact (ex: contact@moncommerce.fr)',
              keyboardType: TextInputType.emailAddress,
              onChanged: widget.onEmailChanged,
            ),
          ),
          if (widget.emailController.text.isNotEmpty &&
              !EmailValidator.isValid(widget.emailController.text)) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Format d\'email invalide.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.redAccent.shade100,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _StepEntrance(
            delayMs: 140,
            child: _TextField(
              controller: widget.websiteController,
              hint: 'Site web (ex: www.moncommerce.com)',
              onChanged: widget.onWebsiteChanged,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 160,
            child: _SuivantButton(
              onPressed: _canProceed
                  ? () {
                      _flushPhonePersist();
                      widget.onNext();
                    }
                  : null,
            ),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final canProceed = selectedId != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _StepAvatar(icon: Icons.category_outlined, size: 72),
          const SizedBox(height: 24),
          const _GradientTitle('Quel type de commerce ?'),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 0, 28, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.auto_stories_rounded, size: 80),
          ),
          const SizedBox(height: 28),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Décrivez votre commerce'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Une belle description donne envie de pousser la porte.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: MerchantOnboardingColors.textGrey,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          _StepEntrance(
            delayMs: 110,
            child: _TextField(
              controller: widget.controller,
              hint: 'Une boulangerie artisanale au cœur du quartier — pain au levain, viennoiseries fraîches chaque matin...',
              maxLines: 4,
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(height: 28),
          _StepEntrance(
            delayMs: 140,
            child: _SuivantButton(onPressed: _canProceed ? widget.onNext : null),
          ),
          _StepEntrance(
            delayMs: 160,
            child: _SkipButton(onTap: widget.onNext),
          ),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
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
      padding: EdgeInsets.fromLTRB(24, 0, 24, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const _StepEntrance(
            child: _StepAvatar(icon: Icons.schedule_rounded, size: 72),
          ),
          const SizedBox(height: 20),
          const _StepEntrance(
            delayMs: 50,
            child: _GradientTitle('Vos horaires'),
          ),
          const SizedBox(height: 8),
          _StepEntrance(
            delayMs: 80,
            child: Text(
              'Optionnel — modifiables à tout moment depuis votre profil.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: MerchantOnboardingColors.textGrey,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _StepEntrance(
            delayMs: 100,
            child: Container(
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
                      onSave: (slots) =>
                          _updateSlots(dayKeys[i], days[i], slots),
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
          ),
          const SizedBox(height: 20),
          _StepEntrance(
            delayMs: 120,
            child: _SuivantButton(onPressed: widget.onNext),
          ),
          _StepEntrance(
            delayMs: 140,
            child: _SkipButton(onTap: widget.onSkip),
          ),
          const SizedBox(height: 8),
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
  late List<TimeSlot> _editableSlots;

  bool get _hasSlots =>
      widget.dayHours.isEnabled && widget.dayHours.timeSlots.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _syncSlots();
  }

  @override
  void didUpdateWidget(covariant _OnboardingDayRow old) {
    super.didUpdateWidget(old);
    if (!_expanded) _syncSlots();
  }

  void _syncSlots() {
    _editableSlots = List<TimeSlot>.from(widget.dayHours.timeSlots);
  }

  void _toggleExpand() {
    if (!_hasSlots) return;
    setState(() {
      if (!_expanded) {
        _syncSlots();
        _expanded = true;
      } else {
        _expanded = false;
      }
    });
  }

  void _addSlot() {
    setState(() {
      _editableSlots.add(const TimeSlot(start: '8h', end: '12h'));
    });
  }

  void _removeSlot(int index) {
    if (_editableSlots.length <= 1) return;
    setState(() => _editableSlots.removeAt(index));
  }

  void _updateStart(int index, String value) {
    setState(() {
      _editableSlots[index] =
          TimeSlot(start: value, end: _editableSlots[index].end);
    });
  }

  void _updateEnd(int index, String value) {
    setState(() {
      _editableSlots[index] =
          TimeSlot(start: _editableSlots[index].start, end: value);
    });
  }

  void _saveChanges() {
    final slots = _editableSlots
        .where((s) => s.start.isNotEmpty && s.end.isNotEmpty)
        .toList();
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
                // Custom toggle switch
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.dayHours.isEnabled
                          ? MerchantOnboardingColors.primaryGold
                          : MerchantOnboardingColors.bgDark1,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: widget.dayHours.isEnabled
                            ? MerchantOnboardingColors.primaryGold
                            : MerchantOnboardingColors.borderColor,
                        width: 1,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: widget.dayHours.isEnabled
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.dayHours.dayName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.dayHours.isEnabled
                          ? MerchantOnboardingColors.textLight
                          : MerchantOnboardingColors.textGrey,
                    ),
                  ),
                ),
                _hasSlots
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.dayHours.displayText,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantOnboardingColors.primaryGold
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
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
                          color: MerchantOnboardingColors.textGrey
                              .withValues(alpha: 0.6),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MerchantOnboardingColors.bgDark1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MerchantOnboardingColors.borderColor),
        ),
        child: Column(
          children: [
            for (int i = 0; i < _editableSlots.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TimeSlotPicker(
                      startTime: _editableSlots[i].start,
                      endTime: _editableSlots[i].end,
                      onStartChanged: (v) => _updateStart(i, v),
                      onEndChanged: (v) => _updateEnd(i, v),
                      // Merchant onboarding sits on the dark brand chrome —
                      // use the matching dark wheel. The storefront hours
                      // editor (day_row.part.dart) stays on the default
                      // light theme.
                      darkTheme: true,
                    ),
                  ),
                  if (_editableSlots.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeSlot(i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: Colors.red.shade300),
                      ),
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
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: MerchantOnboardingColors.primaryGold
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 16,
                        color: MerchantOnboardingColors.primaryGold),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFD4A017)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
    this.postSignupAwaitFullPersistOnly = false,
    this.onPostSignupPersistMerchantReady,
  });

  final VoidCallback onComplete;
  final bool isPostSignup;
  /// When true, [onPostSignupPersistMerchantReady] is the full Firestore save; do not
  /// call [onComplete] afterward (the persist callback handles success navigation).
  final bool postSignupAwaitFullPersistOnly;
  final Future<void> Function()? onPostSignupPersistMerchantReady;

  @override
  State<_StepReady> createState() => _StepReadyState();
}

class _StepReadyState extends State<_StepReady> {
  bool _isLoading = false;

  Future<void> _handleComplete() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (widget.isPostSignup) {
        await widget.onPostSignupPersistMerchantReady?.call();
        if (!widget.postSignupAwaitFullPersistOnly) {
          widget.onComplete();
        }
      } else {
        widget.onComplete();
      }
    } finally {
      await Future<void>.delayed(const Duration(seconds: 8));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 0, 32, (bottomPad > 0 ? bottomPad : 16) + 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepEntrance(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MerchantOnboardingColors.primaryGold.withValues(alpha: 0.18),
                        MerchantOnboardingColors.primaryGold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF163352), Color(0xFF0B1F33)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MerchantOnboardingColors.primaryGold.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: MerchantOnboardingColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _StepEntrance(
            delayMs: 60,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [MerchantOnboardingColors.textLight, Color(0xFFD4AF37)],
                stops: [0.3, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Tout est prêt !',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StepEntrance(
            delayMs: 100,
            child: Text(
              widget.isPostSignup
                  ? 'Votre vitrine est prête.\nAccédez à votre espace commerçant.'
                  : 'Votre profil est configuré.\nBienvenue dans la communauté Yuztoo.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantOnboardingColors.textGrey,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          _StepEntrance(
            delayMs: 160,
            child: SizedBox(
              width: double.infinity,
              child: _GoldCTAButton(
                label: widget.isPostSignup
                    ? 'Accéder à mon commerce'
                    : 'Lancer mon commerce',
                onTap: _handleComplete,
                isLoading: _isLoading,
                height: 56,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared text field ────────────────────────────────────────────────────────

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: MerchantOnboardingColors.primaryGold,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: MerchantOnboardingColors.textLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
          color: MerchantOnboardingColors.textGrey,
          fontSize: 14,
          height: 1.5,
        ),
        filled: true,
        fillColor: MerchantOnboardingColors.bgDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MerchantOnboardingColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: MerchantOnboardingColors.primaryGold,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
