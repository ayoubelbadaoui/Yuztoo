import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/shared/constants/merchant_colors.dart';

// Dark theme colors matching signup / loading
const Color _bgDark2 = MerchantColors.bgHeader;
const Color _primaryGold = MerchantColors.gold;
const Color _textLight = Color(0xFFF5F5F5);
const Color _textGrey = Color(0xFFB0B0B0);
const Color _borderColor = Color(0xFF2A3F5F);

class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.enabled = true,
    this.onSuffixTap,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.enableInteractiveSelection = true,
    this.focusNode,
    this.validateOnChange = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final bool enabled;
  final VoidCallback? onSuffixTap;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableInteractiveSelection;
  final FocusNode? focusNode;
  final bool validateOnChange;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      initialValue: controller.text,
      autovalidateMode: validateOnChange 
          ? AutovalidateMode.onUserInteraction 
          : AutovalidateMode.disabled,
      builder: (formFieldState) {
        // Sync controller value with FormField
        if (formFieldState.value != controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            formFieldState.didChange(controller.text);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFB8C4D4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: enabled ? 1.0 : 0.6,
              child: Container(
                decoration: BoxDecoration(
                  color: _bgDark2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: formFieldState.hasError
                        ? const Color(0xFFE74C3C)
                        : _borderColor,
                    width: formFieldState.hasError ? 1.5 : 1,
                  ),
                ),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  inputFormatters: inputFormatters,
                  validator: null,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  autocorrect: autocorrect,
                  enableSuggestions: enableSuggestions,
                  enableInteractiveSelection: enableInteractiveSelection,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                  autovalidateMode: AutovalidateMode.disabled,
                  cursorColor: _primaryGold,
                  style: GoogleFonts.outfit(
                    color: enabled ? _textLight : _textLight.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  onChanged: (value) {
                    formFieldState.didChange(value);
                    if (validateOnChange) {
                      formFieldState.validate();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.outfit(
                      color: _textGrey,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(icon, color: _primaryGold, size: 18),
                    suffixIcon: suffixIcon != null && onSuffixTap != null
                        ? IconButton(
                            icon: Icon(suffixIcon, color: _primaryGold, size: 18),
                            onPressed: onSuffixTap,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorText: null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
            ),
            if (formFieldState.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  formFieldState.errorText ?? '',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE74C3C),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

