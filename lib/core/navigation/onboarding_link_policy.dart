import '../../types.dart';

/// When a shop link (QR / NFC / install referrer) or a tapped push may be
/// opened. Pure functions, kept out of the 3 000-line shell so they are
/// unit-tested: opening either one in the middle of signup / onboarding left
/// the profile half done, and never replaying it lost the QR shop.

/// Wizards and auth flows: a link or push waits until they are finished.
const Set<ScreenId> kOnboardingAndAuthScreens = {
  ScreenId.login,
  ScreenId.signup,
  ScreenId.otp,
  ScreenId.oauthCompletion,
  ScreenId.clientOnboarding,
  ScreenId.merchantOnboarding,
  ScreenId.merchantSubcategorySelection,
  ScreenId.merchantBenefits,
  ScreenId.merchantProfileForm,
};

/// Guest screens where a shop link opens straight away (QR scan → install →
/// first open lands on the shop without forcing signup first).
const Set<ScreenId> kGuestScreensOpeningShopLinks = {
  ScreenId.roleSelection,
  ScreenId.guestShell,
  ScreenId.discovery,
  ScreenId.storeProfile,
  ScreenId.qrScanner,
};

/// Whether a pending shop link can be opened on [screen] now.
bool canOpenShopLinkNow({
  required ScreenId? screen,
  required bool signedIn,
}) {
  if (screen == null || screen == ScreenId.splash) return false;
  if (!signedIn) return kGuestScreensOpeningShopLinks.contains(screen);
  return !kOnboardingAndAuthScreens.contains(screen);
}

/// Whether a tapped push must wait (replayed after onboarding / routing).
bool mustDeferPushTap(ScreenId? screen) =>
    screen == null ||
    screen == ScreenId.splash ||
    kOnboardingAndAuthScreens.contains(screen);
