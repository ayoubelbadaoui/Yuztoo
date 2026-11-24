import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/navigation/onboarding_link_policy.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  group('shop link (QR / NFC / install referrer)', () {
    test('waits while the client is in onboarding, opens right after', () {
      expect(
          canOpenShopLinkNow(
              screen: ScreenId.clientOnboarding, signedIn: true),
          isFalse);
      // onComplete → clientHome, then the pending link is consumed.
      expect(canOpenShopLinkNow(screen: ScreenId.clientHome, signedIn: true),
          isTrue);
    });

    test('waits during every signup / merchant wizard screen', () {
      for (final s in kOnboardingAndAuthScreens) {
        expect(canOpenShopLinkNow(screen: s, signedIn: true), isFalse,
            reason: '$s');
      }
      expect(
          canOpenShopLinkNow(
              screen: ScreenId.merchantStorefront, signedIn: true),
          isTrue,
          reason: 'merchant lands on storefront → link may open');
    });

    test('never on splash / before the first screen', () {
      expect(canOpenShopLinkNow(screen: null, signedIn: true), isFalse);
      expect(canOpenShopLinkNow(screen: ScreenId.splash, signedIn: false),
          isFalse);
    });

    test('guest: QR → install → first open shows the shop before signup',
        () {
      expect(
          canOpenShopLinkNow(screen: ScreenId.roleSelection, signedIn: false),
          isTrue);
      expect(canOpenShopLinkNow(screen: ScreenId.signup, signedIn: false),
          isFalse,
          reason: 'never yank a guest out of the signup form');
    });
  });

  group('tapped push notification', () {
    test('deferred during onboarding and auth flows', () {
      expect(mustDeferPushTap(ScreenId.clientOnboarding), isTrue);
      expect(mustDeferPushTap(ScreenId.merchantProfileForm), isTrue);
      expect(mustDeferPushTap(ScreenId.otp), isTrue);
      expect(mustDeferPushTap(ScreenId.splash), isTrue);
      expect(mustDeferPushTap(null), isTrue);
    });

    test('opens immediately once the user is in the app', () {
      expect(mustDeferPushTap(ScreenId.clientHome), isFalse);
      expect(mustDeferPushTap(ScreenId.merchantStorefront), isFalse);
      expect(mustDeferPushTap(ScreenId.notifications), isFalse);
    });
  });
}
