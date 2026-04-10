import java.util.Properties
import java.io.FileInputStream

// 1. 在 android 區塊上方讀取 key.properties 設定檔
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "tw.com.gex.eisapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // 修正原本的 jvmTarget 警告，改用較新的寫法
        freeCompilerArgs += "-Xjvm-default=all"
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "tw.com.gex.eisapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. 定義簽署配置 (這一段非常重要)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")

            // 處理 storeFile 的路徑
            val path = keystoreProperties.getProperty("storeFile")
            if (path != null) {
                storeFile = file(path)
            }
        }
    }

    buildTypes {
        getByName("release") {
            // 3. 修正：將簽署配置從 "debug" 改為我們上面定義的 "release"
            signingConfig = signingConfigs.getByName("release")

            // 下面這兩項在初次成功打包前建議先設為 false
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}