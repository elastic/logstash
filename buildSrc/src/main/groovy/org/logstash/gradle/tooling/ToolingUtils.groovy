package org.logstash.gradle.tooling

class ToolingUtils {
    static String jdkFolderName(String osName) {
        return osName == "darwin" ? "jdk.app" : "jdk"
    }

    static String jdkReleaseFilePath(String osName) {
        jdkFolderName(osName) + (osName == "darwin" ? "/Contents/Home/" : "")
//        if (osName == "darwin") {
//            jdkFolderName(osName) + "/Contents/Home/"
//        } else {
//            jdkFolderName(osName)
//        }
    }
}
