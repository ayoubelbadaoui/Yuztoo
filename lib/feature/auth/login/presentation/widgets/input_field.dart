import 'package:flutter/material.dart';
import '../../../../../theme.dart';

/// Reusable input field widget for login form
class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: YColors.muted),
          ),
        ),
      ],
    );
  }
}

