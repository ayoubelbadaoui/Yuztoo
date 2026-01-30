import 'package:flutter/material.dart';

// Dark theme colors matching signup screen
const Color _bgDark2 = Color(0xFF111A2A);
const Color _primaryGold = Color(0xFFD4A017);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1.0 : 0.6,
          child: Container(
            decoration: BoxDecoration(
              color: _bgDark2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor, width: 1),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: validator,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autocorrect: autocorrect,
              enableSuggestions: enableSuggestions,
              enableInteractiveSelection: enableInteractiveSelection,
              // Disables platform spellcheck underlines (Android/iOS) when supported.
              spellCheckConfiguration: SpellCheckConfiguration.disabled(),
              autovalidateMode: AutovalidateMode.disabled,
              cursorColor: const Color(0xFFBF8719),
              style: TextStyle(
                color: enabled ? _textLight : _textLight.withOpacity(0.6),
                fontSize: 14,
              ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _textGrey, fontSize: 13),
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
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorStyle: const TextStyle(color: Color(0xFFE74C3C), fontSize: 12),
            ),
            ),
          ),
        ),
      ],
    );
  }
}

