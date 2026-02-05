package org.logstash.gradle.tooling

class ToolingUtils {
    static String jdkFolderName(String osName, String arch) {
        String normalizedArch = (arch == "x86_64" || arch == "amd64") ? "x64" : "arm64"
        return "jdk-${osName}-${normalizedArch}"
    }

    static String jdkFolderName(String osName) {
        String envArch = System.getenv("ARCH")
        String arch
        if (envArch) {
            arch = (envArch == "x86_64") ? "x64" : "arm64"
        } else {
            String hostArch = System.properties["os.arch"]
            arch = (hostArch == "amd64" || hostArch == "x86_64") ? "x64" : "arm64"
        }
        return jdkFolderName(osName, arch)
    }

    static String jdkReleaseFilePath(String osName, String arch) {
        jdkFolderName(osName, arch) + (osName == "darwin" ? "/Contents/Home/" : "")
    }

    static String jdkReleaseFilePath(String osName) {
        jdkFolderName(osName) + (osName == "darwin" ? "/Contents/Home/" : "")
    }
}
