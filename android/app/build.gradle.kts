plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Enable Google Services for this module
    id("com.google.gms.google-services")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.unipantry"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // enable core-library desugaring (required by some plugins)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.unipantry"
        minSdk = 23
        // match compileSdk
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // core-library desugaring (required by some plugins/AARs)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Note: Other dependencies from Flutter are added by the Flutter Gradle plugin,
    // so you typically don't need to list firebase/flutter libraries here.
}

flutter {
    source = "../.."
}
