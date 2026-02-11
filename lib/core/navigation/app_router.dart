import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feature/splash/presentation/splash_screen.dart';
import '../../feature/role_selection/presentation/role_selection_screen.dart';
import '../../feature/auth/login/presentation/login_screen.dart';
import '../../feature/auth/signup/presentation/signup_screen.dart';
import '../../feature/auth/signup/presentation/otp_screen.dart';
import '../../feature/client_home/presentation/client_home_screen.dart';
import '../../feature/discovery/presentation/discovery_screen.dart';
import '../../feature/qr_scanner/presentation/qr_scanner_screen.dart';
import '../../feature/loyalty/presentation/loyalty_cards_screen.dart';
import '../../feature/store_profile/presentation/store_profile_screen.dart';
import '../../feature/notifications/presentation/notifications_screen.dart';
import '../../feature/messages/presentation/messages_screen.dart';
import '../../feature/profile/presentation/client_profile_screen.dart';
import '../../feature/merchant_dashboard/presentation/merchant_dashboard_screen.dart';
import '../../feature/client_list/presentation/client_list_screen.dart';
import '../../feature/promotions/presentation/promotions_management_screen.dart';
import '../../feature/merchant_qr/presentation/merchant_qr_screen.dart';
import '../../feature/merchant_stats/presentation/merchant_stats_screen.dart';
import '../../feature/merchant_onboarding/presentation/merchant_onboarding_screen.dart';
import '../../feature/merchant_onboarding/presentation/subcategory_selection_screen.dart';
import '../../feature/merchant_onboarding/presentation/merchant_benefits_screen.dart';
import '../../types.dart';
import '../../feature/auth/core/application/providers.dart';
import '../../feature/auth/core/application/state/auth_state.dart';

