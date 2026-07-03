// filepath: android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mizan.mizan_web"
    compileSdk = 36 
    ndkVersion = "28.2.13676358"

    flavorDimensions.add("default")
    
    productFlavors {
        create("gateway") {
            dimension = "default"
            applicationIdSuffix = ".gateway"
            resValue("string", "app_name", "Mizan Gateway")
        }
        create("production") {
            dimension = "default"
            applicationId = "com.mizan.mizan_market"
            resValue("string", "app_name", "Mizan Market")
        }
    }

    defaultConfig {
        applicationId = "com.mizan.mizan_web"
        minSdk = 24
        targetSdk = 36
        versionCode = 7 
        versionName = "1.0.7"
        multiDexEnabled = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            // Using debug signing for now as per your requirement
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    implementation("androidx.startup:startup-runtime:1.1.1")
}