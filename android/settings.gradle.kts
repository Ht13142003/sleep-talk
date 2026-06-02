pluginManagement {
    val flutterSdkPath = run {
        val localPropsFile = file("local.properties")
        if (localPropsFile.exists()) {
            val properties = java.util.Properties()
            localPropsFile.inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")?.let { return@run it }
        }
        // Fallback: try environment variable (common in CI)
        val envSdk = System.getenv("FLUTTER_ROOT")
        if (envSdk != null) return@run envSdk
        // Fallback: try system property
        System.getProperty("flutter.sdk")?.let { return@run it }
        error("Flutter SDK not found. Set flutter.sdk in local.properties or FLUTTER_ROOT environment variable.")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

include(":app")