/// App router configuration using go_router
/// Integrated with auth state for route guards and navigation
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: SplashScreen.path,
    redirect: (context, state) {
      final currentPath = state.uri.path;
      final auth = ref.read(authControllerProvider);
      
      // Public routes that don't require auth
      final publicRoutes = [
        SplashScreen.path,
        RoleSelectionScreen.path,
        LoginScreen.path,
        SignupScreen.path,
        OTPScreen.path,
      ];
      
      // If on a public route, allow access
      if (publicRoutes.contains(currentPath)) {
        return null;
      }
      
      // If not authenticated, redirect to role selection
      if (auth is! Authenticated) {
        return RoleSelectionScreen.path;
      }
      
      // For authenticated users, check navigation state
      final navState = ref.read(navigationStateProvider);
      return navState.when(
        data: (nav) {
          if (nav is NavigationUnauthenticated) {
            // Shouldn't happen if auth is Authenticated, but handle it
            return RoleSelectionScreen.path;
          } else if (nav is NavigationAuthenticated) {
            // Map ScreenId to path
            String? targetPath;
            switch (nav.screen) {
              case ScreenId.clientHome:
                targetPath = ClientHomeScreen.path;
                break;
              case ScreenId.merchantDashboard:
                targetPath = MerchantDashboardScreen.path;
                break;
              case ScreenId.merchantOnboarding:
                targetPath = MerchantOnboardingScreen.path;
                break;
              default:
                break;
            }
            // If we're on a public route but authenticated, redirect to home
            if (targetPath != null && publicRoutes.contains(currentPath)) {
              return targetPath;
            }
            // If we're already on the target path, don't redirect
            if (targetPath != null && currentPath != targetPath) {
              return targetPath;
            }
          } else if (nav is NavigationError) {
            // Error state - sign out and redirect to role selection
            ref.read(authControllerProvider.notifier).signOut();
            return RoleSelectionScreen.path;
          }
          return null;
        },
        loading: () => null, // Keep current route while loading
        error: (_, __) => RoleSelectionScreen.path, // On error, go to role selection
      );
    },
    routes: [
      GoRoute(
        path: SplashScreen.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoleSelectionScreen.path,
        builder: (context, state) {
          // TODO: Pass callbacks from state or use navigation provider
          return RoleSelectionScreen(
            onSelectRole: (role) {
              // Temporary - will be replaced with proper navigation
              context.go(role == UserRole.merchant 
                ? MerchantOnboardingScreen.path 
                : LoginScreen.path);
            },
          );
        },
      ),
      GoRoute(
        path: LoginScreen.path,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] == 'merchant' 
            ? UserRole.merchant 
            : UserRole.client;
          return LoginScreen(
            role: role,
            onBack: () => context.go(RoleSelectionScreen.path),
            onSignup: () => context.go(SignupScreen.path),
          );
        },
      ),
      GoRoute(
        path: SignupScreen.path,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] == 'merchant' 
            ? UserRole.merchant 
            : UserRole.client;
          return SignupScreen(
            role: role,
            onBack: () => context.go(LoginScreen.path),
          );
        },
      ),
      GoRoute(
        path: OTPScreen.path,
        builder: (context, state) {
          // TODO: Extract parameters from state
          return OTPScreen(
            onBack: () => context.go(SignupScreen.path),
            userId: state.uri.queryParameters['userId'] ?? '',
            phone: state.uri.queryParameters['phone'] ?? '',
            email: state.uri.queryParameters['email'] ?? '',
            password: state.uri.queryParameters['password'] ?? '',
            city: state.uri.queryParameters['city'] ?? '',
            role: state.uri.queryParameters['role'] == 'merchant' 
              ? UserRole.merchant 
              : UserRole.client,
            onResend: () {},
          );
        },
      ),
      // Client routes
      GoRoute(
        path: ClientHomeScreen.path,
        builder: (context, state) => ClientHomeScreen(
          onNavigate: (screen) {
            // TODO: Map to proper routes
            context.go('/$screen');
          },
        ),
      ),
      GoRoute(
        path: DiscoveryScreen.path,
        builder: (context, state) => DiscoveryScreen(
          onBack: () => context.go(ClientHomeScreen.path),
          onStoreSelect: () => context.go(StoreProfileScreen.path),
        ),
      ),
      GoRoute(
        path: QRScannerScreen.path,
        builder: (context, state) => QRScannerScreen(
          onBack: () => context.go(ClientHomeScreen.path),
          onScanSuccess: () => context.go(StoreProfileScreen.path),
        ),
      ),
      GoRoute(
        path: LoyaltyCardsScreen.path,
        builder: (context, state) => LoyaltyCardsScreen(
          onBack: () => context.go(ClientHomeScreen.path),
        ),
      ),
      GoRoute(
        path: StoreProfileScreen.path,
        builder: (context, state) => StoreProfileScreen(
          onBack: () => context.go(ClientHomeScreen.path),
          onMessage: () => context.go(MessagesScreen.path),
          onReserve: () => context.go(ClientHomeScreen.path),
        ),
      ),
      GoRoute(
        path: NotificationsScreen.path,
        builder: (context, state) => NotificationsScreen(
          onBack: () => context.go(ClientHomeScreen.path),
        ),
      ),
      GoRoute(
        path: MessagesScreen.path,
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] == 'merchant' 
            ? UserRole.merchant 
            : UserRole.client;
          return MessagesScreen(
            role: role,
            onBack: () => context.go(role == UserRole.merchant 
              ? MerchantDashboardScreen.path 
              : ClientHomeScreen.path),
            onConversationSelect: () {},
          );
        },
      ),
      GoRoute(
        path: ClientProfileScreen.path,
        builder: (context, state) => const ClientProfileScreen(),
      ),
      // Merchant routes
      GoRoute(
        path: MerchantDashboardScreen.path,
        builder: (context, state) => MerchantDashboardScreen(
          onNavigate: (screen) {
            // Map screen names to routes
            final routeMap = {
              'clients': ClientListScreen.path,
              'promotions': PromotionsManagementScreen.path,
              'qr-code': MerchantQRCodeScreen.path,
              'stats': MerchantStatsScreen.path,
              'messages': '${MessagesScreen.path}?role=merchant',
              'settings': ClientProfileScreen.path, // TODO: Create merchant profile screen
              'reservations': MerchantDashboardScreen.path, // TODO: Create reservations screen
            };
            final route = routeMap[screen] ?? MerchantDashboardScreen.path;
            context.go(route);
          },
        ),
      ),
      GoRoute(
        path: ClientListScreen.path,
        builder: (context, state) => ClientListScreen(
          onBack: () => context.go(MerchantDashboardScreen.path),
          onClientSelect: () {},
        ),
      ),
      GoRoute(
        path: PromotionsManagementScreen.path,
        builder: (context, state) => PromotionsManagementScreen(
          onBack: () => context.go(MerchantDashboardScreen.path),
          onCreatePromotion: () {},
        ),
      ),
      GoRoute(
        path: MerchantQRCodeScreen.path,
        builder: (context, state) => MerchantQRCodeScreen(
          onBack: () => context.go(MerchantDashboardScreen.path),
        ),
      ),
      GoRoute(
        path: MerchantStatsScreen.path,
        builder: (context, state) => MerchantStatsScreen(
          onBack: () => context.go(MerchantDashboardScreen.path),
        ),
      ),
      // Merchant onboarding routes
      GoRoute(
        path: MerchantOnboardingScreen.path,
        builder: (context, state) => MerchantOnboardingScreen(
          onBack: () => context.go(RoleSelectionScreen.path),
          onNext: () => context.go(SubcategorySelectionScreen.path),
        ),
      ),
      GoRoute(
        path: SubcategorySelectionScreen.path,
        builder: (context, state) => SubcategorySelectionScreen(
          categoryTitle: 'Métiers de bouche mais encore...',
          subcategories: const [], // TODO: Get from state or provider
          onBack: () => context.go(MerchantOnboardingScreen.path),
          onNext: () => context.go(MerchantBenefitsScreen.path),
        ),
      ),
      GoRoute(
        path: MerchantBenefitsScreen.path,
        builder: (context, state) => MerchantBenefitsScreen(
          onBack: () => context.go(SubcategorySelectionScreen.path),
          onStartFree: () {
            // TODO: Navigate to signup
          },
        ),
      ),
    ],
  );
});

