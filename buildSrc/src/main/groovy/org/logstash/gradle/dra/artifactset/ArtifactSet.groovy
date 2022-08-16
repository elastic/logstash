package org.logstash.gradle.dra.artifactset


import groovy.transform.CompileStatic
import org.gradle.util.ConfigureUtil
import org.logstash.gradle.dra.StackArtifactHandler

@CompileStatic
class ArtifactSet {
    String name
    StackArtifactHandler stackArtifactHandler
    boolean configureArtifacts

    public ArtifactSet(final String name, final StackArtifactHandler stackArtifactHandler, final boolean configureArtifacts) {
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
            ConfigureUtil.configure(closure, stackArtifactHandler)
        }
    }

}
