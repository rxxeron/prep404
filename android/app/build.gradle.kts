import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rxxxeron.prep404"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.16248370"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rxxxeron.prep404"
        manifestPlaceholders["authRedirectScheme"] = "com.rxxxeron.prep404"
        manifestPlaceholders["authRedirectHost"] = "login-callback"
        manifestPlaceholders["googleAndroidClientId"] =
            "560610133772-03ij6u6cqo2pk1t2tbjvmpqrl79md609.apps.googleusercontent.com"
        manifestPlaceholders["allowBackup"] = "true"
        // Plain-HTTP traffic is allowed only in debug builds (local API on 10.0.2.2).
        manifestPlaceholders["usesCleartextTraffic"] = "false"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let {
                val f = file(it)
                if (f.exists()) f else rootProject.file(it)
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        debug {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            // Releases are signed only with the upload key. Without
            // key.properties the release guard below stops the build instead of
            // silently signing with the debug key.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Release guard: a release must call real HTTPS/WSS servers and be signed with
// the upload key. Without it, AppConfig falls back to 10.0.2.2 / localhost and
// the shipped app silently has no backend.
val releaseDartDefines: Map<String, String> = run {
    val raw = project.findProperty("dart-defines") as? String ?: return@run emptyMap()
    val map = mutableMapOf<String, String>()
    for (encoded in raw.split(",")) {
        if (encoded.isBlank()) continue
        try {
            val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            val separator = decoded.indexOf('=')
            if (separator > 0) {
                map[decoded.substring(0, separator)] = decoded.substring(separator + 1)
            }
        } catch (_: Exception) {}
    }
    map
}

tasks.matching { Regex("pre\\w*ReleaseBuild").matches(it.name) }.configureEach {
    doFirst {
        val problems = mutableListOf<String>()
        if (!keystorePropertiesFile.exists()) {
            problems += "android/key.properties is missing, so the release cannot be signed with the upload key."
        }
        val api = releaseDartDefines["API_BASE_URL"] ?: releaseDartDefines["API_HOST"]
        if (api.isNullOrBlank() || !api.startsWith("https://")) {
            problems += "Pass --dart-define=API_HOST=https://<api host> (or API_BASE_URL=https://<api host>/api/v1)."
        }
        val ws = releaseDartDefines["WS_BATTLE_URL"]
        if (ws.isNullOrBlank() || !ws.startsWith("wss://")) {
            problems += "Pass --dart-define=WS_BATTLE_URL=wss://<api host>/ws/battle."
        }
        if (problems.isNotEmpty()) {
            throw GradleException("Release build blocked:\n - " + problems.joinToString("\n - "))
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
