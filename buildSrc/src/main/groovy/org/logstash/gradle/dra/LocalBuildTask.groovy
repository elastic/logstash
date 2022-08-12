package org.logstash.gradle.dra

import groovy.transform.CompileStatic
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.TaskAction
import org.gradle.process.ExecSpec
import org.slf4j.Logger
import org.slf4j.LoggerFactory

@CompileStatic
class LocalBuildTask extends DefaultTask {

    private final Logger logger = LoggerFactory.getLogger(this.class.name)

    @Input
    List<Object> commands

    @Input
    List<String> dslCommands = List.of()

    @Input
    String projectName

    @Input
    String localBuildName

    @Input
    String type

    @Internal
    File projectBuildDirectory

    LocalBuildTask() {
        outputs.upToDateWhen {
            false
        }
    }

    @TaskAction
    private void action() {
        logger.info("[release-manager] The following DSL specified shell commands will be executed:")
        logger.info(dslCommands.join('\n'))
        logger.info("[release-manager] End of listing DSL specified shell commands.")

        List<Object> wrappedScript = []

        // script init
        wrappedScript.addAll([
                '#!/usr/bin/env bash',
                'set -e'
        ])

        // configure golang settings
        wrappedScript.addAll([
                "export GOPATH='${project.getBuildDir().absolutePath + '/projects/gopath'}'",
                'export PATH="$GOPATH/bin:$PATH"',
        ].collect({it.toString()}))

        // Add the commands we were given to the set of commands
        wrappedScript.addAll(commands)

        // make a script and execute it
        final String scriptPath = "build/scripts/local-build-${projectName}-${type}-${localBuildName}.sh"
        final File scriptFile = project.file(scriptPath)

        // check if the directory where the script is going to go exists
        if (scriptFile.parentFile.exists() == false) {

            // make the directory and check if it was successful
            if (scriptFile.parentFile.mkdirs() == false) {
                throw new Exception("Could not make the directories for '${scriptFile.parentFile.absolutePath}', something is up with the directories being used, possible permissions / writeability.")
            }

        }

        scriptFile.setText(wrappedScript.join('\n'), 'UTF-8')
        scriptFile.setExecutable(true)

        execute(List.of(scriptFile.absolutePath))
    }

    private void execute(final List<String> commands) {
        project.exec { final ExecSpec execSpec ->
            execSpec.commandLine = commands
        }
    }
}