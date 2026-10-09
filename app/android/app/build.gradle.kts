plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// App identity (application id, flavor suffixes, display names) is read only
// from gradle.properties. Edit the `app.*` keys there, not this file.
fun identity(key: String): String = providers.gradleProperty("app.$key").get()

android {
    namespace = "com.example.temp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Set in gradle.properties (app.applicationId).
        applicationId = identity("applicationId")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // AGP 9 turns resValue off by default; the flavors use it for app_name.
    buildFeatures {
        resValues = true
    }

    flavorDimensions += "env"

    productFlavors {
        listOf("dev", "staging", "prod").forEach { flavor ->
            create(flavor) {
                dimension = "env"
                applicationIdSuffix = identity("$flavor.applicationIdSuffix")
                versionNameSuffix = identity("$flavor.versionNameSuffix")
                resValue("string", "app_name", identity("$flavor.name"))
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
