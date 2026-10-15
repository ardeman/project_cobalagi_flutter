import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Google Play, kept out of git (see README → Release).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.ardeman.cobalagi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.ardeman.cobalagi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("upload") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Without android/key.properties, release builds are debug-signed:
            // fine for local testing, rejected by Google Play.
            signingConfig = signingConfigs.findByName("upload")
                ?: signingConfigs.getByName("debug")
        }
    }
}

// GitHub Releases' APKs (tool/release_apks.sh sets COBALAGI_GITHUB_APK=1):
// any APK of a newer release must install over any APK of an older one, even
// switching between the universal APK and one for a single architecture.
// Flutter numbers split APKs 1000 × architecture + build and the universal
// one just build, so arm64 build 19 (2019) would refuse universal build 20.
// Here the build comes first: 100000 + build × 10 + architecture, above every
// code published before. Google Play's App Bundle keeps the plain build.
if (System.getenv("COBALAGI_GITHUB_APK") == "1") {
    @Suppress("DEPRECATION")
    android.applicationVariants.all {
        val build = versionCode
        outputs.all {
            val output = this as com.android.build.gradle.api.ApkVariantOutput
            val architecture = when (
                output.getFilter(com.android.build.VariantOutput.FilterType.ABI)
            ) {
                "armeabi-v7a" -> 1
                "arm64-v8a" -> 2
                "x86_64" -> 4
                else -> 0
            }
            output.versionCodeOverride = 100_000 + build * 10 + architecture
        }
    }
}

flutter {
    source = "../.."
}

// Never ship the macOS test voices from tool/test_voices.dart.
val testVoices = rootProject.file("../assets/audio/TEST_VOICES")
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        if (testVoices.exists()) {
            throw GradleException(
                "assets/audio/ holds macOS test voices, which must not be released. " +
                    "Run: dart run tool/test_voices.dart --clean",
            )
        }
    }
}
