import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'theme.dart';
import 'types.dart';
import 'core/shared/widgets/bottom_nav.dart';
import 'feature/client_list/presentation/client_list_screen.dart';
import 'feature/splash/presentation/splash_screen.dart';
import 'feature/role_selection/presentation/role_selection_screen.dart';
import 'feature/auth/presentation/login_screen.dart';
import 'feature/auth/presentation/signup_screen.dart';
import 'feature/auth/presentation/otp_screen.dart';
import 'feature/client_home/presentation/client_home_screen.dart';
import 'feature/discovery/presentation/discovery_screen.dart';
import 'feature/qr_scanner/presentation/qr_scanner_screen.dart';
import 'feature/loyalty/presentation/loyalty_cards_screen.dart';
import 'feature/store_profile/presentation/store_profile_screen.dart';
import 'feature/notifications/presentation/notifications_screen.dart';
import 'feature/messages/presentation/messages_screen.dart';
import 'feature/profile/presentation/client_profile_screen.dart';
import 'feature/merchant_dashboard/presentation/merchant_dashboard_screen.dart';
import 'feature/promotions/presentation/promotions_management_screen.dart';
import 'feature/merchant_qr/presentation/merchant_qr_screen.dart';
import 'feature/merchant_stats/presentation/merchant_stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: AppBootstrap(
        child: YuztooApp(),
      ),
    ),
  );
}

class YuztooApp extends StatelessWidget {
  const YuztooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yuztoo',
      theme: buildTheme(),
      home: const _RootShell(),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  ScreenId _currentScreen = ScreenId.splash;
  UserRole? _role;
  String _activeTab = 'home';

  void _goToRoleSelection() {
    setState(() => _currentScreen = ScreenId.roleSelection);
  }

  void _handleRoleSelect(UserRole role) {
    setState(() {
      _role = role;
      _currentScreen = ScreenId.login;
      _activeTab = role == UserRole.client ? 'home' : 'dashboard';
    });
  }

  void _handleLogin() {
    setState(() {
      if (_role == UserRole.client) {
        _currentScreen = ScreenId.clientHome;
        _activeTab = 'home';
      } else {
        _currentScreen = ScreenId.merchantDashboard;
        _activeTab = 'dashboard';
      }
    });
  }

  void _handleSignup() {
    setState(() => _currentScreen = ScreenId.otp);
  }

  void _handleBackToLogin() {
    setState(() => _currentScreen = ScreenId.login);
  }

  void _handleBackToRole() {
    setState(() => _currentScreen = ScreenId.roleSelection);
  }

  void _handleLogout() {
    setState(() {
      _role = null;
      _currentScreen = ScreenId.roleSelection;
      _activeTab = 'home';
    });
  }

  void _handleNavigate(String screen) {
    final map = <String, ScreenId>{
      'discovery': ScreenId.discovery,
      'qr-scanner': ScreenId.qrScanner,
      'loyalty': ScreenId.loyalty,
      'store-profile': ScreenId.storeProfile,
      'notifications': ScreenId.notifications,
      'messages': _role == UserRole.client ? ScreenId.messages : ScreenId.merchantMessages,
      'profile': _role == UserRole.client ? ScreenId.clientProfile : ScreenId.merchantProfile,
      'clients': ScreenId.merchantClients,
      'promotions': ScreenId.merchantPromotions,
      'qr-code': ScreenId.merchantQr,
      'stats': ScreenId.merchantStats,
      'reservations': ScreenId.clientHome,
      'settings': ScreenId.merchantProfile,
    };

    final target = map[screen];
    if (target != null) {
      setState(() => _currentScreen = target);
    }
  }

  void _handleTabChange(String tab) {
    if (_role == null) return;

    setState(() {
      _activeTab = tab;
      if (_role == UserRole.client) {
        final map = <String, ScreenId>{
          'home': ScreenId.clientHome,
          'discovery': ScreenId.discovery,
          'loyalty': ScreenId.loyalty,
          'messages': ScreenId.messages,
          'profile': ScreenId.clientProfile,
        };
        _currentScreen = map[tab] ?? ScreenId.clientHome;
      } else {
        final map = <String, ScreenId>{
          'dashboard': ScreenId.merchantDashboard,
          'clients': ScreenId.merchantClients,
          'stats': ScreenId.merchantStats,
          'messages': ScreenId.merchantMessages,
          'profile': ScreenId.merchantProfile,
        };
        _currentScreen = map[tab] ?? ScreenId.merchantDashboard;
      }
    });
  }

