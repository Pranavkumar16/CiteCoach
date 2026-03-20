import Flutter
import Foundation

/// Native LLM inference plugin using llama.cpp for iOS.
///
/// This plugin bridges Flutter to llama.cpp for on-device inference.
///
/// ## Setup Instructions:
///
/// 1. Add llama.cpp to the iOS project:
///    - Use Swift Package Manager (SPM):
///      File > Add Packages > https://github.com/ggerganov/llama.cpp
///    - Or use CocoaPods with the llama.cpp podspec
///    - Or manually add the llama.cpp source files to the Xcode project
///
/// 2. Add to ios/Podfile (if using CocoaPods):
///    ```ruby
///    pod 'llama', :git => 'https://github.com/ggerganov/llama.cpp'
///    ```
///
/// 3. Enable Metal acceleration in Build Settings:
///    - Set METAL_LIBRARY_OUTPUT_DIR
///    - Link Metal.framework and MetalKit.framework
///
/// 4. Set minimum deployment target to iOS 14.0+
///
class LlmPlugin: NSObject {

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    // Model state (opaque pointers to llama.cpp structs)
    private var modelPointer: OpaquePointer?
    private var contextPointer: OpaquePointer?

    private var isGenerating = false
    private var shouldStop = false

    private let inferenceQueue = DispatchQueue(
        label: "com.citecoach.llm.inference",
        qos: .userInitiated
    )

    func register(with messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.citecoach/llm",
            binaryMessenger: messenger
        )
        methodChannel?.setMethodCallHandler(handle)

        eventChannel = FlutterEventChannel(
            name: "com.citecoach/llm_stream",
            binaryMessenger: messenger
        )
        eventChannel?.setStreamHandler(StreamHandler(plugin: self))
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadModel":
            let args = call.arguments as? [String: Any]
            let modelPath = args?["modelPath"] as? String
            loadModel(path: modelPath, result: result)

        case "startGeneration":
            let args = call.arguments as? [String: Any] ?? [:]
            let prompt = args["prompt"] as? String ?? ""
            let maxTokens = args["maxTokens"] as? Int ?? 512
            let temperature = args["temperature"] as? Double ?? 0.7
            let topP = args["topP"] as? Double ?? 0.9
            let repeatPenalty = args["repeatPenalty"] as? Double ?? 1.1
            startGeneration(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: Float(temperature),
                topP: Float(topP),
                repeatPenalty: Float(repeatPenalty),
                result: result
            )

        case "stopGeneration":
            shouldStop = true
            result(nil)

        case "unloadModel":
            unloadModel(result: result)

        case "getModelInfo":
            let info: [String: Any] = [
                "name": "Phi-3.5 Mini Instruct",
                "quantization": "Q4_K_M",
                "parameters": "3.8B",
                "isLoaded": modelPointer != nil
            ]
            result(info)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Model Loading

