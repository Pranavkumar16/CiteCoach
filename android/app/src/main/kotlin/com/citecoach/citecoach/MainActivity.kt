package com.citecoach.citecoach

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var llmPlugin: LlmPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        llmPlugin = LlmPlugin()
        llmPlugin.register(flutterEngine, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.citecoach/download").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 421)
                        }
                        val intent = Intent(this, ModelDownloadService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                        else startService(intent)
                        result.success(null)
                    }
                    "update" -> {
                        ModelDownloadService.update(
                            call.argument<Int>("percent") ?: 0,
                            call.argument<String>("message") ?: "Downloading offline AI…"
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        stopService(Intent(this, ModelDownloadService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("DOWNLOAD_SERVICE", "Background download could not start. Reopen CiteCoach and retry.", null)
            }
        }
    }

    override fun onDestroy() {
        llmPlugin.dispose()
        super.onDestroy()
    }
}
