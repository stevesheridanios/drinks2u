plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Google Services for Firebase (must be after Flutter plugin)
    id("com.google.gms.google-services")
}

// NEW: Import for Properties class
import java.util.Properties

// Load keystore properties from key.properties file (Kotlin DSL syntax)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.stevesheridanios.danfels" // Updated to match applicationId for consistency
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID .
        applicationId = "com.stevesheridanios.danfels"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode // Auto-pulls from pubspec.yaml (increment +BUILD there)
        versionName = flutter.versionName // Auto-pulls from pubspec.yaml (MAJOR.MINOR.PATCH)
    }

    signingConfigs {
        create("release") {
            // Signing config for release builds using keystore
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = if (keystoreProperties.containsKey("storeFile")) {
                file(keystoreProperties.getProperty("storeFile"))
            } else {
                null
            }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        getByName("release") {
            // Use the release signing config (requires key.properties)
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}