// 配置 buildscript 仓库（用于插件和构建工具）
buildscript {
    repositories {
        // 优先使用阿里云镜像仓库，避免TLS连接问题
        maven { 
            url = uri("https://maven.aliyun.com/repository/public")
            isAllowInsecureProtocol = false
        }
        maven { 
            url = uri("https://maven.aliyun.com/repository/google")
            isAllowInsecureProtocol = false
        }
        maven { 
            url = uri("https://maven.aliyun.com/repository/jcenter")
            isAllowInsecureProtocol = false
        }
        maven { 
            url = uri("https://maven.aliyun.com/repository/gradle-plugin")
            isAllowInsecureProtocol = false
        }
        
        // 腾讯云镜像作为备选
        maven { 
            url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
            isAllowInsecureProtocol = false
        }
        
        // 荣耀推送插件仓库
        maven { url = uri("https://developer.hihonor.com/repo/") }
        
        // Maven Central
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        // Android Gradle Plugin（供 AGConnect 插件依赖检查）
        classpath("com.android.tools.build:gradle:8.6.1")
        // 华为 AGConnect 配置插件（用于 agconnect-services.json）
        classpath("com.huawei.agconnect:agcp:1.9.1.301")
        // 荣耀推送插件（腾讯IM离线推送需要）
        classpath("com.hihonor.mcs:asplugin:2.0.1.300")
    }
}

allprojects {
    repositories {
        // 先使用 JitPack（提供 com.github.gzu-liyujiang:Android_CN_OAID:4.2.9）
        maven { url = uri("https://jitpack.io") }

        // 优先使用阿里云镜像仓库，避免TLS连接问题
        maven { 
            url = uri("https://maven.aliyun.com/repository/public")
            isAllowInsecureProtocol = false
        }
        maven { 
            url = uri("https://maven.aliyun.com/repository/google")
            isAllowInsecureProtocol = false
        }
        maven { 
            url = uri("https://maven.aliyun.com/repository/jcenter")
            isAllowInsecureProtocol = false
        }
        
        // 使用腾讯云镜像作为备选（也包含Google Maven内容）
        maven { 
            url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
            isAllowInsecureProtocol = false
        }
        
        // Maven Central（不包含Google内容，但作为通用备选）
        mavenCentral()
        
        // JPush 官方仓库
        maven { url = uri("https://repo1.maven.org/maven2/") }
        maven { url = uri("https://oss.sonatype.org/content/repositories/releases/") }
        
        // 华为 & 荣耀 OAID 依赖库（用于 flutter_android_oaid_plugin）
        maven { url = uri("https://developer.huawei.com/repo/") }
        maven { url = uri("https://developer.hihonor.com/repo/") }
        
        // OpenInstall 官方仓库
        maven { url = uri("https://maven.openinstall.io/repository/maven-public/") }
        
        //巨量（使用mavenPom避免Gradle Module Metadata导致的API可见性限制）
        maven {
            url = uri("https://artifact.bytedance.com/repository/Volcengine/")
            metadataSources {
                mavenPom()
                artifact()
            }
        }
        // 友盟官方仓库 - 完全移除，因为POM文件格式有问题
        // maven { 
        //     url = uri("https://developer.umeng.com/repo/")
        //     isAllowInsecureProtocol = true
        // }
    }
}

configurations.all {
    resolutionStrategy {
        force("net.bytebuddy:byte-buddy:1.12.23")
    }
}


val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // 强制所有子项目使用兼容的Android SDK配置
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)  // Android 16 (API 36)
                
                defaultConfig {
                    minSdkVersion(24)    // 符合Flutter最新要求的最小SDK版本
                    targetSdkVersion(36) // Android 16 (API 36)
                }
            }
        }
    }
}
subprojects {
    if (path != ":app") {
        evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
