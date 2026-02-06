import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/signup_constants.dart';
import '../utils/signup_validators.dart';
import '../utils/phone_formatter.dart';
import 'phone_number_formatter.dart';
import 'country_code_modal.dart';
import 'city_selection_modal.dart';
import '../../../../../core/utils/cities.dart';

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
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Adresse email',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SignupConstants.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          validator: SignupValidators.validateEmail,
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: const Color(0xFFBF8719),
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
          style: const TextStyle(
            color: SignupConstants.textLight,
            fontSize: 14,
            decoration: TextDecoration.none,
            decorationColor: Colors.transparent,
          ),
          decoration: InputDecoration(
            hintText: 'email',
            hintStyle: const TextStyle(
              color: SignupConstants.textGrey,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
            prefixIcon: const Icon(Icons.mail_outline, color: SignupConstants.primaryGold, size: 18),
            filled: true,
            fillColor: SignupConstants.bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
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
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
    required this.onFocusChanged,
  }) : super(key: key);

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
        const Text(
          'Mot de passe',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SignupConstants.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: !_isPasswordVisible,
          validator: SignupValidators.validatePassword,
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: const Color(0xFFBF8719),
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
          style: const TextStyle(color: SignupConstants.textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Min. 8 caractères',
            hintStyle: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline, color: SignupConstants.primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
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
  const PasswordHint({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: SignupConstants.textGrey,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '8+ caractères, majuscules, minuscules et chiffres',
              style: TextStyle(
                fontSize: 11,
                color: SignupConstants.textGrey,
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
    Key? key,
    required this.controller,
    required this.passwordController,
    required this.focusNode,
    required this.fieldKey,
    required this.hasBeenValidated,
    required this.enabled,
    this.onTap,
    required this.onUnfocusAll,
  }) : super(key: key);

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
        const Text(
          'Confirmer mot de passe',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SignupConstants.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: !_isPasswordVisible,
          validator: (value) => SignupValidators.validateConfirmPassword(value, widget.passwordController.text),
          autovalidateMode: AutovalidateMode.disabled,
          cursorColor: const Color(0xFFBF8719),
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
          style: const TextStyle(color: SignupConstants.textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Répétez votre mot de passe',
            hintStyle: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline, color: SignupConstants.primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
            ),
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SignupConstants.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          key: fieldKey,
          autovalidateMode: AutovalidateMode.disabled,
          validator: (value) {
            return SignupValidators.validatePhone(value, selectedCountryCode);
          },
          builder: (formFieldState) {
            final hasError = formFieldState.hasError;
            final borderColorValue = hasError
                ? SignupConstants.errorRed
                : (focusNode.hasFocus ? SignupConstants.primaryGold : SignupConstants.borderColor);
            final borderWidth = (hasError || focusNode.hasFocus) ? 1.5 : 1.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColorValue,
                      width: borderWidth,
                    ),
                    color: SignupConstants.bgDark2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Country code button
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
                                  phoneFieldHasBeenValidated: hasBeenValidated,
                                )
                            : null,
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: SignupConstants.borderColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedCountryCode,
                                style: const TextStyle(
                                  color: SignupConstants.textLight,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.expand_more,
                                color: SignupConstants.primaryGold,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Visual separator
                      Container(
                        width: 1,
                        height: 30,
                        color: SignupConstants.borderColor.withOpacity(0.3),
                      ),
                      const SizedBox(width: 8),
                      // Phone number field
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: enabled,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            PhoneNumberFormatter(countryCode: selectedCountryCode),
                          ],
                          cursorColor: const Color(0xFFBF8719),
                          onTap: () {
                            onUnfocusAll();
                            focusNode.requestFocus();
                          },
                          style: const TextStyle(color: SignupConstants.textLight, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '---',
                            hintStyle: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            // The formatter already handles formatting, so we just need to:
                            // 1. Update the form field state for validation
                            formFieldState.didChange(value);
                            
                            // 2. Extract digits and update phone number (E.164 format) for backend
                            final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                            final formattedPhone = PhoneFormatter.formatPhoneNumber(selectedCountryCode, digitsOnly);
                            onPhoneNumberUpdate(formattedPhone);
                            
                            // 3. Real-time validation if field has been validated before
                            if (hasBeenValidated && digitsOnly.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
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
    Key? key,
    required this.fieldKey,
    required this.selectedCity,
    required this.enabled,
    required this.onUnfocusAll,
    required this.onCitySelected,
    required this.onValidateCity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: fieldKey,
      initialValue: selectedCity,
      validator: (value) {
        // Always validate based on current selectedCity
        return SignupValidators.validateCity(selectedCity);
      },
      autovalidateMode: AutovalidateMode.disabled,
      builder: (FormFieldState<String> state) {
        // Update FormField value when selectedCity changes
        if (state.value != selectedCity) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.didChange(selectedCity);
            // Validate after updating value
            state.validate();
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ville',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SignupConstants.textGrey,
                letterSpacing: 0.5,
              ),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.hasError ? SignupConstants.errorRed : SignupConstants.borderColor,
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
                          color: selectedCity != null ? SignupConstants.textLight : SignupConstants.textGrey,
                        ),
                      ),
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

