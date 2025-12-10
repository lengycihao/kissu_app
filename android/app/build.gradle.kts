plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 华为 AGConnect 插件，读取 agconnect-services.json
    id("com.huawei.agconnect")
}

// 添加本地 AAR 仓库
repositories {
    flatDir {
        dirs("../libs")
    }
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

    // Lint 配置：忽略缺失类错误
    lint {
        checkReleaseBuilds = false
        abortOnError = false
        disable += setOf("MissingClass")
    }

    // 解决资源链接问题
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc++_shared.so")
        
        // 保留所有架构的 .so 文件以支持多架构打包
        // 不再排除任何架构
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
        manifestPlaceholders["UMENG_APPKEY"] = "6879fba679267e0210b67bde"
        manifestPlaceholders["UMENG_CHANNEL"] = "Umeng"
        manifestPlaceholders["WECHAT_APPID"] = "wxca15128b8c388c13"
        manifestPlaceholders["qqappid"] = "102797447"
        
        // OpenInstall配置
        manifestPlaceholders["OPENINSTALL_APPKEY"] = "eb24o3"

        // 极光厂商通道（除华为/荣耀，华为需 agconnect-services.json 后再接入）
        // 小米
        manifestPlaceholders["JPUSH_MI_APPID"] = "2882303761520437827"
        manifestPlaceholders["JPUSH_MI_APPKEY"] = "45ID1Ha8xH5MAzDuhT8zug=="
        // OPPO
        manifestPlaceholders["JPUSH_OPPO_APPID"] = "35641549"
        manifestPlaceholders["JPUSH_OPPO_APPKEY"] = "40e53bd9fd784f50870afa706892f7c0"
        manifestPlaceholders["JPUSH_OPPO_APPSECRET"] = "e879a0c19584495a8b014665b03d30da"
        // vivo
        manifestPlaceholders["JPUSH_VIVO_APPID"] = "105947238"
        manifestPlaceholders["JPUSH_VIVO_APPKEY"] = "fa541d6f32b359e1d8c34d99e2d6d07a"
        manifestPlaceholders["JPUSH_VIVO_APPSECRET"] = "187e2978-7d42-43ea-9ad5-5f26a0db7151"
        // 魅族
        manifestPlaceholders["JPUSH_MEIZU_APPID"] = "156177"
        manifestPlaceholders["JPUSH_MEIZU_APPKEY"] = "c4e0fad84dec44f7b77408012ad62149"
    }


    signingConfigs {
        val releaseKeystore = file("kissu1.keystore")
        if (releaseKeystore.exists()) {
            create("release") {
                storeFile = releaseKeystore
                storePassword = "111111"
                keyAlias = "kissu"
                keyPassword = "111111"
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // 如果本地存在正式签名文件，则复用；否则使用系统默认 debug 签名
            signingConfigs.findByName("release")?.let { signingConfig = it }
            isMinifyEnabled = false
        }
        getByName("release") {
            signingConfigs.findByName("release")?.let { signingConfig = it }
            isMinifyEnabled = true  // 开启代码混淆优化性能
            isShrinkResources = true  // 开启资源收缩减小包体积
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
        // 已改用本地极光推送SDK，不再需要强制版本
        // force("cn.jiguang.sdk:jpush:5.7.0")
        // force("cn.jiguang.sdk:jcore:4.9.1")
    }

    // 排除 flutter_android_oaid_plugin 里远程引入的 OAID 依赖，避免和本地 AAR 重复
    exclude(group = "com.github.gzu-liyujiang", module = "Android_CN_OAID")
    
    // 排除 jpush_flutter 插件传递引入的远程极光推送SDK，使用本地SDK
    exclude(group = "cn.jiguang.sdk", module = "jpush")
    exclude(group = "cn.jiguang.sdk", module = "jcore")
    exclude(group = "cn.jiguang.sdk", module = "jpush-xiaomi")
    exclude(group = "cn.jiguang.sdk", module = "jpush-oppo")
    exclude(group = "cn.jiguang.sdk", module = "jpush-vivo")
    exclude(group = "cn.jiguang.sdk", module = "jpush-meizu")
    exclude(group = "cn.jiguang.sdk", module = "jpush-huawei")
    exclude(group = "cn.jiguang.sdk", module = "jpush-honor")
    
    // 🎯 已移除：不再排除高德地图SDK，因为已改回分离版本（3dmap + location）
    // exclude(group = "com.amap.api", module = "3dmap")
    // exclude(group = "com.amap.api", module = "location")
    // exclude(group = "com.amap.api", module = "search")
}

dependencies {
    // 华为推送依赖（供极光华为通道使用）
    implementation("com.huawei.hms:push:6.12.0.300")
    // ================= 极光推送本地SDK依赖 =================
    // JPush 核心依赖 - 使用本地文件
    implementation(files("../libs/jiguang/libs/jcore-android-5.2.2.aar"))
    implementation(files("../libs/jiguang/libs/jpush-android-5.9.0.jar"))
    
    // 极光推送厂商通道插件（SDK 5.0+ 需要单独引入）
    // 小米推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-xiaomi-v5.9.0.jar"))
    implementation(files("../libs/jiguang/libs/MiPush_SDK_Client_6_0_1-C.jar"))
    // OPPO推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-oppo-v5.9.0.jar"))
    implementation(files("../libs/jiguang/libs/com.heytap.msp_V3.7.1.aar"))
    // vivo推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-vivo-v5.9.0.jar"))
    implementation(files("../libs/jiguang/libs/push_sdk_v4.1.0.0_510.jar"))
    implementation(files("../libs/jiguang/libs/push-internal-5.0.5.aar"))
    // 魅族推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-meizu-v5.9.0.jar"))
    // 华为推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-huawei-v5.9.0.jar"))
    implementation(files("../libs/jiguang/libs/HiPushSDK-8.0.12.307.aar"))
    // 荣耀推送通道
    implementation(files("../libs/jiguang/libs/jpush-android-plugin-honor-v5.9.0.jar"))
    // ================= 极光推送本地SDK依赖结束 =================
    
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

    // WorkManager：用于服务被杀后的兜底重启
    implementation("androidx.work:work-runtime-ktx:2.9.1")
    
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // 支付宝支付SDK
    implementation("com.alipay.sdk:alipaysdk-android:15.8.11")
    
    // 微信支付SDK
    implementation("com.tencent.mm.opensdk:wechat-sdk-android:6.8.0")
    // 高德地图和定位SDK - 使用与 feature_4.0 相同的版本，确保自定义 InfoWindow 正常工作
    // 📝 注意：3dmap-location-search:latest.integration 版本可能不兼容自定义 InfoWindow
    implementation("com.amap.api:location:5.6.0")
    implementation("com.amap.api:3dmap:8.1.0")
    // implementation("com.amap.api:3dmap-location-search:latest.integration") // 已禁用：此版本不兼容自定义 InfoWindow

    // 本地 OAID SDK（替代远程 com.github.gzu-liyujiang:Android_CN_OAID:4.2.9）
    implementation(files("../libs/Android_CN_OAID-4.2.9.aar"))
}
