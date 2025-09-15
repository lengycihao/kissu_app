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
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
