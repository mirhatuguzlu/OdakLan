package com.odaklan.odaklan

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.widget.RemoteViews

/** Screen lock/unlock times on disk, so they survive the system killing the app. */
object LockLog {
    private fun prefs(c: Context) = c.getSharedPreferences("odaklan_lock", Context.MODE_PRIVATE)

    // Keep the FIRST lock and the first unlock after it: glancing at the lock
    // screen later (screen on/off without unlocking) must not overwrite the
    // lock that proved the phone was put down, and a later unlock must not
    // hide the first one (when time outside the app started).
    @Synchronized
    fun locked(c: Context) {
        if (lockedAt(c) == null) prefs(c).edit().putLong("lockedAt", System.currentTimeMillis()).commit()
    }

    @Synchronized
    fun unlocked(c: Context) {
        val p = prefs(c)
        if (lockedAt(c) != null && !p.contains("unlockedAt")) {
            p.edit().putLong("unlockedAt", System.currentTimeMillis()).commit()
        }
    }
    fun lockedAt(c: Context): Long? = prefs(c).getLong("lockedAt", 0L).takeIf { it > 0 }

    /** Times since Dart last asked; clears them. */
    @Synchronized
    fun take(c: Context): Map<String, Long?> {
        val p = prefs(c)
        val out = mapOf(
            "lockedAt" to p.getLong("lockedAt", 0L).takeIf { it > 0 },
            "unlockedAt" to p.getLong("unlockedAt", 0L).takeIf { it > 0 },
        )
        p.edit().clear().commit()
        return out
    }
}

/**
 * Runs while a focus session is active: an ongoing "Odaklanıyorsun" countdown
 * notification that keeps the process alive (MIUI's LockScreenClean otherwise
 * kills it ~10 min after locking) and records lock/unlock times.
 */
class FocusService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val finished = Runnable { showFinished() }
    private val refresh = object : Runnable {
        override fun run() {
            notifications().notify(NOTIFICATION_ID, focusNotification())
            handler.postDelayed(this, 60_000)
        }
    }
    private var session = Session(0L, 0L, "", "")

    /** What the notification shows; persisted for a system restart. */
    private data class Session(val startMs: Long, val endMs: Long, val subtitle: String, val goal: String)

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> LockLog.locked(context)
                Intent.ACTION_USER_PRESENT -> LockLog.unlocked(context)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, filter)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Odak seansı", NotificationManager.IMPORTANCE_LOW)
                    .apply { description = "Seans sürerken kalan süre" }
            )
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences("odaklan_session", Context.MODE_PRIVATE)
        // A null intent = the system restarted us after killing the process.
        if (intent?.hasExtra(EXTRA_END) == true) {
            prefs.edit()
                .putLong("startMs", intent.getLongExtra(EXTRA_START, 0L))
                .putLong("endMs", intent.getLongExtra(EXTRA_END, 0L))
                .putString("subtitle", intent.getStringExtra(EXTRA_SUBTITLE) ?: "")
                .putString("goal", intent.getStringExtra(EXTRA_GOAL) ?: "")
                .apply()
        }
        session = Session(
            prefs.getLong("startMs", 0L),
            prefs.getLong("endMs", 0L),
            prefs.getString("subtitle", "") ?: "",
            prefs.getString("goal", "") ?: "",
        )
        val endMs = session.endMs
        if (endMs <= System.currentTimeMillis()) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            val n = focusNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, n)
            }
        } catch (e: Exception) {
            // Android 12+ may refuse a foreground start from the background.
            stopSelf()
            return START_NOT_STICKY
        }
        handler.removeCallbacks(finished)
        handler.postDelayed(finished, endMs - System.currentTimeMillis())
        handler.removeCallbacks(refresh)
        handler.postDelayed(refresh, 60_000)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(finished)
        handler.removeCallbacks(refresh)
        unregisterReceiver(screenReceiver)
        super.onDestroy()
    }

    // The reward is paid when the app opens again; tell the user it's waiting.
    private fun showFinished() {
        val n = builder()
            .setContentTitle("✅ Seans tamamlandı!")
            .setContentText("Ödülünü almak için OdakLan'ı aç.")
            .setAutoCancel(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION") stopForeground(true)
        }
        notifications().notify(FINISHED_ID, n)
        stopSelf()
    }

    private fun notifications() = getSystemService(NotificationManager::class.java)

    // Chronometer ticks by itself; the progress bar is re-posted once a minute.
    private fun focusNotification(): Notification {
        val now = System.currentTimeMillis()
        val base = SystemClock.elapsedRealtime() + (session.endMs - now)
        val total = (session.endMs - session.startMs).coerceAtLeast(1L)
        val done = (now - session.startMs).coerceIn(0L, total)
        val subtitle = session.subtitle.ifEmpty { "Odak seansı" }
        fun view(layout: Int) = RemoteViews(packageName, layout).apply {
            setChronometer(R.id.focus_timer, base, null, true)
            setChronometerCountDown(R.id.focus_timer, true)
            setTextViewText(R.id.focus_subtitle, subtitle)
        }
        val big = view(R.layout.notification_focus_big).apply {
            setProgressBar(R.id.focus_progress, 1000, (done * 1000 / total).toInt(), false)
            setTextViewText(R.id.focus_goal, session.goal)
        }
        return builder()
            .setContentTitle("Odaklanıyorsun")
            .setContentText(subtitle)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(view(R.layout.notification_focus_small))
            .setCustomBigContentView(big)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_PROGRESS)
            // Just a timer: fine to show in full on the lock screen.
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }

    private fun builder(): Notification.Builder {
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(this)
        }
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return b.setSmallIcon(R.drawable.ic_stat_focus)
            .setColor(getColor(R.color.focus_accent))
            .setContentIntent(open)
    }

    companion object {
        private const val CHANNEL_ID = "focus_session"
        private const val NOTIFICATION_ID = 1002
        private const val FINISHED_ID = 1003
        private const val EXTRA_START = "startMs"
        private const val EXTRA_END = "endMs"
        private const val EXTRA_SUBTITLE = "subtitle"
        private const val EXTRA_GOAL = "goal"

        fun start(c: Context, startMs: Long, endMs: Long, subtitle: String, goal: String) {
            c.getSystemService(NotificationManager::class.java).cancel(FINISHED_ID)
            val i = Intent(c, FocusService::class.java)
                .putExtra(EXTRA_START, startMs)
                .putExtra(EXTRA_END, endMs)
                .putExtra(EXTRA_SUBTITLE, subtitle)
                .putExtra(EXTRA_GOAL, goal)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) c.startForegroundService(i) else c.startService(i)
        }

        fun stop(c: Context) {
            c.getSharedPreferences("odaklan_session", Context.MODE_PRIVATE).edit().clear().apply()
            c.stopService(Intent(c, FocusService::class.java))
        }
    }
}
