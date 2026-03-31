#include <jni.h>
#include <android/log.h>

#define LOG_TAG "CiteCoachLLM"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Stub implementations when llama.cpp is not available.
// All methods return error states so the Dart side can handle gracefully.

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeLoadModel(
    JNIEnv *env, jobject thiz, jstring model_path) {
    LOGE("llama.cpp not compiled into this build");
    return 0;
}

JNIEXPORT jlong JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeCreateContext(
    JNIEnv *env, jobject thiz, jlong model_handle, jint context_size) {
    return 0;
}

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeGenerate(
    JNIEnv *env, jobject thiz,
    jlong context_handle, jstring prompt_str,
    jint max_tokens, jfloat temperature, jfloat top_p,
    jfloat repeat_penalty, jobject token_callback) {
    LOGE("llama.cpp not compiled into this build");
}

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeFreeContext(
    JNIEnv *env, jobject thiz, jlong context_handle) {}

JNIEXPORT void JNICALL
Java_com_citecoach_citecoach_LlmPlugin_nativeFreeModel(
    JNIEnv *env, jobject thiz, jlong model_handle) {}

} // extern "C"
