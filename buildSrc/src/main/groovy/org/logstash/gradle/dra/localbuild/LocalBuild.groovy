package org.logstash.gradle.dra.localbuild

import groovy.transform.CompileStatic
import org.logstash.gradle.dra.StackArtifactHandler
import org.gradle.util.ConfigureUtil

@CompileStatic
class LocalBuild {
    String name
    List<String> buildSnapshotCommands
    List<String> buildReleaseCommands
    StackArtifactHandler stackArtifactHandler
    boolean configureArtifacts

    public LocalBuild(final String name, final StackArtifactHandler stackArtifactHandler, final boolean configureArtifacts) {
        this.name = name
        this.stackArtifactHandler = stackArtifactHandler
        this.configureArtifacts = configureArtifacts
    }

    public void configure(Closure closure) {
        closure.delegate = this
        // ensure the artifacts closure goes to the method we have defined in this class
        closure.resolveStrategy = Closure.DELEGATE_FIRST
        closure.call()
    }

    public void artifacts(Closure closure) {
        if (configureArtifacts) {
            stackArtifactHandler.localBuildName = name
            ConfigureUtil.configure(closure, stackArtifactHandler)
        }
    }
}