    private func loadModel(path: String?, result: @escaping FlutterResult) {
        inferenceQueue.async { [weak self] in
            guard let self = self else { return }

            let modelPath = path ?? self.getDefaultModelPath()

            guard FileManager.default.fileExists(atPath: modelPath) else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "MODEL_NOT_FOUND",
                        message: "Model file not found at: \(modelPath)",
                        details: nil
                    ))
                }
                return
            }

            do {
                // Initialize llama.cpp model
                // NOTE: Replace these with actual llama.cpp API calls
                // after adding llama.cpp to the project.
                //
                // var params = llama_model_default_params()
                // params.n_gpu_layers = 99  // Use Metal GPU
                // self.modelPointer = llama_load_model_from_file(modelPath, params)
                //
                // var ctxParams = llama_context_default_params()
                // ctxParams.n_ctx = 2048
                // ctxParams.n_threads = 4
                // self.contextPointer = llama_new_context_with_model(self.modelPointer, ctxParams)

                // Placeholder: Simulate successful load
                // Remove this once llama.cpp is integrated
                self.modelPointer = OpaquePointer(bitPattern: 1)
                self.contextPointer = OpaquePointer(bitPattern: 1)

                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "LOAD_ERROR",
                        message: "Failed to load model: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - Text Generation

    private func startGeneration(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        topP: Float,
        repeatPenalty: Float,
        result: @escaping FlutterResult
    ) {
        guard modelPointer != nil, contextPointer != nil else {
            result(FlutterError(
                code: "MODEL_NOT_LOADED",
                message: "Model is not loaded",
                details: nil
            ))
            return
        }

        guard !isGenerating else {
            result(FlutterError(
                code: "ALREADY_GENERATING",
                message: "Generation already in progress",
                details: nil
            ))
            return
        }

        isGenerating = true
        shouldStop = false
        result(nil) // Acknowledge start

        inferenceQueue.async { [weak self] in
            guard let self = self else { return }

            defer { self.isGenerating = false }

            // NOTE: Replace this with actual llama.cpp inference
            // after integrating the library.
            //
            // Actual implementation would:
            // 1. Tokenize the prompt
            // 2. Run inference token by token
            // 3. Stream each decoded token back via eventSink
            //
            // Example with llama.cpp API:
            //
            // let tokens = llama_tokenize(self.contextPointer, prompt, ...)
            // llama_eval(self.contextPointer, tokens, ...)
            //
            // for _ in 0..<maxTokens {
            //     if self.shouldStop { break }
            //
            //     let logits = llama_get_logits(self.contextPointer)
            //     let tokenId = llama_sample(logits, temperature, topP, repeatPenalty)
            //
            //     if tokenId == llama_token_eos(self.modelPointer) { break }
            //
            //     let tokenStr = llama_token_to_piece(self.modelPointer, tokenId)
            //     DispatchQueue.main.async {
            //         self.eventSink?(tokenStr)
            //     }
            //
            //     llama_eval(self.contextPointer, [tokenId], ...)
            // }

            // Placeholder response for testing without native lib
            let placeholderTokens = [
                "Based ", "on ", "the ", "document, ",
                "I ", "can ", "see ", "that ",
                "this ", "topic ", "is ", "discussed ",
                "in ", "the ", "referenced ", "pages. ",
                "Please ", "integrate ", "llama.cpp ",
                "native ", "library ", "for ", "real ",
                "AI-powered ", "responses."
            ]

            for token in placeholderTokens {
                if self.shouldStop { break }
                DispatchQueue.main.async {
                    self.eventSink?(token)
                }
                Thread.sleep(forTimeInterval: 0.03)
            }

            DispatchQueue.main.async {
                self.eventSink?("[DONE]")
            }
        }
    }

    // MARK: - Model Unloading

    private func unloadModel(result: @escaping FlutterResult) {
        inferenceQueue.async { [weak self] in
            guard let self = self else { return }

            // NOTE: Replace with actual llama.cpp cleanup:
            // if let ctx = self.contextPointer {
            //     llama_free(ctx)
            // }
            // if let model = self.modelPointer {
            //     llama_free_model(model)
            // }

            self.contextPointer = nil
            self.modelPointer = nil

            DispatchQueue.main.async {
                result(true)
            }
        }
    }

    // MARK: - Helpers

    private func getDefaultModelPath() -> String {
        let documentsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsDir.appendingPathComponent(
            "models/phi-3.5-mini-instruct-q4_k_m.gguf"
        ).path
    }

    func dispose() {
        shouldStop = true
        inferenceQueue.async { [weak self] in
            // if let ctx = self?.contextPointer { llama_free(ctx) }
            // if let model = self?.modelPointer { llama_free_model(model) }
            self?.contextPointer = nil
            self?.modelPointer = nil
        }
        methodChannel?.setMethodCallHandler(nil)
    }

    // MARK: - Stream Handler

    class StreamHandler: NSObject, FlutterStreamHandler {
        weak var plugin: LlmPlugin?

        init(plugin: LlmPlugin) {
            self.plugin = plugin
        }

        func onListen(
            withArguments arguments: Any?,
            eventSink events: @escaping FlutterEventSink
        ) -> FlutterError? {
            plugin?.eventSink = events
            return nil
        }

        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.eventSink = nil
            return nil
        }
    }
}
