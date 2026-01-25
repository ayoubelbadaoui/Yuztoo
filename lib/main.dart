import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'feature/auth/core/application/providers.dart';
import 'feature/auth/core/application/state/auth_state.dart';
import 'theme.dart';
import 'types.dart';
import 'core/shared/widgets/bottom_nav.dart';
import 'feature/client_list/presentation/client_list_screen.dart';
import 'feature/splash/presentation/splash_screen.dart';
import 'feature/role_selection/presentation/role_selection_screen.dart';
import 'feature/auth/login/presentation/login_screen.dart';
import 'feature/auth/signup/presentation/signup_screen.dart';
import 'feature/auth/signup/presentation/otp_screen.dart';
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

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  ScreenId _currentScreen = ScreenId.splash;
  UserRole? _role;
  String _activeTab = 'home';
  String? _signupUserId; // Store user ID from signup (passed to OTP screen)
  String? _phoneNumber; // Store phone number for OTP screen
  String? _verificationId; // Store verificationId for OTP resend
  String? _signupEmail; // Store email for Firestore profile
  String? _signupCity; // Store city for Firestore profile
  String? _otpUnavailableMessage; // Store OTP unavailable message
  bool _hasCheckedAuth = false; // Track if we've checked auth state
  bool _isCheckingAuth = true; // Track if we're currently checking auth state

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes from application layer
    // This must be done in build method (ref.listen requirement)
    final authState = ref.watch(authStateProvider);
    
    // Check auth state on first build
    if (!_hasCheckedAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasCheckedAuth) {
          _hasCheckedAuth = true;
          _handleAuthStateFromProvider(authState);
        }
      });
    }

    // Listen to future changes (login/logout)
    ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        // Only handle subsequent auth state changes (login/logout)
        // First change is handled above
        if (_hasCheckedAuth && previous != next) {
          _handleAuthStateFromProvider(next);
        }
      },
    );

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

  /// Handle auth state from AuthState provider
  void _handleAuthStateFromProvider(AuthState authState) async {
    switch (authState) {
      case AuthInitial():
        // Initial state - wait for stream to emit, don't mark as checked yet
        // The listener will handle the first real state change
        return;
      case AuthLoading():
        // Still loading - wait for actual state
        return;
      case Authenticated(:final user):
        // User is authenticated - get role from Firestore using application layer
        if (!_hasCheckedAuth) {
          _hasCheckedAuth = true;
          try {
            final getUserRole = ref.read(getUserRoleProvider);
            final roleResult = await getUserRole.call(user.id);
            final role = roleResult.fold(
              (_) => null,
              (r) => r,
            );
            
            if (mounted) {
              setState(() {
                _isCheckingAuth = false;
                _role = role ?? UserRole.client;
                if (_role == UserRole.client) {
                  _currentScreen = ScreenId.clientHome;
                  _activeTab = 'home';
                } else {
                  _currentScreen = ScreenId.merchantDashboard;
                  _activeTab = 'dashboard';
                }
              });
            }
          } catch (e) {
            // Error getting role - default to client and show home
            if (mounted) {
              setState(() {
                _isCheckingAuth = false;
                _role = UserRole.client;
                _currentScreen = ScreenId.clientHome;
                _activeTab = 'home';
              });
            }
          }
        }
      case Unauthenticated():
        // No user - show splash
        if (!_hasCheckedAuth) {
          _hasCheckedAuth = true;
          if (mounted) {
            setState(() {
              _isCheckingAuth = false;
              _currentScreen = ScreenId.splash;
            });
          }
        }
      case AuthError():
        // Error - show splash anyway
        if (!_hasCheckedAuth) {
          _hasCheckedAuth = true;
          if (mounted) {
            setState(() {
              _isCheckingAuth = false;
              _currentScreen = ScreenId.splash;
            });
          }
        }
    }
  }

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

  Widget _buildScreen() {
    // Show splash/loading while checking auth state
    if (_isCheckingAuth) {
      return SplashScreen(onComplete: () {});
    }
    
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
          onBack: () => setState(() => _currentScreen = ScreenId.login),
          onSignupSuccess: (userId, phoneNumber, verificationId, email, city, {otpUnavailableMessage}) {
            // Store all signup data, then navigate to OTP screen
            setState(() {
              _signupUserId = userId;
              _phoneNumber = phoneNumber;
              _verificationId = verificationId;
              _signupEmail = email;
              _signupCity = city;
              _otpUnavailableMessage = otpUnavailableMessage;
              _currentScreen = ScreenId.otp;
            });
          },
        );
      case ScreenId.otp:
        return OTPScreen(
          userId: _signupUserId ?? '',
          phone: _phoneNumber ?? '+33 XXX XXX XXX',
          verificationId: _verificationId,
          email: _signupEmail ?? '',
          city: _signupCity ?? '',
          role: _role ?? UserRole.client,
          otpUnavailableMessage: _otpUnavailableMessage,
          onBack: _handleBackToLogin,
          onVerify: _handleLogin,
          onResend: () {
            // VerificationId will be updated by OTP screen if resend succeeds
            // This callback can be used for any additional logic if needed
          },
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
