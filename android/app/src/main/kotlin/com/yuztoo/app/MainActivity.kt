package com.yuztoo.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        createNotificationChannel()
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java) ?: return
            // Delete old channel so blocked state doesn't carry over.
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
