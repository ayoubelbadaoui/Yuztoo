package com.yuztoo.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Build
import android.os.Parcelable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val nfcChannelName = "com.yuztoo.app/nfc"
    private var nfcChannel: MethodChannel? = null
    private var nfcAdapter: NfcAdapter? = null

    /// While true, the app's in-app NFC reader (flutter_nfc_kit reader mode) is
    /// active, so we must NOT also hold foreground dispatch — the two NFC
    /// capture modes are mutually exclusive. Flutter toggles this around its
    /// own poll/write sessions via the method channel.
    private var nfcForegroundDispatchPaused = false

    /// URL read from an NFC tap that launched (or resumed) the activity before
    /// the Flutter engine / Dart listener was ready. Flutter drains it once via
    /// `getInitialNfcLink`.
    private var pendingNfcUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            nfcChannelName,
        )
        nfcChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialNfcLink" -> {
                    result.success(pendingNfcUrl)
                    pendingNfcUrl = null
                }
                // Called by Flutter before it starts its own NFC session
                // (merchant tag programming / in-app scan) so the OS hands the
                // tag to flutter_nfc_kit instead of our foreground dispatch.
                "pauseNfcForegroundDispatch" -> {
                    nfcForegroundDispatchPaused = true
                    disableNfcForegroundDispatch()
                    result.success(null)
                }
                "resumeNfcForegroundDispatch" -> {
                    nfcForegroundDispatchPaused = false
                    enableNfcForegroundDispatch()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // The activity may have been cold-launched by an NFC tap; capture the
        // URL now so Flutter can pull it on startup.
        extractNfcUrl(intent)?.let { pendingNfcUrl = it }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val url = extractNfcUrl(intent) ?: return
        val channel = nfcChannel
        if (channel != null) {
            channel.invokeMethod("onNfcLink", url)
        } else {
            pendingNfcUrl = url
        }
    }

    /**
     * Returns a Yuztoo vitrine URL from an NFC tag-dispatch [intent], or null
     * when the intent isn't an NFC tap. Tries, in order: the URI Android
     * resolved onto the intent's data (NDEF auto-dispatch), the raw NDEF
     * messages extra (foreground dispatch), and finally the live tag's cached
     * NDEF message.
     */
    private fun extractNfcUrl(intent: Intent?): String? {
        if (intent == null) return null
        when (intent.action) {
            NfcAdapter.ACTION_NDEF_DISCOVERED,
            NfcAdapter.ACTION_TECH_DISCOVERED,
            NfcAdapter.ACTION_TAG_DISCOVERED -> Unit
            else -> return null
        }

        intent.dataString?.let { if (it.isNotEmpty()) return it }

        val rawMessages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayExtra(
                NfcAdapter.EXTRA_NDEF_MESSAGES,
                Parcelable::class.java,
            )
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
        }
        rawMessages?.let { messages ->
            for (parcelable in messages) {
                uriFromNdefMessage(parcelable as? NdefMessage)?.let { return it }
            }
        }

        // Foreground-dispatched TAG_DISCOVERED may carry only the Tag handle;
        // read its cached NDEF message directly.
        val tag: Tag? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
        }
        if (tag != null) {
            try {
                val ndef = Ndef.get(tag)
                val message = ndef?.cachedNdefMessage
                uriFromNdefMessage(message)?.let { return it }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun uriFromNdefMessage(message: NdefMessage?): String? {
        if (message == null) return null
        for (record in message.records) {
            val uri = try {
                record.toUri()?.toString()
            } catch (_: Exception) {
                null
            }
            if (!uri.isNullOrEmpty()) return uri
        }
        return null
    }

    /**
     * Captures every NFC tap while the app is in the foreground and routes it
     * to [onNewIntent] — no system chooser, no browser. This is what makes an
     * open app register a passage instantly, mirroring iOS Core NFC.
     */
    private fun enableNfcForegroundDispatch() {
        if (nfcForegroundDispatchPaused) return
        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return
        nfcAdapter = adapter
        if (!adapter.isEnabled) return
        val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)
        try {
            adapter.enableForegroundDispatch(this, pendingIntent, null, null)
        } catch (_: Exception) {
        }
    }

    private fun disableNfcForegroundDispatch() {
        try {
            nfcAdapter?.disableForegroundDispatch(this)
        } catch (_: Exception) {
        }
    }

    override fun onResume() {
        super.onResume()
        createNotificationChannel()
        enableNfcForegroundDispatch()
    }

    override fun onPause() {
        super.onPause()
        disableNfcForegroundDispatch()
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
