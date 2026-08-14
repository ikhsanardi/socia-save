allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    val subproject = this
    if (subproject.name != "app") {
        subproject.afterEvaluate {
            val android = subproject.extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
            if (android != null) {
                if (android.namespace == null) {
                    android.namespace = if (subproject.group.toString().isNotEmpty()) {
                        subproject.group.toString()
                    } else {
                        "dev.flutter.plugins.${subproject.name.replace('-', '_')}"
                    }
                }
                android.compileSdk = 36
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


