package org.logstash.gradle.tooling

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

abstract class ExtractBundledJdkVersion extends DefaultTask {

    /**
     * Defines the name of the output filename containing the JDK version.
     * */
    @Input
    abstract Property<String> getOutputFilename()

    @InputFile
    File jdkReleaseFile = project.file("${project.projectDir}/jdk/release")

    @OutputFile
    File getJdkVersionFile() {
        project.file("${project.projectDir}/${outputFilename.get()}")
    }

    ExtractBundledJdkVersion() {
        description = "Extracts IMPLEMENTOR_VERSION from JDK's release file"
        group = "org.logstash.tooling"
        outputFilename.convention("JDK_VERSION")
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
