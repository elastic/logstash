package org.logstash.gradle.dra.artifactset

import groovy.transform.CompileStatic
import org.logstash.gradle.dra.StackArtifactHandler

@CompileStatic
class ArtifactSetHandler {

    private final Map<String, ArtifactSet> artifactSets = new LinkedHashMap<>()

    void artifactSet(final String name, final StackArtifactHandler stackArtifactHandler, final boolean configureArtifacts, Closure closure) {
        ArtifactSet build = new ArtifactSet(name, stackArtifactHandler, configureArtifacts)
        build.configure(closure)
        artifactSets[name] = build
    }

    public Map<String, ArtifactSet> getArtifactSets() {
        return artifactSets
    }

}
