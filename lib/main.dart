import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'l10n/app_localizations.dart';

import 'core/app_bootstrap.dart';
import 'feature/auth/core/application/providers.dart';
import 'feature/auth/core/infrastructure/user_repository_provider.dart';
import 'feature/auth/core/application/state/auth_state.dart';
import 'feature/auth/core/domain/entities/auth_user.dart';
import 'theme.dart';
import 'types.dart';
import 'core/shared/widgets/bottom_nav.dart';
import 'feature/client_list/application/screens.dart';
import 'feature/splash/application/screens.dart';
import 'feature/role_selection/application/screens.dart';
import 'feature/auth/login/application/screens.dart';
import 'feature/auth/signup/application/screens.dart';
import 'feature/client_onboarding/application/screens.dart';
import 'feature/client_home/application/screens.dart';
import 'feature/discovery/application/screens.dart';
import 'feature/qr_scanner/application/screens.dart';
import 'feature/loyalty/application/screens.dart';
import 'feature/store_profile/application/providers.dart'
    as store_profile_providers;
import 'feature/store_profile/application/screens.dart';
import 'feature/notifications/application/screens.dart';
import 'feature/messages/application/screens.dart';
import 'feature/profile/application/screens.dart';
import 'feature/promotions/application/screens.dart';
import 'feature/merchant_qr/application/screens.dart';
import 'feature/merchant_stats/application/screens.dart';
import 'feature/merchant_onboarding/application/screens.dart';
import 'feature/merchant_onboarding/application/onboarding_flow_provider.dart'
    as merchant_onboarding_providers;
import 'feature/storefront/application/screens.dart';
import 'feature/storefront/application/providers.dart' as storefront_providers;
import 'feature/merchant/application/screens.dart';
import 'feature/rappels/application/screens.dart';
import 'feature/merchant_settings/application/screens.dart';
import 'feature/e_fidelite/application/screens.dart';
import 'feature/account_preferences/application/screens.dart';
import 'feature/merchant/application/providers.dart' as merchant_providers;
import 'feature/client_notification/infrastructure/fcm_token_service.dart';
import 'core/config/vitrine_qr_config.dart';

part 'main_shell_state.part.dart';

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

