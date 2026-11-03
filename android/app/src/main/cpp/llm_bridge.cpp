#include <jni.h>
#include <string>
#include <vector>
#include <atomic>
#include <algorithm>
#include <android/log.h>

#include "llama.h"

#define LOG_TAG "CiteCoachLLM"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ============================================================
// Batch helpers (inlined from common.h since we only link llama/ggml)
// ============================================================

static void batch_clear(llama_batch & batch) {
    batch.n_tokens = 0;
}

static void batch_add(llama_batch & batch, llama_token id, llama_pos pos,
                      const std::vector<llama_seq_id> & seq_ids, bool logits) {
    batch.token   [batch.n_tokens] = id;
    batch.pos     [batch.n_tokens] = pos;
    batch.n_seq_id[batch.n_tokens] = (int32_t) seq_ids.size();
    for (size_t j = 0; j < seq_ids.size(); j++) {
        batch.seq_id[batch.n_tokens][j] = seq_ids[j];
    }
    batch.logits  [batch.n_tokens] = logits;
    batch.n_tokens++;
}

// ============================================================
// JNI Bridge: Kotlin LlmPlugin <-> llama.cpp
// ============================================================

static std::atomic<bool> stop_requested{false};
static void inference_error(JNIEnv *env, const char *message) {
    env->ThrowNew(env->FindClass("java/lang/IllegalStateException"), message);
}

