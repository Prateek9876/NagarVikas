plugins {
    // Apply common plugins if needed (kept minimal for easy deployment)
    base
}

allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal() // added for future plugin flexibility
    }
}

// Centralized build directory outside module dirs
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // Assign subproject-specific build dirs
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    // Ensure :app is always evaluated first (kept from original)
    evaluationDependsOn(":app")

    // Common configuration across subprojects (future-proofing)
    tasks.withType<JavaCompile> {
        options.encoding = "UTF-8"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
