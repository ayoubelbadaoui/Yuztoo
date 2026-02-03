import 'package:flutter/material.dart';

void main() {
  runApp(const YuztooApp());
}

class YuztooApp extends StatelessWidget {
  const YuztooApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuztoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro',
      ),
      home: const YuztooBenefitsScreen(),
    );
  }
}

class YuztooBenefitsScreen extends StatefulWidget {
  const YuztooBenefitsScreen({Key? key}) : super(key: key);

  @override
  State<YuztooBenefitsScreen> createState() => _YuztooBenefitsScreenState();
}

class _YuztooBenefitsScreenState extends State<YuztooBenefitsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Original Yuztoo colors only
  static const Color bgDark1 = Color(0xFF0F1A29);
  static const Color bgDark2 = Color(0xFF1A2B42);
  static const Color primaryGold = Color(0xFFD4A017);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color borderColor = Color(0xFF2A3F5F);

  final List<BenefitItem> benefits = [
    BenefitItem(
      title: 'Vos clients, vraiment à vous:',
      description: 'Centralisez vos clients sans dépendre\ndes plateformes.',
    ),
    BenefitItem(
      title: 'Communiquez simplement:',
      description: 'Envoyez des infos utiles directement à\nvos clients, sans intermédiaire.',
    ),
    BenefitItem(
      title: 'La fidélité se fait toute seule:',
      description: 'Chaque passage compte sans carte ni\ncontrainte.',
    ),
    BenefitItem(
      title: 'Cercle de confiance',
      description: 'Recommandez des commerces et soyez\nrecommandés sans note ni classement.',
    ),
    BenefitItem(
      title: 'Accès direct',
      description: 'Facilitez l\'accès à vos solutions existantes\n(réservation, click & collect...)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleStartFree() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Démarrage gratuit...'),
        backgroundColor: primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark1,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Main Title
                      _buildMainTitle(),
                      
                      const SizedBox(height: 24),
                      
                      // Subtitle
                      _buildSubtitle(),
                      
                      const SizedBox(height: 32),
                      
                      // Benefits List
                      _buildBenefitsList(),
                      
                      const SizedBox(height: 32),
                      
                      // Free text
                      _buildFreeText(),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // CTA Button (Fixed at bottom)
            _buildCTAButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTitle() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          Text(
            'Yuztoo, concrètement pour vous',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: textLight,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryGold.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _animationController,
      child: Text(
        'Restez dans la poche de vos clients',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w300,
          color: textLight,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      children: List.generate(
        benefits.length,
        (index) {
          final delay = index * 100;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + delay),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildBenefitCard(benefits[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitCard(BenefitItem benefit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgDark2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            benefit.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryGold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            benefit.description,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeText() {
    return FadeTransition(
      opacity: _animationController,
      child: Text(
        'Gratuit pour démarrer, sans engagement.',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: textGrey,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            bgDark1,
            bgDark1.withOpacity(0.95),
            bgDark1.withOpacity(0.0),
          ],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _handleStartFree,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            shadowColor: primaryGold.withOpacity(0.4),
          ),
          child: Text(
            'Démarrer gratuitement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: bgDark1,
            ),
          ),
        ),
      ),
    );
  }
}

class BenefitItem {
  final String title;
  final String description;

  BenefitItem({
    required this.title,
    required this.description,
  });
}