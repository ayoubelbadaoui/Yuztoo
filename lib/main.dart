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
  String? _signupUserId; // Store user ID from signup (passed to OTP screen) - now empty until OTP verified
  String? _phoneNumber; // Store phone number for OTP screen
  String? _verificationId; // Store verificationId for OTP resend
  String? _signupEmail; // Store email for Firestore profile
  String? _signupPassword; // Store password for user creation after OTP verification
  String? _signupCity; // Store city for Firestore profile
  String? _otpUnavailableMessage; // Store OTP unavailable message
  bool _isCheckingAuth = true; // Track if we're currently checking auth state
  bool _isReturningFromOTP = false; // Track if we're returning from OTP screen to preserve data

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state - stream now emits immediately (root fix in repository)
    final authState = ref.watch(authStateProvider);
    
    // Handle current state immediately (don't wait for changes)
    if (_isCheckingAuth) {
      // Handle auth state synchronously if it's already determined
      if (authState is! AuthInitial && authState is! AuthLoading) {
        // Auth state is already determined - handle it immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isCheckingAuth) {
            _handleAuthStateFromProvider(authState);
          }
        });
      } else {
        // Still loading - wait for the state to be determined
        // The listener below will handle it when it changes
      }
    }

    // Listen to future changes (login/logout) and initial state determination
    ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (_isCheckingAuth) {
          // Still checking auth - handle the state
          if (next is! AuthInitial && next is! AuthLoading) {
            _handleAuthStateFromProvider(next);
          }
        } else {
          // Handle state changes after initial check
          if (previous != next) {
            _handleAuthStateFromProvider(next);
          }
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
      case AuthLoading():
        // Wait for real state - keep showing splash/loading
        // Don't set _isCheckingAuth to false yet
        return;
      case Authenticated(:final user):
        // User is authenticated - get role from Firestore using application layer
        if (_isCheckingAuth) {
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
            // Error getting role - user is authenticated but we can't get their role
            // Default to client and show home (user IS authenticated, just role fetch failed)
            if (mounted) {
              setState(() {
                _isCheckingAuth = false;
                _role = UserRole.client;
                _currentScreen = ScreenId.clientHome;
                _activeTab = 'home';
              });
            }
          }
        } else {
          // User became authenticated after initial check (e.g., after login or signup)
          // CRITICAL: Don't navigate if we're in the signup/OTP flow
          // The signup flow will handle navigation to OTP screen
          if (_currentScreen == ScreenId.signup || _currentScreen == ScreenId.otp) {
            // User just signed up - don't navigate yet, let signup flow handle it
            // Just update the role if we can get it, but don't change screen
            try {
              final getUserRole = ref.read(getUserRoleProvider);
              final roleResult = await getUserRole.call(user.id);
              final role = roleResult.fold(
                (_) => null,
                (r) => r,
              );
              
              if (mounted) {
                setState(() {
                  _role = role ?? UserRole.client;
                  // Don't change _currentScreen - let signup/OTP flow handle navigation
                });
              }
            } catch (e) {
              // Error getting role - just set default role, don't navigate
              if (mounted) {
                setState(() {
                  _role = UserRole.client;
                  // Don't change _currentScreen - let signup/OTP flow handle navigation
                });
              }
            }
            return; // Exit early - don't navigate
          }
          
          // Only navigate if we're not already on an authenticated screen
          if (!_isAuthenticatedScreen(_currentScreen)) {
            try {
              final getUserRole = ref.read(getUserRoleProvider);
              final roleResult = await getUserRole.call(user.id);
              final role = roleResult.fold(
                (_) => null,
                (r) => r,
              );
              
              if (mounted) {
                setState(() {
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
                  _role = UserRole.client;
                  _currentScreen = ScreenId.clientHome;
                  _activeTab = 'home';
                });
              }
            }
          }
        }
      case Unauthenticated():
        // No user - ALWAYS go to role selection/login screen
        // This handles both initial check and subsequent logout/session expiry
        // ROOT FIX: Always set to roleSelection when unauthenticated, no conditions
        if (mounted) {
          setState(() {
            _isCheckingAuth = false;
            _role = null;
            // ALWAYS go to role selection when unauthenticated - no exceptions
            // This ensures we never stay on splash or authenticated screens
            _currentScreen = ScreenId.roleSelection;
          });
        }
      case AuthError():
        // Error - show splash anyway
        if (_isCheckingAuth) {
          if (mounted) {
            setState(() {
              _isCheckingAuth = false;
              _role = null;
              if (_isAuthenticatedScreen(_currentScreen)) {
                _currentScreen = ScreenId.login;
              }
            });
          }
        } else {
          // If error occurs after initial check, go to role selection
          if (mounted) {
            setState(() {
              _role = null;
              if (_isAuthenticatedScreen(_currentScreen)) {
                _currentScreen = ScreenId.login;
              }
            });
          }
        }
    }
  }

  /// Check if current screen requires authentication
  bool _isAuthenticatedScreen(ScreenId screen) {
    const authenticatedScreens = {
      ScreenId.clientHome,
      ScreenId.discovery,
      ScreenId.qrScanner,
      ScreenId.loyalty,
      ScreenId.storeProfile,
      ScreenId.notifications,
      ScreenId.messages,
      ScreenId.clientProfile,
      ScreenId.merchantDashboard,
      ScreenId.merchantClients,
      ScreenId.merchantPromotions,
      ScreenId.merchantQr,
      ScreenId.merchantMessages,
      ScreenId.merchantProfile,
      ScreenId.merchantStats,
    };
    return authenticatedScreens.contains(screen);
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

  // Removed _handleLogin - business logic moved to LoginFlowController
  // Navigation is now handled via onLoginSuccess callback

  void _handleBackToSignup() {
    setState(() {
      _isReturningFromOTP = true; // Mark that we're returning from OTP
      _currentScreen = ScreenId.signup;
    });
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
    // Get current auth state
    final authState = ref.watch(authStateProvider);
    
    // CRITICAL SAFETY CHECK: Never show authenticated screens unless user is authenticated
    // This prevents showing home page when user is not logged in
    final isAuthenticated = authState is Authenticated;
    final isAuthenticatedScreen = _isAuthenticatedScreen(_currentScreen);
    
    // ROOT FIX: Immediately update state and return correct screen if user is not authenticated
    // This prevents any flash of authenticated screens
    if (!isAuthenticated && isAuthenticatedScreen) {
      // User is NOT authenticated but trying to access authenticated screen
      // Force redirect to role selection IMMEDIATELY (synchronously)
      if (mounted) {
        // Update state synchronously - don't wait for postFrameCallback
        _isCheckingAuth = false;
        _currentScreen = ScreenId.roleSelection;
        _role = null;
        // Trigger setState to notify listeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
      // Return role selection screen immediately
      return RoleSelectionScreen(onSelectRole: _handleRoleSelect);
    }
    
    // ROOT FIX: If user is not authenticated and we're on splash, go to role selection
    // This handles the case where _currentScreen is still splash but auth state is determined
    if (!isAuthenticated && _currentScreen == ScreenId.splash && !_isCheckingAuth) {
      if (mounted) {
        _currentScreen = ScreenId.roleSelection;
        _role = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
      return RoleSelectionScreen(onSelectRole: _handleRoleSelect);
    }
    
    // Show splash/loading while checking auth state (only if we're still checking)
    if (_isCheckingAuth && (authState is AuthInitial || authState is AuthLoading)) {
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
          onLoginSuccess: ({
            required String uid,
            required UserRole role,
            required String city,
            required bool onboardingCompleted,
          }) {
            setState(() {
              _isCheckingAuth = false;
              _role = role;
              if (role == UserRole.client) {
                _currentScreen = ScreenId.clientHome;
                _activeTab = 'home';
                } else {
                  // Merchant - route to dashboard (onboarding handled separately if needed)
                  _currentScreen = ScreenId.merchantDashboard;
                  _activeTab = 'dashboard';
                }
            });
          },
          onSignup: () => setState(() {
            _isReturningFromOTP = false; // Clear flag when going to signup from login
            _currentScreen = ScreenId.signup;
          }),
        );
      case ScreenId.signup:
        // Only preserve data if returning from OTP screen
        String? extractedCountryCode;
        if (_isReturningFromOTP && _phoneNumber != null && _phoneNumber!.isNotEmpty && _phoneNumber!.startsWith('+')) {
          // Extract country code from phone number if available
          // Try to match against common country codes
          final commonCodes = ['+33', '+1', '+44', '+34', '+49', '+39', '+31', '+32', '+41', '+43', 
                              '+351', '+30', '+46', '+47', '+45', '+358', '+48', '+420', '+36', '+40',
                              '+212', '+216', '+213', '+20', '+27', '+81', '+82', '+86', '+91', '+61', '+64', '+55', '+52', '+54', '+56'];
          for (final code in commonCodes) {
            if (_phoneNumber!.startsWith(code)) {
              extractedCountryCode = code;
              break;
            }
          }
          // Fallback: use first 3 characters as country code
          if (extractedCountryCode == null && _phoneNumber!.length > 3) {
            extractedCountryCode = _phoneNumber!.substring(0, 3);
          }
        }
        
        return SignupScreen(
          role: _role ?? UserRole.client,
          onBack: () => setState(() {
            _isReturningFromOTP = false; // Clear flag when going back to login
            _currentScreen = ScreenId.login;
          }),
          // Pass stored data ONLY when returning from OTP screen
          initialEmail: _isReturningFromOTP ? _signupEmail : null,
          initialPassword: _isReturningFromOTP ? _signupPassword : null,
          initialPhone: _isReturningFromOTP ? _phoneNumber : null,
          initialCity: _isReturningFromOTP ? _signupCity : null,
          initialCountryCode: _isReturningFromOTP ? extractedCountryCode : null,
          onSignupSuccess: (userId, phoneNumber, verificationId, email, password, city, {otpUnavailableMessage}) {
            // Store all signup data, then navigate to OTP screen
            // Note: userId is empty until OTP is verified and user is created
            setState(() {
              _signupUserId = userId; // Empty string until OTP verified
              _phoneNumber = phoneNumber;
              _verificationId = verificationId;
              _signupEmail = email;
              _signupPassword = password; // Store password for user creation after OTP verification
              _signupCity = city;
              _otpUnavailableMessage = otpUnavailableMessage;
              _isReturningFromOTP = false; // Clear flag when going to OTP
              _currentScreen = ScreenId.otp;
            });
          },
        );
      case ScreenId.otp:
        return OTPScreen(
          userId: _signupUserId ?? '', // Empty until OTP verified and user created
          phone: _phoneNumber ?? '+33 XXX XXX XXX',
          verificationId: _verificationId,
          email: _signupEmail ?? '',
          password: _signupPassword ?? '', // Password for user creation after OTP verification
          city: _signupCity ?? '',
          role: _role ?? UserRole.client,
          otpUnavailableMessage: _otpUnavailableMessage,
          onBack: _handleBackToSignup,
          onVerify: () {
            // OTP verified - navigation handled by signup flow
            // Auth state will update and trigger navigation
          },
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
