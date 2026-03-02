import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/role_selection/presentation/role_selection_screen.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:flutter_yuztoo/l10n/app_localizations.dart';

void main() {
  group('RoleSelectionScreen - All Buttons Navigation Tests', () {
    UserRole? selectedRole;
    UserRole? roleChanged;

    setUp(() {
      selectedRole = null;
      roleChanged = null;
    });

    Widget createTestWidget({UserRole? initialRole}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RoleSelectionScreen(
          onSelectRole: (role) {
            selectedRole = role;
          },
          initialRole: initialRole,
          onRoleChanged: (role) {
            roleChanged = role;
          },
        ),
      );
    }

    testWidgets('1. Role Toggle - Merchant button changes role to merchant', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.client));
      await tester.pump();

      // Find text "Commerçant" or "MERCHANT" in role toggle
      final merchantToggleText = find.text('Commerçant');
      if (merchantToggleText.evaluate().isEmpty) {
        // Try finding by GestureDetector in the toggle area
        final allGestures = find.byType(GestureDetector);
        expect(allGestures, findsWidgets);
        // First GestureDetector should be merchant button
        await tester.tap(allGestures.first);
      } else {
        await tester.tap(merchantToggleText);
      }

      await tester.pump();

      // Verify role changed callback was called
      expect(roleChanged, UserRole.merchant);
      // Verify merchant view is now shown
      expect(find.textContaining('Votre relation clients'), findsOneWidget);
    });

    testWidgets('2. Role Toggle - Client button changes role to client', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.merchant));
      await tester.pump();

      // Find text "Client" in role toggle
      final clientToggleText = find.text('Client');
      if (clientToggleText.evaluate().isEmpty) {
        // Try finding by GestureDetector - second one should be client
        final allGestures = find.byType(GestureDetector);
        if (allGestures.evaluate().length >= 2) {
          await tester.tap(allGestures.at(1));
        }
      } else {
        await tester.tap(clientToggleText);
      }

      await tester.pump();

      // Verify role changed callback was called
      expect(roleChanged, UserRole.client);
    });

    testWidgets('3. Merchant "Découvrir" button calls onSelectRole with merchant', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.merchant));
      await tester.pump();

      // Find ElevatedButton (Découvrir button)
      final discoverButton = find.byType(ElevatedButton);
      expect(discoverButton, findsOneWidget);

      await tester.tap(discoverButton);
      await tester.pump();

      // Verify onSelectRole was called with merchant
      expect(selectedRole, UserRole.merchant);
    });

    testWidgets('4. Client "Scanner" button calls onSelectRole with client', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.client));
      await tester.pump();

      // Find ElevatedButton.icon (Scanner button) - it's wrapped in AnimatedContainer
      final scanButton = find.byType(ElevatedButton);
      if (scanButton.evaluate().isEmpty) {
        // Try finding by icon
        final qrIcon = find.byIcon(Icons.qr_code_scanner_rounded);
        if (qrIcon.evaluate().isNotEmpty) {
          await tester.tap(qrIcon);
        } else {
          // Find by text containing scan-related words
          final scanText = find.textContaining('Scanner', findRichText: true);
          if (scanText.evaluate().isNotEmpty) {
            await tester.tap(scanText);
          } else {
            // Last resort: find any tappable widget in client view
            final gestures = find.byType(GestureDetector);
            if (gestures.evaluate().length > 2) {
              // Skip role toggle gestures, get the scan button gesture
              await tester.tap(gestures.at(gestures.evaluate().length - 1));
            }
          }
        }
      } else {
        await tester.tap(scanButton);
      }

      // Wait for the 2 second delay in _handleScan
      await tester.pump(const Duration(milliseconds: 2100));

      // Verify onSelectRole was called with client
      expect(selectedRole, UserRole.client);
    });

    testWidgets('5. Login link calls onSelectRole with current selected role', (tester) async {
      // Test with client role
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.client));
      await tester.pump();

      // Find LoginLink widget by text
      final loginLink = find.text('Vous avez déjà un compte ?');
      expect(loginLink, findsOneWidget);

      // Scroll to make sure it's visible
      await tester.ensureVisible(loginLink);
      await tester.pump();

      await tester.tap(loginLink, warnIfMissed: false);
      await tester.pump();

      // Verify onSelectRole was called with client (current role)
      expect(selectedRole, UserRole.client);
    });

    testWidgets('6. Login link with merchant role calls onSelectRole with merchant', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.merchant));
      await tester.pump();

      // Find LoginLink widget
      final loginLink = find.text('Vous avez déjà un compte ?');
      expect(loginLink, findsOneWidget);

      // Scroll to make sure it's visible
      await tester.ensureVisible(loginLink);
      await tester.pump();

      await tester.tap(loginLink, warnIfMissed: false);
      await tester.pump();

      // Verify onSelectRole was called with merchant (current role)
      expect(selectedRole, UserRole.merchant);
    });

    testWidgets('7. All buttons exist and are visible', (tester) async {
      // Test merchant view
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.merchant));
      await tester.pump();

      // Check role toggle exists
      expect(find.text('Commerçant'), findsOneWidget);
      expect(find.text('Client'), findsOneWidget);

      // Check Découvrir button exists
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Check login link exists
      expect(find.text('Vous avez déjà un compte ?'), findsOneWidget);

      // Switch to client view
      final clientToggle = find.text('Client');
      await tester.tap(clientToggle);
      await tester.pump();

      // Check Scanner button exists (ElevatedButton or ElevatedButton.icon)
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);
    });

    testWidgets('8. Button navigation flow: Toggle → Action → Login', (tester) async {
      await tester.pumpWidget(createTestWidget(initialRole: UserRole.client));
      await tester.pump();

      // Step 1: Toggle to merchant
      final merchantToggle = find.text('Commerçant');
      await tester.tap(merchantToggle);
      await tester.pump();
      expect(roleChanged, UserRole.merchant);

      // Step 2: Tap Découvrir button
      final discoverButton = find.byType(ElevatedButton);
      await tester.tap(discoverButton);
      await tester.pump();
      expect(selectedRole, UserRole.merchant);

      // Reset for next test
      selectedRole = null;

      // Step 3: Toggle back to client
      final clientToggle = find.text('Client');
      await tester.tap(clientToggle);
      await tester.pump();
      expect(roleChanged, UserRole.client);

      // Step 4: Tap Scanner button
      final scanButton = find.byType(ElevatedButton);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pump(const Duration(milliseconds: 2100));
        expect(selectedRole, UserRole.client);
      }

      // Step 5: Tap Login link
      selectedRole = null;
      final loginLink = find.text('Vous avez déjà un compte ?');
      await tester.ensureVisible(loginLink);
      await tester.pump();
      await tester.tap(loginLink, warnIfMissed: false);
      await tester.pump();
      expect(selectedRole, UserRole.client);
    });
  });
}
