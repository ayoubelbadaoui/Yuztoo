import 'package:flutter/material.dart';
import '../theme.dart';
import '../types.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onSignup,
  });

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onSignup;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSignup();
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.role == UserRole.client;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: YColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Y', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 18),
                Text('Inscription', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  isClient ? 'Créez votre compte client' : 'Créez votre compte professionnel',
                  style: const TextStyle(color: YColors.muted),
                ),
                const SizedBox(height: 24),
                _InputField(
                  controller: _nameController,
                  label: isClient ? 'Nom complet' : 'Nom du commerce',
                  hint: isClient ? 'Jean Dupont' : 'Mon Commerce',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'votre@email.com',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  hint: '+212 6XX XXX XXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _confirmPasswordController,
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Créer mon compte'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "En vous inscrivant, vous acceptez nos conditions d'utilisation et notre politique de confidentialité",
                  style: TextStyle(color: YColors.muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: YColors.muted),
          ),
        ),
      ],
    );
  }
}
