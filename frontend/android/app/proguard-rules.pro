# ========================================================
# STARS HOMES - Proguard / R8 Keep Rules for Android
# ========================================================

-dontwarn com.google.android.play.core.**
-dontwarn **

# Flutter core and plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Pigeon generated classes for shared_preferences_android
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.shared_preferences_android.** { *; }

# Keep required Kotlin and coroutine hooks used by Pigeon/Datastore reflection
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep printing & pdf
-keep class net.nfet.flutter.printing.** { *; }

