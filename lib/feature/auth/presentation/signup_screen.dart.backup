import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;

  // State variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'client';
  String _selectedCountryCode = '+212';
  String? _phoneNumber;
  String? _selectedCity;

  // Colors - Exact Yuztoo theme
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);
  static const Color cardBg = Color(0xFF1A2A3A);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 8) {
      return 'Au minimum 8 caractères.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir une majuscule.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir une minuscule.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir un chiffre.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe.';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ville est requise.';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      _showSnackbar('Numéro de téléphone invalide.', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement Firebase Auth signup flow
      // 1. Create user with email/password
      // 2. Send OTP for phone verification
      // 3. Link phone credential
      // 4. Create Firestore profile
      // 5. Route based on role

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        _showSnackbar('Inscription réussie!', true);
        _clearForm();
        // TODO: Navigate to home or OTP verification screen
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Une erreur s\'est produite.', false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _cityController.clear();
    setState(() {
      _selectedRole = 'client';
      _selectedCity = null;
      _phoneNumber = null;
    });
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: textLight,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isSuccess ? successGreen : errorRed,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildLogoSection(),
              const SizedBox(height: 32),
              _buildSignupForm(),
              const SizedBox(height: 24),
              _buildSignupButton(),
              const SizedBox(height: 20),
              _buildSocialDivider(),
              const SizedBox(height: 16),
              _buildSocialLoginButtons(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryGold.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: primaryGold,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuztoo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'pour eux, pour vous',
          style: TextStyle(
            fontSize: 12,
            color: textGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Créez votre compte',
          style: TextStyle(
            fontSize: 18,
            color: textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'votre@email.com',
            keyboardType: TextInputType.emailAddress,
            icon: Icons.mail_outline,
            validator: _validateEmail,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: 'Min. 8 caractères',
            validator: _validatePassword,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          _buildPasswordHint(),
          const SizedBox(height: 16),
          _buildConfirmPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer mot de passe',
            hint: 'Répétez votre mot de passe',
            validator: _validateConfirmPassword,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildCityDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(icon, color: primaryGold, size: 18),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: !_isPasswordVisible,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline, color: primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: primaryGold,
                size: 20,
              ),
              onPressed: enabled
                  ? () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: textGrey,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '8+ caractères, majuscules, minuscules et chiffres',
              style: TextStyle(
                fontSize: 11,
                color: textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: !_isConfirmPasswordVisible,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(Icons.lock_outline, color: primaryGold, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: primaryGold,
                size: 20,
              ),
              onPressed: enabled
                  ? () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)
                  : null,
            ),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de téléphone',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          enabled: !_isLoading,
          disableLengthCheck: false,
          decoration: InputDecoration(
            hintText: 'Entrez votre numéro',
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
          ),
          style: const TextStyle(color: textLight, fontSize: 14),
          initialCountryCode: 'MA',
          keyboardType: TextInputType.number,
          searchText: 'Rechercher pays',
          onChanged: (phone) {
            setState(() {
              _phoneNumber = phone.completeNumber;
              _selectedCountryCode = '+${phone.countryCode}';
            });
          },
          onCountryChanged: (country) {
            setState(() => _selectedCountryCode = '+${country.dialCode}');
          },
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final cities = [
      'Casablanca',
      'Fès',
      'Marrakech',
      'Rabat',
      'Salé',
      'Tanger',
      'Meknès',
      'Agadir',
      'Tétouan',
      'Oujda',
      'Taourirt',
      'Nador',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ville',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCity,
          items: cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() => _selectedCity = value);
                },
          validator: _validateCity,
          autovalidateMode: AutovalidateMode.onUnfocus,
          decoration: InputDecoration(
            hintText: 'Sélectionnez votre ville',
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            prefixIcon: Icon(Icons.location_city, color: primaryGold, size: 18),
            filled: true,
            fillColor: bgDark2,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: errorRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 11,
            ),
          ),
          style: const TextStyle(color: textLight, fontSize: 14),
          dropdownColor: bgDark2,
          iconEnabledColor: primaryGold,
          iconDisabledColor: textGrey,
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFBF8719),
          disabledBackgroundColor: borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: const Color(0xFFBF8719).withOpacity(0.3),
          elevation: _isLoading ? 4 : 2,
        ),
        onPressed: _isLoading ? null : _handleSignup,
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(bgDark1.withOpacity(0.8)),
                ),
              )
            : const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: bgDark1,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              fontSize: 11,
              color: textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: borderColor.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            onPressed: () => _handleSocialLogin('google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            onPressed: () => _handleSocialLogin('facebook'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButtonApple(),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          color: bgDark2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryGold, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: textLight,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtonApple() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _handleSocialLogin('apple'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          color: bgDark2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🍎',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apple',
              style: TextStyle(
                fontSize: 10,
                color: textLight,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    // TODO: Implement social login (Google, Facebook, Apple)
    _showSnackbar('$provider login coming soon', false);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'Vous avez un compte ? ',
            style: const TextStyle(color: textGrey, fontSize: 13),
            children: [
              TextSpan(
                text: 'Connectez-vous',
                style: const TextStyle(
                  color: primaryGold,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: 0.6,
          child: Text(
            'En continuant, vous acceptez nos conditions d\'utilisation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: textGrey,
            ),
          ),
        ),
      ],
    );
  }
}
