android {
    compileSdkVersion 33

    defaultConfig {
        applicationId = "com.example.parkalot"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // Add the following ndkVersion line to specify the required NDK version
    ndkVersion = "27.0.12077973" // Set the highest NDK version to avoid plugin errors
}
