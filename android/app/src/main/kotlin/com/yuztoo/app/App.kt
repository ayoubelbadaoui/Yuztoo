package com.yuztoo.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Custom Application class.
 *
 * Creates the FCM notification channel in [onCreate] so the channel exists
 * BEFORE FCM delivers the first push notification, including when the app is
 * in a killed or background state.
 *
 * If the channel is only created in MainActivity (configureFlutterEngine),
 * FCM falls back to an auto-created channel with IMPORTANCE_DEFAULT for
 * killed-state messages, which produces no heads-up banner.
 */
class App : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return
            // Remove the old channel so any "blocked" state doesn't carry over.
            manager.deleteNotificationChannel("yuztoo_promotions")
            val channel = NotificationChannel(
                "yuztoo_promo_v2",
                "Promotions & Fidélité",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications des promotions et du programme de fidélité"
                enableVibration(true)
                enableLights(true)
            }
            manager.createNotificationChannel(channel)
        }
    }
}
