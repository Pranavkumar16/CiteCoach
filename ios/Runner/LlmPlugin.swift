import Flutter
import Foundation

/// Native LLM inference plugin using llama.cpp for iOS.
///
/// Uses llama.cpp C API directly via the bridging header.
/// Metal GPU acceleration is enabled when available.
///
class LlmPlugin: NSObject {

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    // Model state (opaque pointers to llama.cpp structs)
    private var model: OpaquePointer?
    private var ctx: OpaquePointer?

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
                "name": "Gemma 2B Instruct",
                "quantization": "Q4_K_M",
                "parameters": "2B",
                "isLoaded": model != nil
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

            // Initialize llama.cpp backend
            llama_backend_init()

            // Configure model parameters with Metal GPU acceleration
            var modelParams = llama_model_default_params()
            modelParams.n_gpu_layers = 99 // Offload all layers to Metal GPU

            // Load the model
            guard let loadedModel = llama_model_load_from_file(modelPath, modelParams) else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "LOAD_FAILED",
                        message: "Failed to load model from: \(modelPath)",
                        details: nil
                    ))
                }
                return
            }
            self.model = loadedModel

            // Create inference context
            var ctxParams = llama_context_default_params()
            ctxParams.n_ctx = 2048
            ctxParams.n_threads = UInt32(min(ProcessInfo.processInfo.activeProcessorCount, 4))
            ctxParams.n_batch = 512

            guard let context = llama_init_from_model(loadedModel, ctxParams) else {
                llama_model_free(loadedModel)
                self.model = nil
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "CONTEXT_FAILED",
                        message: "Failed to create inference context",
                        details: nil
                    ))
                }
                return
            }
            self.ctx = context

            DispatchQueue.main.async {
                result(true)
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
        guard let model = self.model, let ctx = self.ctx else {
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
        result(nil) // Acknowledge start, tokens come via EventChannel

        inferenceQueue.async { [weak self] in
            guard let self = self else { return }
            defer { self.isGenerating = false }

            let vocab = llama_model_get_vocab(model)

            // Tokenize the prompt
            let promptCStr = prompt.cString(using: .utf8)!
            let nPromptMax = Int32(prompt.utf8.count + 256)
            var tokens = [llama_token](repeating: 0, count: Int(nPromptMax))
            let nTokens = llama_tokenize(vocab, promptCStr, Int32(promptCStr.count - 1),
                                          &tokens, nPromptMax, true, true)

            if nTokens < 0 {
                DispatchQueue.main.async {
                    self.eventSink?("[ERROR]Failed to tokenize prompt")
                }
                return
            }
            tokens = Array(tokens.prefix(Int(nTokens)))

            // Clear KV cache
            llama_kv_cache_clear(ctx)

            // Process prompt in batches
            var batch = llama_batch_init(512, 0, 1)

            for i in 0..<Int(nTokens) {
                llama_batch_add(&batch, tokens[i], Int32(i), [0], false)
                if batch.n_tokens >= 512 || i == Int(nTokens) - 1 {
                    if i == Int(nTokens) - 1 {
                        batch.logits[Int(batch.n_tokens) - 1] = 1 // true
                    }
                    if llama_decode(ctx, batch) != 0 {
                        DispatchQueue.main.async {
                            self.eventSink?("[ERROR]Failed to decode prompt")
                        }
                        llama_batch_free(batch)
                        return
                    }
                    llama_batch_clear(&batch)
                }
            }

            // Set up sampler chain
            let smpl = llama_sampler_chain_init(llama_sampler_chain_default_params())!
            llama_sampler_chain_add(smpl, llama_sampler_init_temp(temperature))
            llama_sampler_chain_add(smpl, llama_sampler_init_top_p(topP, 1))
            llama_sampler_chain_add(smpl, llama_sampler_init_penalties(
                64, repeatPenalty, 0.0, 0.0))
            llama_sampler_chain_add(smpl, llama_sampler_init_dist(42))

            // Generate tokens
            var nGenerated = 0
            var nPos = Int32(nTokens)

            while nGenerated < maxTokens {
                if self.shouldStop { break }

                // Sample next token
                let newToken = llama_sampler_sample(smpl, ctx, -1)

                // Check for end of generation
                if llama_vocab_is_eog(vocab, newToken) {
                    break
                }

                // Convert token to text
                var buf = [CChar](repeating: 0, count: 256)
                let n = llama_token_to_piece(vocab, newToken, &buf, 256, 0, true)
                if n < 0 {
                    break
                }

                let tokenText = String(cString: buf)

                // Send token to Flutter via EventChannel
                DispatchQueue.main.async {
                    self.eventSink?(tokenText)
                }

                // Prepare next batch
                llama_batch_clear(&batch)
                llama_batch_add(&batch, newToken, nPos, [0], true)
                nPos += 1

                if llama_decode(ctx, batch) != 0 {
                    DispatchQueue.main.async {
                        self.eventSink?("[ERROR]Failed to decode token")
                    }
                    break
                }

                nGenerated += 1
            }

            llama_batch_free(batch)
            llama_sampler_free(smpl)

            // Signal completion
            DispatchQueue.main.async {
                self.eventSink?("[DONE]")
            }
        }
    }

    // MARK: - Model Unloading

    private func unloadModel(result: @escaping FlutterResult) {
        inferenceQueue.async { [weak self] in
            guard let self = self else { return }

            if let ctx = self.ctx {
                llama_free(ctx)
            }
            if let model = self.model {
                llama_model_free(model)
                llama_backend_free()
            }

            self.ctx = nil
            self.model = nil

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
            "models/gemma-2b-it-q4"
        ).path
    }

    func dispose() {
        shouldStop = true
        inferenceQueue.async { [weak self] in
            if let ctx = self?.ctx { llama_free(ctx) }
            if let model = self?.model {
                llama_model_free(model)
                llama_backend_free()
            }
            self?.ctx = nil
            self?.model = nil
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
