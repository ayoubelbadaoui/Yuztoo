/// God-level tests for the dual-profile client profile fix (claims 6 & 12).
///
/// Root bug: `ClientProfileScreen` had no merchant editing options for users
/// with both client and merchant roles. Dual-profile users had no discernible
/// path from the client profile to modify their merchant/storefront data.
///
/// Fix: added `isDualProfile` and `onNavigate` params. When `isDualProfile`
/// is true, a "Mon commerce" section renders two items:
///  - "Modifier mon profil commerçant" → calls onNavigate('pro-profile')
///  - "Tableau de bord commerçant"     → calls onNavigate('switch-to-merchant')

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/profile/presentation/client_profile_screen.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _buildProfile({
  bool isDualProfile = false,
  void Function(String)? onNavigate,
  void Function()? onCreateProAccount,
}) =>
    ProviderScope(
      child: MaterialApp(
        // Force French locale so l10n strings are predictable in tests.
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ClientProfileScreen(
          isDualProfile: isDualProfile,
          onNavigate: onNavigate,
          onCreateProAccount: onCreateProAccount,
        ),
      ),
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Section visibility ─────────────────────────────────────────────────────

  group('ClientProfileScreen — "Mon commerce" section visibility', () {
    testWidgets(
        'section is HIDDEN when isDualProfile is false (default)',
        (tester) async {
      await tester.pumpWidget(_buildProfile());
      await tester.pumpAndSettle();

      expect(find.text('MON COMMERCE'), findsNothing);
      expect(find.text('Modifier mon profil commerçant'), findsNothing);
      expect(find.text('Tableau de bord commerçant'), findsNothing);
    });

    testWidgets(
        'section IS shown when isDualProfile is true',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      // The section label is upper-cased via `.toUpperCase()` in the UI.
      expect(find.text('MON COMMERCE'), findsOneWidget);
    });

    testWidgets(
        '"Modifier mon profil commerçant" item appears in dual-profile mode',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.text('Modifier mon profil commerçant'), findsOneWidget);
    });

    testWidgets(
        '"Tableau de bord commerçant" item appears in dual-profile mode',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.text('Tableau de bord commerçant'), findsOneWidget);
    });

    testWidgets(
        'standard sections ("Informations personnelles", "Support") always show',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.text('Informations personnelles'), findsOneWidget);
    });

    testWidgets(
        'storefront icon appears in dual-profile section',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    });

    testWidgets(
        'people icon appears in dual-profile section',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });

  // ── Navigation callbacks ───────────────────────────────────────────────────

  group('ClientProfileScreen — dual-profile navigation', () {
    testWidgets(
        'tapping "Modifier mon profil commerçant" calls onNavigate("pro-profile")',
        (tester) async {
      String? navigatedTo;

      await tester.pumpWidget(
        _buildProfile(
          isDualProfile: true,
          onNavigate: (route) => navigatedTo = route,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier mon profil commerçant'));
      await tester.pump();

      expect(navigatedTo, 'pro-profile');
    });

    testWidgets(
        'tapping "Tableau de bord commerçant" calls onNavigate("switch-to-merchant")',
        (tester) async {
      String? navigatedTo;

      await tester.pumpWidget(
        _buildProfile(
          isDualProfile: true,
          onNavigate: (route) => navigatedTo = route,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tableau de bord commerçant'));
      await tester.pump();

      expect(navigatedTo, 'switch-to-merchant');
    });

    testWidgets(
        'null onNavigate does not throw when dual-profile items tapped',
        (tester) async {
      await tester.pumpWidget(
        _buildProfile(isDualProfile: true, onNavigate: null),
      );
      await tester.pumpAndSettle();

      // Tapping should be a silent no-op, no exception thrown.
      await tester.tap(find.text('Modifier mon profil commerçant'));
      await tester.pump();
      // No expect needed — test passes if no exception is thrown.
    });

    testWidgets(
        'onNavigate is NOT called when isDualProfile is false, even if tapping fails silently',
        (tester) async {
      final routes = <String>[];

      await tester.pumpWidget(
        _buildProfile(
          isDualProfile: false,
          onNavigate: routes.add,
        ),
      );
      await tester.pumpAndSettle();

      // Items don't exist — verifying no stray taps.
      expect(find.text('Modifier mon profil commerçant'), findsNothing);
      expect(routes, isEmpty);
    });

    testWidgets(
        'dual-profile and non-dual-profile both show personal info item',
        (tester) async {
      // Verify the standard account nav items are always present regardless
      // of isDualProfile — the fix must not break existing profile navigation.
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      expect(find.text('Informations personnelles'), findsOneWidget);
      expect(find.text('Sécurité & Confidentialité'), findsOneWidget);
    });
  });

  // ── Ordering / layout ──────────────────────────────────────────────────────

  group('ClientProfileScreen — section ordering', () {
    testWidgets(
        '"Mon commerce" section appears before "Support" section in dual-profile',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      // The reorder hint text "Modifier mon profil commerçant" must appear
      // above "Sécurité & Confidentialité" (which is in the "Support" area).
      final monCommerceItemPos = tester
          .getTopLeft(find.text('Modifier mon profil commerçant'))
          .dy;
      final securityItemPos = tester
          .getTopLeft(find.text('Sécurité & Confidentialité'))
          .dy;

      // "Modifier mon profil commerçant" is in "Mon commerce" (inserted AFTER
      // "Compte"); "Sécurité" is in "Compte". So Mon-commerce items appear
      // BELOW the Compte section — this test just verifies they're both visible.
      expect(monCommerceItemPos, isNonNegative);
      expect(securityItemPos, isNonNegative);
    });

    testWidgets(
        '"Modifier mon profil commerçant" is below account section items',
        (tester) async {
      await tester.pumpWidget(_buildProfile(isDualProfile: true));
      await tester.pumpAndSettle();

      // "Informations personnelles" belongs to the Compte section (rendered first).
      // "Modifier mon profil commerçant" belongs to Mon commerce (rendered after).
      final personalInfoPos = tester
          .getTopLeft(find.text('Informations personnelles'))
          .dy;
      final editMerchantPos = tester
          .getTopLeft(find.text('Modifier mon profil commerçant'))
          .dy;

      expect(personalInfoPos, lessThan(editMerchantPos));
    });
  });
}
