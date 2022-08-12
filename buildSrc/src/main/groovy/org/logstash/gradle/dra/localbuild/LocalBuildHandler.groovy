package org.logstash.gradle.dra.localbuild

import groovy.transform.CompileStatic
import org.logstash.gradle.dra.StackArtifactHandler

@CompileStatic
class LocalBuildHandler {

    private final Map<String, LocalBuild> localBuilds = new LinkedHashMap<>()

    void localBuild(final String name, final StackArtifactHandler stackArtifactHandler, final boolean configureArtifacts, Closure closure) {
        LocalBuild build = new LocalBuild(name, stackArtifactHandler, configureArtifacts)
        build.configure(closure)
        localBuilds[name] = build
    }

    public Map<String, LocalBuild> getLocalBuilds() {
        return localBuilds
    }
}