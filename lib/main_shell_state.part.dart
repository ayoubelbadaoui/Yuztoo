part of 'main.dart';

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
  ProviderSubscription<AuthState>? _authStateSub;
  ProviderSubscription<OAuthSignupState>? _oauthSignupSub;
  // Main navigation screen from provider (auth flow)
  ScreenId? _authScreen; // null = loading
  // Within-app navigation stack layered on top of the base [_authScreen] tab.
  // Empty = only the base tab is showing. Each entry is a sub-page; the system
  // back button / iOS swipe pops ONE level so the user returns to the specific
  // previous page instead of being thrown back to the root tab.
  final List<ScreenId> _nestedStack = <ScreenId>[];

  /// Topmost nested sub-screen, or null when only the base tab shows.
  ScreenId? get _nestedScreen =>
      _nestedStack.isEmpty ? null : _nestedStack.last;
  UserRole? _role; // For bottom nav and role-based navigation
  bool _isDualProfile =
      false; // true when user has both client + merchant roles
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

  /// Tracks which screen invoked the OAuth completion flow, so a cancel
  /// from [ScreenId.oauthCompletion] returns the user to the screen
  /// they came from (login or signup) rather than always defaulting to
  /// signup. Defaults to [ScreenId.signup] because the very first OAuth
  /// flow shipped from the signup screen.
  ScreenId _oauthCompletionReturnScreen = ScreenId.signup;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSubscription;

  /// Android-only channel that delivers NFC tag taps captured natively by
  /// [MainActivity]. On Android the OS routes a Yuztoo NFC tap to the app via
  /// the NDEF_DISCOVERED intent filter (no browser / no redirect prompt); the
  /// tag's URL arrives here and is funneled through the same vitrine deep-link
  /// path as a QR scan so the passage registers automatically.
  static const MethodChannel _nfcChannel = MethodChannel('com.yuztoo.app/nfc');
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<RemoteMessage>? _fcmOpenedAppSub;
  StreamSubscription<Map<String, dynamic>?>? _notifTapSub;
  StreamSubscription<BleClientDetection>? _bleDetectionSub;
  ProviderSubscription<AsyncValue<List<ActiveValidationRequest>>>?
      _activeValidationSub;
  bool _activeValidationSheetOpen = false;
  final Set<String> _handledActiveValidationKeys = <String>{};

  /// Vitrine deep link received before auth / main shell is ready (cold start or login).
  String? _pendingVitrineMerchantId;

  /// Persisted store of [_pendingVitrineMerchantId] so the deep-link
  /// survives a cold start that interrupts onboarding (the user kills
  /// the app while signing up, the merchantId would otherwise be lost
  /// when the next launch goes through splash → onboarding without
  /// flushing the pending intent). 24h TTL keeps stale taps from
  /// hijacking a future scan.
  static const String _pendingVitrinePrefsKey =
      'yuztoo.pending_vitrine_merchant_id';
  static const String _pendingVitrineTimestampKey =
      'yuztoo.pending_vitrine_recorded_at_ms';
  static const Duration _pendingVitrineTtl = Duration(hours: 24);

  /// FCM message received via getInitialMessage() before the auth state resolved.
  RemoteMessage? _pendingInitialFcmMessage;

  /// Manual passage validation push received before merchant shell / queue ready.
  String? _pendingPassageValidationClientUid;
  String? _pendingPassageValidationMerchantId;
  bool _passageValidationPushInFlight = false;

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
    // `onError:` on every long-lived stream is non-negotiable: an unhandled
    // stream error escapes to the Zone handler and surfaces as Flutter's
    // red error screen. Logging is enough; the next message resubscribes.
    _fcmForegroundSub = FirebaseMessaging.onMessage.listen(
      (message) {
        debugPrint('[FCM] foreground message: ${message.notification?.title}');
        final type =
            (message.data['type'] ?? '').toString().trim().toLowerCase();
        if (type == 'loyalty_passage_request') {
          _handlePassageValidationPush(message.data);
        }
        unawaited(NotificationService.instance.showFromRemoteMessage(message));
      },
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'FCM foreground stream error',
          error: e,
          stackTrace: st,
        );
      },
    );

    // Open correct screen when user taps the in-app overlay banner.
    _notifTapSub = NotificationService.instance.onNotificationTap.listen(
      (data) {
        if (mounted) _handleFcmTap(data);
      },
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'In-app notification tap stream error',
          error: e,
          stackTrace: st,
        );
      },
    );

    // Open correct screen when user taps a system push while app was in background.
    // Stored so it can be cancelled on dispose (previously leaked).
    _fcmOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        if (mounted) _handleFcmTap(message.data);
      },
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'FCM opened-app stream error',
          error: e,
          stackTrace: st,
        );
      },
    );

    // Store initial message from killed state — process once shell is mounted + auth resolved.
    FirebaseMessaging.instance.getInitialMessage().then(
      (message) {
        if (message != null) _pendingInitialFcmMessage = message;
      },
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'FCM getInitialMessage failed',
          error: e,
          stackTrace: st,
        );
      },
    );

    // Initialize to splash screen immediately
    _authScreen = ScreenId.splash;
    _hasReceivedFirstAuthState = false;
    _isNavigatingToHome = false;

    // Listen immediately so we don't miss a fast first auth emission.
    //
    // We pass `previous` through to the handler so it can distinguish a
    // genuine sign-in from a same-user profile refresh — the latter must
    // NOT re-trigger the splash-and-route flow, otherwise every
    // `refreshUserProfileCache` call (which is fired after onboarding
    // completion + profile edits) dumps the user back on splash for the
    // duration of role-lookup retries.
    _authStateSub = ref.listenManual<AuthState>(
      authControllerProvider,
      (previous, next) => _handleAuthStateChange(next, previous: previous),
      fireImmediately: true,
    );

    _oauthSignupSub = ref.listenManual<OAuthSignupState>(
      signup_providers.oauthSignupControllerProvider,
      (previous, next) => _handleOAuthSignupControllerChange(next),
    );

    _appLinkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (!mounted) return;
        _onAppLinkUri(uri);
      },
      onError: (Object e, StackTrace st) {
        LoggerService.logError(
          'Deep link stream error',
          error: e,
          stackTrace: st,
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialAppLink());
    });

    _setupNfcChannel();
  }

  /// Listens for native NFC tag taps on Android and replays the URL through the
  /// vitrine deep-link funnel. No-op on other platforms (iOS reads NFC in-app
  /// via [NfcService] / Core NFC, so there is no native channel to bind to).
  void _setupNfcChannel() {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _nfcChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNfcLink') {
        final url = call.arguments;
        if (mounted && url is String && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null) _onAppLinkUri(uri);
        }
      }
      return null;
    });
    // Drain a tap that cold-launched the app before this handler was ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialNfcLink());
    });
  }

  Future<void> _consumeInitialNfcLink() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final url = await _nfcChannel.invokeMethod<String>('getInitialNfcLink');
      if (!mounted || url == null || url.isEmpty) return;
      final uri = Uri.tryParse(url);
      if (uri != null) _onAppLinkUri(uri);
    } catch (_) {
      // Channel not wired (older build) or no pending tap — safe to ignore.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-attach overlay each time context changes (first frame + any context rebuild).
    NotificationService.instance.attachOverlay(Overlay.of(context));
  }

  /// Requests notification permission on every cold-start, regardless of auth
  /// state. Safe to call repeatedly — Android shows the dialog only when needed.
  Future<void> _requestRuntimePermissions() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // iOS: play sound + update badge in foreground; suppress system banner
      // since the Flutter overlay (NotificationService) handles the visual.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
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
    _activeValidationSub?.close();
    _authStateSub?.close();
    _oauthSignupSub?.close();
    super.dispose();
  }

  Future<void> _consumeInitialAppLink() async {
    // Replay any deep-link queued before a cold restart (user killed
    // the app mid-onboarding, etc.). Does nothing when the prefs are
    // empty or expired.
    await _restorePendingVitrineMerchantIdIfFresh();

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
      unawaited(_persistPendingVitrineMerchantId(merchantId));
    }
  }

  Future<void> _persistPendingVitrineMerchantId(String merchantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingVitrinePrefsKey, merchantId);
      await prefs.setInt(
        _pendingVitrineTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Best-effort: in-memory fallback is still set, so the live session
      // path keeps working even if disk persistence fails.
    }
  }

  Future<void> _clearPersistedPendingVitrineMerchantId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingVitrinePrefsKey);
      await prefs.remove(_pendingVitrineTimestampKey);
    } catch (_) {}
  }

  Future<void> _restorePendingVitrineMerchantIdIfFresh() async {
    if (_pendingVitrineMerchantId != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_pendingVitrinePrefsKey);
      if (id == null || id.isEmpty) return;
      final ts = prefs.getInt(_pendingVitrineTimestampKey) ?? 0;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(ts));
      if (age.isNegative || age > _pendingVitrineTtl) {
        await prefs.remove(_pendingVitrinePrefsKey);
        await prefs.remove(_pendingVitrineTimestampKey);
        return;
      }
      _pendingVitrineMerchantId = id;
    } catch (_) {}
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
      ScreenId.oauthCompletion,
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
  ///
  /// Dual-profile users on the **merchant** shell are switched to the client
  /// shell first — otherwise [ScreenId.storeProfile] would render on top of
  /// merchant bottom-nav / home, which is confusing and hides the promo context.
  void _openVitrineForMerchant(String merchantId, {String? promotionId}) {
    if (!mounted) return;
    ref
        .read(store_profile_providers.selectedStoreMerchantIdProvider.notifier)
        .state = merchantId;
    ref
        .read(store_profile_providers.pendingStorePromotionIdProvider.notifier)
        .state = (promotionId == null ||
            promotionId.isEmpty)
        ? null
        : promotionId;

    final wasAlreadyClient = _role == UserRole.client;
    if (wasAlreadyClient) {
      ref
          .read(
              store_profile_providers.pendingVitrineScanIntentProvider.notifier)
          .state = store_profile_providers.VitrineScanIntent.fromQrOrNfc;
    }

    final switchToClientForVitrine =
        _role == UserRole.merchant && _isDualProfile;
    if (switchToClientForVitrine) {
      setState(() {
        _role = UserRole.client;
        _authScreen = ScreenId.clientHome;
        _activeTab = 'home';
        _nestedStack
          ..clear()
          ..add(ScreenId.storeProfile);
      });
      _persistSessionRole();
      return;
    }

    setState(() {
      _pushNestedScreen(ScreenId.storeProfile);
    });
  }

  void _tryConsumePendingVitrineLink() {
    final id = _pendingVitrineMerchantId;
    if (id == null || id.isEmpty) return;
    if (!_canApplyVitrineDeepLinkNow()) return;
    _pendingVitrineMerchantId = null;
    unawaited(_clearPersistedPendingVitrineMerchantId());
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
      unawaited(_startMerchantRealtimeServices());
    } else {
      unawaited(WakelockPlus.disable());
      unawaited(_stopBleOnly());
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

  /// Opens the client "Mes avantages" loyalty tab when the recipient should see
  /// it as a client: already in client shell, or dual-profile (switches role).
  /// Merchant-only accounts fall back to the notifications inbox — same as
  /// the FCM paths for `bon_*` and generic `loyalty` payloads.
  void _openClientLoyaltyMesAvantagesFromNotification() {
    if (!mounted) return;
    if (_role == UserRole.client) {
      setState(() {
        _activeTab = 'loyalty';
        _authScreen = ScreenId.loyalty;
        _nestedStack.clear();
      });
      return;
    }
    if (_isDualProfile) {
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
        _nestedStack.clear();
      });
      _persistSessionRole();
      return;
    }
    _openNotificationsScreen();
  }

  /// Routes a notification tap to the relevant screen based on FCM data payload.
  ///
  /// Priority (see [functions/src/index.ts] `onNotificationCreated` data block):
  ///  1. Promotion-like type + `merchant_id` + `promotion_id` → vitrine + promo sheet
  ///  2. Promotion-like type + `merchant_id` without promo id → inbox "Promotions" tab
  ///  3. `bon_expiring` / `bon_expired` → loyalty tab ("Mes avantages")
  ///  4. `type == loyalty_passage_request` + merchant → passage sheet (merchant shell)
  ///  5. `type` contains `loyalty` (but not passage_request) → loyalty tab
  ///  6. Anything else (incl. `auto`) → notifications inbox
  ///     (`notification_id` scroll when present) — never the bare vitrine.
  void _handleFcmTap(Map<String, dynamic>? data) {
    if (!mounted) return;
    if (data == null) {
      _openNotificationsScreen();
      return;
    }

    String fcmStr(String key) {
      final v = data[key];
      if (v == null) return '';
      return v.toString().trim();
    }

    bool looksLikePromotionType(String t) {
      if (t.isEmpty) return false;
      if (t == 'promotion' ||
          t == 'promotion_created' ||
          t == 'promo' ||
          t.startsWith('promotion')) {
        return true;
      }
      return false;
    }

    final type = fcmStr('type').toLowerCase();
    final merchantId = fcmStr('merchant_id');
    final notificationId = fcmStr('notification_id');

    if (looksLikePromotionType(type) && merchantId.isNotEmpty) {
      final promotionId = fcmStr('promotion_id');
      if (promotionId.isNotEmpty) {
        _openVitrineForMerchant(
          merchantId,
          promotionId: promotionId,
        );
      } else {
        _openNotificationsScreen(
          notificationId: notificationId.isEmpty ? null : notificationId,
          initialInboxTab: 'promos',
        );
      }
      return;
    }

    if (type == 'bon_expiring' || type == 'bon_expired') {
      _openClientLoyaltyMesAvantagesFromNotification();
      return;
    }

    if (type == 'loyalty_passage_validated' && _role == UserRole.merchant) {
      if (_activeTab != 'communaute' && mounted) {
        setState(() => _activeTab = 'communaute');
      }
      return;
    }

    if (type == 'loyalty_passage_request') {
      _handlePassageValidationPush(data);
      return;
    }

    if (type.contains('loyalty')) {
      _openClientLoyaltyMesAvantagesFromNotification();
      return;
    }

    // Auto notifications (rappels, anniversaires…) intentionally fall through
    // to the inbox: "quand un client clique sur une notification … il veut
    // voir la notification, pas repartir sur la vitrine". The inbox scrolls
    // to the row when `notification_id` is present, and the row's detail
    // sheet keeps the storefront one tap away.
    _openNotificationsScreen(
      notificationId: notificationId.isEmpty ? null : notificationId,
    );
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
  void _handleAuthStateChange(AuthState authState, {AuthState? previous}) {
    if (!mounted) return;

    // Same-user profile refresh short-circuit. `reloadProfile()` re-emits
    // an `Authenticated` state with updated user fields after profile edits
    // or onboarding completion. Without this guard every such refresh
    // pushed the shell back to splash + ran the full role-lookup retry
    // chain (up to 15–30s with timeouts), so users saw "still loading"
    // after finishing onboarding and had to force-quit the app.
    //
    // IMPORTANT: short-circuit ONLY when the user is already past the
    // pre-auth screens. Screens in [_kPreAuthScreens] need the shell
    // to re-route on every auth emission — that is literally how the
    // OTP screen reaches client/merchant onboarding after a successful
    // signup. Skipping the re-route there left the user stuck on OTP
    // after entering a valid code.
    //
    // Conditions for the short-circuit:
    //   - same user uid (no actual sign-in/out happened),
    //   - we are NOT on a pre-auth screen (splash/login/signup/otp/role),
    //   - we are NOT mid-navigation (don't interrupt a still-running
    //     _handleAuthenticatedUser).
    const preAuthScreens = <ScreenId>{
      ScreenId.splash,
      ScreenId.roleSelection,
      ScreenId.login,
      ScreenId.signup,
      ScreenId.oauthCompletion,
      ScreenId.otp,
    };
    if (authState is Authenticated &&
        previous is Authenticated &&
        previous.user.id == authState.user.id &&
        _authScreen != null &&
        !preAuthScreens.contains(_authScreen) &&
        !_isNavigatingToHome) {
      return;
    }

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
            _authScreen == ScreenId.oauthCompletion ||
            _authScreen == ScreenId.otp ||
            (_authScreen == ScreenId.splash && _isNavigatingToHome);

        // Don't navigate if we're in the middle of navigating to home (prevents logout during login)
        if (!inAuthFlow && !_isNavigatingToHome) {
          setState(() {
            // Onboarding is only after signup for merchants (see merchantProfileForm)
            _authScreen = ScreenId.roleSelection;
            _nestedStack.clear();
            _role = null;
          });
          unawaited(_stopMerchantRealtimeServices());
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
            _nestedStack.clear();
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
          await patchUserDoc.call(user.id).timeout(const Duration(seconds: 10));
        } catch (_) {}
      })(),
    );

    // Flag is already set in _handleAuthStateChange, but ensure we're still on splash
    if (_authScreen != ScreenId.splash && mounted) {
      setState(() => _authScreen = ScreenId.splash);
    }

    try {
      final freshOAuthRole = ref.read(oauthSignupFreshProfileRoleProvider);
      final roleAttempts = freshOAuthRole != null ? 10 : 3;

      // Firestore-driven routing: role and onboarding are resolved from users/{uid}.
      final getUserRole = ref.read(getUserRoleProvider);
      UserRole? role;

      // Retry to absorb eventual consistency right after signup/profile writes.
      for (int attempt = 0; attempt < roleAttempts; attempt++) {
        if (attempt > 0) {
          await Future.delayed(Duration(milliseconds: 150 * attempt));
        }
        final roleResult =
            await getUserRole.call(user.id).timeout(const Duration(seconds: 3));
        role = roleResult.fold((_) => null, (r) => r);
        if (role != null) break;
      }

      // No `/users/{uid}` (e.g. brand-new Google/Apple account). Never trust role
      // cache alone — that produced a ghost session. OAuth signup sets
      // [oauthFirestoreProfilePendingProvider] while collecting phone on signup.
      if (role == null) {
        var hasFirestoreProfile = false;
        final basicsAttempts = freshOAuthRole != null ? 10 : 3;
        for (int attempt = 0; attempt < basicsAttempts; attempt++) {
          if (attempt > 0) {
            await Future.delayed(Duration(milliseconds: 150 * attempt));
          }
          final basicsResult = await ref
              .read(getUserProfileBasicsProvider)
              .call(user.id)
              .timeout(const Duration(seconds: 3));
          hasFirestoreProfile =
              basicsResult.fold((_) => false, (b) => b != null);
          if (hasFirestoreProfile) break;
        }

        if (!hasFirestoreProfile &&
            ref.read(oauthFirestoreProfilePendingProvider)) {
          _isNavigatingToHome = false;
          if (mounted) {
            if (_authScreen != ScreenId.oauthCompletion) {
              setState(() {
                _oauthCompletionReturnScreen = _authScreen == ScreenId.login
                    ? ScreenId.login
                    : ScreenId.signup;
                _authScreen = ScreenId.oauthCompletion;
              });
            }
          }
          return;
        }

        if (!hasFirestoreProfile) {
          if (freshOAuthRole != null) {
            // Profile was just written — trust the intended role rather than
            // signing out while Firestore catches up.
            role = freshOAuthRole;
          } else {
            ref.read(oauthFirestoreProfilePendingProvider.notifier).state =
                false;
            clearOAuthSignupRoutingHintsFromWidget(ref);
            try {
              await ref.read(fcmTokenServiceProvider).clearToken(user.id);
            } catch (_) {}
            await ref.read(signOutProvider).call();
            if (!mounted) return;
            setState(() {
              _authScreen = ScreenId.roleSelection;
              _nestedStack.clear();
              _role = null;
              _isNavigatingToHome = false;
            });
            return;
          }
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
        role ??= ref.read(oauthSignupIntendedRoleProvider);
        role ??= freshOAuthRole;
      }

      if (role == null && freshOAuthRole != null && mounted) {
        role = await resolveRoleAfterFreshOAuthSignup(
          fetchRole: () => getUserRole.call(user.id),
          intendedRole: freshOAuthRole,
        );
      }

      // If no fallback role exists (first app open + fresh install), wait only
      // briefly for users/{uid} to appear after signup. Long waits keep users
      // stuck on splash when Firestore rules deny reads.
      if (role == null && mounted) {
        final maxExtraWaitMs = freshOAuthRole != null ? 8000 : 3000;
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
        role ??= freshOAuthRole;
      }

      // If we still have no role after cache fallback, deny session.
      if (role == null) {
        clearOAuthSignupRoutingHintsFromWidget(ref);
        try {
          await ref.read(fcmTokenServiceProvider).clearToken(user.id);
        } catch (_) {}
        await ref.read(signOutProvider).call();
        if (!mounted) return;
        setState(() {
          _authScreen = ScreenId.roleSelection;
          _nestedStack.clear();
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
          dualProfile = await ref
              .read(merchant_providers.hasLinkedMerchantAccountProvider.future);
        }
        setState(() {
          _authScreen = targetScreen;
          _role = role;
          _isDualProfile = dualProfile;
          _activeTab = role == UserRole.client ? 'home' : 'storefront';
          _nestedStack.clear();
          _isNavigatingToHome = false; // Navigation complete
        });
        unawaited(
          ref.read(roleCacheServiceProvider).saveLastSelectedRole(
                role,
                userId: user.id,
              ),
        );
        clearOAuthSignupRoutingHintsFromWidget(ref);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _tryConsumePendingVitrineLink();
          _tryConsumePendingFcmMessage();
        });
        unawaited(_startMerchantRealtimeServices());
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
          _nestedStack.clear();
          _isNavigatingToHome = false; // Navigation complete
        });
      }
    }
  }

  // Note: navigation to role selection is driven by AuthState (Unauthenticated),
  // not by the splash screen timer.

  /// After email/phone OTP signup + Firestore user doc — route off OTP.
  void _routeAfterOtpSignupComplete() {
    if (!mounted) return;
    // The reloadProfile() emission from the OTP flow usually triggers routing
    // via the auth-state listener first. Running _handleAuthenticatedUser a
    // second time in parallel caused a visible re-navigation (screen shown,
    // then bounced) — this call is only a fallback when no emission arrived.
    if (_isNavigatingToHome) return;
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;

    _isNavigatingToHome = true;
    if (_authScreen != ScreenId.splash) {
      setState(() => _authScreen = ScreenId.splash);
    }
    unawaited(_handleAuthenticatedUser(authState.user));
  }

  /// After Google / Apple sign-in (new profile written or existing user).
  void _routeAfterOAuthSignIn() {
    if (!mounted) return;
    // Same double-navigation guard as [_routeAfterOtpSignupComplete].
    if (_isNavigatingToHome) return;
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;

    _isNavigatingToHome = true;
    if (_authScreen != ScreenId.splash) {
      setState(() => _authScreen = ScreenId.splash);
    }
    unawaited(_handleAuthenticatedUser(authState.user));
  }

  void _handleOAuthSignupControllerChange(OAuthSignupState next) {
    if (!mounted) return;

    if (next is OAuthSignupAuthenticating) {
      ref.read(oauthSignupIntendedRoleProvider.notifier).state =
          _role ?? UserRole.client;
      return;
    }

    if (next is OAuthSignupNeedsCompletion) {
      if (_authScreen == ScreenId.oauthCompletion) return;
      setState(() {
        _oauthCompletionReturnScreen = _authScreen == ScreenId.login
            ? ScreenId.login
            : ScreenId.signup;
        _authScreen = ScreenId.oauthCompletion;
      });
      return;
    }

    if (next is OAuthSignupExistingUser) {
      _routeAfterOAuthSignIn();
    }

    if (next is OAuthSignupCompleted) {
      _routeAfterOAuthSignIn();
    }
  }

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
  /// BLE scan/advertise + merchant passage-validation Firestore listener.
  Future<void> _startMerchantRealtimeServices() async {
    await _startBleOnly();
    _ensureMerchantPassageListener();
  }

  Future<void> _stopMerchantRealtimeServices() async {
    _stopActiveValidationListener();
    await _stopBleOnly();
  }

  Future<void> _startBleOnly() async {
    final authState = ref.read(authControllerProvider);
    if (authState is! Authenticated) return;
    final notifier = ref.read(bleProximityProvider.notifier);
    _bleDetectionSub?.cancel();
    _bleDetectionSub = null;
    if (_role == UserRole.client) {
      _stopActiveValidationListener();
      await notifier.startAsClient(authState.user.id);
    } else if (_role == UserRole.merchant) {
      _bleDetectionSub = notifier.detections.listen(_onClientDetected);
      await notifier.startAsMerchant();
    }
  }

  /// Stops BLE only (passage listener stays active while merchant shell is open).
  Future<void> _stopBleOnly() async {
    _bleDetectionSub?.cancel();
    _bleDetectionSub = null;
    await ref.read(bleProximityProvider.notifier).stop();
  }

  void _ensureMerchantPassageListener() {
    if (_role != UserRole.merchant) return;
    if (_activeValidationSub != null) return;
    _startActiveValidationListener();
  }

  void _handlePassageValidationPush(Map<String, dynamic> data) {
    String fcmStr(String key) {
      final v = data[key];
      if (v == null) return '';
      return v.toString().trim();
    }

    final clientUid = fcmStr('client_uid');
    if (clientUid.isEmpty) return;

    final merchantId = fcmStr('merchant_id');
    _pendingPassageValidationClientUid = clientUid;
    _pendingPassageValidationMerchantId =
        merchantId.isNotEmpty ? merchantId : null;
    unawaited(_consumePendingPassageValidationPush());
  }

  void _clearPendingPassageValidationPush() {
    _pendingPassageValidationClientUid = null;
    _pendingPassageValidationMerchantId = null;
  }

  /// Opens the validation sheet from a passage-request push (background,
  /// killed app, or foreground). Switches to merchant role when needed and
  /// fetches the Firestore session directly when the queue stream lags.
  Future<void> _consumePendingPassageValidationPush() async {
    if (_passageValidationPushInFlight) return;
    final clientUid = _pendingPassageValidationClientUid;
    if (clientUid == null || clientUid.isEmpty) return;

    _passageValidationPushInFlight = true;
    try {
      if (!mounted) return;
      final authState = ref.read(authStateProvider);
      if (authState is! Authenticated) return;

      if (_role != UserRole.merchant) {
        var hasMerchant = false;
        try {
          hasMerchant = await ref
              .read(merchant_providers.hasLinkedMerchantAccountProvider.future);
        } catch (_) {}
        if (!hasMerchant) {
          _clearPendingPassageValidationPush();
          return;
        }
        await _switchToMerchant();
        if (!mounted || _role != UserRole.merchant) return;
      }

      _ensureMerchantPassageListener();

      final merchant = await ref.read(
        merchant_providers.currentMerchantForOwnerProvider.future,
      );
      if (!mounted || merchant == null) return;

      final pushMerchantId = _pendingPassageValidationMerchantId;
      if (pushMerchantId != null &&
          pushMerchantId.isNotEmpty &&
          merchant.id != pushMerchantId) {
        _clearPendingPassageValidationPush();
        return;
      }

      if (isAutomaticPassageAllowedForMerchant(merchant)) {
        _clearPendingPassageValidationPush();
        return;
      }

      if (_activeValidationSheetOpen) return;

      ActiveValidationRequest? session;
      final repo = ref.read(activeValidationRepositoryProvider);
      for (var attempt = 0; attempt < 8; attempt++) {
        final result = await repo.getClientSession(
          merchantId: merchant.id,
          clientUid: clientUid,
        );
        session = result.fold((_) => null, (s) => s);
        if (session != null && session.isAwaiting && !session.isExpired) {
          break;
        }
        session = null;
        if (attempt < 7) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }
        if (!mounted) return;
      }

      if (session == null || !session.isAwaiting || session.isExpired) {
        return;
      }
      if (session.isBle) {
        _clearPendingPassageValidationPush();
        return;
      }

      _clearPendingPassageValidationPush();

      final key = _activeValidationSessionKey(session);
      if (_handledActiveValidationKeys.contains(key)) return;
      _handledActiveValidationKeys.add(key);

      if (_activeTab != 'communaute' && mounted) {
        setState(() => _activeTab = 'communaute');
      }

      await _openActiveValidationSheet(session);
    } finally {
      _passageValidationPushInFlight = false;
    }
  }

  /// Subscribes to merchant-side live validation requests. When a new
  /// 'awaiting' session appears, pops the smart-form sheet on top of any
  /// screen. Serializes overlapping requests with [_activeValidationSheetOpen].
  void _startActiveValidationListener() {
    _activeValidationSub?.close();
    _activeValidationSub =
        ref.listenManual<AsyncValue<List<ActiveValidationRequest>>>(
      merchantActiveValidationQueueProvider,
      (previous, next) {
        next.whenData(_onActiveValidationQueue);
      },
      fireImmediately: true,
    );
  }

  void _stopActiveValidationListener() {
    _activeValidationSub?.close();
    _activeValidationSub = null;
    _handledActiveValidationKeys.clear();
    _activeValidationSheetOpen = false;
  }

  String _activeValidationSessionKey(ActiveValidationRequest session) =>
      '${session.merchantId}__${session.clientUid}__'
      '${session.createdAt?.millisecondsSinceEpoch ?? 0}';

  void _onActiveValidationQueue(List<ActiveValidationRequest> queue) {
    if (!mounted) return;

    final pendingUid = _pendingPassageValidationClientUid;
    if (pendingUid != null && !_activeValidationSheetOpen) {
      for (final session in queue) {
        if (session.clientUid != pendingUid) continue;
        if (!session.isAwaiting || session.isExpired || session.isBle) continue;
        _clearPendingPassageValidationPush();
        final key = _activeValidationSessionKey(session);
        if (_handledActiveValidationKeys.contains(key)) return;
        _handledActiveValidationKeys.add(key);
        _openActiveValidationSheet(session);
        return;
      }
    }

    if (_activeValidationSheetOpen) return;
    for (final session in queue) {
      if (!session.isAwaiting || session.isExpired) continue;
      // BLE sessions require explicit merchant proximity confirmation
      // (detection sheet or « Valider un passage »), not a shell auto-popup.
      if (session.isBle) continue;
      final key = _activeValidationSessionKey(session);
      if (_handledActiveValidationKeys.contains(key)) continue;
      _handledActiveValidationKeys.add(key);
      final merchant =
          ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
      if (merchant != null &&
          merchant.id == session.merchantId &&
          isAutomaticPassageAllowedForMerchant(merchant)) {
        unawaited(_autoConfirmPassageSession(session, merchant));
        continue;
      }
      _openActiveValidationSheet(session);
      break; // Open one at a time; the next will be picked up on close.
    }
  }

  /// When passage validation is automatic, confirm immediately — no sheet,
  /// no client "validation en cours" wait (handles desynced legacy sessions).
  Future<void> _autoConfirmPassageSession(
    ActiveValidationRequest session,
    Merchant merchant,
  ) async {
    final result = await ref.read(confirmActiveValidationProvider).call(
          actingOwnerUid: merchant.ownerUid,
          merchant: merchant,
          session: session,
        );
    result.fold(
      (_) {},
      (_) {
        ref.invalidate(merchantActiveValidationQueueProvider);
      },
    );
  }

  Future<void> _openActiveValidationSheet(
    ActiveValidationRequest session,
  ) async {
    final merchant = await ref.read(
      merchant_providers.currentMerchantForOwnerProvider.future,
    );
    if (!mounted || merchant == null || merchant.id != session.merchantId) {
      return;
    }
    _activeValidationSheetOpen = true;
    await openMerchantPassageValidation(
      ref: ref,
      context: context,
      merchant: merchant,
      session: session,
    );
    if (!mounted) return;
    _activeValidationSheetOpen = false;
    // Re-process the queue in case another request landed while the sheet
    // was open — the provider always holds the current state.
    final next = ref.read(merchantActiveValidationQueueProvider).valueOrNull;
    if (next != null) _onActiveValidationQueue(next);
  }

  /// Called when a client is detected nearby. Shows the confirmation sheet on
  /// top of whatever screen the merchant is currently viewing.
  void _onClientDetected(BleClientDetection detection) {
    if (!mounted) return;
    final merchant =
        ref.read(merchant_providers.currentMerchantForOwnerProvider).valueOrNull;
    if (merchant == null || !isAutomaticPassageAllowedForMerchant(merchant)) {
      ref.read(bleProximityProvider.notifier).resetAfterDetection();
      return;
    }
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
            content:
                Text('Impossible de vérifier votre profil client. Réessayez.'),
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

      // Identity (first name, last name, DOB) is what onboarding enforces.
      // When it's already on file we finalize the client profile silently
      // and enter — photo / city being empty must NOT re-trigger the wizard.
      if (readiness.hasRequiredIdentityData) {
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
              content:
                  Text('Impossible de finaliser le profil client. Réessayez.'),
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
        _nestedStack.clear();
      });
      unawaited(_startBleOnly());
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
      _nestedStack.clear();
    });
    unawaited(_startBleOnly());
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
      var completed = completedResult.fold((_) => null, (v) => v);

      // `onboarding.merchant` can be missing or stale while `merchants/{id}`
      // already exists (legacy / interrupted writes). If a storefront doc is
      // linked, treat onboarding as done so dual users are not sent through
      // the full wizard again on every role switch.
      var canOpenMerchantShell = completed == true;
      if (!canOpenMerchantShell) {
        try {
          canOpenMerchantShell = await ref
              .read(merchant_providers.hasLinkedMerchantAccountProvider.future);
        } catch (_) {}
      }

      if (canOpenMerchantShell) {
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
          _nestedStack.clear();
        });
        unawaited(_startMerchantRealtimeServices());
      } else {
        // First time — register the merchant role in Firestore, then onboard.
        final roleResult = await repo.addSecondaryMerchantRole(uid);
        if (!mounted) return;
        final roleFailed = roleResult.fold((_) => true, (_) => false);
        if (roleFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de créer le profil pro. Réessayez.'),
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
          _nestedStack.clear();
        });
        unawaited(_startMerchantRealtimeServices());
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
      'storefront-links': ScreenId.merchantStorefrontLinks,
    };

    final target = map[screen];
    if (target != null) {
      setState(() {
        if (_role == UserRole.client && target == ScreenId.notifications) {
          _activeTab = 'notifications';
          _authScreen = ScreenId.notifications;
          _nestedStack.clear();
        } else {
          _pushNestedScreen(target);
        }
      });
    } else if (screen == 'storefront') {
      setState(() {
        _activeTab = 'storefront';
        _authScreen = ScreenId.merchantStorefront;
        _nestedStack.clear();
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
      setState(() => _pushNestedScreen(ScreenId.merchantStorefrontEditProfile));
    } else if (screen == 'store-preview') {
      // Preview merchant's own storefront as a client would see it
      final merchantId = ref
              .read(merchant_providers.currentMerchantForOwnerProvider)
              .valueOrNull
              ?.id ??
          '';
      if (merchantId.isNotEmpty) {
        ref
            .read(store_profile_providers
                .selectedStoreMerchantIdProvider.notifier)
            .state = merchantId;
        setState(() => _pushNestedScreen(ScreenId.storeProfile));
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

    final canClient =
        rolesMap?['client'] == true || firestoreRole == UserRole.client;
    var canMerchant =
        rolesMap?['merchant'] == true || firestoreRole == UserRole.merchant;
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
        _nestedStack.clear();

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
        _nestedStack.clear();
      } else {
        final map = <String, ScreenId>{
          'communaute': ScreenId.merchantClients,
          'rappels': ScreenId.merchantRappels,
          'storefront': ScreenId.merchantStorefront,
          'promotions': ScreenId.merchantPromotions,
          'profile': ScreenId.merchantProfile,
        };
        final target = map[tab] ?? ScreenId.merchantStorefront;
        if (target == ScreenId.merchantClients ||
            target == ScreenId.merchantNotificationsHub ||
            target == ScreenId.merchantRappels ||
            target == ScreenId.merchantPromotions ||
            target == ScreenId.merchantProfile ||
            target == ScreenId.merchantStorefront) {
          _authScreen = target;
          _nestedStack.clear();
        } else {
          _nestedStack
            ..clear()
            ..add(target);
        }
      }
    });
  }

  void _handleBackToBase() {
    if (_role == UserRole.client) {
      setState(() {
        _authScreen = ScreenId.clientHome;
        _nestedStack.clear();

        _activeTab = 'home';
      });
    } else {
      setState(() {
        _authScreen = ScreenId.merchantStorefront;
        _nestedStack.clear();

        _activeTab = 'storefront';
      });
    }
    _persistSessionRole();
  }

  void _openNotificationsScreen({
    String? notificationId,
    String initialInboxTab = 'alertes',
  }) {
    final nid = notificationId?.trim() ?? '';
    final hasScrollTarget = nid.isNotEmpty;
    final nonDefaultTab = initialInboxTab != 'alertes';
    if (hasScrollTarget || nonDefaultTab) {
      ref.read(client_notification_providers.notificationInboxDeepLinkProvider
              .notifier)
          .state = client_notification_providers.NotificationInboxDeepLink(
        initialTab:
            initialInboxTab == 'promos' ? 'promos' : 'alertes',
        notificationId: hasScrollTarget ? nid : null,
      );
    } else {
      ref
          .read(client_notification_providers
              .notificationInboxDeepLinkProvider.notifier)
          .state = null;
    }
    setState(() {
      _authScreen = ScreenId.notifications;
      _activeTab = 'notifications';
      _nestedStack.clear();
    });
    _persistSessionRole();
  }

  /// Pushes a sub-screen onto the nested navigation stack. Consecutive
  /// duplicates are ignored so a re-tap (or a deep-link to the page the user
  /// is already on) doesn't stack the same screen twice — which would make
  /// the first back press feel like a no-op.
  ///
  /// Call this INSIDE a `setState` closure (it only mutates [_nestedStack]).
  void _pushNestedScreen(ScreenId screen) {
    if (_nestedStack.isNotEmpty && _nestedStack.last == screen) return;
    _nestedStack.add(screen);
  }

  /// Goes back one level: pops the topmost nested sub-screen so the user
  /// returns to the *specific* page that opened it (the previous nested
  /// screen, or the base tab when the stack empties). Unlike
  /// [_handleBackToBase] this never jumps straight to the root home/vitrine
  /// while intermediate pages are still on the stack.
  void _handleBackFromNested() {
    if (_nestedStack.isNotEmpty) {
      setState(() {
        _nestedStack.removeLast();
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

    // 1) On a nested sub-screen: pop ONE level so the user returns to the
    //    specific page that opened it (the previous sub-page, or the base tab
    //    once the stack empties) — never a forced jump to the root.
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
        _nestedStack.clear();
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
        _nestedStack.clear();
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

    // Get current screen for key and styling. When [_authScreen] is null
    // (transient [AuthLoading] — see [_handleAuthStateChange]), fall back to
    // splash so we keep the branded loading surface instead of coercing to
    // role selection (which broke styling and could feel like a "white" or
    // wrong first paint during slow auth refresh).
    final currentScreen =
        _nestedScreen ?? _authScreen ?? ScreenId.splash;

    // Sharper transitions: key forces AnimatedSwitcher to run transition when screen changes,
    // shorter duration reduces fuzzy crossfade, no layout scaling.
    Widget shellBody = AnimatedSwitcher(
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

    final authStateForShell = ref.watch(authControllerProvider);
    if (authStateForShell is Authenticated && _role == UserRole.client) {
      final followedIds =
          ref.watch(followedMerchantIdsForCurrentUserProvider).valueOrNull ??
              const <String>[];
      shellBody = LoyaltyCelebrationOverlay(
        followedMerchantIds: followedIds,
        child: shellBody,
      );
    }
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
    final isAccountPrefs =
        currentScreen == ScreenId.merchantAccountPreferences ||
            currentScreen == ScreenId.merchantSecurity ||
            currentScreen == ScreenId.merchantDataPrivacy ||
            currentScreen == ScreenId.merchantProfileSummary ||
            currentScreen == ScreenId.merchantGratificationConfig ||
            currentScreen == ScreenId.merchantStorefrontLinks;
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
        ? const Color(0xFF0B1F33) // MerchantColors.bgHeader (match dark header)
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
              final content = shellBody;

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
    // Nested wins, then auth route. Null [_authScreen] = auth loading surface
    // (same fallback as [build] — must stay splash, not role selection).
    final currentScreen =
        _nestedScreen ?? _authScreen ?? ScreenId.splash;

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
              _nestedStack.clear();
            });
          },
          onScanQr: () {
            // Open QR scanner even without an account; back returns to role selection.
            setState(() {
              _authScreen = ScreenId.qrScanner;
              _nestedStack.clear();
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
                _nestedStack.clear();
              });
            } else {
              setState(() => _authScreen = ScreenId.roleSelection);
            }
          },
          onNext: () => setState(
              () => _authScreen = ScreenId.merchantSubcategorySelection),
        );
      case ScreenId.merchantSubcategorySelection:
        return SubcategorySelectionScreen(
          onBack: () =>
              setState(() => _authScreen = ScreenId.merchantOnboarding),
          onNext: () => setState(() => _authScreen = ScreenId.merchantBenefits),
        );
      case ScreenId.merchantBenefits:
        return MerchantBenefitsScreen(
          onBack: () => setState(
              () => _authScreen = ScreenId.merchantSubcategorySelection),
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
          onNavigateToOAuthCompletion: () {
            setState(() {
              _oauthCompletionReturnScreen = ScreenId.login;
              _authScreen = ScreenId.oauthCompletion;
            });
          },
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
          onNavigateToOAuthCompletion: () {
            setState(() {
              _oauthCompletionReturnScreen = ScreenId.signup;
              _authScreen = ScreenId.oauthCompletion;
            });
          },
          onSignupComplete: _routeAfterOtpSignupComplete,
        );
      case ScreenId.oauthCompletion:
        return OAuthCompletionScreen(
          role: _role ?? UserRole.client,
          onCancelled: () {
            // Cancel route — controller already signed the OAuth user out
            // and reset itself to idle. Return to whichever screen
            // invoked the flow so the user lands where they expect.
            if (mounted) {
              setState(() => _authScreen = _oauthCompletionReturnScreen);
            }
          },
          onCompleted: () {
            // Profile was created — route explicitly (same pattern as OTP
            // signup) so Firestore lag cannot sign the user out.
            _routeAfterOAuthSignIn();
          },
        );
      case ScreenId.otp:
        return OTPScreen(
          onBack: _handleBackToLogin,
          onSignupComplete: _routeAfterOtpSignupComplete,
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
              _pushNestedScreen(ScreenId.storeProfile);
            });
          },
        );
      case ScreenId.guestShell:
        return GuestShellScreen(
          onBack: () => setState(() {
            _authScreen = ScreenId.roleSelection;
            _nestedStack.clear();
          }),
          onStoreSelect: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _pushNestedScreen(ScreenId.storeProfile));
          },
          onSignUp: () => setState(() {
            _authScreen = ScreenId.signup;
            _nestedStack.clear();
          }),
          onSignIn: () => setState(() {
            _authScreen = ScreenId.login;
            _nestedStack.clear();
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
              _pushNestedScreen(ScreenId.storeProfile);
            });
          },
        );
      case ScreenId.qrScanner:
        return QRScannerScreen(
          onBack: () {
            final authState = ref.read(authControllerProvider);
            if (authState is Authenticated) {
              // Logged-in users reach the scanner from a sub-page (e.g. the
              // Fidélité FAB). Pop one level so back returns to that opener,
              // not the root home/vitrine.
              _handleBackFromNested();
            } else {
              setState(() {
                _authScreen = ScreenId.roleSelection;
                _nestedStack.clear();
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
              _pushNestedScreen(ScreenId.storeProfile);
            });
          },
        );
      case ScreenId.loyalty:
        return LoyaltyCardsScreen(
          onBack: _handleBackFromNested,
          onNotifications: _openNotificationsScreen,
          // Scan-only passage validation: the FAB opens the QR/NFC scanner
          // (which routes through the vitrine scan funnel) instead of the
          // legacy BLE broadcast screen.
          onScan: () => _handleNavigate('qr-scanner'),
          onSwitchToMerchant:
              _isDualProfile ? () => unawaited(_switchToMerchant()) : null,
          onStoreTap: (merchantId) {
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _pushNestedScreen(ScreenId.storeProfile));
          },
        );
      case ScreenId.storeProfile:
        return StoreProfileScreen(
          onBack: _handleBackFromNested,
          onNotifications: _openNotificationsScreen,
          onMessage: () => setState(() => _pushNestedScreen(ScreenId.messages)),
          onReserve: _handleBackToBase,
          onRequestLogin: () {
            // Preserve the current merchant so that after the user logs in,
            // _tryConsumePendingVitrineLink reopens the store profile
            // automatically — no need to scan again.
            final mid = ref
                .read(store_profile_providers.selectedStoreMerchantIdProvider);
            setState(() {
              if (mid != null && mid.isNotEmpty) {
                _pendingVitrineMerchantId = mid;
              }
              _nestedStack.clear();
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
                _nestedStack.clear();
              });
              return;
            }
            ref
                .read(store_profile_providers
                    .selectedStoreMerchantIdProvider.notifier)
                .state = merchantId;
            setState(() => _pushNestedScreen(ScreenId.storeProfile));
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
            setState(() => _pushNestedScreen(ScreenId.storeProfile));
          },
          // Bon / loyalty rows and matching FCM taps land on Mes avantages
          // (with dual-profile role switch when needed) — see
          // [_openClientLoyaltyMesAvantagesFromNotification] / [_handleFcmTap].
          onBonTap: _openClientLoyaltyMesAvantagesFromNotification,
        );
      case ScreenId.messages:
        return MessagesScreen(
          role: _role ?? UserRole.client,
          onBack: _handleBackFromNested,
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
          onNavigate: _handleNavigate,
        );
      case ScreenId.merchantPromotions:
        return PromotionsManagementScreen(
          onNavigate: _handleNavigate,
          onBack: _handleBackToBase,
        );
      case ScreenId.merchantQr:
        return MerchantQRCodeScreen(onBack: _handleBackFromNested);
      case ScreenId.merchantMessages:
        return MessagesScreen(
          role: _role ?? UserRole.merchant,
          onBack: _handleBackFromNested,
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
          isDualProfile: _isDualProfile,
          createOtherRoleLabel: 'Créer un carnet Yuztoo',
          onCreateProAccount: () => unawaited(_switchToClient()),
        );
      case ScreenId.merchantSecurity:
        return IdentificationSecurityScreen(
          onBack: _handleBackFromNested,
          onAccountDeleted: () {
            if (!mounted) return;
            setState(() {
              _nestedStack.clear();
              _role = null;
              _authScreen = ScreenId.roleSelection;
            });
            unawaited(_stopMerchantRealtimeServices());
            unawaited(_clearAuthTransientDrafts());
          },
        );
      case ScreenId.merchantDataPrivacy:
        return DataPrivacyScreen(
          onBack: _handleBackFromNested,
          onAccountDeleted: () {
            if (!mounted) return;
            setState(() {
              _nestedStack.clear();
              _role = null;
              _authScreen = ScreenId.roleSelection;
            });
            unawaited(_stopMerchantRealtimeServices());
            unawaited(_clearAuthTransientDrafts());
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
        return MerchantStatsScreen(onBack: _handleBackFromNested);
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
                _nestedStack.clear();
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
      case ScreenId.merchantStorefrontLinks:
        return MerchantStorefrontLinksScreen(
          onBack: _handleBackFromNested,
        );
    }
  }
}
