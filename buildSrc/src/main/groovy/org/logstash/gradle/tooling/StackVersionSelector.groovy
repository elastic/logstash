package org.logstash.gradle.tooling

import org.gradle.api.GradleException
import groovy.json.JsonSlurper

class StackVersionSelector {

   private final String artifactVersionsApi

   public StackVersionSelector(String artifactVersionsApi) {
       this.artifactVersionsApi = artifactVersionsApi
   }

    def selectClosestVersion(String version) {
        String apiResponse = artifactVersionsApi.toURL().text
        def dlVersions = new JsonSlurper().parseText(apiResponse)
        List<String> versions = dlVersions['versions']

        def versionQualifier = System.getenv('VERSION_QUALIFIER')
        def isReleaseBuild = System.getenv('RELEASE') == "1" || versionQualifier

        String qualifiedVersion = selectClosestInList(isReleaseBuild ? version : "${version}-SNAPSHOT", versions)
        if (qualifiedVersion == null) {
            throw new GradleException("could not find the current artifact from the artifact-api ${artifactVersionsApi} for ${version}")
        }
        qualifiedVersion
    }

    protected def selectClosestInList(String version, List<String> availableVersions) {
        availableVersions.grep( ~/^${version}/)[0]
    }
}