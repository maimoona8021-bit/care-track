plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sehatfile"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // =====================================================
    // JAVA + DESUGARING
    // Required for scheduled local notifications
    // =====================================================
    compileOptions {
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // =====================================================
    // DEFAULT CONFIG
    // =====================================================
    defaultConfig {
        applicationId = "com.example.sehatfile"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Allows larger dependency sets if required
        multiDexEnabled = true
    }

    // =====================================================
    // BUILD TYPES
    // =====================================================
    buildTypes {
        release {
            // Using debug signing for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// =========================================================
// KOTLIN
// =========================================================
kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// =========================================================
// FLUTTER
// =========================================================
flutter {
    source = "../.."
}

// =========================================================
// DEPENDENCIES
// Required by flutter_local_notifications
// =========================================================
dependencies {
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.4"
    )
}