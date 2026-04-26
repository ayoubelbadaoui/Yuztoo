part of 'signup_form_fields.dart';

// Shared label style — all field labels use this.
TextStyle _labelStyle() => GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFB8C4D4),
      letterSpacing: 0.6,
    );

// Shared input text style.
const TextStyle _inputTextStyle = TextStyle(
  color: SignupConstants.textLight,
  fontSize: 14,
);

// Shared hint text style.
TextStyle _hintStyle() => const TextStyle(
      color: SignupConstants.textGrey,
      fontSize: 13,
    );

// Shared border helper.
OutlineInputBorder _border(double radius, Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );

/// Email field widget
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey<FormFieldState> fieldKey;
  final bool hasBeenValidated;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onUnfocusAll;

  const EmailField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADRESSE E-MAIL', style: _labelStyle()),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          validator: SignupValidators.validateEmail,
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: SignupConstants.primaryGold,
          onTap: onTap ?? () {
            onUnfocusAll();
            focusNode.requestFocus();
          },
          onChanged: (value) {
            if (hasBeenValidated && value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fieldKey.currentState?.validate();
              });
            }
          },
          style: _inputTextStyle.copyWith(
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          decoration: InputDecoration(
            hintText: 'exemple@email.com',
            hintStyle: _hintStyle(),
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: SignupConstants.primaryGold,
              size: 18,
            ),
            filled: true,
            fillColor: SignupConstants.bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            isDense: true,
            border: _border(12, SignupConstants.borderColor, 1),
            enabledBorder: _border(12, SignupConstants.borderColor, 1),
            focusedBorder: _border(12, SignupConstants.primaryGold, 1.5),
            errorBorder: _border(12, SignupConstants.errorRed, 1.5),
            focusedErrorBorder: _border(12, SignupConstants.errorRed, 1.5),
            disabledBorder: _border(12, SignupConstants.borderColor, 1),
            errorStyle: const TextStyle(
              color: SignupConstants.errorRed,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field widget
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey<FormFieldState> fieldKey;
  final bool hasBeenValidated;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onUnfocusAll;
  final ValueChanged<bool> onFocusChanged;

  const PasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
    required this.onFocusChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MOT DE PASSE', style: _labelStyle()),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: !_isPasswordVisible,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          validator: SignupValidators.validatePassword,
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: SignupConstants.primaryGold,
          onTap: widget.onTap ?? () {
            widget.onUnfocusAll();
            widget.focusNode.requestFocus();
          },
          onChanged: (value) {
            if (widget.hasBeenValidated && value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.fieldKey.currentState?.validate();
              });
            }
          },
          style: _inputTextStyle,
          decoration: InputDecoration(
            hintText: 'Min. 8 caractères',
            hintStyle: _hintStyle(),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: SignupConstants.primaryGold,
              size: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: SignupConstants.primaryGold,
                size: 20,
              ),
              onPressed: widget.enabled
                  ? () => setState(() => _isPasswordVisible = !_isPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: SignupConstants.bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(12, SignupConstants.borderColor, 1),
            enabledBorder: _border(12, SignupConstants.borderColor, 1),
            focusedBorder: _border(12, SignupConstants.primaryGold, 1.5),
            errorBorder: _border(12, SignupConstants.errorRed, 1.5),
            focusedErrorBorder: _border(12, SignupConstants.errorRed, 1.5),
            disabledBorder: _border(12, SignupConstants.borderColor, 1),
            errorStyle: const TextStyle(
              color: SignupConstants.errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Password hint widget
class PasswordHint extends StatelessWidget {
  const PasswordHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: SignupConstants.textGrey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '8+ caractères avec majuscules, minuscules et chiffres',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: SignupConstants.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirm password field widget
class ConfirmPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final FocusNode focusNode;
  final GlobalKey<FormFieldState> fieldKey;
  final bool hasBeenValidated;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onUnfocusAll;

  const ConfirmPasswordField({
    super.key,
    required this.controller,
    required this.passwordController,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
  });

  @override
  State<ConfirmPasswordField> createState() => _ConfirmPasswordFieldState();
}

class _ConfirmPasswordFieldState extends State<ConfirmPasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CONFIRMER LE MOT DE PASSE', style: _labelStyle()),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: !_isPasswordVisible,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          validator: (value) => SignupValidators.validateConfirmPassword(
              value, widget.passwordController.text),
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: SignupConstants.primaryGold,
          onTap: widget.onTap ?? () {
            widget.onUnfocusAll();
            widget.focusNode.requestFocus();
          },
          onChanged: (value) {
            if (widget.hasBeenValidated && value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.fieldKey.currentState?.validate();
              });
            }
          },
          style: _inputTextStyle,
          decoration: InputDecoration(
            hintText: 'Répétez votre mot de passe',
            hintStyle: _hintStyle(),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: SignupConstants.primaryGold,
              size: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: SignupConstants.primaryGold,
                size: 20,
              ),
              onPressed: widget.enabled
                  ? () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: SignupConstants.bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(12, SignupConstants.borderColor, 1),
            enabledBorder: _border(12, SignupConstants.borderColor, 1),
            focusedBorder: _border(12, SignupConstants.primaryGold, 1.5),
            errorBorder: _border(12, SignupConstants.errorRed, 1.5),
            focusedErrorBorder: _border(12, SignupConstants.errorRed, 1.5),
            disabledBorder: _border(12, SignupConstants.borderColor, 1),
            errorStyle: const TextStyle(
              color: SignupConstants.errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone field widget
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey<FormFieldState> fieldKey;
  final String selectedCountryCode;
  final bool hasBeenValidated;
  final bool enabled;
  final VoidCallback onUnfocusAll;
  final Function(String) onPhoneNumberUpdate;
  final Function(String) onCountryCodeChange;
  final Function() onRevalidatePhone;

  const PhoneField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.selectedCountryCode,
    required this.hasBeenValidated,
    required this.enabled,
    required this.onUnfocusAll,
    required this.onPhoneNumberUpdate,
    required this.onCountryCodeChange,
    required this.onRevalidatePhone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('NUMÉRO DE TÉLÉPHONE', style: _labelStyle()),
        const SizedBox(height: 8),
        FormField<String>(
          key: fieldKey,
          autovalidateMode: AutovalidateMode.disabled,
          validator: (value) =>
              SignupValidators.validatePhone(value, selectedCountryCode),
          builder: (formFieldState) {
            final hasError = formFieldState.hasError;
            final isFocused = focusNode.hasFocus;
            final borderColor = hasError
                ? SignupConstants.errorRed
                : (isFocused
                    ? SignupConstants.primaryGold
                    : SignupConstants.borderColor);
            final borderWidth =
                (hasError || isFocused) ? 1.5 : 1.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    color: SignupConstants.bgDark2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Country code selector
                      GestureDetector(
                        onTap: enabled
                            ? () => CountryCodeModal.show(
                                  context,
                                  selectedCountryCode: selectedCountryCode,
                                  onCountrySelected: (code, name, flag) {
                                    onCountryCodeChange(code);
                                  },
                                  phoneController: controller,
                                  onPhoneNumberUpdate: onPhoneNumberUpdate,
                                  onRevalidatePhone: onRevalidatePhone,
                                  phoneFieldHasBeenValidated:
                                      hasBeenValidated,
                                )
                            : null,
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: SignupConstants.borderColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedCountryCode,
                                style: GoogleFonts.outfit(
                                  color: SignupConstants.textLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: SignupConstants.primaryGold,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Phone number input
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: enabled,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            PhoneNumberFormatter(
                                countryCode: selectedCountryCode),
                          ],
                          cursorColor: SignupConstants.primaryGold,
                          onTap: () {
                            onUnfocusAll();
                            focusNode.requestFocus();
                          },
                          style: _inputTextStyle,
                          decoration: InputDecoration(
                            hintText: SignupConstants.countryPhoneHints[
                                    selectedCountryCode] ??
                                '---',
                            hintStyle: _hintStyle(),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 15,
                            ),
                          ),
                          onChanged: (value) {
                            formFieldState.didChange(value);
                            final digitsOnly =
                                value.replaceAll(RegExp(r'[^\d]'), '');
                            final formattedPhone =
                                PhoneFormatter.formatPhoneNumber(
                                    selectedCountryCode, digitsOnly);
                            onPhoneNumberUpdate(formattedPhone);
                            if (hasBeenValidated &&
                                digitsOnly.isNotEmpty) {
                              WidgetsBinding.instance
                                  .addPostFrameCallback((_) {
                                formFieldState.validate();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasError && formFieldState.errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      formFieldState.errorText!,
                      style: const TextStyle(
                        color: SignupConstants.errorRed,
                        fontSize: 11,
                        height: 1.0,
                      ),
                      maxLines: 1,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// City dropdown widget
class CityDropdown extends StatelessWidget {
  final GlobalKey<FormFieldState> fieldKey;
  final String? selectedCity;
  final bool enabled;
  final VoidCallback onUnfocusAll;
  final Function(String) onCitySelected;
  final Function() onValidateCity;

  const CityDropdown({
    super.key,
    required this.fieldKey,
    required this.selectedCity,
    required this.enabled,
    required this.onUnfocusAll,
    required this.onCitySelected,
    required this.onValidateCity,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: fieldKey,
      initialValue: selectedCity,
      validator: (value) => SignupValidators.validateCity(selectedCity),
      autovalidateMode: AutovalidateMode.disabled,
      builder: (FormFieldState<String> state) {
        if (state.value != selectedCity) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.didChange(selectedCity);
            state.validate();
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('VILLE', style: _labelStyle()),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: enabled
                  ? () {
                      onUnfocusAll();
                      CitySelectionModal.show(
                        context,
                        cities: frenchCities,
                        selectedCity: selectedCity,
                        onCitySelected: onCitySelected,
                        onValidateCity: onValidateCity,
                      );
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError
                        ? SignupConstants.errorRed
                        : SignupConstants.borderColor,
                    width: state.hasError ? 1.5 : 1,
                  ),
                  color: SignupConstants.bgDark2,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_city_outlined,
                      color: SignupConstants.primaryGold,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedCity ?? 'Sélectionnez votre ville',
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedCity != null
                              ? SignupConstants.textLight
                              : SignupConstants.textGrey,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: SignupConstants.textGrey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(
                    color: SignupConstants.errorRed,
                    fontSize: 11,
                    height: 1.0,
                  ),
                  maxLines: 1,
                ),
              ),
          ],
        );
      },
    );
  }
}
