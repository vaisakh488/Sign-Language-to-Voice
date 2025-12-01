plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sign_language_app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sign_language_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

        buildTypes {
        getByName("release") {
            // Disable shrinking/obfuscation (quick fix)
            isMinifyEnabled = false
            isShrinkResources = false

            // If you want to enable shrinking later, keep TFLite classes
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }

        getByName("debug") {
            // Usually debug doesn't shrink
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // FIXED: Kotlin DSL syntax for aaptOptions
    androidResources {
        noCompress += listOf("tflite", "lite")
    }
}

dependencies {
    // FIXED: Kotlin DSL syntax - use parentheses instead of quotes
    implementation("org.tensorflow:tensorflow-lite:2.8.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.8.0")
}

flutter {
    source = "../.."
}
