# Google ML Kit - optional script recognizers not bundled in this build
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# This callback is called from JNI, outside R8's visible call graph.
-keep interface com.citecoach.citecoach.NativeTokenCallback { *; }
-keep class * implements com.citecoach.citecoach.NativeTokenCallback {
    public boolean onToken(java.lang.String);
}
-keepclasseswithmembers,includedescriptorclasses class com.citecoach.citecoach.LlmPlugin {
    native <methods>;
}
