package org.logstash.gradle.tooling

import org.gradle.api.DefaultTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction

abstract class SignAliasDefinitions extends DefaultTask {

    enum Stage {
        main, test;
    }

    /**
     * Relative path to the AliasRegistry.yml file to use, relative to project's root
     * */
    @Input
    String registry = 'org/logstash/plugins/AliasRegistry.yml'

    @InputFile
    File getRegistryFullPath() {
        String stagedRegistry = "logstash-core/src/${stage}/resources/${registry}"
        project.file("${project.projectDir}/${stagedRegistry}")
    }

    /**
     * Full file path to the file containing the marked AliasRegistry file
     * */
    @OutputFile
    File hashedFile

    private Stage stage = Stage.main

    @TaskAction
    def sign() {
        String aliasesDefs = registryFullPath.text
        String hash = aliasesDefs.digest('SHA-256')
        String stagedRegistry = "logstash-core/src/${stage}/resources/${registry}"
        hashedFile.withWriter('utf-8') { writer ->
            writer.writeLine "#CHECKSUM: ${hash}"
            writer.writeLine "# DON'T EDIT THIS FILE, PLEASE REFER TO ${stagedRegistry}"
            writer.write aliasesDefs
        }
    }

    SignAliasDefinitions stage(Stage stage) {
        this.stage = stage
        return this
    }
}
