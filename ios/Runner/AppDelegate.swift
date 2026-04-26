import Flutter
import UIKit
import UserNotifications

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
