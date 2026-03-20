package com.citecoach.citecoach

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var llmPlugin: LlmPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        llmPlugin = LlmPlugin()
        llmPlugin.register(flutterEngine, this)
    }

    override fun onDestroy() {
        llmPlugin.dispose()
        super.onDestroy()
    }
}
