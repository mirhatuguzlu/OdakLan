package com.odaklan.odaklan

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/// "Yesterday's leftover quest rewards were auto-collected" notice. Dart
/// schedules it for the next morning; the Enerji itself is paid by Dart.
object RewardNotice {
    private const val CHANNEL_ID = "reward_auto_collect"
    private const val NOTIFICATION_ID = 1002
    private const val EXTRA_ENERGY = "energy"

    private fun alarmIntent(context: Context, code: Int, energy: Int = 0) =
        PendingIntent.getBroadcast(
            context, code,
            Intent(context, RewardNoticeReceiver::class.java).putExtra(EXTRA_ENERGY, energy),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    /// energy 0 cancels the alarm with this code.
    fun schedule(context: Context, code: Int, atMs: Long, energy: Int) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        if (energy <= 0) {
            alarms.cancel(alarmIntent(context, code))
            return
        }
        // Inexact on purpose: no exact-alarm permission needed for a morning note.
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, alarmIntent(context, code, energy))
    }

    fun showNow(context: Context, code: Int, energy: Int) {
        context.getSystemService(AlarmManager::class.java).cancel(alarmIntent(context, code))
        post(context, energy)
    }

    fun post(context: Context, energy: Int) {
        if (energy <= 0) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Otomatik ödül", NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { description = "Toplanmayan görev ödülleri ertesi gün toplanınca" }
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val open = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        manager.notify(
            NOTIFICATION_ID,
            b.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("⚡ +$energy Enerji toplandı")
                .setContentText("Dün toplamayı unuttuğun görev ödüllerini senin için topladık.")
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }

    fun readEnergy(intent: Intent) = intent.getIntExtra(EXTRA_ENERGY, 0)
}

class RewardNoticeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) =
        RewardNotice.post(context, RewardNotice.readEnergy(intent))
}
