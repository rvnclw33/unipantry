buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 1. Android Gradle Plugin
        // This version must match your Gradle wrapper. 
        // If you are using Gradle 8.x, this should be 8.1.0 or higher.
        classpath("com.android.tools.build:gradle:8.6.0")

        // 2. Google Services Plugin
        // We explicitly use 4.3.15 here to match the version your system is "stuck" on.
        // This fixes the "already on the classpath" error.
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
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