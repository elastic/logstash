package org.logstash.gradle.tooling

import org.gradle.api.DefaultTask
import org.gradle.api.file.ProjectLayout
import org.gradle.api.tasks.TaskAction
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.Input
import org.gradle.api.artifacts.Dependency

import javax.inject.Inject
import java.nio.file.Files

abstract class ListProjectDependencies extends DefaultTask {

    @Inject
    abstract ProjectLayout getLayout()

    @Input
    String report = 'licenses.csv'

    @OutputFile
    File getReportFile() {
        layout.buildDirectory.file("reports/dependency-license/" + report).get().asFile
    }

    @OutputDirectory
    File getReportDir() {
        reportFile.toPath().parent.toFile()
    }

    ListProjectDependencies() {
        description = "Lists the projects dependencies in a CSV file"
        group = "org.logstash.tooling"
    }

    @TaskAction
    def list() {
        // collect all project's dependencies
        Set<Dependency> moduleDeps = new HashSet<>()
        moduleDeps.addAll(project.configurations.implementation.getAllDependencies())
        moduleDeps.addAll(project.configurations.runtimeClasspath.getAllDependencies())
        moduleDeps.addAll(project.configurations.runtimeOnly.getAllDependencies())

        def depsInGAV = moduleDeps.collect {dep ->

            // SelfResolvingDependency has no group or version information
            if (!dep.group && !dep.version && dep.reason) {
                def m = dep.reason =~ /DEPENDENCY: ([\w\.\-]+:[\w\.\-]+:[\w\.\-]+)/
                if (m.matches()) return m[0][1]
            }

            "${dep.group}:${dep.name}:${dep.version}"
        }

        // output in a CSV to be read by dependencies-report tool
        Files.createDirectories(reportFile.toPath().parent)
        reportFile.withWriter('utf-8') { writer ->
            writer.writeLine '"artifact","moduleUrl","moduleLicense","moduleLicenseUrl",'
            depsInGAV.each { s ->
                writer.writeLine "\"$s\",,,,"
            }
        }
    }

}
