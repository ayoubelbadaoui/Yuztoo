import 'package:flutter/material.dart';
import '../../../../theme.dart';
import '../../../../types.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.role,
    required this.onBack,
    required this.onLogin,
    required this.onSignup,
  });

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: YColors.primary,
              ),
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
                Text('Connexion', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  widget.role == UserRole.client
                      ? 'Connectez-vous pour découvrir les commerces'
                      : 'Accédez à votre espace professionnel',
                  style: TextStyle(color: YColors.muted),
                ),
                const SizedBox(height: 24),
                _InputField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'votre@email.com',
                  icon: Icons.mail_outline,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: YColors.secondary),
                  child: const Text('Mot de passe oublié ?'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vous n'avez pas de compte ?", style: TextStyle(color: YColors.muted)),
                    TextButton(
                      onPressed: widget.onSignup,
                      style: TextButton.styleFrom(foregroundColor: YColors.secondary),
                      child: const Text("S'inscrire"),
                    ),
                  ],
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
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: YColors.muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration.collapsed(
                  hintText: hint,
                  hintStyle: TextStyle(color: YColors.muted),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