  void _handleBackToBase() {
    if (_role == UserRole.client) {
      setState(() {
        _currentScreen = ScreenId.clientHome;
        _activeTab = 'home';
      });
    } else {
      setState(() {
        _currentScreen = ScreenId.merchantDashboard;
        _activeTab = 'dashboard';
      });
    }
  }

  bool get _showBottomNav {
    final allowed = <ScreenId>{
      ScreenId.clientHome,
      ScreenId.discovery,
      ScreenId.loyalty,
      ScreenId.messages,
      ScreenId.clientProfile,
      ScreenId.merchantDashboard,
      ScreenId.merchantClients,
      ScreenId.merchantStats,
      ScreenId.merchantMessages,
      ScreenId.merchantProfile,
    };
    return _role != null && allowed.contains(_currentScreen);
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildScreen(),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: _showBottomNav ? 72 : 0),
          child: body,
        ),
      ),
      bottomNavigationBar: _showBottomNav && _role != null
          ? YBottomNav(
              role: _role!,
              activeTab: _activeTab,
              onTabChange: _handleTabChange,
            )
          : null,
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case ScreenId.splash:
        return SplashScreen(onComplete: _goToRoleSelection);
      case ScreenId.roleSelection:
        return RoleSelectionScreen(onSelectRole: _handleRoleSelect);
      case ScreenId.login:
        return LoginScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToRole,
          onLogin: _handleLogin,
          onSignup: () => setState(() => _currentScreen = ScreenId.signup),
        );
      case ScreenId.signup:
        return SignupScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToLogin,
          onSignup: _handleSignup,
        );
      case ScreenId.otp:
        return OTPScreen(
          phone: '+212 6XX XXX XXX',
          onBack: _handleBackToLogin,
          onVerify: _handleLogin,
        );
      case ScreenId.clientHome:
        return ClientHomeScreen(onNavigate: _handleNavigate);
      case ScreenId.discovery:
        return DiscoveryScreen(
          onBack: _handleBackToBase,
          onStoreSelect: () => setState(() => _currentScreen = ScreenId.storeProfile),
        );
      case ScreenId.qrScanner:
        return QRScannerScreen(
          onBack: _handleBackToBase,
          onScanSuccess: () => setState(() => _currentScreen = ScreenId.storeProfile),
        );
      case ScreenId.loyalty:
        return LoyaltyCardsScreen(onBack: _handleBackToBase);
      case ScreenId.storeProfile:
        return StoreProfileScreen(
          onBack: _handleBackToBase,
          onMessage: () => setState(() => _currentScreen = ScreenId.messages),
          onReserve: _handleBackToBase,
        );
      case ScreenId.notifications:
        return NotificationsScreen(onBack: _handleBackToBase);
      case ScreenId.messages:
        return MessagesScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToBase,
          onConversationSelect: () {},
        );
      case ScreenId.clientProfile:
        return ClientProfileScreen(onLogout: _handleLogout);
      case ScreenId.merchantDashboard:
        return MerchantDashboardScreen(onNavigate: _handleNavigate);
      case ScreenId.merchantClients:
        return ClientListScreen(
          onBack: _handleBackToBase,
          onClientSelect: () {},
        );
      case ScreenId.merchantPromotions:
        return PromotionsManagementScreen(
          onBack: _handleBackToBase,
          onCreatePromotion: () {},
        );
      case ScreenId.merchantQr:
        return MerchantQRCodeScreen(onBack: _handleBackToBase);
      case ScreenId.merchantMessages:
        return MessagesScreen(
          role: _role ?? UserRole.merchant,
          onBack: _handleBackToBase,
          onConversationSelect: () {},
        );
      case ScreenId.merchantProfile:
        return ClientProfileScreen(onLogout: _handleLogout);
      case ScreenId.merchantStats:
        return MerchantStatsScreen(onBack: _handleBackToBase);
    }
  }
}