extern "C" {
JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeResetCancellation(JNIEnv *, jobject) {
    stop_requested.store(false);
}

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeStopGeneration(JNIEnv *, jobject) {
    stop_requested.store(true);
}

// ---- Model Loading ----

JNIEXPORT jlong JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeLoadModel(
    JNIEnv *env, jobject thiz, jstring model_path) {

    const char *path = env->GetStringUTFChars(model_path, nullptr);
    LOGI("Loading model from: %s", path);

    // Initialize llama backend
    llama_backend_init();

    // Configure model parameters
    auto model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0; // CPU only on Android

    // Load the model
    llama_model *model = llama_model_load_from_file(path, model_params);
    env->ReleaseStringUTFChars(model_path, path);

    if (model == nullptr) {
        LOGE("Failed to load model");
        return 0;
    }

    LOGI("Model loaded successfully");
    return reinterpret_cast<jlong>(model);
}

// ---- Context Creation ----

JNIEXPORT jlong JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeCreateContext(
    JNIEnv *env, jobject thiz, jlong model_handle, jint context_size) {

    auto *model = reinterpret_cast<llama_model *>(model_handle);
    if (model == nullptr) {
        LOGE("Model handle is null");
        return 0;
    }

    auto ctx_params = llama_context_default_params();
    ctx_params.n_ctx = context_size;
    ctx_params.n_threads = 4;  // Use 4 threads for mobile
    ctx_params.n_threads_batch = 4;
    ctx_params.n_batch = 256;

    llama_context *ctx = llama_init_from_model(model, ctx_params);
    if (ctx == nullptr) {
        LOGE("Failed to create context");
        return 0;
    }

    LOGI("Context created (size=%d)", context_size);
    return reinterpret_cast<jlong>(ctx);
}

// ---- Text Generation ----

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeGenerate(
    JNIEnv *env, jobject thiz,
    jlong context_handle, jstring prompt_str,
    jint max_tokens, jfloat temperature, jfloat top_p,
    jfloat repeat_penalty, jobject token_callback) {

    auto *ctx = reinterpret_cast<llama_context *>(context_handle);
    if (ctx == nullptr) {
        LOGE("Context handle is null");
        return;
    }

    const llama_model *model = llama_get_model(ctx);
    const llama_vocab *vocab = llama_model_get_vocab(model);

    const char *prompt_cstr = env->GetStringUTFChars(prompt_str, nullptr);
    std::string prompt(prompt_cstr);
    env->ReleaseStringUTFChars(prompt_str, prompt_cstr);

    LOGI("Generating response (prompt length=%zu, max_tokens=%d)", prompt.length(), max_tokens);

    // Tokenize the prompt
    const int n_prompt_max = prompt.length() + 256;
    std::vector<llama_token> tokens(n_prompt_max);
    int n_tokens = llama_tokenize(vocab, prompt.c_str(), prompt.length(),
                                   tokens.data(), n_prompt_max, true, true);
    if (n_tokens < 0) {
        inference_error(env, "Could not tokenize the question. Try a shorter question.");
        return;
    }
    tokens.resize(n_tokens);
    LOGI("Tokenized prompt: %d tokens", n_tokens);

    const int capacity = static_cast<int>(llama_n_ctx(ctx));
    if (n_tokens == 0 || n_tokens + max_tokens >= capacity) {
        inference_error(env, "Question and evidence exceed the model context. Start a new chat or ask a shorter question.");
        return;
    }

    // Clear memory (KV cache)
    llama_memory_clear(llama_get_memory(ctx), true);

    // Process prompt in batches
    llama_batch batch = llama_batch_init(256, 0, 1);

    for (int i = 0; i < n_tokens; i++) {
        if (stop_requested.load()) { llama_batch_free(batch); return; }
        batch_add(batch, tokens[i], i, {0}, false);
        if (batch.n_tokens >= 256 || i == n_tokens - 1) {
            if (i == n_tokens - 1) {
                batch.logits[batch.n_tokens - 1] = true;
            }
            if (llama_decode(ctx, batch) != 0) {
                inference_error(env, "AI could not process document evidence. Try a shorter question.");
                llama_batch_free(batch);
                return;
            }
            batch_clear(batch);
        }
    }

    // Get callback method
    jclass callbackClass = env->GetObjectClass(token_callback);
    jmethodID invokeMethod = env->GetMethodID(callbackClass, "invoke",
        "(Ljava/lang/Object;)Ljava/lang/Object;");

    // Set up sampler
    auto *smpl = llama_sampler_chain_init(llama_sampler_chain_default_params());
    llama_sampler_chain_add(smpl, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(smpl, llama_sampler_init_top_p(top_p, 1));
    llama_sampler_chain_add(smpl, llama_sampler_init_penalties(
        llama_vocab_n_tokens(vocab), 64, repeat_penalty, 0.0f, 0.0f));
    llama_sampler_chain_add(smpl, llama_sampler_init_dist(42));

    // Generate tokens
    int n_generated = 0;
    int n_pos = n_tokens;

    while (n_generated < max_tokens && !stop_requested.load()) {
        // Sample next token
        llama_token new_token = llama_sampler_sample(smpl, ctx, -1);

        // Check for end of generation
        if (llama_vocab_is_eog(vocab, new_token)) {
            LOGI("End of generation token received");
            break;
        }

        // Convert token to text
        char buf[256];
        int n = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, true);
        if (n < 0) {
            LOGE("Failed to convert token to text");
            break;
        }

        std::string token_text(buf, n);

        // Send token to Kotlin callback
        jstring java_token = env->NewStringUTF(token_text.c_str());
        jobject result = env->CallObjectMethod(token_callback, invokeMethod, java_token);
        env->DeleteLocalRef(java_token);

        // Check if callback returned false (stop requested)
        if (result != nullptr) {
            jclass boolClass = env->FindClass("java/lang/Boolean");
            jmethodID boolValue = env->GetMethodID(boolClass, "booleanValue", "()Z");
            jboolean shouldContinue = env->CallBooleanMethod(result, boolValue);
            env->DeleteLocalRef(result);
            env->DeleteLocalRef(boolClass);

            if (!shouldContinue) {
                LOGI("Generation stopped by callback");
                break;
            }
        }

        // Prepare next batch
        batch_clear(batch);
        batch_add(batch, new_token, n_pos, {0}, true);
        n_pos++;

        if (llama_decode(ctx, batch) != 0) {
            LOGE("Failed to decode generated token");
            break;
        }

        n_generated++;
    }

    llama_batch_free(batch);
    llama_sampler_free(smpl);

    LOGI("Generation complete: %d tokens generated", n_generated);
}

// ---- Cleanup ----

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeFreeContext(
    JNIEnv *env, jobject thiz, jlong context_handle) {

    auto *ctx = reinterpret_cast<llama_context *>(context_handle);
    if (ctx != nullptr) {
        llama_free(ctx);
        LOGI("Context freed");
    }
}

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeFreeModel(
    JNIEnv *env, jobject thiz, jlong model_handle) {

    auto *model = reinterpret_cast<llama_model *>(model_handle);
    if (model != nullptr) {
        llama_model_free(model);
        llama_backend_free();
        LOGI("Model freed");
    }
}

} // extern "C"
