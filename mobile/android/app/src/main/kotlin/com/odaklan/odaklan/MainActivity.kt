package com.odaklan.odaklan

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Latest screen lock/unlock times (epoch ms) since Dart last asked.
    private var lockedAt: Long? = null
    private var unlockedAt: Long? = null

    // Lets a focus session tell "phone put down" apart from "switched apps".
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> lockedAt = System.currentTimeMillis()
                Intent.ACTION_USER_PRESENT -> unlockedAt = System.currentTimeMillis()
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
                    else -> result.notImplemented()
                }
            }
    }
}
