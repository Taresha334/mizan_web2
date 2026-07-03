buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val projectName = project.name
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        
        if (android != null) {
            // Enforcement of valid namespaces for modern Android builds
            when (projectName) {
                "telephony" -> android.namespace = "com.shounakmulay.telephony"
                "background_sms" -> android.namespace = "com.j.background_sms"
                "flutter_background_service" -> android.namespace = "id.flutter.flutter_background_service"
            }
        }
    }
}

rootProject.layout.buildDirectory.set(file("../build"))
subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}