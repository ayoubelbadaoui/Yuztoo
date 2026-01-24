import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared/widgets/snackbar.dart';
import '../../../../types.dart';
import '../application/providers.dart';
import '../../core/application/auth_error_mapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    Key? key,
    required this.role,
    required this.onBack,
    required this.onLogin,
    required this.onSignup,
  }) : super(key: key);

  final UserRole role;
  final VoidCallback onBack;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  // Focus Nodes
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;

  // State variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _selectedRole = 'client'; // Will be synced with widget.role

  // Colors - Exact Yuztoo theme (matching signup screen)
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color buttonGold = Color(0xFFBF8719);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);
  static const Color errorRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    
    // Sync selected role with widget.role
    _selectedRole = widget.role == UserRole.client ? 'client' : 'merchant';
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+').hasMatch(value)) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit faire au minimum 6 caractères.';
    }
    return null;
  }

  void _unfocusAllFields() {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Use application layer - DDD compliant (matching signup screen pattern)
    final signInUseCase = ref.read(signInWithEmailPasswordProvider);
    final signInResult = await signInUseCase.call(email: email, password: password);

    signInResult.fold(
      (failure) {
        if (mounted) {
          final frenchMessage = AuthErrorMapper.getFrenchMessage(failure);
          showErrorSnackbar(context, frenchMessage);
          setState(() => _isLoading = false);
        }
      },
      (authUser) {
        if (mounted) {
          setState(() => _isLoading = false);
          showSuccessSnackbar(context, 'Connexion réussie en tant que ${_selectedRole == 'client' ? 'Client' : 'Commerçant'}!');
    widget.onLogin();
        }
      },
    );
  }

  void _handleSocialLogin(String provider) {
    // TODO: Implement social login (Google, Facebook, Apple)
    showErrorSnackbar(context, 'Connexion $provider bientôt disponible');
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
              Align(
                alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFFBF8719),
                  iconSize: 24,
                ),
              ),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildRoleSelector(),
              const SizedBox(height: 40),
              _buildForm(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                color: primaryGold.withOpacity(0.25),
                blurRadius: 30,
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
                const SizedBox(height: 24),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textLight,
                ),
              ),
              TextSpan(
                text: 'too',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryGold,
                ),
              ),
            ],
          ),
                ),
                const SizedBox(height: 8),
        const Text(
          'POUR EUX, POUR VOUS',
          style: TextStyle(
            fontSize: 12,
            color: primaryGold,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgDark2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
                  children: [
          Expanded(
            child: _buildRoleButton('client', 'Clients'),
          ),
          Expanded(
            child: _buildRoleButton('merchant', 'Commerçant'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(String value, String label) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? buttonGold : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? bgDark1 : textLight,
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            placeholder: 'Adresse email',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            enabled: !_isLoading,
            onTap: () {
              _unfocusAllFields();
              _emailFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 32),
          // Forgot password link
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => print('Forgot password'),
              child: const Text(
                'Mot de passe oublié?',
                style: TextStyle(
                  fontSize: 13,
                  color: primaryGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSignInButton(),
          const SizedBox(height: 32),
          _buildSocialDivider(),
          const SizedBox(height: 24),
          _buildSocialButtons(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUnfocus,
          cursorColor: const Color(0xFFBF8719),
          onTap: onTap,
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: textGrey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: errorRed,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Colors.transparent,
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          enabled: !_isLoading,
          obscureText: !_isPasswordVisible,
          validator: _validatePassword,
          autovalidateMode: AutovalidateMode.onUnfocus,
          cursorColor: const Color(0xFFBF8719),
          onTap: () {
            _unfocusAllFields();
            _passwordFocusNode.requestFocus();
          },
          style: const TextStyle(color: textLight, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Mot de passe',
            hintStyle: const TextStyle(color: textGrey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              child: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: primaryGold,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: primaryGold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: errorRed,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
            filled: true,
            fillColor: Colors.transparent,
            errorStyle: const TextStyle(
              color: errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: buttonGold,
          disabledBackgroundColor: buttonGold.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: buttonGold.withOpacity(0.3),
          elevation: _isLoading ? 4 : 2,
        ),
        onPressed: _isLoading ? null : _handleSubmit,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(bgDark1),
                ),
              )
            : const Text(
                'Se connecter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: bgDark1,
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

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            label: 'Google',
            iconWidget: _buildGoogleIcon(),
            onPressed: () => _handleSocialLogin('google'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            iconColor: const Color(0xFF1877F2),
            onPressed: () => _handleSocialLogin('facebook'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            iconColor: textLight,
            onPressed: () => _handleSocialLogin('apple'),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? label,
    Color? iconColor,
    Widget? iconWidget,
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
            iconWidget ?? Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label ?? '',
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

  Widget _buildFooter() {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.onSignup,
          child: Text.rich(
            TextSpan(
              text: 'Vous n\'avez pas de compte ? ',
              style: const TextStyle(color: textGrey, fontSize: 13),
              children: [
                TextSpan(
                  text: 'Créer un compte',
                  style: const TextStyle(
                    color: primaryGold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
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

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.55;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // Draw the outer colored "G" shape
    // Blue section (top-right quadrant)
    final bluePath = Path()
      ..arcTo(rect, -1.57, 1.57, false)
      ..arcTo(innerRect, 0, -1.57, true)
      ..close();
    canvas.drawPath(
      bluePath,
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );

    // Red section (top-left quadrant)
    final redPath = Path()
      ..arcTo(rect, 1.57, 1.57, false)
      ..arcTo(innerRect, 3.14, -1.57, true)
      ..close();
    canvas.drawPath(
      redPath,
      Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill,
    );

    // Yellow section (bottom-left quadrant)
    final yellowPath = Path()
      ..arcTo(rect, 3.14, 1.57, false)
      ..arcTo(innerRect, 4.71, -1.57, true)
      ..close();
    canvas.drawPath(
      yellowPath,
      Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill,
    );

    // Green section (bottom-right, extends further)
    final greenPath = Path()
      ..arcTo(rect, -1.57, 3.14, false)
      ..arcTo(innerRect, 1.57, -3.14, true)
      ..close();
    canvas.drawPath(
      greenPath,
      Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill,
    );

    // Draw white center circle
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );

    // Draw the "G" opening - horizontal bar extending from center-right
    final gBarPath = Path()
      ..moveTo(center.dx + innerRadius * 0.3, center.dy)
      ..lineTo(center.dx + radius * 0.7, center.dy)
      ..lineTo(center.dx + radius * 0.7, center.dy - radius * 0.15)
      ..lineTo(center.dx + innerRadius * 0.5, center.dy - radius * 0.15)
      ..lineTo(center.dx + innerRadius * 0.5, center.dy - innerRadius * 0.3)
      ..lineTo(center.dx + radius * 0.6, center.dy - innerRadius * 0.3)
      ..lineTo(center.dx + radius * 0.6, center.dy)
      ..close();
    canvas.drawPath(
      gBarPath,
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
