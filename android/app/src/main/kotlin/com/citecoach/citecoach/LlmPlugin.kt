package com.citecoach.citecoach

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Native LLM inference plugin using llama.cpp.
 *
 * This plugin bridges Flutter to the native llama.cpp library for
 * on-device LLM inference. It handles:
 * - Model loading/unloading
 * - Text generation with streaming
 * - Memory management
 *
 * ## Setup Instructions:
 *
 * 1. Add llama.cpp as a native dependency:
 *    - Download llama.cpp source from https://github.com/ggerganov/llama.cpp
 *    - Place in android/app/src/main/cpp/llama.cpp/
 *    - Or use the pre-built AAR from llama.cpp releases
 *
 * 2. Add to android/app/build.gradle:
 *    ```
 *    android {
 *        externalNativeBuild {
 *            cmake {
 *                path "src/main/cpp/CMakeLists.txt"
 *            }
 *        }
 *    }
 *    ```
 *
 * 3. Create CMakeLists.txt in android/app/src/main/cpp/:
 *    ```cmake
 *    cmake_minimum_required(VERSION 3.22)
 *    project(citecoach_llm)
 *    add_subdirectory(llama.cpp)
 *    add_library(citecoach_llm SHARED llm_bridge.cpp)
 *    target_link_libraries(citecoach_llm llama common)
 *    ```
 */
class LlmPlugin : MethodChannel.MethodCallHandler {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    // Native model handle (0 = not loaded)
    private var modelHandle: Long = 0
    private var contextHandle: Long = 0

    @Volatile
    private var isGenerating = false

    @Volatile
    private var shouldStop = false

    fun register(engine: FlutterEngine, context: Context) {
        this.context = context

        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.citecoach/llm")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "com.citecoach/llm_stream")
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath")
                loadModel(modelPath, result)
            }
            "startGeneration" -> {
                val prompt = call.argument<String>("prompt") ?: ""
                val maxTokens = call.argument<Int>("maxTokens") ?: 512
                val temperature = call.argument<Double>("temperature") ?: 0.7
                val topP = call.argument<Double>("topP") ?: 0.9
                val repeatPenalty = call.argument<Double>("repeatPenalty") ?: 1.1
                startGeneration(prompt, maxTokens, temperature.toFloat(),
                    topP.toFloat(), repeatPenalty.toFloat(), result)
            }
            "stopGeneration" -> {
                stopGeneration(result)
            }
            "unloadModel" -> {
                unloadModel(result)
            }
            "getModelInfo" -> {
                getModelInfo(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun loadModel(modelPath: String?, result: MethodChannel.Result) {
        executor.execute {
            try {
                val path = modelPath ?: getDefaultModelPath()
                val file = File(path)

                if (!file.exists()) {
                    mainHandler.post {
                        result.error("MODEL_NOT_FOUND",
                            "Model file not found at: $path", null)
                    }
                    return@execute
                }

                // Load native library
                System.loadLibrary("citecoach_llm")

                // Load model via JNI
                modelHandle = nativeLoadModel(path)

                if (modelHandle == 0L) {
                    mainHandler.post {
                        result.error("LOAD_FAILED",
                            "Failed to load model", null)
                    }
                    return@execute
                }

                // Create inference context (1024 tokens - balanced for mobile)
                contextHandle = nativeCreateContext(modelHandle, 1024)

                mainHandler.post { result.success(true) }
            } catch (e: UnsatisfiedLinkError) {
                mainHandler.post {
                    result.error("NATIVE_LIB_MISSING",
                        "Native llama.cpp library not found. " +
                        "Please follow the setup instructions in LlmPlugin.kt " +
                        "to build the native library.", null)
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("LOAD_ERROR",
                        "Error loading model: ${e.message}", null)
                }
            }
        }
    }

    private fun startGeneration(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        repeatPenalty: Float,
        result: MethodChannel.Result
    ) {
        if (modelHandle == 0L || contextHandle == 0L) {
            result.error("MODEL_NOT_LOADED", "Model is not loaded", null)
            return
        }

        if (isGenerating) {
            result.error("ALREADY_GENERATING",
                "Generation already in progress", null)
            return
        }

        isGenerating = true
        shouldStop = false
        result.success(null) // Acknowledge start, tokens come via EventChannel

        executor.execute {
            try {
                nativeGenerate(
                    contextHandle,
                    prompt,
                    maxTokens,
                    temperature,
                    topP,
                    repeatPenalty
                ) { token ->
                    if (shouldStop) return@nativeGenerate false

                    mainHandler.post {
                        eventSink?.success(token)
                    }
                    true // Continue generating
                }

                mainHandler.post {
                    eventSink?.success("[DONE]")
                }
            } catch (e: Exception) {
                mainHandler.post {
                    eventSink?.success("[ERROR]${e.message}")
                }
            } finally {
                isGenerating = false
            }
        }
    }

    private fun stopGeneration(result: MethodChannel.Result) {
        shouldStop = true
        result.success(null)
    }

    private fun unloadModel(result: MethodChannel.Result) {
        executor.execute {
            try {
                if (contextHandle != 0L) {
                    nativeFreeContext(contextHandle)
                    contextHandle = 0
                }
                if (modelHandle != 0L) {
                    nativeFreeModel(modelHandle)
                    modelHandle = 0
                }
                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("UNLOAD_ERROR",
                        "Error unloading model: ${e.message}", null)
                }
            }
        }
    }

    private fun getModelInfo(result: MethodChannel.Result) {
        val info = HashMap<String, Any>()
        info["name"] = "Qwen 2.5 1.5B Instruct"
        info["parameters"] = "1.5B"
        info["isLoaded"] = modelHandle != 0L
        result.success(info)
    }

    private fun getDefaultModelPath(): String {
        val appDir = context?.filesDir?.absolutePath ?: ""
        return "$appDir/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
    }

    fun dispose() {
        shouldStop = true
        executor.execute {
            if (contextHandle != 0L) {
                nativeFreeContext(contextHandle)
                contextHandle = 0
            }
            if (modelHandle != 0L) {
                nativeFreeModel(modelHandle)
                modelHandle = 0
            }
        }
        executor.shutdown()
        methodChannel?.setMethodCallHandler(null)
    }

    // ---- JNI Native Methods ----
    // These are implemented in the native C++ bridge (llm_bridge.cpp)
    // that links against llama.cpp

    private external fun nativeLoadModel(modelPath: String): Long
    private external fun nativeCreateContext(modelHandle: Long, contextSize: Int): Long
    private external fun nativeGenerate(
        contextHandle: Long,
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        repeatPenalty: Float,
        tokenCallback: (String) -> Boolean
    )
    private external fun nativeFreeContext(contextHandle: Long)
    private external fun nativeFreeModel(modelHandle: Long)
}
