part of 'main.dart';

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
  ProviderSubscription<AuthState>? _authStateSub;
  // Main navigation screen from provider (auth flow)
  ScreenId? _authScreen; // null = loading
  // Within-app navigation (discovery, messages, etc.) - manual state
  ScreenId? _nestedScreen; // null = use _authScreen
  UserRole? _role; // For bottom nav and role-based navigation
  bool _isDualProfile = false; // true when user has both client + merchant roles
  // Guard: prevents double-tap from launching two concurrent merchant switches.
  bool _isSwitchingToMerchant = false;
  bool _isSwitchingToClient = false;
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
  StreamSubscription<RemoteMessage>? _fcmOpenedAppSub;
  StreamSubscription<Map<String, dynamic>?>? _notifTapSub;
  StreamSubscription<BleClientDetection>? _bleDetectionSub;

  /// Vitrine deep link received before auth / main shell is ready (cold start or login).
  String? _pendingVitrineMerchantId;

  /// FCM message received via getInitialMessage() before the auth state resolved.
  RemoteMessage? _pendingInitialFcmMessage;

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

    // Open correct screen when user taps the in-app overlay banner.
    _notifTapSub = NotificationService.instance.onNotificationTap.listen((data) {
      if (mounted) _handleFcmTap(data);
    });

    // Open correct screen when user taps a system push while app was in background.
    // Stored so it can be cancelled on dispose (previously leaked).
    _fcmOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (mounted) _handleFcmTap(message.data);
    });

    // Store initial message from killed state — process once shell is mounted + auth resolved.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _pendingInitialFcmMessage = message;
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
      // iOS: play sound + update badge in foreground; suppress system banner
      // since the Flutter overlay (NotificationService) handles the visual.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      // 2. Battery optimisation exemption — prevents Samsung/Xiaomi/OPPO from
      //    killing FCM in background. Shows a one-time system dialog.
      const channel = MethodChannel('com.yuztoo.app/battery');
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
    _fcmOpenedAppSub?.cancel();
    _notifTapSub?.cancel();
    NotificationService.instance.dispose();
    _appLinkSubscription?.cancel();
    _bleDetectionSub?.cancel();
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

  /// Navigates to a merchant's storefront, optionally deep-linking into a
  /// specific promotion. When [promotionId] is non-null the storefront
  /// consumes [pendingStorePromotionIdProvider] on arrival and opens the
  /// promo detail sheet — so tapping a push that says "Nouvelle promo X"
  /// lands the user on X, not on the storefront's accueil.
  void _openVitrineForMerchant(String merchantId, {String? promotionId}) {
    if (!mounted) return;
    ref
        .read(store_profile_providers.selectedStoreMerchantIdProvider.notifier)
        .state = merchantId;
    ref
        .read(store_profile_providers.pendingStorePromotionIdProvider.notifier)
        .state = (promotionId == null || promotionId.isEmpty) ? null : promotionId;
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

      // Re-register FCM token on every resume. Covers three failure modes:
      //   1. Token was rotated while the app was killed (getToken() returns new token).
      //   2. Cloud Function deleted push_tokens/device (invalid-token error).
      //   3. User granted notification permission in device Settings after denying in-app.
      _reRegisterFcmToken();
      unawaited(_startBle());
    } else {
      unawaited(WakelockPlus.disable());
      unawaited(_stopBle());
    }
  }

  void _reRegisterFcmToken() {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;
    unawaited(
      (() async {
        try {
          final fcmService = ref.read(fcmTokenServiceProvider);
          await fcmService.registerToken(authState.user.id);
        } catch (_) {}
      })(),
    );
  }

  /// Routes a notification tap to the relevant screen based on FCM data payload.
  ///
  /// Priority:
  ///  1. `type == promotion` + `merchant_id` → store vitrine
  ///  2. `type` contains `loyalty` → loyalty tab
  ///  3. Anything else → notifications tab
  void _handleFcmTap(Map<String, dynamic>? data) {
    if (!mounted) return;
    if (data == null) {
      _openNotificationsScreen();
      return;
    }

    final type = (data['type'] as String? ?? '').toLowerCase();
    final merchantId = data['merchant_id'] as String? ?? '';

    // 'promotion' is the type written by ClientNotificationDto.typeToString.
    // Previously stored as 'promotion_created' which never matched.
    if (type == 'promotion' && merchantId.isNotEmpty) {
      // Carry the promotion id through to the storefront so tapping the
      // push opens the actual promo detail instead of dumping the user
      // on the storefront's accueil to hunt for it. Field name matches
      // the CF payload (`promotion_id`).
      final promotionId = data['promotion_id'] as String? ?? '';
      _openVitrineForMerchant(
        merchantId,
        promotionId: promotionId.isEmpty ? null : promotionId,
      );
      return;
    }

    if (type.contains('loyalty')) {
      if (_role == UserRole.client) {
        // Already in client shell — open loyalty tab directly.
        setState(() {
          _activeTab = 'loyalty';
          _authScreen = ScreenId.loyalty;
          _nestedScreen = null;
        });
        return;
      }
      if (_isDualProfile) {
        // Dual-profile user currently in merchant shell: switch to client shell
        // and open the loyalty tab so the push lands on the right screen.
        final uid = ref.read(authStateProvider);
        if (uid is Authenticated) {
          ref.read(roleCacheServiceProvider).saveLastSelectedRole(
                UserRole.client,
                userId: uid.user.id,
              );
        }
        setState(() {
          _role = UserRole.client;
          _activeTab = 'loyalty';
          _authScreen = ScreenId.loyalty;
          _nestedScreen = null;
        });
        return;
      }
    }

    _openNotificationsScreen();
  }

  /// Consumes any pending initial FCM message after the shell is ready.
  void _tryConsumePendingFcmMessage() {
    final msg = _pendingInitialFcmMessage;
    if (msg == null) return;
    _pendingInitialFcmMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleFcmTap(msg.data);
    });
  }

  bool _hasReceivedFirstAuthState = false;
  bool _isNavigatingToHome = false; // Track when we're navigating to home

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
        // FCM token is cleared **before** Firebase sign-out (see [AuthController.signOut]
        // and pre-[signOutProvider] cleanup in [_handleAuthenticatedUser]).
        unawaited(_clearAuthTransientDrafts());
        // While splash + post-signup routing is in progress, do not clear the flag:
        // a brief Unauthenticated tick would otherwise send the user to role selection
        // instead of client onboarding.
        if (!(_authScreen == ScreenId.splash && _isNavigatingToHome)) {
          _isNavigatingToHome = false;
        }

        // On first auth state, if unauthenticated, go to role selection
        // IMPORTANT: If we're navigating to home (just logged in), don't navigate away
        // This prevents race conditions where userChanges() emits null briefly
        final inAuthFlow = _authScreen == ScreenId.login ||
            _authScreen == ScreenId.signup ||
            _authScreen == ScreenId.otp ||
            (_authScreen == ScreenId.splash && _isNavigatingToHome);

        // Don't navigate if we're in the middle of navigating to home (prevents logout during login)
        if (!inAuthFlow && !_isNavigatingToHome) {
          setState(() {
            // Onboarding is only after signup for merchants (see merchantProfileForm)
            _authScreen = ScreenId.roleSelection;
            _nestedScreen = null;
            _role = null;
          });
          unawaited(_stopBle());
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
        // While email OTP signup (or OAuth phone collection) is in progress the
        // Firestore document hasn't been written yet. Skip automatic navigation
        // so we don't sign the user back out before `createUserDocument` finishes.
        if (ref.read(oauthFirestoreProfilePendingProvider)) return;

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

      // No `/users/{uid}` (e.g. brand-new Google/Apple account). Never trust role
      // cache alone — that produced a ghost session. OAuth signup sets
      // [oauthFirestoreProfilePendingProvider] while collecting phone on signup.
      if (role == null) {
        var hasFirestoreProfile = false;
        for (int attempt = 0; attempt < 3; attempt++) {
          if (attempt > 0) {
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
          final basicsResult = await ref
              .read(getUserProfileBasicsProvider)
              .call(user.id)
              .timeout(const Duration(seconds: 5));
          hasFirestoreProfile =
              basicsResult.fold((_) => false, (b) => b != null);
          if (hasFirestoreProfile) break;
        }

        if (!hasFirestoreProfile &&
            ref.read(oauthFirestoreProfilePendingProvider)) {
          _isNavigatingToHome = false;
          if (mounted) {
            setState(() => _authScreen = ScreenId.signup);
          }
          return;
        }

        if (!hasFirestoreProfile) {
          ref.read(oauthFirestoreProfilePendingProvider.notifier).state = false;
          try {
            await ref.read(fcmTokenServiceProvider).clearToken(user.id);
          } catch (_) {}
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
      }

      // If Firestore role is unreadable (e.g., rules lag), fall back to cached
      // role so signup/login can proceed without bouncing back to auth screens.
      if (role == null) {
        try {
          role = await ref
              .read(roleCacheServiceProvider)
              .readLastSelectedRole(userId: user.id);
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
        try {
          await ref.read(fcmTokenServiceProvider).clearToken(user.id);
        } catch (_) {}
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

      role = await _resolveRoleForSession(user.id, role);

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
        final roles = user.roles;
        final dualFromRoles = roles != null &&
            roles['client'] == true &&
            roles['merchant'] == true;
        var dualProfile = dualFromRoles;
        if (!dualProfile && role == UserRole.client) {
          dualProfile =
              await ref.read(merchant_providers.hasLinkedMerchantAccountProvider.future);
        }
        setState(() {
          _authScreen = targetScreen;
          _role = role;
          _isDualProfile = dualProfile;
          _activeTab = role == UserRole.client ? 'home' : 'storefront';
          _nestedScreen = null;
          _isNavigatingToHome = false; // Navigation complete
        });
        unawaited(
          ref.read(roleCacheServiceProvider).saveLastSelectedRole(
                role,
                userId: user.id,
              ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryConsumePendingVitrineLink();
          _tryConsumePendingFcmMessage();
        });
        unawaited(_startBle());
      }
    } catch (_) {
      // Fail closed: keep access guarded when profile routing cannot be resolved.
      if (!mounted) {
        _isNavigatingToHome = false;
        return;
      }

      try {
        try {
          await ref.read(fcmTokenServiceProvider).clearToken(user.id);
        } catch (_) {}
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

  // ── BLE proximity ─────────────────────────────────────────────────────────

  /// Starts BLE in the mode matching the current role (client → advertise,
  /// merchant → scan). No-op when unauthenticated or role is unknown.
  Future<void> _startBle() async {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;
    final notifier = ref.read(bleProximityProvider.notifier);
    _bleDetectionSub?.cancel();
    _bleDetectionSub = null;
    if (_role == UserRole.client) {
      await notifier.startAsClient(authState.user.id);
    } else if (_role == UserRole.merchant) {
      _bleDetectionSub = notifier.detections.listen(_onClientDetected);
      await notifier.startAsMerchant();
    }
  }

  /// Stops all BLE activity and cancels the detection subscription.
  Future<void> _stopBle() async {
    _bleDetectionSub?.cancel();
    _bleDetectionSub = null;
    await ref.read(bleProximityProvider.notifier).stop();
  }

  /// Called when a client is detected nearby. Shows the confirmation sheet on
  /// top of whatever screen the merchant is currently viewing.
  void _onClientDetected(BleClientDetection detection) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BleClientDetectionSheet(
        detection: detection,
        onDismiss: () {},
      ),
    ).then((_) {
      if (mounted) {
        ref.read(bleProximityProvider.notifier).resetAfterDetection();
      }
    });
  }

  // ── Dual-profile role switching ────────────────────────────────────────────

  /// Merchant taps "switch to client" — confirm, then onboarding only if profile gaps remain.
  Future<void> _switchToClient() async {
    if (_isSwitchingToClient) return;
    _isSwitchingToClient = true;
    try {
      final authState = ref.read(authStateProvider);
      if (authState is! Authenticated) return;
      final uid = authState.user.id;
      final repo = ref.read(userRepositoryProvider);

      final readinessResult = await repo.getClientProfileReadiness(uid);
      if (!mounted) return;
      final ClientProfileReadiness? readiness = readinessResult.fold(
        (_) => null,
        (ClientProfileReadiness r) => r,
      );
      if (readiness == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de vérifier votre profil client. Réessayez.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (readiness.canEnterClientHomeDirectly) {
        await _applyClientModeNavigation(uid);
        return;
      }

      final confirmed = await _confirmCreateClientAccount(readiness);
      if (!mounted || confirmed != true) return;

      if (!readiness.hasClientRole) {
        final roleResult = await repo.addSecondaryClientRole(uid);
        if (!mounted) return;
        final roleFailed = roleResult.fold((_) => true, (_) => false);
        if (roleFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de créer le compte client. Réessayez.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (readiness.isProfileDataComplete) {
        final authStateNow = ref.read(authStateProvider);
        final displayName = buildClientDisplayName(
          firstName: readiness.firstName,
          lastName: readiness.lastName,
          fallbackDisplayName: authStateNow is Authenticated
              ? authStateNow.user.displayName
              : null,
        );
        final completeResult = await repo.completeClientProfile(
          uid: uid,
          displayName: displayName.isNotEmpty ? displayName : 'Client',
          firstName: readiness.firstName,
          lastName: readiness.lastName,
          dateOfBirth: readiness.dateOfBirth,
          city: readiness.city,
          photoUrl: readiness.photoUrl,
        );
        if (!mounted) return;
        if (completeResult.isLeft) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de finaliser le profil client. Réessayez.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        await _applyClientModeNavigation(uid);
        return;
      }

      if (!mounted) return;
      ref.read(roleCacheServiceProvider).saveLastSelectedRole(
            UserRole.client,
            userId: uid,
          );
      setState(() {
        _role = UserRole.client;
        _isDualProfile = true;
        _authScreen = ScreenId.clientOnboarding;
        _activeTab = 'home';
        _nestedScreen = null;
      });
      unawaited(_startBle());
    } finally {
      _isSwitchingToClient = false;
    }
  }

  Future<void> _applyClientModeNavigation(String uid) async {
    ref.read(roleCacheServiceProvider).saveLastSelectedRole(
          UserRole.client,
          userId: uid,
        );
    if (!mounted) return;
    setState(() {
      _role = UserRole.client;
      _isDualProfile = true;
      _authScreen = ScreenId.clientHome;
      _activeTab = 'home';
      _nestedScreen = null;
    });
    unawaited(_startBle());
  }

  /// Returns `true` when the user confirms creating a client account.
  Future<bool?> _confirmCreateClientAccount(ClientProfileReadiness readiness) {
    final missing = readiness.missingFieldsLabelFr;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: const Text(
          'Créer un compte client ?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          missing.isEmpty
              ? 'Voulez-vous utiliser Yuztoo aussi en tant que client ? '
                  'Vous pourrez suivre vos commerces favoris et profiter de la fidélité.'
              : 'Voulez-vous créer votre compte client ?\n\n'
                  'Il nous manque encore : $missing.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.45,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0E2A44),
            ),
            child: const Text(
              'Créer mon compte client',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Client taps "switch to merchant" / "Créer un compte pro". If this is the
  /// first time (no merchant profile yet), adds the merchant role in Firestore
  /// and routes to merchant onboarding. Otherwise goes straight to the storefront.
  Future<void> _switchToMerchant() async {
    // Prevent concurrent calls from double-taps.
    if (_isSwitchingToMerchant) return;
    _isSwitchingToMerchant = true;
    try {
      final authState = ref.read(authStateProvider);
      if (authState is! Authenticated) return;
      final uid = authState.user.id;
      final repo = ref.read(userRepositoryProvider);

      final completedResult = await repo.isMerchantOnboardingCompleted(uid);
      final completed = completedResult.fold((_) => null, (v) => v);

      if (completed == true) {
        // Already has a merchant profile — switch immediately.
        ref.read(roleCacheServiceProvider).saveLastSelectedRole(
              UserRole.merchant,
              userId: uid,
            );
        if (!mounted) return;
        setState(() {
          _role = UserRole.merchant;
          _isDualProfile = true;
          _authScreen = ScreenId.merchantStorefront;
          _activeTab = 'storefront';
          _nestedScreen = null;
        });
        unawaited(_startBle());
      } else {
        // First time — register the merchant role in Firestore, then onboard.
        final roleResult = await repo.addSecondaryMerchantRole(uid);
        if (!mounted) return;
        final roleFailed = roleResult.fold((_) => true, (_) => false);
        if (roleFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Impossible de créer le profil pro. Réessayez.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        ref.read(roleCacheServiceProvider).saveLastSelectedRole(
              UserRole.merchant,
              userId: uid,
            );
        setState(() {
          _role = UserRole.merchant;
          _isDualProfile = true;
          _authScreen = ScreenId.merchantOnboarding;
          _activeTab = 'storefront';
          _nestedScreen = null;
        });
        unawaited(_startBle());
      }
    } finally {
      _isSwitchingToMerchant = false;
    }
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
      'security': ScreenId.merchantSecurity,
      'data-privacy': ScreenId.merchantDataPrivacy,
      'pro-profile': ScreenId.merchantProfileSummary,
      'merchant-identity-edit': ScreenId.merchantIdentityEdit,
      'partners': ScreenId.merchantPartners,
      'notifications-hub': ScreenId.merchantNotificationsHub,
      'scheduled-notifications': ScreenId.merchantScheduledNotifications,
      'gratification-config': ScreenId.merchantGratificationConfig,
    };

    final target = map[screen];
    if (target != null) {
      setState(() {
        if (_role == UserRole.client && target == ScreenId.notifications) {
          _activeTab = 'notifications';
          _authScreen = ScreenId.notifications;
          _nestedScreen = null;
        } else {
          _nestedScreen = target;
        }
      });
    } else if (screen == 'storefront') {
      setState(() {
        _activeTab = 'storefront';
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
      });
      ref.invalidate(storefront_providers.storefrontProvider);
    } else if (screen == 'switch-to-client') {
      unawaited(_switchToClient());
    } else if (screen == 'switch-to-merchant') {
      unawaited(_switchToMerchant());
    } else if (screen == 'storefront-edit-profile') {
      final storefront =
          ref.read(storefront_providers.storefrontProvider).valueOrNull;
      if (storefront != null) {
        unawaited(
          ref
              .read(storefrontProfileEditProvider.notifier)
              .initializeFrom(storefront),
        );
      }
      setState(() => _nestedScreen = ScreenId.merchantStorefrontEditProfile);
    } else if (screen == 'store-preview') {
      // Preview merchant's own storefront as a client would see it
      final merchantId = ref
          .read(merchant_providers.currentMerchantForOwnerProvider)
          .valueOrNull
          ?.id ?? '';
      if (merchantId.isNotEmpty) {
        ref
            .read(store_profile_providers.selectedStoreMerchantIdProvider.notifier)
            .state = merchantId;
        setState(() => _nestedScreen = ScreenId.storeProfile);
      }
    }
  }

  /// Restores client vs merchant shell from local session when the account
  /// can use both (dual profile or merchant doc + client role).
  Future<UserRole> _resolveRoleForSession(
    String userId,
    UserRole firestoreRole,
  ) async {
    final rolesResult = await ref.read(getUserRolesProvider).call(userId);
    final rolesMap = rolesResult.fold((_) => null, (m) => m);

    final canClient = rolesMap?['client'] == true ||
        firestoreRole == UserRole.client;
    var canMerchant = rolesMap?['merchant'] == true ||
        firestoreRole == UserRole.merchant;
    if (!canMerchant) {
      try {
        canMerchant = await ref
            .read(merchant_providers.hasLinkedMerchantAccountProvider.future);
      } catch (_) {
        canMerchant = false;
      }
    }

    if (!canClient || !canMerchant) {
      return firestoreRole;
    }

    try {
      final last = await ref
          .read(roleCacheServiceProvider)
          .readLastSelectedRole(userId: userId);
      if (last == UserRole.client && canClient) return UserRole.client;
      if (last == UserRole.merchant && canMerchant) return UserRole.merchant;
    } catch (_) {}

    return firestoreRole;
  }

  void _persistSessionRole() {
    final authState = ref.read(authStateProvider);
    final role = _role;
    if (authState is! Authenticated || role == null) return;
    unawaited(
      ref.read(roleCacheServiceProvider).saveLastSelectedRole(
            role,
            userId: authState.user.id,
          ),
    );
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
        
        return;
      }
      if (_role == UserRole.client) {
        final map = <String, ScreenId>{
          'home': ScreenId.clientHome,
          'discovery': ScreenId.discovery,
          'notifications': ScreenId.notifications,
          'loyalty': ScreenId.loyalty,
          'profile': ScreenId.clientProfile,
        };
        final target = map[tab] ?? ScreenId.clientHome;
        // All client tabs are top-level: set auth screen and clear nested
        _authScreen = target;
        _nestedScreen = null;
        
      } else {
        final map = <String, ScreenId>{
          'communaute': ScreenId.merchantClients,
          'rappels': ScreenId.merchantRappels,
          'storefront': ScreenId.merchantStorefront,
          'promotions': ScreenId.merchantPromotions,
          'profile': ScreenId.merchantProfile,
        };
        final target =
            map[tab] ?? ScreenId.merchantStorefront;
        if (target == ScreenId.merchantClients ||
            target == ScreenId.merchantNotificationsHub ||
            target == ScreenId.merchantRappels ||
            target == ScreenId.merchantPromotions ||
            target == ScreenId.merchantProfile ||
            target == ScreenId.merchantStorefront) {
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
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
        
        _activeTab = 'storefront';
      });
    }
    _persistSessionRole();
  }

  void _openNotificationsScreen() {
    // Notifications is a first-class tab for clients – navigate to it as a tab.
    setState(() {
      _authScreen = ScreenId.notifications;
      _activeTab = 'notifications';
      _nestedScreen = null;
      
    });
    _persistSessionRole();
  }

  /// Go back from a nested screen to its parent (the current _authScreen).
  /// Unlike _handleBackToBase, this does NOT reset to the root home/storefront.
  void _handleBackFromNested() {
    if (_nestedScreen != null) {
      setState(() {
        _nestedScreen = null;
        
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
      // Reset role on back so the unauthenticated user cannot accidentally reach
      // authenticated screens via the generic merchant-back-to-storefront handler.
      setState(() {
        _authScreen = ScreenId.roleSelection;
        _role = null;
      });
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
    // Role selection is the unauthenticated entry point – never go further back.
    if (currentScreen == ScreenId.roleSelection) return;

    // 3) Merchant tab screens – go back to vitrine root unless already there.
    // Guard: only authenticated merchants may reach the storefront this way.
    final isAuthenticated = ref.read(authControllerProvider) is Authenticated;
    if (isAuthenticated &&
        _role == UserRole.merchant &&
        currentScreen != ScreenId.merchantStorefront) {
      setState(() {
        _authScreen = ScreenId.merchantStorefront;
        _nestedScreen = null;
        _activeTab = 'storefront';
      });
      return;
    }

    // 4) Client tab screens – go back to home unless already there.
    if (isAuthenticated &&
        _role == UserRole.client &&
        currentScreen != ScreenId.clientHome) {
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
      ScreenId.notifications,
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

    final isRappels = currentScreen == ScreenId.merchantRappels ||
        currentScreen == ScreenId.merchantNotificationsHub;
    final isPromotions = currentScreen == ScreenId.merchantPromotions;
    final isNotificationsAuto =
        currentScreen == ScreenId.merchantNotificationsAuto;
    final isMerchantProfile = currentScreen == ScreenId.merchantProfile;
    final isEFidelite = currentScreen == ScreenId.merchantEFidelite;
    final isAccountPrefs = currentScreen == ScreenId.merchantAccountPreferences ||
        currentScreen == ScreenId.merchantSecurity ||
        currentScreen == ScreenId.merchantDataPrivacy ||
        currentScreen == ScreenId.merchantProfileSummary ||
        currentScreen == ScreenId.merchantGratificationConfig;
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
    final statusBarColor = isNotifications ||
            currentScreen == ScreenId.merchantGratificationConfig
        ? const Color(
            0xFF0B1F33) // MerchantColors.bgHeader (match dark header)
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
                      currentScreen == ScreenId.merchantNotificationsHub ||
                      currentScreen == ScreenId.merchantPromotions ||
                      currentScreen == ScreenId.merchantNotificationsAuto ||
                      currentScreen == ScreenId.merchantProfile ||
                      currentScreen == ScreenId.merchantEFidelite ||
                      currentScreen == ScreenId.merchantAccountPreferences ||
                      currentScreen == ScreenId.merchantSecurity ||
                      currentScreen == ScreenId.merchantDataPrivacy ||
                      currentScreen == ScreenId.merchantProfileSummary ||
                      currentScreen == ScreenId.merchantStorefrontEditProfile ||
                      currentScreen == ScreenId.merchantPartners ||
                      currentScreen == ScreenId.merchantClients ||
                      currentScreen == ScreenId.clientProfile ||
                      currentScreen == ScreenId.clientHome ||
                      currentScreen == ScreenId.discovery ||
                      currentScreen == ScreenId.qrScanner ||
                      currentScreen == ScreenId.storeProfile ||
                      currentScreen == ScreenId.notifications ||
                      currentScreen == ScreenId.loyalty ||
                      currentScreen == ScreenId.guestShell;

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
                  notificationBadgeCount: _role == UserRole.client
                      ? ref.watch(
                          client_notification_providers
                              .unreadNotificationCountProvider,
                        )
                      : 0,
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
          onGuestDiscover: () {
            setState(() {
              _authScreen = ScreenId.guestShell;
              _nestedScreen = null;
            });
          },
          onScanQr: () {
            // Open QR scanner even without an account; back returns to role selection.
            setState(() {
              _authScreen = ScreenId.qrScanner;
              _nestedScreen = null;
            });
          },
        );
      case ScreenId.merchantOnboarding:
        return MerchantOnboardingScreen(
          onBack: () {
            if (_isDualProfile) {
              // Dual-profile user is cancelling merchant creation → return to
              // client shell cleanly rather than dropping them into role selection.
              setState(() {
                _role = UserRole.client;
                _authScreen = ScreenId.clientHome;
                _activeTab = 'home';
                _nestedScreen = null;
              });
            } else {
              setState(() => _authScreen = ScreenId.roleSelection);
            }
          },
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
            final isAuthenticated =
                ref.read(authStateProvider) is Authenticated;
            if (isAuthenticated) {
              // User is already signed in (adding a merchant profile to an
              // existing client account). Skip signup and go straight to the
              // merchant profile form which creates the merchant doc.
              setState(() => _authScreen = ScreenId.merchantProfileForm);
            } else {
              // New user arriving from the unauthenticated onboarding funnel.
              setState(() {
                _role = UserRole.merchant;
                _authScreen = ScreenId.signup;
              });
              ref
                  .read(roleCacheServiceProvider)
                  .saveLastSelectedRole(UserRole.merchant);
            }
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
          phone: _phoneNumber ?? '',
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
          isDualProfile: _isDualProfile,
          onStoreSelect: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() {
              
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.guestShell:
        return GuestShellScreen(
          onBack: () => setState(() {
            _authScreen = ScreenId.roleSelection;
            _nestedScreen = null;
          }),
          onStoreSelect: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _nestedScreen = ScreenId.storeProfile);
          },
          onSignUp: () => setState(() {
            _authScreen = ScreenId.signup;
            _nestedScreen = null;
          }),
          onSignIn: () => setState(() {
            _authScreen = ScreenId.login;
            _nestedScreen = null;
          }),
        );
      case ScreenId.discovery:
        return DiscoveryScreen(
          onBack: _handleBackFromDiscovery,
          onNotifications: _openNotificationsScreen,
          isDualProfile: _isDualProfile,
          onStoreSelect: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() {
              
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.qrScanner:
        return QRScannerScreen(
          onBack: () {
            final authState = ref.read(authControllerProvider);
            if (authState is Authenticated) {
              _handleBackToBase();
            } else {
              setState(() {
                _authScreen = ScreenId.roleSelection;
                _nestedScreen = null;
                _role = null;
              });
            }
          },
          onVitrineMerchantFound: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            ref
                .read(store_profile_providers
                    .pendingVitrineScanIntentProvider.notifier)
                .state = store_profile_providers.VitrineScanIntent.fromQrOrNfc;
            setState(() {
              _nestedScreen = ScreenId.storeProfile;
            });
          },
        );
      case ScreenId.loyalty:
        return LoyaltyCardsScreen(
          onBack: _handleBackToBase,
          onNotifications: _openNotificationsScreen,
          onSwitchToMerchant:
              _isDualProfile ? () => unawaited(_switchToMerchant()) : null,
          onStoreTap: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _nestedScreen = ScreenId.storeProfile);
          },
        );
      case ScreenId.storeProfile:
        return StoreProfileScreen(
          onBack: _handleBackFromNested,
          onNotifications: _openNotificationsScreen,
          onMessage: () => setState(() => _nestedScreen = ScreenId.messages),
          onReserve: _handleBackToBase,
          onRequestLogin: () {
            // Preserve the current merchant so that after the user logs in,
            // _tryConsumePendingVitrineLink reopens the store profile
            // automatically — no need to scan again.
            final mid = ref.read(
                store_profile_providers.selectedStoreMerchantIdProvider);
            setState(() {
              if (mid != null && mid.isNotEmpty) {
                _pendingVitrineMerchantId = mid;
              }
              _nestedScreen = null;
              _role = null;
              _authScreen = ScreenId.login;
            });
          },
        );
      case ScreenId.notifications:
        return NotificationsScreen(
          onMerchantTap: (merchantId) {
            if (merchantId.isEmpty) {
              // Empty-state "Découvrir" button
              setState(() {
                _authScreen = ScreenId.discovery;
                _activeTab = 'discovery';
                _nestedScreen = null;
              });
              return;
            }
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _nestedScreen = ScreenId.storeProfile);
          },
          onPromotionTap: (merchantId, promotionId) {
            // Set the merchant target AND the one-shot promotion deep-link
            // so the storefront opens directly into the promotion detail
            // sheet on arrival. Previously the promotionId was ignored
            // and the user was dropped on the storefront — they then had
            // to scroll to find the promotion the notification was about.
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            ref
                .read(store_profile_providers
                    .pendingStorePromotionIdProvider.notifier)
                .state = promotionId.isEmpty ? null : promotionId;
            setState(() => _nestedScreen = ScreenId.storeProfile);
          },
          // Tapping a bon_expiring / bon_expired push lands on Mes
          // avantages so the client can act on (or acknowledge) the
          // bon — same behaviour as the type=='loyalty' deep-link
          // path higher up in this file.
          onBonTap: () {
            setState(() {
              _activeTab = 'loyalty';
              _authScreen = ScreenId.loyalty;
              _nestedScreen = null;
            });
          },
        );
      case ScreenId.messages:
        return MessagesScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackToBase,
          onConversationSelect: () {},
        );
      case ScreenId.clientProfile:
        return ClientProfileScreen(
          isDualProfile: _isDualProfile,
          onCreateProAccount: () {
            // PersonalInformationScreen is pushed on the root navigator on top
            // of the shell. If we just switch state below, that pushed screen
            // stays on top and hides the new merchant onboarding screens.
            // Pop everything down to the shell's root route first.
            Navigator.of(context).popUntil((route) => route.isFirst);
            unawaited(_switchToMerchant());
          },
          onNavigate: _handleNavigate,
        );
      case ScreenId.merchantClients:
        return ClientListScreen(
          onBack: _handleBackToBase,
          onClientSelect: () {},
          isDualProfile: _isDualProfile,
          onSwitchRole: () => _handleNavigate('switch-to-client'),
          onShowQr: () => _handleNavigate('qr-code'),
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
        // The merchant "Préférences du compte pro" entry now opens the
        // personal-info edit screen directly — no intermediate landing page.
        // Editing here writes through to Firestore via
        // [updateClientBasicInfoProvider] (already wired in this screen's
        // _save method).
        //
        // A merchant on this screen sees a secondary-role CTA — the action
        // is creating a Yuztoo client carnet (so they can use the app from
        // the client side too), NOT creating a pro account they already
        // have. The previous label "Créer un compte pro" was the
        // user-reported regression.
        return PersonalInformationScreen(
          onBack: _handleBackFromNested,
          createOtherRoleLabel: 'Créer un carnet Yuztoo',
          onCreateProAccount: () => unawaited(_switchToClient()),
        );
      case ScreenId.merchantSecurity:
        return IdentificationSecurityScreen(
          onBack: _handleBackFromNested,
          onAccountDeleted: () {
            setState(() {
              _nestedScreen = null;
              _authScreen = ScreenId.login;
            });
          },
        );
      case ScreenId.merchantDataPrivacy:
        return DataPrivacyScreen(
          onBack: _handleBackFromNested,
          onAccountDeleted: () {
            setState(() {
              _nestedScreen = null;
              _authScreen = ScreenId.login;
            });
          },
        );
      case ScreenId.merchantProfileSummary:
        return MerchantProfileSummaryScreen(
          onBack: _handleBackFromNested,
          onNavigate: _handleNavigate,
        );
      case ScreenId.merchantIdentityEdit:
        return MerchantIdentityEditScreen(onBack: _handleBackFromNested);
      case ScreenId.merchantStorefrontEditProfile:
        return StorefrontEditProfileScreen(onBack: _handleBackFromNested);
      case ScreenId.merchantStats:
        return MerchantStatsScreen(onBack: _handleBackToBase);
      case ScreenId.merchantStorefront:
        return StorefrontScreen(
          onNavigate: _handleNavigate,
          isDualProfile: _isDualProfile,
        );
      case ScreenId.merchantProfileForm:
        return MerchantProfileFormScreen(
          // A dual-profile user already completed client onboarding — skip
          // the personal-info steps (owner name, DOB, logo) since that
          // data is already on the account.
          skipPersonalInfo: _isDualProfile,
          onBack: () {
            if (_isDualProfile) {
              // Dual-profile user is abandoning merchant creation →
              // return to the client shell gracefully.
              setState(() {
                _role = UserRole.client;
                _authScreen = ScreenId.clientHome;
                _activeTab = 'home';
                _nestedScreen = null;
              });
            } else {
              // New-user path: back → benefits screen.
              setState(() => _authScreen = ScreenId.merchantBenefits);
            }
          },
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
      case ScreenId.merchantNotificationsHub:
        return MerchantNotificationsHubScreen(
          onBack: _handleBackFromNested,
          onNavigate: _handleNavigate,
          isDualProfile: _isDualProfile,
        );
      case ScreenId.merchantNotificationsAuto:
        return NotificationsAutoScreen(
          onBack: _handleBackFromNested,
        );
      case ScreenId.merchantPartners:
        return MerchantPartnersScreen(
          onBack: _handleBackFromNested,
        );
      case ScreenId.merchantScheduledNotifications:
        return ScheduledNotificationsScreen(
          onBack: _handleBackFromNested,
        );
      case ScreenId.merchantGratificationConfig:
        return ClientGratificationConfigScreen(
          onBack: _handleBackFromNested,
        );
    }
  }
}
