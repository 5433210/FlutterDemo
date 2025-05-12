buildscript {
    repositories {
        gradlePluginPortal()
        google()
        mavenLocal()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://repo.maven.apache.org/maven2") }
        maven { url = uri("https://dl.google.com/dl/android/maven2") }
        maven { url = uri("https://plugins.gradle.org/m2") }
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://jitpack.io") }
    }

    dependencies {
        // These dependencies should be obtained directly from Maven Central instead of Aliyun
        classpath("com.google.j2objc:j2objc-annotations:2.8")
        classpath("org.codehaus.mojo:animal-sniffer-annotations:1.23")
    }
}

allprojects {
    repositories {
        gradlePluginPortal()
        google()
        mavenLocal()
        mavenCentral()
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://repo.maven.apache.org/maven2") }
        maven { url = uri("https://dl.google.com/dl/android/maven2") }
        maven { url = uri("https://plugins.gradle.org/m2") }
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://repo1.maven.org/maven2") } // Maven Central direct URL
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Use layout API to set build directory - modern approach
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Modern approach to declare subproject dependencies
subprojects {
    // Apply evaluation dependency on app
    if (name != "app") {
        evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
