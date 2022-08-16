package org.logstash.gradle.dra

import groovy.transform.CompileStatic
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.Task

/**
 * Extensions and tasks to build Logstash artifacts.
 * */
@CompileStatic
class LogstashDraPlugin implements Plugin<Project> {

    // name used in the extension DSL
    private static final String EXTENSION_NAME = "logstash"

    @Override
    void apply(Project project) {
//        Task checkTasks = project.tasks.create('checks')
//        checkTasks.group = 'preBuild'
//        checkTasks.description = 'Execute some verification before starting to build artifacts'

        StackProject stackProject = new StackProject(project)
        project.extensions.add(EXTENSION_NAME, stackProject)
    }
}
