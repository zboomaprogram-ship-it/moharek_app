import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
    }
}

// ── Load per-flavor keystore properties ──────────────────────────────────────
// Moharek uses android/key.properties (alias: upload, file: upload-keystore.jks)
// Rabhan uses android/key-rabhan.properties (alias: rabhan, file: rabhan-keystore.jks)
// Both files are gitignored — never commit keystores or key.properties files!

val moharekKeystoreFile = rootProject.file("key.properties")
val moharekKeystoreProps = Properties()
if (moharekKeystoreFile.exists()) {
    moharekKeystoreProps.load(moharekKeystoreFile.inputStream())
}

val rabhanKeystoreFile = rootProject.file("key-rabhan.properties")
val rabhanKeystoreProps = Properties()
if (rabhanKeystoreFile.exists()) {
    rabhanKeystoreProps.load(rabhanKeystoreFile.inputStream())
}

android {
    namespace = "com.zbooma.moharek"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Fallback Application ID
        applicationId = "com.zbooma.moharek"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        // Moharek signing (existing upload keystore)
        create("moharekRelease") {
            keyAlias = moharekKeystoreProps["keyAlias"] as String?
            keyPassword = moharekKeystoreProps["keyPassword"] as String?
            storeFile = (moharekKeystoreProps["storeFile"] as String?)?.let { rootProject.file("app/$it") }
            storePassword = moharekKeystoreProps["storePassword"] as String?
        }
        // Rabhan signing (separate keystore — no conflict with Moharek Play Console)
        create("rabhanRelease") {
            keyAlias = rabhanKeystoreProps["keyAlias"] as String?
            keyPassword = rabhanKeystoreProps["keyPassword"] as String?
            storeFile = (rabhanKeystoreProps["storeFile"] as String?)?.let { rootProject.file("app/$it") }
            storePassword = rabhanKeystoreProps["storePassword"] as String?
        }
    }

    flavorDimensions.add("app")

    productFlavors {
        create("moharek") {
            dimension = "app"
            applicationId = "com.zbooma.moharek"
            manifestPlaceholders["appName"] = "Moharek"
            if (moharekKeystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("moharekRelease")
            }
        }
        create("rabhan") {
            dimension = "app"
            applicationId = "com.zbooma.rabhan"
            manifestPlaceholders["appName"] = "ربحان"
            if (rabhanKeystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("rabhanRelease")
            }
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            pickFirsts += "lib/x86/libc++_shared.so"
            pickFirsts += "lib/x86_64/libc++_shared.so"
            pickFirsts += "lib/armeabi-v7a/libc++_shared.so"
            pickFirsts += "lib/arm64-v8a/libc++_shared.so"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
