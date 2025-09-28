plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yuluo.kissu"
    compileSdk = 36  // Android 16 (API 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 解决资源链接问题
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }

    // 添加资源配置
    androidResources {
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~"
        // 禁用资源验证以避免lStar属性错误
        additionalParameters("--allow-reserved-package-id", "--no-version-vectors")
    }

    defaultConfig {
        applicationId = "com.yuluo.kissu"
        minSdk = 24  // 符合Flutter最新要求的最小SDK版本
        targetSdk = 36  // Android 16 (API 36)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 友盟分享配置
        manifestPlaceholders["UMENG_APPKEY"] = "6879fbe579267e0210b67be9"
        manifestPlaceholders["UMENG_CHANNEL"] = "Umeng"
        manifestPlaceholders["WECHAT_APPID"] = "wxca15128b8c388c13"
        manifestPlaceholders["qqappid"] = "102797447"
        
        // OpenInstall配置
        manifestPlaceholders["OPENINSTALL_APPKEY"] = "eb24o3"

        // 只支持arm64-v8a架构
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
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
            isMinifyEnabled = false  // 关闭代码混淆
            isShrinkResources = false  // 关闭资源收缩
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
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
    // 使用与原生项目相同的腾讯SDK版本（已复制）
    implementation(files("../libs/Android/share/share_android_7.3.7/platforms/qq/libs/open_sdk_3.5.17.3_r75955a58_lite.jar"))
    
    // Android 基础依赖 - 更新到支持新SDK的版本
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    
    // 添加Material Design组件支持新的lStar属性
    implementation("com.google.android.material:material:1.12.0")
    
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // 支付宝支付SDK
    implementation("com.alipay.sdk:alipaysdk-android:15.8.11")
    
    // 微信支付SDK
    implementation("com.tencent.mm.opensdk:wechat-sdk-android:6.8.0")
    
    // 高德地图和定位SDK
    implementation("com.amap.api:location:5.6.0")
    implementation("com.amap.api:3dmap:8.1.0")
}
