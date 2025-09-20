allprojects {
    repositories {
        google()
        mavenCentral()
        // JPush 官方仓库 - 必须添加这个仓库
        maven { url = uri("https://repo1.maven.org/maven2/") }
        maven { url = uri("https://oss.sonatype.org/content/repositories/releases/") }
        maven { url = uri("https://developer.huawei.com/repo/") }
        maven { url = uri("https://jitpack.io") }
        // 友盟官方仓库
        maven { 
            url = uri("https://developer.umeng.com/repo/")
            isAllowInsecureProtocol = true
        }
        // 添加阿里云镜像仓库作为备选
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        // 添加JCenter作为备选（JPush可能在这里）
        maven { url = uri("https://jcenter.bintray.com/") }
        // OpenInstall 官方仓库
        maven { url = uri("https://maven.openinstall.io/repository/maven-public/") }
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
                compileSdkVersion(36)  // 使用与主项目相同的版本
                
                defaultConfig {
                    minSdk = 23  // Flutter要求的最小SDK版本
                    targetSdk = 36  // 使用与主项目相同的版本
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
