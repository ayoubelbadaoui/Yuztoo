import Flutter
import UIKit
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Explicitly ask APNs for a device token on every cold start. Without this,
    // the token never lands on Messaging and FCM sends silently fail (no banner,
    // no sound) even when permission is granted in-app. Belt-and-suspenders to
    // the requestPermission call in Dart so registration also happens for users
    // who deny in-app but later flip the iOS Settings toggle.
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Forward the APNs token to Firebase Messaging. With swizzling enabled this
  // would happen automatically, but doing it explicitly guarantees the token
  // reaches Messaging even if another plugin's AppDelegate hook intercepts it.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  // Clear the app icon badge as soon as the user opens the app.
  // This mirrors the behaviour of Instagram, WhatsApp, and Messenger.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    super.applicationDidBecomeActive(application)
  }

  // Called when a notification arrives while the app is in the FOREGROUND.
  // We suppress the system banner (.banner) because the Flutter overlay
  // already shows an in-app banner via FirebaseMessaging.onMessage.
  // We still play the sound and update the badge so the UX matches
  // background behaviour (sound + badge, just no duplicate system popup).
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler:
      @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.sound, .badge])   // no .banner — Flutter overlay handles it
    } else {
      completionHandler([.sound, .badge])   // no .alert
    }
  }
}
