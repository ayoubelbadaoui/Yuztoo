import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_bootstrap.dart';
import 'core/domain/core/either.dart';
import 'core/domain/core/failure.dart';
import 'core/domain/core/result.dart';
import 'feature/auth/core/application/providers.dart';
import 'feature/auth/core/application/state/auth_state.dart';
import 'feature/auth/core/domain/entities/auth_user.dart';
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
import 'feature/merchant_onboarding/presentation/merchant_onboarding_screen.dart';
import 'feature/storefront/presentation/storefront_screen.dart';
import 'feature/merchant_onboarding/presentation/subcategory_selection_screen.dart';
import 'feature/merchant_onboarding/presentation/merchant_benefits_screen.dart';
import 'feature/merchant_onboarding/presentation/widgets/subcategory/restaurant_subcategories.dart';

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
  ProviderSubscription<AuthState>? _authStateSub;
  // Main navigation screen from provider (auth flow)
  ScreenId? _authScreen; // null = loading
  // Within-app navigation (discovery, messages, etc.) - manual state
  ScreenId? _nestedScreen; // null = use _authScreen
  UserRole? _role; // For bottom nav and role-based navigation
  String _activeTab = 'home';
  // Signup/OTP flow data
  String? _signupUserId;
  String? _phoneNumber;
  String? _verificationId;
  String? _signupEmail;
  String? _signupPassword;
  String? _signupCity;
  String? _otpUnavailableMessage;

  @override
  void initState() {
    super.initState();
    // Initialize to splash screen immediately
    _authScreen = ScreenId.splash;
    _hasReceivedFirstAuthState = false;
    _isNavigatingToHome = false;

    // Listen immediately so we don't miss a fast first auth emission.
    _authStateSub = ref.listenManual<AuthState>(
      authControllerProvider,
      (previous, next) => _handleAuthStateChange(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authStateSub?.close();
    super.dispose();
  }

  bool _hasReceivedFirstAuthState = false;
  bool _isNavigatingToHome = false; // Track when we're navigating to home

  /// Handle auth state changes and update navigation
  void _handleAuthStateChange(AuthState authState) {
    if (!mounted) return;
    
    if (authState is AuthInitial) {
      // Initial state - show splash while auth stream initializes
      // Only set if we're on splash or null
      if (_authScreen == null || _authScreen == ScreenId.splash) {
        setState(() => _authScreen = ScreenId.splash);
      }
      return;
    } else if (authState is AuthLoading) {
      // Show loading, but keep splash if we haven't received first state yet
      if (!_hasReceivedFirstAuthState || _isNavigatingToHome) {
        setState(() => _authScreen = ScreenId.splash);
      } else {
        setState(() => _authScreen = null); // Show loading
      }
    } else {
      // Mark that we've received the first real auth state.
      // IMPORTANT: capture whether this is the first state BEFORE flipping the flag,
      // so AuthError can correctly route off splash on first emission.
      final wasFirstRealAuthState = !_hasReceivedFirstAuthState;
      _hasReceivedFirstAuthState = true;
      
      if (authState is Unauthenticated) {
        // Reset navigation flag
        _isNavigatingToHome = false;
        
        // On first auth state, if unauthenticated, go to role selection
        // But if we're already on a home screen (shouldn't happen, but safety check), don't navigate
        // IMPORTANT: If we're navigating to home (just logged in), don't navigate away
        // This prevents race conditions where userChanges() emits null briefly
        final onHomeScreen = _authScreen == ScreenId.clientHome ||
            _authScreen == ScreenId.merchantDashboard;
        final inAuthFlow = _authScreen == ScreenId.login ||
            _authScreen == ScreenId.signup ||
            _authScreen == ScreenId.otp;
        
        // Don't navigate if we're in the middle of navigating to home (prevents logout during login)
        if (!onHomeScreen && !inAuthFlow && !_isNavigatingToHome) {
          setState(() {
            _authScreen = ScreenId.roleSelection;
            // Don't reset _role - preserve last selection
            _nestedScreen = null;
          });
        }
      } else if (authState is AuthError) {
        // Reset navigation flag
        _isNavigatingToHome = false;
        
        // Only navigate to role selection if this is the first real auth state.
        // This prevents showing errors for temporary network issues during app startup
        if (wasFirstRealAuthState) {
          // First real state is an error - likely temporary, treat as unauthenticated
          setState(() {
            _authScreen = ScreenId.roleSelection;
            _role = null;
            _nestedScreen = null;
          });
        }
        // If we already have a state, don't navigate away (prevents flicker)
        // The error might be temporary and will resolve on next auth state change
      } else if (authState is Authenticated) {
        // For authenticated users, compute navigation based on role
        // Keep splash screen until navigation is ready
        // Set flag and ensure splash BEFORE async operation to prevent any flicker
        _isNavigatingToHome = true;
        if (_authScreen != ScreenId.splash) {
          setState(() => _authScreen = ScreenId.splash);
        }
        // Now handle navigation (async)
        _handleAuthenticatedUser(authState.user);
      }
    }
  }
  
  /// Handle authenticated user - compute role and navigate
  /// Handles delays gracefully without showing errors
  /// Keeps splash screen until navigation is ready to prevent flicker
  /// NOTE: Flag and splash screen are set synchronously in _handleAuthStateChange
  /// before this async function is called to prevent any race conditions
  Future<void> _handleAuthenticatedUser(AuthUser user) async {
    if (!mounted) {
      _isNavigatingToHome = false;
      return;
    }
    
    // Flag is already set in _handleAuthStateChange, but ensure we're still on splash
    if (_authScreen != ScreenId.splash && mounted) {
      setState(() => _authScreen = ScreenId.splash);
    }
    
    // Use fallback role immediately (from user.role) to prevent delays
    final fallbackRole = _mapUserRoleString(user.role) ?? UserRole.client;
    
    try {
      // Get user role with timeout to handle network delays gracefully
      final getUserRole = ref.read(getUserRoleProvider);
      Result<UserRole?> roleResult;
      try {
        roleResult = await getUserRole
            .call(user.id)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException catch (_) {
        // Timeout is not an error - return fallback role wrapped in Result
        roleResult = Right<AppFailure, UserRole?>(fallbackRole);
      } catch (_) {
        // Any error - use fallback role wrapped in Result
        roleResult = Right<AppFailure, UserRole?>(fallbackRole);
      }
      
      final role = roleResult.fold(
        (_) => fallbackRole, // network/firestore failure → fall back to authUser role
        (r) => r ?? fallbackRole, // missing doc/roles → fall back to authUser role
      );
      
      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }
      
      // Use the role (fallbackRole is already set, so role will never be null)
      final effectiveRole = role;
      
      // Determine target screen based on role and onboarding status
      ScreenId targetScreen;
      if (effectiveRole == UserRole.client) {
        targetScreen = ScreenId.clientHome;
    } else {
        // Merchant - after signup, always go to dashboard (not onboarding)
        // Merchants can access onboarding from within the dashboard if needed
        targetScreen = ScreenId.merchantDashboard;
      }
      
      // Now navigate to home screen (we were on splash, so this is safe)
      if (mounted) {
        setState(() {
          _authScreen = targetScreen;
          _role = effectiveRole;
          _activeTab = effectiveRole == UserRole.client ? 'home' : 'taches';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
      }
    } catch (e) {
      // On any unexpected error, fall back to authUser role without signing out
      // Don't show errors - just use fallback data
      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }
      
      final fallbackRole = _mapUserRoleString(user.role) ?? UserRole.client;
      
      // Determine target screen with onboarding check for merchants
      ScreenId targetScreen;
      if (fallbackRole == UserRole.merchant) {
        // Check onboarding status with timeout
        bool onboardingCompleted = false;
        try {
          final isOnboardingCompleted = ref.read(isMerchantOnboardingCompletedProvider);
          final onboardingResult = await isOnboardingCompleted
              .call(user.id)
              .timeout(const Duration(seconds: 5));
          onboardingCompleted = onboardingResult.fold(
            (_) => false, // Error → assume incomplete
            (completed) => completed ?? false, // null → incomplete
          );
        } catch (_) {
          // Timeout or error → assume incomplete (non-fatal)
          onboardingCompleted = false;
        }
        targetScreen = onboardingCompleted
            ? ScreenId.merchantDashboard
            : ScreenId.merchantOnboarding;
      } else {
        targetScreen = ScreenId.clientHome;
      }
      
      if (mounted) {
        setState(() {
          _role = fallbackRole;
          _authScreen = targetScreen;
          _activeTab = fallbackRole == UserRole.merchant ? 'taches' : 'home';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
      }
    }
  }

  UserRole? _mapUserRoleString(String role) {
    switch (role.toLowerCase()) {
      case 'merchant':
        return UserRole.merchant;
      case 'client':
      default:
        return UserRole.client;
    }
  }

  // Note: navigation to role selection is driven by AuthState (Unauthenticated),
  // not by the splash screen timer.

  void _handleRoleSelect(UserRole role) {
    // Set role and navigate based on role
    // This is called when user clicks action buttons (Découvrir, Scan, Login)
    // so we should always navigate
    setState(() {
      _role = role;
      if (role == UserRole.merchant) {
        // Navigate to merchant onboarding for discovery
        _authScreen = ScreenId.merchantOnboarding;
      } else {
        // Navigate to login for clients
        _authScreen = ScreenId.login;
      }
      _activeTab = role == UserRole.client ? 'home' : 'taches';
    });
  }

  void _handleBackToLogin() {
    setState(() => _authScreen = ScreenId.login);
  }

  void _handleBackToRole() {
    setState(() => _authScreen = ScreenId.roleSelection);
  }

  void _handleNavigate(String screen) {
    // Within-app navigation (manual state for nested screens)
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
      setState(() => _nestedScreen = target);
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
        final target = map[tab] ?? ScreenId.clientHome;
        // If it's a main tab screen, update auth screen; otherwise nested
        if (target == ScreenId.clientHome || target == ScreenId.clientProfile) {
          _authScreen = target;
          _nestedScreen = null;
        } else {
          _nestedScreen = target;
        }
      } else {
        final map = <String, ScreenId>{
          'communaute': ScreenId.merchantClients, // Map to clients screen
          'taches': ScreenId.merchantDashboard, // Map to dashboard for tasks
          'storefront': ScreenId.merchantStorefront,
          'marketing': ScreenId.merchantPromotions, // Map to promotions for marketing
          'profile': ScreenId.merchantProfile,
        };
        final target = map[tab] ?? ScreenId.merchantDashboard;
        // If it's a main tab screen, update auth screen; otherwise nested
        if (target == ScreenId.merchantDashboard || target == ScreenId.merchantProfile || target == ScreenId.merchantStorefront) {
          _authScreen = target;
          _nestedScreen = null;
        } else {
          _nestedScreen = target;
        }
      }
    });
  }

  void _handleBackToBase() {
    if (_role == UserRole.client) {
      setState(() {
        _authScreen = ScreenId.clientHome;
        _nestedScreen = null;
        _activeTab = 'home';
      });
    } else {
      setState(() {
        _authScreen = ScreenId.merchantDashboard;
        _nestedScreen = null;
        _activeTab = 'taches';
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
      ScreenId.merchantStorefront,
      ScreenId.merchantPromotions,
      ScreenId.merchantMessages,
      ScreenId.merchantProfile,
    };
    final currentScreen = _nestedScreen ?? _authScreen;
    return _role != null && currentScreen != null && allowed.contains(currentScreen);
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider alive (listening is in initState via listenManual)
    ref.watch(authControllerProvider);
    
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildScreen(),
    );

    // Get current screen to set background color
    final currentScreen = _nestedScreen ?? _authScreen;
    final isStorefront = currentScreen == ScreenId.merchantStorefront;
    final scaffoldBgColor = isStorefront 
        ? const Color(0xFFFDFBF7) // Storefront background color
        : Colors.white; // Default white
    
    // Set system navigation bar color to match bottom nav for all merchant pages with bottom nav
    if (_role == UserRole.merchant && _showBottomNav) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFF0B162C), // StorefrontColors.navyDark
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );
    } else {
      // Reset to default for other screens
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          // Don't add bottom padding for storefront - it handles its own spacing
          padding: EdgeInsets.only(bottom: (_showBottomNav && !isStorefront) ? 72 : 0),
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
    // Determine current screen: nested screen takes priority, then auth screen
    // Fallback to role selection if auth screen is null (shouldn't happen, but safety)
    final currentScreen = _nestedScreen ?? _authScreen ?? ScreenId.roleSelection;
    
    switch (currentScreen) {
      case ScreenId.splash:
        // Splash is a pure loading surface; routing is driven by AuthState.
        return const SplashScreen();
      case ScreenId.roleSelection:
        return RoleSelectionScreen(
          onSelectRole: _handleRoleSelect,
          initialRole: _role,
          onRoleChanged: (UserRole role) {
            // Update role without navigating (just preserve selection)
            setState(() => _role = role);
          },
          onLogin: () {
            // Navigate to login page for the currently selected role
            setState(() {
              _authScreen = ScreenId.login;
            });
          },
        );
      case ScreenId.login:
        return LoginScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToRole,
          onSignup: () => setState(() => _authScreen = ScreenId.signup),
        );
      case ScreenId.signup:
        return SignupScreen(
          role: _role ?? UserRole.client,
          onBack: () => setState(() => _authScreen = ScreenId.login),
        );
      case ScreenId.otp:
        return OTPScreen(
          onBack: _handleBackToLogin,
          userId: _signupUserId ?? '',
          phone: _phoneNumber ?? '+33 XXX XXX XXX',
          verificationId: _verificationId,
          email: _signupEmail ?? '',
          password: _signupPassword ?? '',
          city: _signupCity ?? '',
          role: _role ?? UserRole.client,
          otpUnavailableMessage: _otpUnavailableMessage,
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
          onStoreSelect: () => setState(() => _nestedScreen = ScreenId.storeProfile),
        );
      case ScreenId.qrScanner:
        return QRScannerScreen(
          onBack: _handleBackToBase,
          onScanSuccess: () => setState(() => _nestedScreen = ScreenId.storeProfile),
        );
      case ScreenId.loyalty:
        return LoyaltyCardsScreen(onBack: _handleBackToBase);
      case ScreenId.storeProfile:
        return StoreProfileScreen(
          onBack: _handleBackToBase,
          onMessage: () => setState(() => _nestedScreen = ScreenId.messages),
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
        return const ClientProfileScreen();
      case ScreenId.merchantOnboarding:
        return MerchantOnboardingScreen(
          onCategorySelected: (categoryId) {
            // Category selection handled internally
          },
          onBack: () => setState(() => _authScreen = ScreenId.roleSelection),
          onNext: () {
            // Navigate to subcategory selection for restaurant (for now, only restaurant has subcategories)
            setState(() => _authScreen = ScreenId.merchantSubcategorySelection);
          },
        );
      case ScreenId.merchantSubcategorySelection:
        return SubcategorySelectionScreen(
          categoryTitle: 'Métiers de bouche mais encore...',
          subcategories: RestaurantSubcategories.all,
          onSubcategorySelected: (subcategoryId) {
            // Handle subcategory selection
          },
          onBack: () => setState(() => _authScreen = ScreenId.merchantOnboarding),
          onNext: () {
            setState(() => _authScreen = ScreenId.merchantBenefits);
          },
        );
      case ScreenId.merchantBenefits:
        return MerchantBenefitsScreen(
          onBack: () => setState(() => _authScreen = ScreenId.merchantSubcategorySelection),
          onStartFree: () {
            // Navigate to merchant signup page
            setState(() {
              _role = UserRole.merchant;
              _authScreen = ScreenId.signup;
            });
          },
        );
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
        return const ClientProfileScreen();
      case ScreenId.merchantStats:
        return MerchantStatsScreen(onBack: _handleBackToBase);
      case ScreenId.merchantStorefront:
        return const StorefrontScreen();
    }
  }
}
