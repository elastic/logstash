package org.logstash.gradle.tooling

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

abstract class ExtractBundledJdkVersion extends DefaultTask {

    @InputFile
    File jdkReleaseFile = project.file("${project.projectDir}/jdk/release")

    @OutputFile
    File jdkVersionFile = project.file("${project.projectDir}/JDK_VERSION")

    ExtractBundledJdkVersion() {
        description = "Extracts IMPLEMENTOR_VERSION from JDK's release file"
        group = "org.logstash.tooling"
    }

    @TaskAction
    def extractVersionFile() {
        def sw = new StringWriter()
        jdkReleaseFile.filterLine(sw) { it =~ /IMPLEMENTOR_VERSION=.*/ }
        if (!sw.toString().empty) {
            def groups = (sw.toString() =~ /^IMPLEMENTOR_VERSION=\"(.*)\"$/)
            if (!groups.hasGroup()) {
                throw new GradleException("Malformed IMPLEMENTOR_VERSION property in ${jdkReleaseFile}")
            }
            jdkVersionFile.write(groups[0][1])
        }
    }
}
