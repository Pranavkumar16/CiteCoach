package com.citecoach.citecoach

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock

class ModelDownloadService : Service() {
    companion object {
        private const val CHANNEL_ID = "citecoach_model_download"
        private const val NOTIFICATION_ID = 421
        private const val LEASE_MS = 10 * 60 * 1000L
        private var instance: ModelDownloadService? = null

        fun update(percent: Int, message: String) {
            instance?.showProgress(percent.coerceIn(0, 100), message)
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var lastUpdate = SystemClock.elapsedRealtime()
    private val watchdog = object : Runnable {
        override fun run() {
            if (SystemClock.elapsedRealtime() - lastUpdate >= LEASE_MS) {
                stopSelf()
            } else {
                handler.postDelayed(this, 60_000L)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "AI model downloads", NotificationManager.IMPORTANCE_LOW)
            )
        }
        val notification = notification(0, "Starting AI model download…")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "CiteCoach:ModelDownload").apply {
            setReferenceCounted(false)
            acquire(LEASE_MS)
        }
        handler.postDelayed(watchdog, 60_000L)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_NOT_STICKY

    private fun notification(percent: Int, message: String): Notification {
        val openApp = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this, 0, openApp, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            Notification.Builder(this, CHANNEL_ID) else Notification.Builder(this)
        return builder
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Downloading CiteCoach AI")
            .setContentText(message)
            .setContentIntent(pending)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setProgress(100, percent, percent == 0)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .build()
    }

    private fun showProgress(percent: Int, message: String) {
        lastUpdate = SystemClock.elapsedRealtime()
        wakeLock?.acquire(LEASE_MS)
        getSystemService(NotificationManager::class.java)
            .notify(NOTIFICATION_ID, notification(percent, message))
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        if (instance === this) instance = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
