plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yuluo.kissu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yuluo.kissu"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 友盟分享配置
        manifestPlaceholders["UMENG_APPKEY"] = "6879fbe579267e0210b67be9"
        manifestPlaceholders["UMENG_CHANNEL"] = "Umeng"
        manifestPlaceholders["WECHAT_APPID"] = "wxca15128b8c388c13"
        manifestPlaceholders["qqappid"] = "102797447"
    }

    signingConfigs {
        create("release") {
            storeFile = file("kissu1.keystore")
            storePassword = "111111"
            keyAlias = "kissu"
            keyPassword = "111111"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
    // 使用稳定版本组合 (JPush 5.7.0 + JCore 4.9.1)
    force("cn.jiguang.sdk:jpush:5.7.0")
    force("cn.jiguang.sdk:jcore:4.9.1")
    }
}

dependencies {
    // JPush 核心依赖 - 使用与Flutter插件匹配的版本
    implementation("cn.jiguang.sdk:jpush:5.8.0")
    implementation("cn.jiguang.sdk:jcore:2.9.7")
    
    // 友盟本地SDK依赖
    // 友盟基础组件
    implementation(files("../libs/Android/common/common_android_9.8.8/umeng-common-9.8.8.aar"))
    implementation(files("../libs/Android/common/common_android_9.8.8/umeng-asms-v1.8.7.aar"))
    
    // 友盟分享核心
    implementation(files("../libs/Android/share/share_android_7.3.7/main/libs/umeng-share-core-7.3.7.jar"))
    implementation(files("../libs/Android/share/share_android_7.3.7/main/libs/umeng-sharetool-7.3.7.jar"))
    
    // 微信分享
    implementation(files("../libs/Android/share/share_android_7.3.7/platforms/wechat/libs/umeng-share-wechat-full-7.3.7.jar"))
    
    // QQ分享
    implementation(files("../libs/Android/share/share_android_7.3.7/platforms/qq/libs/umeng-share-QQ-full-7.3.7.jar"))
    implementation(files("../libs/Android/share/share_android_7.3.7/platforms/qq/libs/open_sdk_3.5.16.4_r8c01346_lite.jar"))
    
    // Android 基础依赖
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
