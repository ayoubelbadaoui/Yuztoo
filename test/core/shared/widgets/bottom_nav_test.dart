import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/shared/widgets/bottom_nav.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('YBottomNav — mal corrigé S1', () {
    testWidgets('merchant rappels tab uses campaign icon, not notifications',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          YBottomNav(
            role: UserRole.merchant,
            activeTab: 'rappels',
            onTabChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets('client notifications tab still uses bell icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          YBottomNav(
            role: UserRole.client,
            activeTab: 'notifications',
            onTabChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsNothing);
    });

    testWidgets('merchant communaute tab uses people icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          YBottomNav(
            role: UserRole.merchant,
            activeTab: 'communaute',
            onTabChange: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });
}
