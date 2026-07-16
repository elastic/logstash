package org.logstash.gradle.tooling

class ToolingUtils {
    static String jdkFolderName(String osName, String arch) {
        String normalizedArch = (arch == "x86_64" || arch == "amd64") ? "x64" : "arm64"
        return "jdk-${osName}-${normalizedArch}"
    }
}
