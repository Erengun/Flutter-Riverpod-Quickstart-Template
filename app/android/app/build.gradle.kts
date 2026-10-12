import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// App identity (application id, flavor suffixes, display names) is read only
// from gradle.properties. Edit the `app.*` keys there, not this file.
fun identity(key: String): String = providers.gradleProperty("app.$key").get()

// Release signing. Each value comes from an environment variable (CI) or else
// from android/key.properties (local, gitignored). With no keystore set,
// release builds are signed with the debug keys, so CI's unsigned builds and
// `flutter run --release` keep working; a store upload needs a real keystore.
//   ANDROID_KEYSTORE_PATH     or key.properties storeFile (relative to android/)
//   ANDROID_KEYSTORE_PASSWORD or key.properties storePassword
//   ANDROID_KEY_ALIAS         or key.properties keyAlias
//   ANDROID_KEY_PASSWORD      or key.properties keyPassword
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(env: String, key: String): String? =
    providers.environmentVariable(env).orNull?.takeIf { it.isNotBlank() }
        ?: keyProperties.getProperty(key)?.takeIf { it.isNotBlank() }

// A path is not checked here: a stale one would stop every Gradle run, debug
// builds and IDE sync included. AGP's validateSigning task fails a release
// build whose keystore is missing.
val releaseKeystore: File? = signingValue("ANDROID_KEYSTORE_PATH", "storeFile")?.let { rootProject.file(it) }

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

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = releaseKeystore
                storePassword = signingValue("ANDROID_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("ANDROID_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("ANDROID_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // The release keystore when one is set (see signingValue above),
            // otherwise the debug keys.
            signingConfig = signingConfigs.getByName(if (releaseKeystore != null) "release" else "debug")
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
