import 'package:flutter/material.dart';

class YuztooScreen extends StatefulWidget {
  const YuztooScreen({Key? key}) : super(key: key);

  @override
  State<YuztooScreen> createState() => _YuztooScreenState();
}

class _YuztooScreenState extends State<YuztooScreen> {
  String _selectedRole = 'client';
  bool _isScanning = false;

  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF111A2A);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);

  void _handleScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code scanned successfully!'),
            backgroundColor: Color(0xFF27AE60),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _handleDiscover() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Découvrir Yuztoo as ${_selectedRole == 'client' ? 'Clients' : 'Commerçant'}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login as ${_selectedRole == 'client' ? 'Clients' : 'Commerçant'}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HEADER
              _buildHeader(),
              const SizedBox(height: 32),
              
              // CONTENT
              _selectedRole == 'merchant'
                  ? _buildCommerçantView()
                  : _buildClientsView(),
              
              const SizedBox(height: 48),
              
              // FOOTER
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 4),
            boxShadow: [
              BoxShadow(
                color: primaryGold.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF192D41).withOpacity(0.6),
                bgDark2.withOpacity(0.8),
              ],
            ),
          ),
          child: Icon(
            Icons.location_on_rounded,
            size: 60,
            color: primaryGold,
          ),
        ),
        const SizedBox(height: 24),

        // Brand
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'yuz',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: textLight,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'too',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: primaryGold,
                  letterSpacing: -0.5,
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
            color: textGrey,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // Description
        const Text(
          'All the shops',
          style: TextStyle(
            fontSize: 17,
            color: textLight,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),

        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: '"You\'re used" to',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primaryGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Question
        const Text(
          'Bienvenue, Vous êtes ?',
          style: TextStyle(
            fontSize: 16,
            color: textLight,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        // Role Buttons
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgDark2.withOpacity(0.4),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: primaryGold.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildRoleButton('merchant', 'Commerçant'),
              ),
              Expanded(
                child: _buildRoleButton('client', 'Clients'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton(String value, String label) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryGold : Colors.transparent,
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

  Widget _buildCommerçantView() {
    return Column(
      children: [
        // Description Text
        Text(
          'Votre relation clients, vos données,\nvotre indépendance.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: textLight,
            fontWeight: FontWeight.w400,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 48),

        // Discover Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleDiscover,
            style: ElevatedButton.styleFrom(
              backgroundColor: textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              shadowColor: Colors.black.withOpacity(0.1),
              elevation: 4,
            ),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Découvrir Yuz',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: bgDark1,
                    ),
                  ),
                  TextSpan(
                    text: 'too',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientsView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
          color: primaryGold.withOpacity(0.35),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        color: bgDark2.withOpacity(0.7),
      ),
      child: Column(
        children: [
          // Camera Icon Top
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryGold,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryGold.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: bgDark1,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),

          // QR Code Box
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryGold.withOpacity(0.25),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: bgDark1.withOpacity(0.5),
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(100, 100),
                painter: QrPatternPainter(color: primaryGold),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Description Text
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Scanne le ',
                  style: TextStyle(
                    fontSize: 14,
                    color: textLight,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: 'QR code',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryGold,
                    height: 1.6,
                  ),
                ),
                const TextSpan(
                  text: ' ou la ',
                  style: TextStyle(
                    fontSize: 14,
                    color: textLight,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: 'plaque',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryGold,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'de ton commerce.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textLight,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Ajoute-le à ton carnet Yuztoo\net reçois ses infos utiles\n(offres, horaires, nouveautés).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textGrey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // Scan Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _handleScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                disabledBackgroundColor: primaryGold.withOpacity(0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: primaryGold.withOpacity(0.2),
                elevation: 6,
              ),
              icon: _isScanning
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(bgDark1),
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_rounded,
                      color: bgDark1,
                      size: 18,
                    ),
              label: Text(
                _isScanning ? 'Scanning...' : 'Lancer le scan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: bgDark1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return GestureDetector(
      onTap: _handleLogin,
      child: Text(
        'Vous avez déjà un compte ?',
        style: TextStyle(
          fontSize: 14,
          color: textGrey,
        ),
      ),
    );
  }
}

// QR Pattern Painter
class QrPatternPainter extends CustomPainter {
  final Color color;

  QrPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cellSize = size.width / 21;

    // Corner markers
    final corners = [
      (8, 8, 22),   // top-left
      (75, 8, 22),  // top-right
      (8, 75, 22),  // bottom-left
    ];

    for (var (x, y, s) in corners) {
      // Outer
      canvas.drawRect(
        Rect.fromLTWH(x, y, s, s),
        paint..color = color.withOpacity(0.5),
      );
      // Middle
      canvas.drawRect(
        Rect.fromLTWH(x + 3, y + 3, s - 6, s - 6),
        paint..color = color.withOpacity(0.3),
      );
      // Inner
      canvas.drawRect(
        Rect.fromLTWH(x + 6, y + 6, s - 12, s - 12),
        paint..color = color,
      );
    }

    // Data dots
    final dots = [
      (35, 35), (50, 35), (65, 35),
      (35, 50), (50, 50), (65, 50),
      (35, 65), (50, 65), (65, 65),
    ];

    for (var (x, y) in dots) {
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        paint..color = color.withOpacity(0.6),
      );
    }
  }

  @override
  bool shouldRepaint(QrPatternPainter oldDelegate) => false;
}