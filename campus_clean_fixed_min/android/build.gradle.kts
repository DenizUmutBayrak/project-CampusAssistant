allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build dizinini kök dizinin dışına (../../build) taşıyan yapılandırma
val customBuildDir: File = rootProject.projectDir.resolve("../../build")

// Root projenin build dizinini ayarla
rootProject.layout.buildDirectory.set(customBuildDir)

subprojects {
    // Her alt projenin kendi klasörünü oluştur: ../../build/app, ../../build/module1 vb.
    val subprojectBuildDir = customBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(subprojectBuildDir)
}

// Bağımlılık yönetimi
subprojects {
    // Sadece ':app' modülü olmayan projelerin ':app'e bağımlı olmasını sağlar
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
}

// Clean görevi
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}