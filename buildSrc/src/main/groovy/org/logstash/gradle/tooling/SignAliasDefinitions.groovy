package org.logstash.gradle.tooling

import org.gradle.api.DefaultTask
import org.gradle.api.file.ProjectLayout
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

import javax.inject.Inject

abstract class SignAliasDefinitions extends DefaultTask {

    enum Stage {
        main, test;
    }

    private final ProjectLayout projectLayout

    @Inject
    SignAliasDefinitions(ProjectLayout projectLayout) {
        this.projectLayout = projectLayout
        registry.convention('org/logstash/plugins/AliasRegistry.yml')
        stage.convention(Stage.main)
        registryFile.convention(registry.zip(stage) { reg, st ->
            projectLayout.projectDirectory.file("logstash-core/src/${st}/resources/${reg}")
        })
    }

    /**
     * Relative path to the AliasRegistry.yml file to use, relative to project's root.
     */
    @Input
    abstract Property<String> getRegistry()

    @Input
    abstract Property<Stage> getStage()

    @InputFile
    @PathSensitive(PathSensitivity.RELATIVE)
    abstract RegularFileProperty getRegistryFile()

    @OutputFile
    abstract RegularFileProperty getHashedFile()

    @TaskAction
    void sign() {
        Stage stageValue = stage.get()
        String registryPath = registry.get()
        String stagedRegistry = "logstash-core/src/${stageValue}/resources/${registryPath}"
        String aliasesDefs = registryFile.get().asFile.text
        String hash = aliasesDefs.digest('SHA-256')
        hashedFile.get().asFile.withWriter('utf-8') { writer ->
            writer.writeLine "#CHECKSUM: ${hash}"
            writer.writeLine "# DON'T EDIT THIS FILE, PLEASE REFER TO ${stagedRegistry}"
            writer.write aliasesDefs
        }
    }

    SignAliasDefinitions stage(Stage stage) {
        this.stage.set(stage)
        return this
    }

}
