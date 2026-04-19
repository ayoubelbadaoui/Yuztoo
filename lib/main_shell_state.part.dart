part of 'main.dart';

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
  ProviderSubscription<AuthState>? _authStateSub;
  // Main navigation screen from provider (auth flow)
  ScreenId? _authScreen; // null = loading
  // Within-app navigation (discovery, messages, etc.) - manual state
  ScreenId? _nestedScreen; // null = use _authScreen
  ScreenId?
      _previousNestedScreen; // remembers previous nested screen before notifications
  UserRole? _role; // For bottom nav and role-based navigation
  String _activeTab = 'home';
  // Signup/OTP flow data
  String? _signupUserId;
  String? _phoneNumber;
  String? _verificationId;
  String? _signupEmail;
  String? _signupPassword;
  String? _otpUnavailableMessage;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSubscription;
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<String?>? _notifTapSub;

  /// Vitrine deep link received before auth / main shell is ready (cold start or login).
  String? _pendingVitrineMerchantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(WakelockPlus.enable());

    // Request all runtime permissions on every app start — before auth state
    // resolves. This ensures even users who never log out see the dialogs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_requestRuntimePermissions());
    });

    // Attach overlay after the first frame so Overlay.of(context) is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.instance.attachOverlay(Overlay.of(context));
      }
    });

    // Show banner for foreground FCM messages.
    _fcmForegroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground message: ${message.notification?.title}');
      unawaited(NotificationService.instance.showFromRemoteMessage(message));
    });

    // Open notifications screen when user taps a banner while app is open.
    _notifTapSub = NotificationService.instance.onNotificationTap.listen((_) {
      if (mounted) _openNotificationsScreen();
    });

    // Open notifications screen when user taps a push while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (mounted) _openNotificationsScreen();
    });

    // Handle notification tap from a terminated (killed) app.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && mounted) _openNotificationsScreen();
    });

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-attach overlay each time context changes (first frame + any context rebuild).
    NotificationService.instance.attachOverlay(Overlay.of(context));
  }

  /// Requests notification permission + battery optimisation exemption on
  /// every cold-start, regardless of auth state.
  /// Safe to call repeatedly — Android shows the dialog only when needed.
  Future<void> _requestRuntimePermissions() async {
    try {
      // 1. Notification permission (Android 13+ / iOS).
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      // 2. Battery optimisation exemption — prevents Samsung/Xiaomi/OPPO from
      //    killing FCM in background. Shows a one-time system dialog.
      const channel = MethodChannel('com.yuztoo.synerteam/battery');
      final isExempt =
          await channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
              false;
      if (!isExempt) {
        await channel.invokeMethod('requestIgnoreBatteryOptimizations');
      }
    } on MissingPluginException {
      // Not on Android — no-op.
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(WakelockPlus.disable());
    _fcmForegroundSub?.cancel();
    _notifTapSub?.cancel();
    NotificationService.instance.dispose();
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
      ScreenId.clientOnboarding,
      ScreenId.merchantOnboarding,
      ScreenId.merchantSubcategorySelection,
      ScreenId.merchantBenefits,
      ScreenId.merchantProfileForm,
    };
    return !defer.contains(screen);
  }

  void _openVitrineForMerchant(String merchantId) {
    if (!mounted) return;
    ref
        .read(store_profile_providers.selectedStoreMerchantIdProvider.notifier)
        .state = merchantId;
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
      // Refetch vitrine when returning to the app on the merchant storefront;
      // cached Riverpod/Firestore snapshots can otherwise show an outdated page.
      final currentScreen = _nestedScreen ?? _authScreen;
      if (_role == UserRole.merchant &&
          currentScreen == ScreenId.merchantStorefront) {
        ref.invalidate(storefront_providers.storefrontProvider);
      }
    } else {
      unawaited(WakelockPlus.disable());
    }
  }

  bool _hasReceivedFirstAuthState = false;
  bool _isNavigatingToHome = false; // Track when we're navigating to home
  String? _lastAuthenticatedUserId; // Held for FCM token cleanup on sign-out.

  /// Clears transient signup/onboarding draft data to avoid leaking values
  /// between different accounts after logout.
  Future<void> _clearAuthTransientDrafts() async {
    try {
      await ref
          .read(merchant_providers.merchantProfileCacheServiceProvider)
          .clear();
    } catch (_) {}
    try {
      ref
          .read(merchant_onboarding_providers.onboardingFlowProvider.notifier)
          .reset();
    } catch (_) {}
    _signupUserId = null;
    _phoneNumber = null;
    _verificationId = null;
    _signupEmail = null;
    _signupPassword = null;
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
        // Clear FCM token so this device stops receiving pushes for the old user.
        final prevUserId = _lastAuthenticatedUserId;
        if (prevUserId != null) {
          _lastAuthenticatedUserId = null;
          unawaited(
            (() async {
              try {
                await ref.read(fcmTokenServiceProvider).clearToken(prevUserId);
              } catch (_) {}
            })(),
          );
        }
        unawaited(_clearAuthTransientDrafts());
        // While splash + post-signup routing is in progress, do not clear the flag:
        // a brief Unauthenticated tick would otherwise send the user to role selection
        // instead of client onboarding.
        if (!(_authScreen == ScreenId.splash && _isNavigatingToHome)) {
          _isNavigatingToHome = false;
        }

        // On first auth state, if unauthenticated, go to role selection
        // But if we're already on a home screen (shouldn't happen, but safety check), don't navigate
        // IMPORTANT: If we're navigating to home (just logged in), don't navigate away
        // This prevents race conditions where userChanges() emits null briefly
        final onHomeScreen = _authScreen == ScreenId.clientHome ||
            _authScreen == ScreenId.merchantStorefront;
        final inAuthFlow = _authScreen == ScreenId.login ||
            _authScreen == ScreenId.signup ||
            _authScreen == ScreenId.otp ||
            (_authScreen == ScreenId.splash && _isNavigatingToHome);

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
        _lastAuthenticatedUserId = authState.user.id;
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

    // Register FCM token for this device so push notifications work.
    unawaited(
      (() async {
        try {
          final fcmService = ref.read(fcmTokenServiceProvider);
          await fcmService.registerToken(user.id);
        } catch (_) {}
      })(),
    );

    // Best-effort legacy cleanup for user schema drift (e.g. dotted role keys).
    // Never await this before routing: Firestore get/update can stall with no timeout
    // and leaves new users (especially client signup) stuck on splash forever.
    unawaited(
      (() async {
        try {
          final patchUserDoc = ref.read(patchUserDocumentProvider);
          await patchUserDoc
              .call(user.id)
              .timeout(const Duration(seconds: 10));
        } catch (_) {}
      })(),
    );

    // Flag is already set in _handleAuthStateChange, but ensure we're still on splash
    if (_authScreen != ScreenId.splash && mounted) {
      setState(() => _authScreen = ScreenId.splash);
    }

    try {
      // Firestore-driven routing: role and onboarding are resolved from users/{uid}.
      final getUserRole = ref.read(getUserRoleProvider);
      UserRole? role;

      // Retry a few times to absorb eventual consistency right after signup/profile writes.
      for (int attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
        final roleResult =
            await getUserRole.call(user.id).timeout(const Duration(seconds: 5));
        role = roleResult.fold((_) => null, (r) => r);
        if (role != null) break;
      }

      // If Firestore role is unreadable (e.g., rules lag), fall back to cached
      // role so signup/login can proceed without bouncing back to auth screens.
      if (role == null) {
        try {
          role = await ref.read(roleCacheServiceProvider).readLastSelectedRole();
        } catch (_) {}
        role ??= _role;
      }

      // If no fallback role exists (first app open + fresh install), wait only
      // briefly for users/{uid} to appear after signup. Long waits keep users
      // stuck on splash when Firestore rules deny reads.
      if (role == null && mounted) {
        const maxExtraWaitMs = 3000;
        const stepMs = 500;
        var elapsed = 0;
        while (role == null && elapsed < maxExtraWaitMs && mounted) {
          await Future.delayed(const Duration(milliseconds: stepMs));
          elapsed += stepMs;
          final roleResult = await getUserRole
              .call(user.id)
              .timeout(const Duration(seconds: 5));
          role = roleResult.fold((_) => null, (r) => r);
        }
      }

      // If we still have no role after cache fallback, deny session.
      if (role == null) {
        await ref.read(signOutProvider).call();
        if (!mounted) return;
        setState(() {
          _authScreen = ScreenId.roleSelection;
          _nestedScreen = null;
          _role = null;
          _isNavigatingToHome = false;
        });
        return;
      }

      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }

      // Determine target screen based strictly on Firestore role + onboarding.
      ScreenId targetScreen;
      if (role == UserRole.client) {
        final clientOnboardingDone =
            await clientOnboardingCompletedFromFirestore(
          ref.read(userRepositoryProvider),
          user.id,
        );
        targetScreen = clientOnboardingDone
            ? ScreenId.clientHome
            : ScreenId.clientOnboarding;
      } else {
        // Merchant gate: no dashboard access until onboarding is completed.
        final onboardingCompleted =
            await merchantOnboardingCompletedFromFirestore(
          ref.read(userRepositoryProvider),
          user.id,
        );
        targetScreen = onboardingCompleted
            ? ScreenId.merchantStorefront
            : ScreenId.merchantProfileForm;
      }

      // Now navigate to home screen (we were on splash, so this is safe)
      if (mounted) {
        setState(() {
          _authScreen = targetScreen;
          _role = role;
          _activeTab = role == UserRole.client ? 'home' : 'storefront';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryConsumePendingVitrineLink();
        });
        // UI updates handled by setState above
      }
    } catch (_) {
      // Fail closed: keep access guarded when profile routing cannot be resolved.
      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }

      try {
        await ref.read(signOutProvider).call();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _role = null;
          _authScreen = ScreenId.roleSelection;
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
      }
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
      _authScreen = role == UserRole.merchant
          ? ScreenId.merchantOnboarding
          : ScreenId.login;
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
      'messages': _role == UserRole.client
          ? ScreenId.messages
          : ScreenId.merchantMessages,
      'profile': _role == UserRole.client
          ? ScreenId.clientProfile
          : ScreenId.merchantProfile,
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

    // Always refetch vitrine when merchant opens the storefront tab (Riverpod +
    // Firestore cache can otherwise show an outdated snapshot).
    if (_role == UserRole.merchant && tab == 'storefront') {
      ref.invalidate(storefront_providers.storefrontProvider);
    }

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
        final target =
            map[tab] ?? ScreenId.merchantStorefront; // Default to storefront
        // If it's a main tab screen, update auth screen; otherwise nested
        if (target == ScreenId.merchantClients ||
            target == ScreenId.merchantRappels ||
            target == ScreenId.merchantPromotions ||
            target == ScreenId.merchantProfile ||
            target == ScreenId.merchantStorefront) {
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
    if (currentScreen == ScreenId.merchantSubcategorySelection) {
      setState(() => _authScreen = ScreenId.merchantOnboarding);
      return;
    }
    if (currentScreen == ScreenId.merchantBenefits) {
      setState(() => _authScreen = ScreenId.merchantSubcategorySelection);
      return;
    }
    if (currentScreen == ScreenId.merchantProfileForm) {
      // Merchant onboarding is mandatory: do not allow back-navigation bypass.
      return;
    }
    if (currentScreen == ScreenId.clientOnboarding) {
      // Client profile onboarding is mandatory until completed.
      return;
    }

    // 3) Merchant tab screens – go back to vitrine root unless already there.
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
    final currentScreen =
        _nestedScreen ?? _authScreen ?? ScreenId.roleSelection;

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
    const authBgDark =
        Color(0xFF0E2A44); // MerchantColors.bgMain – auth + discover pages
    final isAuthDarkScreen = currentScreen == ScreenId.splash ||
        currentScreen == ScreenId.roleSelection ||
        currentScreen == ScreenId.login ||
        currentScreen == ScreenId.signup ||
        currentScreen == ScreenId.otp ||
        currentScreen == ScreenId.clientOnboarding ||
        currentScreen == ScreenId.merchantProfileForm ||
        currentScreen == ScreenId.merchantOnboarding ||
        currentScreen == ScreenId.merchantSubcategorySelection ||
        currentScreen == ScreenId.merchantBenefits;

    // Screens whose topmost section/header is the app primary color (dark),
    // so the status bar should match that header for a seamless look.
    final hasPrimaryHeaderTop = currentScreen == ScreenId.clientHome ||
        currentScreen == ScreenId.clientProfile ||
        currentScreen == ScreenId.qrScanner ||
        currentScreen == ScreenId.loyalty;

    final isRappels = currentScreen == ScreenId.merchantRappels;
    final isPromotions = currentScreen == ScreenId.merchantPromotions;
    final isNotificationsAuto =
        currentScreen == ScreenId.merchantNotificationsAuto;
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
    final isDarkMerchantScreen = isRappels ||
        isPromotions ||
        isNotificationsAuto ||
        isMerchantProfile ||
        isEFidelite ||
        isAccountPrefs ||
        isMerchantClients;
    final isClientDarkScreen = isClientProfile ||
        isClientHome ||
        isDiscovery ||
        isQrScanner ||
        isStoreProfile ||
        isNotifications ||
        currentScreen == ScreenId.loyalty;
    final scaffoldBgColor = isStorefront
        ? const Color(0xFFFDFBF7) // Storefront background color
        : isDarkMerchantScreen
            ? const Color(0xFF0E2A44) // MerchantColors.bgMain
            : isClientDarkScreen
                ? const Color(
                    0xFF0E2A44) // MerchantColors.bgMain – client home, profile, discovery
                : (isAuthDarkScreen ? authBgDark : Colors.white);

    // Default rule: system bars follow the current background (and bottom nav if present).
    // IMPORTANT: Use AnnotatedRegion (not SystemChrome.setSystemUIOverlayStyle in build),
    // so screens that provide their own overlay style (e.g. OTP/Login dark screens)
    // are not overridden.
    final statusBarColor = isNotifications
        ? const Color(
            0xFF0B1F33) // MerchantColors.bgHeader (match notifications header)
        : isAuthDarkScreen
            ? authBgDark
            : (isStorefront
                ? scaffoldBgColor
                : (hasPrimaryHeaderTop || isDiscovery || isStoreProfile
                    ? YColors.primary
                    : scaffoldBgColor));
    final systemNavBarColor = (_showBottomNav && _role == UserRole.merchant)
        ? const Color(0xFF0B1F33) // MerchantColors.bgHeader
        : (_showBottomNav && _role == UserRole.client)
            ? const Color(
                0xFF0B1F33) // same dark nav for client (no white square)
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
              final screenHandlesSafeArea =
                  currentScreen == ScreenId.roleSelection ||
                      currentScreen == ScreenId.login ||
                      currentScreen == ScreenId.signup ||
                      currentScreen == ScreenId.otp ||
                      currentScreen == ScreenId.clientOnboarding ||
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
    final currentScreen =
        _nestedScreen ?? _authScreen ?? ScreenId.roleSelection;

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
          onSignup: (UserRole role) {
            // Navigate directly to signup screen from role selection.
            setState(() {
              _role = role;
              _authScreen = ScreenId.signup;
            });
            ref.read(roleCacheServiceProvider).saveLastSelectedRole(role);
          },
        );
      case ScreenId.merchantOnboarding:
        return MerchantOnboardingScreen(
          onBack: () => setState(() => _authScreen = ScreenId.roleSelection),
          onNext: () =>
              setState(() => _authScreen = ScreenId.merchantSubcategorySelection),
        );
      case ScreenId.merchantSubcategorySelection:
        return SubcategorySelectionScreen(
          onBack: () =>
              setState(() => _authScreen = ScreenId.merchantOnboarding),
          onNext: () =>
              setState(() => _authScreen = ScreenId.merchantBenefits),
        );
      case ScreenId.merchantBenefits:
        return MerchantBenefitsScreen(
          onBack: () =>
              setState(() => _authScreen = ScreenId.merchantSubcategorySelection),
          onNext: () {
            setState(() {
              _role = UserRole.merchant;
              _authScreen = ScreenId.signup;
            });
            ref
                .read(roleCacheServiceProvider)
                .saveLastSelectedRole(UserRole.merchant);
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
          onNavigateToOtp: (data) {
            setState(() {
              _verificationId = data.verificationId;
              _signupEmail = data.email;
              _signupPassword = data.password;
              _phoneNumber = data.phone;
              _authScreen = ScreenId.otp;
            });
          },
        );
      case ScreenId.otp:
        return OTPScreen(
          onBack: _handleBackToLogin,
          userId: _signupUserId ?? '',
          phone: _phoneNumber ?? '+33 XXX XXX XXX',
          verificationId: _verificationId,
          email: _signupEmail ?? '',
          password: _signupPassword ?? '',
          role: _role ?? UserRole.client,
          otpUnavailableMessage: _otpUnavailableMessage,
          onResend: () {
            // VerificationId will be updated by OTP screen if resend succeeds
            // This callback can be used for any additional logic if needed
          },
        );
      case ScreenId.clientOnboarding:
        return ClientOnboardingScreen(
          onComplete: () {
            setState(() {
              _authScreen = ScreenId.clientHome;
              _activeTab = 'home';
            });
          },
        );
      case ScreenId.clientHome:
        return ClientHomeScreen(
          onNavigate: _handleNavigate,
          onStoreSelect: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
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
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
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
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
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
          onBack: () {},
          onComplete: () {
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
