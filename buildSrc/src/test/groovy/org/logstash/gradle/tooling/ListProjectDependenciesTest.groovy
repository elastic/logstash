package org.logstash.gradle.tooling

import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.gradle.api.*
import org.gradle.testfixtures.ProjectBuilder

class ListProjectDependenciesTest {

    static final TASK_NAME = 'generateLicenseReport'
    Project project

    @BeforeEach
    void setUp() {
        project = ProjectBuilder.builder().build()
        project.getConfigurations().create("implementation")
        project.getConfigurations().create("runtimeClasspath")
        project.getConfigurations().create("runtimeOnly")
    }

    @Test
    void "list dependencies"() {
        // configure the project to have Jetty client as a dependency
        project.getDependencies().add('implementation',
                [group: "org.eclipse.jetty", name: "jetty-client", version: "9.4.43.v20210629", configuration: "implementation"])

        // configure and execute the task
        project.task(TASK_NAME, type: ListProjectDependencies) {
            report = "test.csv"
            reportFile = project.buildDir.toPath().resolve("test.csv").toFile()
        }
        def task = project.tasks.findByName(TASK_NAME)
        task != null
        task.list()

        // Verify the CSV generated
        List<String> fileContents = new File("${project.buildDir}/test.csv").readLines()
        assert fileContents.size() == 2
        assert fileContents[0] == '"artifact","moduleUrl","moduleLicense","moduleLicenseUrl",'
        assert fileContents[1] == '"org.eclipse.jetty:jetty-client:9.4.43.v20210629",,,,'
    }

}
