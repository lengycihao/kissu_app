allprojects {
    repositories {
        // 优先使用Google和Maven Central，确保基础依赖能正常下载
        google()
        mavenCentral()
        
        // 添加阿里云镜像仓库作为主要备选
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        
        // JPush 官方仓库
        maven { url = uri("https://repo1.maven.org/maven2/") }
        maven { url = uri("https://oss.sonatype.org/content/repositories/releases/") }
        maven { url = uri("https://developer.huawei.com/repo/") }
        maven { url = uri("https://jitpack.io") }
        
        // OpenInstall 官方仓库
        maven { url = uri("https://maven.openinstall.io/repository/maven-public/") }
        
        // 友盟官方仓库 - 完全移除，因为POM文件格式有问题
        // maven { 
        //     url = uri("https://developer.umeng.com/repo/")
        //     isAllowInsecureProtocol = true
        // }
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
                    minSdk = 24  // 符合Flutter最新要求的最小SDK版本
                    targetSdk = 36  // Android 16 (API 36)
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
