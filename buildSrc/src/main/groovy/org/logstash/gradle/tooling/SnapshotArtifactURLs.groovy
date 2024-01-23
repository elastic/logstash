package org.logstash.gradle.tooling

import groovy.json.JsonSlurper

/**
 * Helper class to obtain project specific (e.g. Elasticsearch or beats/filebeat) snapshot-DRA artifacts.
 * We use it in all cases apart from release builds.
 * */
class SnapshotArtifactURLs {
    /**
     * Returns a list of the package and package SHA(512) URLs for a given project / version / downloadedPackageName
     * */
    static def packageUrls(String project, String projectVersion, String downloadedPackageName) {
        String artifactSnapshotVersionsApiPrefix = "https://artifacts-snapshot.elastic.co"

        // e.g. https://artifacts-snapshot.elastic.co/elasticsearch/latest/8.11.5-SNAPSHOT.json
        String apiResponse = "${artifactSnapshotVersionsApiPrefix}/${project}/latest/${projectVersion}.json".toURL().text
        def artifactUrls = new JsonSlurper().parseText(apiResponse)
        String manifestUrl = artifactUrls["manifest_url"]
        // e.g. https://artifacts-snapshot.elastic.co/elasticsearch/8.11.5-12345678/manifest-8.11.5-SNAPSHOT.json
        apiResponse = manifestUrl.toURL().text
        def packageArtifactUrls = new JsonSlurper().parseText(apiResponse)
        String packageUrl = packageArtifactUrls["projects"]["${project}"]["packages"]["${downloadedPackageName}.tar.gz"]["url"]
        String packageShaUrl = packageArtifactUrls["projects"]["${project}"]["packages"]["${downloadedPackageName}.tar.gz"]["sha_url"]

        return ["packageUrl": packageUrl, "packageShaUrl": packageShaUrl]
    }
}
