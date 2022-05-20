package org.logstash.gradle.tooling

import org.gradle.api.Project
import org.gradle.testfixtures.ProjectBuilder
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

import java.nio.file.Files
import java.nio.file.Path

class SignAliasDefinitionsTest {
    Project project

    @BeforeEach
    void setUp() {
        project = ProjectBuilder.builder().build()
    }

    @Test
    void "test sign registry file adds header definition and SHA"() {
        Path toSignFile = project.rootDir.toPath().resolve("logstash-core/src/test/resources/ToSign.yml")
        Files.createDirectories(toSignFile.parent)

        String someYaml = """
            |input:
            |  - alias: elastic_agent
            |    from: beats
        """.stripMargin().stripIndent()

        toSignFile.toFile() << someYaml
        assert Files.exists(toSignFile)

        Path signedFile = project.buildDir.toPath().resolve("hashed_output.yml")
        // necessary to avoid FileNotFoundException when the task try to write on the output file
        Files.createDirectories(signedFile.parent)

        def task = project.task("signerTask", type: SignAliasDefinitions) {
            stage SignAliasDefinitions.Stage.test
            registry = "ToSign.yml"
            hashedFile = project.file("${project.buildDir}/hashed_output.yml")
        }

        // Exercise
        task.sign()

        // Verify
        String hash = someYaml.digest('SHA-256')
        assert signedFile.toFile().text.startsWith("#CHECKSUM: ${hash}")
    }
}
