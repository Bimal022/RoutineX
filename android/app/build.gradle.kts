import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyStoreProperties = Properties()
val keyStorePropertiesFile = rootProject.file("key.properties")

if (keyStorePropertiesFile.exists()) {
    keyStoreProperties.load(FileInputStream(keyStorePropertiesFile))
}

android {
    namespace = "com.example.routinex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bimal.routinex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
    create("release") {
        keyAlias = keyStoreProperties["keyAlias"] as String
        keyPassword = keyStoreProperties["keyPassword"] as String
        storeFile = file(keyStoreProperties["storeFile"] as String)
        storePassword = keyStoreProperties["storePassword"] as String
    }
}
    buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
}

flutter {
    source = "../.."
}
