package com.odaklan.odaklan

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Latest screen lock/unlock times (epoch ms) since Dart last asked.
    private var lockedAt: Long? = null
    private var unlockedAt: Long? = null

    // Leave-countdown state: away from the app with a session running.
    private var graceMs: Long? = null
    private var countdownRunning = false
    private val handler = Handler(Looper.getMainLooper())
    private val brokeNow = Runnable { showBroken() }

    // Lets a focus session tell "phone put down" apart from "switched apps".
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    lockedAt = System.currentTimeMillis()
                    // Locking inside the grace forgives the leave (FocusSession.resumed).
                    if (countdownRunning) stopCountdown()
                }
                Intent.ACTION_USER_PRESENT -> {
                    unlockedAt = System.currentTimeMillis()
                    // Unlocked somewhere else: the grace starts again from now.
                    if (graceMs != null && !countdownRunning && lockedAt != null) startCountdown()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        // System broadcasts only; other apps cannot send to this receiver.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifications().createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Odak uyarısı", NotificationManager.IMPORTANCE_HIGH)
                    .apply { description = "Uygulamadan çıkınca seans bozulmadan önceki geri sayım" }
            )
        }
    }

    override fun onDestroy() {
        unregisterReceiver(screenReceiver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "odaklan/screen_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeLockEvents" -> {
                        result.success(mapOf("lockedAt" to lockedAt, "unlockedAt" to unlockedAt))
                        lockedAt = null
                        unlockedAt = null
                    }
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0)
                        }
                        result.success(null)
                    }
                    "leaveStarted" -> {
                        graceMs = call.argument<Number>("graceMs")?.toLong()
                        // Hidden because the screen went off: wait for the unlock instead.
                        val screenOn = (getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
                        if (graceMs != null && screenOn) startCountdown()
                        result.success(null)
                    }
                    "leaveEnded" -> {
                        graceMs = null
                        stopCountdown()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun notifications() = getSystemService(NotificationManager::class.java)

    private fun builder(): Notification.Builder {
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_HIGH)
        }
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return b.setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(open)
            .setCategory(Notification.CATEGORY_ALARM)
    }

    // One notification whose system chronometer counts down: no per-second reposts.
    private fun startCountdown() {
        val grace = graceMs ?: return
        countdownRunning = true
        // Chronometer bases use the elapsed-realtime clock.
        val base = SystemClock.elapsedRealtime() + grace
        fun countdownView(layout: Int) = RemoteViews(packageName, layout).apply {
            setChronometer(R.id.countdown_timer, base, null, true)
            setChronometerCountDown(R.id.countdown_timer, true)
        }
        val small = countdownView(R.layout.notification_countdown_small)
        val b = builder()
            .setContentTitle("⏳ OdakLan'a geri dön!")
            .setContentText("Süre dolunca seans bozulur ve şehrin hasar alır.")
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(small)
            .setCustomHeadsUpContentView(small)
            .setCustomBigContentView(countdownView(R.layout.notification_countdown_big))
            .setColor(getColor(R.color.countdown_alert))
            .setOngoing(true)
            .setAutoCancel(true)
        // shortcut: if the process dies mid-countdown the "broken" update never
        // posts; the timeout at least clears the stale countdown.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) b.setTimeoutAfter(grace)
        notifications().notify(NOTIFICATION_ID, b.build())
        handler.removeCallbacks(brokeNow)
        handler.postDelayed(brokeNow, grace)
    }

    private fun stopCountdown() {
        countdownRunning = false
        handler.removeCallbacks(brokeNow)
        notifications().cancel(NOTIFICATION_ID)
    }

    private fun showBroken() {
        countdownRunning = false
        graceMs = null
        notifications().notify(
            NOTIFICATION_ID,
            builder()
                .setContentTitle("💥 Seans bozuldu")
                .setContentText("Süre doldu, odak seansın sona erdi. Tamamlanan bloklar senin.")
                .setAutoCancel(true)
                .build(),
        )
    }

    private companion object {
        const val CHANNEL_ID = "leave_countdown"
        const val NOTIFICATION_ID = 1001
    }
}
