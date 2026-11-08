import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

// AdMob ID는 GitHub Secrets → 워크플로 환경 변수로 들어온다. 없으면 Google 테스트 광고 ID를 쓴다.
val testAppId = "ca-app-pub-3940256099942544~3347511713"
val testRewardedId = "ca-app-pub-3940256099942544/5224354917"
val admobAppId = System.getenv("ADMOB_APP_ID")?.takeIf { it.isNotBlank() } ?: testAppId
val admobRewardedId = System.getenv("ADMOB_REWARDED_ID")?.takeIf { it.isNotBlank() } ?: testRewardedId

android {
    namespace = "com.ohsang.util.thousandcranes"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.ohsang.util.thousandcranes"
        minSdk = 26
        targetSdk = 36
        // GitHub Actions에서는 실행 번호가 버전 코드가 된다
        versionCode = System.getenv("VERSION_CODE")?.toIntOrNull() ?: 1
        versionName = "1.0.0"
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    // 업로드 키는 GitHub Secrets → 워크플로가 환경 변수로 넘겨준다
    val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    signingConfigs {
        if (keystorePath != null) {
            create("upload") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: "upload"
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
                    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            // 디버그 빌드는 항상 테스트 광고
            buildConfigField("String", "ADMOB_REWARDED_ID", "\"$testRewardedId\"")
            manifestPlaceholders["admobAppId"] = testAppId
        }
        release {
            if (keystorePath != null) signingConfig = signingConfigs.getByName("upload")
            buildConfigField("String", "ADMOB_REWARDED_ID", "\"$admobRewardedId\"")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    androidResources {
        // woff2 글꼴은 이미 압축돼 있다
        noCompress += listOf("woff2")
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.webkit)
    implementation(libs.play.services.ads)
}
