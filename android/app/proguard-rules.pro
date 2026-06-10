# Standard Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / PostgREST models
# We keep models to ensure JSON serialization/deserialization works after obfuscation
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# OneSignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Core (Fixes R8 missing class errors)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.android.gms.common.**

# Flutter Callkit Incoming
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
