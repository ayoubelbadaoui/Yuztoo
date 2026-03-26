import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'l10n/app_localizations.dart';

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
import 'feature/store_profile/application/providers.dart' as store_profile_providers;
import 'feature/store_profile/presentation/store_profile_screen.dart';
import 'feature/notifications/presentation/notifications_screen.dart';
import 'feature/messages/presentation/messages_screen.dart';
import 'feature/profile/presentation/client_profile_screen.dart';
import 'feature/merchant_dashboard/presentation/merchant_dashboard_screen.dart';
import 'feature/promotions/presentation/promotions_management_screen.dart';
import 'feature/merchant_qr/presentation/merchant_qr_screen.dart';
import 'feature/merchant_stats/presentation/merchant_stats_screen.dart';
import 'feature/merchant_onboarding/presentation/merchant_onboarding_screen.dart';
import 'feature/merchant_onboarding/presentation/subcategory_selection_screen.dart';
import 'feature/merchant_onboarding/presentation/merchant_benefits_screen.dart';
import 'feature/merchant_onboarding/application/onboarding_flow_provider.dart'
    as merchant_onboarding_providers;
import 'feature/storefront/presentation/storefront_screen.dart';
import 'feature/merchant/presentation/merchant_profile_form_screen.dart';
import 'feature/rappels/presentation/rappels_screen.dart';
import 'feature/rappels/presentation/notifications_auto_screen.dart';
import 'feature/merchant_settings/presentation/merchant_settings_screen.dart';
import 'feature/e_fidelite/presentation/e_fidelite_screen.dart';
import 'feature/account_preferences/presentation/account_preferences_screen.dart';
import 'feature/merchant/application/providers.dart' as merchant_providers;
import 'core/config/vitrine_qr_config.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> with WidgetsBindingObserver {
  ProviderSubscription<AuthState>? _authStateSub;
  // Main navigation screen from provider (auth flow)
  ScreenId? _authScreen; // null = loading
  // Within-app navigation (discovery, messages, etc.) - manual state
  ScreenId? _nestedScreen; // null = use _authScreen
  ScreenId? _previousNestedScreen; // remembers previous nested screen before notifications
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

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSubscription;
  /// Vitrine deep link received before auth / main shell is ready (cold start or login).
  String? _pendingVitrineMerchantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep display awake while the app is in the foreground (OS may still suspend in background).
    unawaited(WakelockPlus.enable());

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

    _appLinkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      if (!mounted) return;
      _onAppLinkUri(uri);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialAppLink());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(WakelockPlus.disable());
    _appLinkSubscription?.cancel();
    _authStateSub?.close();
    super.dispose();
  }

  Future<void> _consumeInitialAppLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (!mounted || uri == null) return;
      _onAppLinkUri(uri);
    } catch (_) {}
  }

  void _onAppLinkUri(Uri uri) {
    final merchantId = VitrineQrConfig.tryParseMerchantId(uri.toString());
    if (merchantId == null || merchantId.isEmpty) return;

    if (_canApplyVitrineDeepLinkNow()) {
      _openVitrineForMerchant(merchantId);
    } else {
      _pendingVitrineMerchantId = merchantId;
    }
  }

  bool _canApplyVitrineDeepLinkNow() {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return false;
    final screen = _nestedScreen ?? _authScreen;
    if (screen == null) return false;
    const defer = <ScreenId>{
      ScreenId.splash,
      ScreenId.roleSelection,
      ScreenId.login,
      ScreenId.signup,
      ScreenId.otp,
      ScreenId.merchantOnboarding,
      ScreenId.merchantSubcategorySelection,
      ScreenId.merchantBenefits,
      ScreenId.merchantProfileForm,
    };
    return !defer.contains(screen);
  }

  void _openVitrineForMerchant(String merchantId) {
    if (!mounted) return;
    ref.read(store_profile_providers.selectedStoreMerchantIdProvider.notifier).state =
        merchantId;
    setState(() {
      _nestedScreen = ScreenId.storeProfile;
    });
  }

  void _tryConsumePendingVitrineLink() {
    final id = _pendingVitrineMerchantId;
    if (id == null || id.isEmpty) return;
    if (!_canApplyVitrineDeepLinkNow()) return;
    _pendingVitrineMerchantId = null;
    _openVitrineForMerchant(id);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(WakelockPlus.enable());
    } else {
      unawaited(WakelockPlus.disable());
    }
  }

  bool _hasReceivedFirstAuthState = false;
  bool _isNavigatingToHome = false; // Track when we're navigating to home

  /// Clears transient signup/onboarding draft data to avoid leaking values
  /// between different accounts after logout.
  Future<void> _clearAuthTransientDrafts() async {
    try {
      await ref.read(merchant_providers.merchantProfileCacheServiceProvider).clear();
    } catch (_) {}
    try {
      ref.read(merchant_onboarding_providers.onboardingFlowProvider.notifier).reset();
    } catch (_) {}
    _signupUserId = null;
    _phoneNumber = null;
    _verificationId = null;
    _signupEmail = null;
    _signupPassword = null;
    _signupCity = null;
    _otpUnavailableMessage = null;
  }

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
        unawaited(_clearAuthTransientDrafts());
        // Reset navigation flag
        _isNavigatingToHome = false;
        
        // On first auth state, if unauthenticated, go to role selection
        // But if we're already on a home screen (shouldn't happen, but safety check), don't navigate
        // IMPORTANT: If we're navigating to home (just logged in), don't navigate away
        // This prevents race conditions where userChanges() emits null briefly
        final onHomeScreen = _authScreen == ScreenId.clientHome ||
            _authScreen == ScreenId.merchantDashboard ||
            _authScreen == ScreenId.merchantStorefront;
        final inAuthFlow = _authScreen == ScreenId.login ||
            _authScreen == ScreenId.signup ||
            _authScreen == ScreenId.otp;
        
        // Don't navigate if we're in the middle of navigating to home (prevents logout during login)
        if (!onHomeScreen && !inAuthFlow && !_isNavigatingToHome) {
          setState(() {
            // Onboarding is only after signup for merchants (see merchantProfileForm)
            _authScreen = ScreenId.roleSelection;
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
    
    // Use the best available fallback role:
    // - current in-memory selection (role selection / signup flow)
    // - last locally saved selection (survives app restarts)
    // - authUser.role (legacy fallback)
    final cachedRole =
        await ref.read(roleCacheServiceProvider).readLastSelectedRole();
    final fallbackRole =
        _role ?? cachedRole ?? _mapUserRoleString(user.role) ?? UserRole.client;
    
    try {
      // Get user role with retry logic
      // For newly created accounts (signup), Firestore might need a moment to write the document
      // For existing accounts (login), this ensures we get the role even if there's a brief delay
      final getUserRole = ref.read(getUserRoleProvider);
      Result<UserRole?> roleResult;
      UserRole? role;
      
      // Retry up to 3 times with increasing delays (200ms, 500ms)
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          if (attempt > 0) {
            // Wait before retry: 200ms, 500ms
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
          
          roleResult = await getUserRole
              .call(user.id)
              .timeout(const Duration(seconds: 5));
          
          role = roleResult.fold(
            (_) => null, // network/firestore failure → null, will retry
            (r) => r, // success → use the role
          );
          
          // If we got a valid role, break out of retry loop
          if (role != null) break;
        } on TimeoutException catch (_) {
          // Timeout → will retry if attempts remain
          if (attempt == 2) {
            // Last attempt failed → use fallback
            roleResult = Right<AppFailure, UserRole?>(fallbackRole);
            role = fallbackRole;
          }
        } catch (_) {
          // Any error → will retry if attempts remain
          if (attempt == 2) {
            // Last attempt failed → use fallback
            roleResult = Right<AppFailure, UserRole?>(fallbackRole);
            role = fallbackRole;
          }
        }
      }
      
      // Use the role we got, or fallback if Firestore is unavailable (e.g. permission-denied).
      UserRole effectiveRole = role ?? fallbackRole;

      // Users with BOTH client and merchant: getUserRole() in Firestore returns merchant first.
      // Respect the role the user chose on the login screen / cached intent.
      try {
        final getUserRoles = ref.read(getUserRolesProvider);
        final rolesResult = await getUserRoles.call(user.id);
        final rolesMap = rolesResult.fold((_) => null, (m) => m);
        final hasClient = rolesMap?['client'] == true;
        final hasMerchant = rolesMap?['merchant'] == true;
        if (hasClient && hasMerchant) {
          final consumeForceMerchantNextLogin =
              ref.read(consumeForceMerchantNextLoginProvider);
          final consumeResult = await consumeForceMerchantNextLogin.call(user.id);
          final forceMerchantOnce = consumeResult.fold((_) => false, (v) => v);
          if (forceMerchantOnce) {
            effectiveRole = UserRole.merchant;
          } else {
            // Until role switch is added, multi-role users should open as client by default.
            effectiveRole = UserRole.client;
          }
        }
      } catch (_) {
        // Keep effectiveRole
      }

      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }

      // Persist resolved role so next cold start matches last session
      try {
        await ref.read(roleCacheServiceProvider).saveLastSelectedRole(effectiveRole);
      } catch (_) {}

      // Determine target screen based on role and onboarding status
      ScreenId targetScreen;
      if (effectiveRole == UserRole.client) {
        targetScreen = ScreenId.clientHome;
      } else {
        // Merchant - check if onboarding is complete
        // Check cache FIRST (works even if Firestore fails)
        bool onboardingCompleted = false;
        try {
          final cacheService = ref.read(merchant_providers.merchantProfileCacheServiceProvider);
          final cachedData = await cacheService.loadProfile();
          // If cache has merchant name, consider onboarding complete
          if (cachedData['userId'] == user.id && cachedData['name'] != null && cachedData['name']!.isNotEmpty) {
            onboardingCompleted = true;
          }
        } catch (_) {
          // Cache check failed - continue to Firestore check
        }
        
        // If cache didn't have data, check Firestore (optional)
        if (!onboardingCompleted) {
          try {
            final isOnboardingCompleted = ref.read(isMerchantOnboardingCompletedProvider);
            final onboardingResult = await isOnboardingCompleted.call(user.id);
            onboardingCompleted = onboardingResult.fold(
              (_) => false, // Firestore failed - keep false, show form
              (completed) => completed ?? false,
            );
          } catch (_) {
            // Firestore check failed - keep false, show form
            onboardingCompleted = false;
          }
        }
        
        // If onboarding not complete, show profile form
        targetScreen = onboardingCompleted 
            ? ScreenId.merchantStorefront 
            : ScreenId.merchantProfileForm;
      }
      
      // Now navigate to home screen (we were on splash, so this is safe)
      if (mounted) {
        setState(() {
          _authScreen = targetScreen;
          _role = effectiveRole;
          _activeTab = effectiveRole == UserRole.client ? 'home' : 'storefront';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryConsumePendingVitrineLink();
        });
        // UI updates handled by setState above
      }
    } catch (e) {
      // On any unexpected error, fall back to authUser role without signing out
      // Don't show errors - just use fallback data
      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }
      
      final cachedRole =
          await ref.read(roleCacheServiceProvider).readLastSelectedRole();
      final fallbackRole =
          _role ?? cachedRole ?? _mapUserRoleString(user.role) ?? UserRole.client;
      
      // Determine target screen with onboarding check for merchants
      ScreenId targetScreen;
      if (fallbackRole == UserRole.merchant) {
        // Check cache to see if merchant profile exists
        bool hasProfile = false;
        try {
          final cacheService = ref.read(merchant_providers.merchantProfileCacheServiceProvider);
          final cachedData = await cacheService.loadProfile();
          if (cachedData['userId'] == user.id && cachedData['name'] != null && cachedData['name']!.isNotEmpty) {
            hasProfile = true;
          }
        } catch (_) {
          // Cache check failed - assume no profile
        }
        targetScreen = hasProfile ? ScreenId.merchantStorefront : ScreenId.merchantProfileForm;
      } else {
        targetScreen = ScreenId.clientHome;
      }
      
      if (mounted) {
        setState(() {
          _role = fallbackRole;
          _authScreen = targetScreen;
          _activeTab = fallbackRole == UserRole.merchant ? 'storefront' : 'home';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryConsumePendingVitrineLink();
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
      _authScreen =
          role == UserRole.merchant ? ScreenId.merchantOnboarding : ScreenId.login;
      _activeTab = role == UserRole.client ? 'home' : 'storefront';
    });

    // Persist role so we can route correctly even if Firestore rules block reads/writes.
    ref.read(roleCacheServiceProvider).saveLastSelectedRole(role);
  }

  void _handleBackToLogin() {
    setState(() => _authScreen = ScreenId.login);
  }

  void _handleBackToRole() {
    setState(() => _authScreen = ScreenId.roleSelection);
  }

  /// Discovery back: unauthenticated (e.g. merchant guest browse) → role selection.
  void _handleBackFromDiscovery() {
    final authState = ref.read(authControllerProvider);
    if (authState is Unauthenticated) {
      setState(() => _authScreen = ScreenId.roleSelection);
      return;
    }
    _handleBackToBase();
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
      'notifications-auto': ScreenId.merchantNotificationsAuto,
      'e-fidelite': ScreenId.merchantEFidelite,
      'account-preferences': ScreenId.merchantAccountPreferences,
    };

    final target = map[screen];
    if (target != null) {
      setState(() {
        // Client QR scanner is a tab – switch to it instead of nesting
        if (_role == UserRole.client && target == ScreenId.qrScanner) {
          _activeTab = 'qr-scanner';
          _authScreen = ScreenId.qrScanner;
          _nestedScreen = null;
          _previousNestedScreen = null;
        } else {
          if (target == ScreenId.notifications &&
              _nestedScreen != null &&
              _nestedScreen != ScreenId.notifications) {
            _previousNestedScreen = _nestedScreen;
          } else if (target != ScreenId.notifications) {
            _previousNestedScreen = null;
          }
          _nestedScreen = target;
        }
      });
    }
  }

  void _handleTabChange(String tab) {
    if (_role == null) return;

    setState(() {
      _activeTab = tab;
      // For merchants, if storefront tab is selected, ensure we're on storefront screen
      if (_role == UserRole.merchant && tab == 'storefront') {
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
        _previousNestedScreen = null;
        return;
      }
      if (_role == UserRole.client) {
        final map = <String, ScreenId>{
          'home': ScreenId.clientHome,
          'discovery': ScreenId.discovery,
          'qr-scanner': ScreenId.qrScanner,
          'loyalty': ScreenId.loyalty,
          'profile': ScreenId.clientProfile,
        };
        final target = map[tab] ?? ScreenId.clientHome;
        // All client tabs are top-level: set auth screen and clear nested
        _authScreen = target;
        _nestedScreen = null;
        _previousNestedScreen = null;
      } else {
        final map = <String, ScreenId>{
          'communaute': ScreenId.merchantClients, // Map to clients screen
          'rappels': ScreenId.merchantRappels, // Map to rappels screen
          'storefront': ScreenId.merchantStorefront,
          'promotions': ScreenId.merchantPromotions, // Map to promotions
          'profile': ScreenId.merchantProfile,
        };
        final target = map[tab] ?? ScreenId.merchantStorefront; // Default to storefront
        // If it's a main tab screen, update auth screen; otherwise nested
        if (target == ScreenId.merchantClients || target == ScreenId.merchantRappels || target == ScreenId.merchantPromotions || target == ScreenId.merchantProfile || target == ScreenId.merchantStorefront) {
          _authScreen = target;
          _nestedScreen = null;
          _previousNestedScreen = null;
        } else {
          _previousNestedScreen = null;
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
        _previousNestedScreen = null;
        _activeTab = 'home';
      });
    } else {
      setState(() {
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
        _previousNestedScreen = null;
        _activeTab = 'storefront';
      });
    }
  }

  void _openNotificationsScreen() {
    setState(() {
      if (_nestedScreen != null && _nestedScreen != ScreenId.notifications) {
        _previousNestedScreen = _nestedScreen;
      }
      _nestedScreen = ScreenId.notifications;
    });
  }

  /// Go back from a nested screen to its parent (the current _authScreen).
  /// Unlike _handleBackToBase, this does NOT reset to the root home/storefront.
  void _handleBackFromNested() {
    if (_nestedScreen == ScreenId.notifications &&
        _previousNestedScreen != null) {
      setState(() {
        _nestedScreen = _previousNestedScreen;
        _previousNestedScreen = null;
      });
    } else if (_nestedScreen != null) {
      setState(() {
        _nestedScreen = null;
        _previousNestedScreen = null;
      });
    } else {
      _handleBackToBase();
    }
  }

  /// Handles the Android system back button and the iOS swipe-back gesture.
  /// NEVER exits the app – always navigates backwards or stays put.
  void _handleSystemBack(bool didPop) {
    if (didPop) return; // Already handled by a nested Navigator

    final currentScreen = _nestedScreen ?? _authScreen;

    // 1) If we're on a nested sub-screen, go back to the parent tab screen.
    if (_nestedScreen != null) {
      _handleBackFromNested();
      return;
    }

    // 2) Auth flow – go back through the auth screens.
    if (currentScreen == ScreenId.login) {
      setState(() => _authScreen = ScreenId.roleSelection);
      return;
    }
    if (currentScreen == ScreenId.signup) {
      setState(() => _authScreen = ScreenId.login);
      return;
    }
    if (currentScreen == ScreenId.otp) {
      setState(() => _authScreen = ScreenId.login);
      return;
    }
    if (currentScreen == ScreenId.merchantOnboarding) {
      setState(() => _authScreen = ScreenId.roleSelection);
      return;
    }

    // 3) Merchant tab screens – go back to storefront (home) unless already there.
    if (_role == UserRole.merchant &&
        currentScreen != ScreenId.merchantStorefront) {
      setState(() {
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
        _activeTab = 'storefront';
      });
      return;
    }

    // 4) Client tab screens – go back to home unless already there.
    if (_role == UserRole.client && currentScreen != ScreenId.clientHome) {
      setState(() {
        _authScreen = ScreenId.clientHome;
        _nestedScreen = null;
        _activeTab = 'home';
      });
      return;
    }

    // 5) Already on root home / role selection – do nothing. Never exit the app.
  }

  bool get _showBottomNav {
    final allowed = <ScreenId>{
      ScreenId.clientHome,
      ScreenId.discovery,
      ScreenId.qrScanner,
      ScreenId.loyalty,
      ScreenId.clientProfile,
      ScreenId.merchantDashboard,
      ScreenId.merchantClients,
      ScreenId.merchantStorefront,
      ScreenId.merchantRappels,
      ScreenId.merchantPromotions,
      ScreenId.merchantMessages,
      ScreenId.merchantProfile,
    };
    final currentScreen = _nestedScreen ?? _authScreen;
    if (_role == null || currentScreen == null) return false;
    if (!allowed.contains(currentScreen)) return false;
    // Merchant browsing discovery grid (guest): no bottom nav — not a merchant tab.
    if (_role == UserRole.merchant && currentScreen == ScreenId.discovery) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Keep provider alive (listening is in initState via listenManual)
    ref.watch(authControllerProvider);

    // Get current screen for key and styling
    final currentScreen = _nestedScreen ?? _authScreen ?? ScreenId.roleSelection;

    // Sharper transitions: key forces AnimatedSwitcher to run transition when screen changes,
    // shorter duration reduces fuzzy crossfade, no layout scaling.
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey<ScreenId>(currentScreen),
        child: _buildScreen(),
      ),
    );
    final isStorefront = currentScreen == ScreenId.merchantStorefront;
    const authBgDark = Color(0xFF0E2A44); // MerchantColors.bgMain – auth + discover pages
    final isAuthDarkScreen = currentScreen == ScreenId.splash ||
        currentScreen == ScreenId.roleSelection ||
        currentScreen == ScreenId.login ||
        currentScreen == ScreenId.signup ||
        currentScreen == ScreenId.otp ||
        currentScreen == ScreenId.merchantProfileForm ||
        currentScreen == ScreenId.merchantOnboarding ||
        currentScreen == ScreenId.merchantSubcategorySelection ||
        currentScreen == ScreenId.merchantBenefits;

    // Screens whose topmost section/header is the app primary color (dark),
    // so the status bar should match that header for a seamless look.
    final hasPrimaryHeaderTop = currentScreen == ScreenId.clientHome ||
        currentScreen == ScreenId.merchantDashboard ||
        currentScreen == ScreenId.clientProfile ||
        currentScreen == ScreenId.qrScanner ||
        currentScreen == ScreenId.loyalty;

    final isRappels = currentScreen == ScreenId.merchantRappels;
    final isPromotions = currentScreen == ScreenId.merchantPromotions;
    final isNotificationsAuto = currentScreen == ScreenId.merchantNotificationsAuto;
    final isMerchantProfile = currentScreen == ScreenId.merchantProfile;
    final isEFidelite = currentScreen == ScreenId.merchantEFidelite;
    final isAccountPrefs = currentScreen == ScreenId.merchantAccountPreferences;
    final isMerchantClients = currentScreen == ScreenId.merchantClients;
    final isClientProfile = currentScreen == ScreenId.clientProfile;
    final isClientHome = currentScreen == ScreenId.clientHome;
    final isDiscovery = currentScreen == ScreenId.discovery;
    final isQrScanner = currentScreen == ScreenId.qrScanner;
    final isStoreProfile = currentScreen == ScreenId.storeProfile;
    final isNotifications = currentScreen == ScreenId.notifications;
    final isDarkMerchantScreen = isRappels || isPromotions || isNotificationsAuto || isMerchantProfile || isEFidelite || isAccountPrefs || isMerchantClients;
    final isClientDarkScreen = isClientProfile || isClientHome || isDiscovery || isQrScanner || isStoreProfile || isNotifications || currentScreen == ScreenId.loyalty;
    final scaffoldBgColor = isStorefront
        ? const Color(0xFFFDFBF7) // Storefront background color
        : isDarkMerchantScreen
            ? const Color(0xFF0E2A44) // MerchantColors.bgMain
            : isClientDarkScreen
                ? const Color(0xFF0E2A44) // MerchantColors.bgMain – client home, profile, discovery
                : (isAuthDarkScreen ? authBgDark : Colors.white);
    
    // Default rule: system bars follow the current background (and bottom nav if present).
    // IMPORTANT: Use AnnotatedRegion (not SystemChrome.setSystemUIOverlayStyle in build),
    // so screens that provide their own overlay style (e.g. OTP/Login dark screens)
    // are not overridden.
    final statusBarColor = isNotifications
        ? const Color(0xFF0B1F33) // MerchantColors.bgHeader (match notifications header)
        : isAuthDarkScreen
        ? authBgDark
        : (isStorefront
            ? scaffoldBgColor
            : (hasPrimaryHeaderTop || isDiscovery || isStoreProfile ? YColors.primary : scaffoldBgColor));
    final systemNavBarColor = (_showBottomNav && _role == UserRole.merchant)
        ? const Color(0xFF0B1F33) // MerchantColors.bgHeader
        : (_showBottomNav && _role == UserRole.client)
            ? const Color(0xFF0B1F33) // same dark nav for client (no white square)
            : scaffoldBgColor;

    final statusIsLight = statusBarColor.computeLuminance() > 0.5;
    final navIsLight = systemNavBarColor.computeLuminance() > 0.5;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: statusBarColor,
      statusBarIconBrightness:
          statusIsLight ? Brightness.dark : Brightness.light,
      // iOS: "brightness of the status bar" == brightness of the *background*
      statusBarBrightness: statusIsLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: systemNavBarColor,
      systemNavigationBarIconBrightness:
          navIsLight ? Brightness.dark : Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
        child: Scaffold(
          backgroundColor: scaffoldBgColor,
          body: Builder(
          builder: (context) {
            final topInset = MediaQuery.of(context).padding.top;

            // Some screens already include their own SafeArea (auth + onboarding + storefront),
            // so we avoid applying SafeArea twice.
            final screenHandlesSafeArea = currentScreen == ScreenId.roleSelection ||
                currentScreen == ScreenId.login ||
                currentScreen == ScreenId.signup ||
                currentScreen == ScreenId.otp ||
                currentScreen == ScreenId.merchantProfileForm ||
                currentScreen == ScreenId.merchantOnboarding ||
                currentScreen == ScreenId.merchantSubcategorySelection ||
                currentScreen == ScreenId.merchantBenefits ||
                currentScreen == ScreenId.merchantStorefront ||
                currentScreen == ScreenId.merchantRappels ||
                currentScreen == ScreenId.merchantPromotions ||
                currentScreen == ScreenId.merchantNotificationsAuto ||
                currentScreen == ScreenId.merchantProfile ||
                currentScreen == ScreenId.merchantEFidelite ||
                currentScreen == ScreenId.merchantAccountPreferences ||
                currentScreen == ScreenId.merchantClients ||
                currentScreen == ScreenId.clientProfile ||
                currentScreen == ScreenId.clientHome ||
                currentScreen == ScreenId.discovery ||
                currentScreen == ScreenId.qrScanner ||
                currentScreen == ScreenId.storeProfile ||
                currentScreen == ScreenId.notifications ||
                currentScreen == ScreenId.loyalty;

            // No bottom padding here – same as profile. Each screen adds its own scroll padding
            // so content stays above the nav. Avoids the visible square/band at the bottom.
            final content = body;

            return Stack(
              children: [
                if (topInset > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topInset,
                    child: Container(color: statusBarColor),
                  ),
                screenHandlesSafeArea
                    ? content
                    : SafeArea(
                        bottom: false,
                        child: content,
                      ),
              ],
            );
          },
        ),
          bottomNavigationBar: _showBottomNav && _role != null
              ? YBottomNav(
                  role: _role!,
                  activeTab: _activeTab,
                  onTabChange: _handleTabChange,
                )
              : null,
        ),
      ),
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
            ref.read(roleCacheServiceProvider).saveLastSelectedRole(role);
          },
          onLogin: (UserRole role) {
            // Navigate directly to login screen (for "Se connecter" button)
            setState(() {
              _role = role;
              _authScreen = ScreenId.login;
            });
            ref.read(roleCacheServiceProvider).saveLastSelectedRole(role);
          },
        );
      case ScreenId.merchantOnboarding:
        return MerchantOnboardingScreen(
          onBack: () => setState(() => _authScreen = ScreenId.roleSelection),
          onNext: () => setState(() => _authScreen = ScreenId.merchantSubcategorySelection),
        );
      case ScreenId.merchantSubcategorySelection:
        return SubcategorySelectionScreen(
          onBack: () => setState(() => _authScreen = ScreenId.merchantOnboarding),
          onNext: () => setState(() => _authScreen = ScreenId.merchantBenefits),
        );
      case ScreenId.merchantBenefits:
        return MerchantBenefitsScreen(
          onBack: () => setState(() => _authScreen = ScreenId.merchantSubcategorySelection),
          onNext: () {
            setState(() {
              _role = UserRole.merchant;
              _authScreen = ScreenId.signup;
            });
            ref.read(roleCacheServiceProvider).saveLastSelectedRole(UserRole.merchant);
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
        return ClientHomeScreen(
          onNavigate: _handleNavigate,
          onStoreSelect: (merchantId) {
            ref.read(store_profile_providers.selectedStoreMerchantIdProvider.notifier).state = merchantId;
            setState(() {
              _previousNestedScreen = null;
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.discovery:
        return DiscoveryScreen(
          onBack: _handleBackFromDiscovery,
          onNotifications: _openNotificationsScreen,
          onStoreSelect: (merchantId) {
            ref.read(store_profile_providers.selectedStoreMerchantIdProvider.notifier).state = merchantId;
            setState(() {
              _previousNestedScreen = null;
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.qrScanner:
        return QRScannerScreen(
          onBack: _handleBackToBase,
          onVitrineMerchantFound: (merchantId) {
            ref.read(store_profile_providers.selectedStoreMerchantIdProvider.notifier).state =
                merchantId;
            setState(() {
              _previousNestedScreen = null;
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.loyalty:
        return LoyaltyCardsScreen(
          onBack: _handleBackToBase,
          onNotifications: _openNotificationsScreen,
        );
      case ScreenId.storeProfile:
        return StoreProfileScreen(
          onBack: _handleBackFromNested,
          onNotifications: _openNotificationsScreen,
          onMessage: () => setState(() => _nestedScreen = ScreenId.messages),
          onReserve: _handleBackToBase,
        );
      case ScreenId.notifications:
        return NotificationsScreen(onBack: _handleBackFromNested);
      case ScreenId.messages:
        return MessagesScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToBase,
          onConversationSelect: () {},
        );
      case ScreenId.clientProfile:
        return const ClientProfileScreen();
      case ScreenId.merchantDashboard:
        return MerchantDashboardScreen(onNavigate: _handleNavigate);
      case ScreenId.merchantClients:
        return ClientListScreen(
          onBack: _handleBackToBase,
          onClientSelect: () {},
        );
      case ScreenId.merchantPromotions:
        return PromotionsManagementScreen(
          onNavigate: _handleNavigate,
          onBack: _handleBackToBase,
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
        return MerchantSettingsScreen(
          onNavigate: _handleNavigate,
        );
      case ScreenId.merchantEFidelite:
        return EFideliteScreen(
          onBack: _handleBackFromNested,
        );
      case ScreenId.merchantAccountPreferences:
        return AccountPreferencesScreen(
          onBack: _handleBackFromNested,
        );
      case ScreenId.merchantStats:
        return MerchantStatsScreen(onBack: _handleBackToBase);
      case ScreenId.merchantStorefront:
        return const StorefrontScreen();
      case ScreenId.merchantProfileForm:
        return MerchantProfileFormScreen(
          onBack: () {
            // If user goes back, navigate to storefront (don't disconnect)
            // Storefront will show empty state if profile is incomplete
            setState(() {
              _authScreen = ScreenId.merchantStorefront;
              _activeTab = 'storefront';
            });
          },
          onComplete: () {
            // After completing profile, navigate to storefront
            setState(() {
              _authScreen = ScreenId.merchantStorefront;
              _activeTab = 'storefront';
            });
          },
        );
      case ScreenId.merchantRappels:
        return RappelsScreen(
          onNavigate: _handleNavigate,
        );
      case ScreenId.merchantNotificationsAuto:
        return NotificationsAutoScreen(
          onBack: _handleBackFromNested,
        );
    }
  }
}
