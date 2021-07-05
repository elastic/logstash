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
        List<StackVersion> versions = dlVersions['versions'].collect {s -> StackVersion.asVersion(s)}

        def versionQualifier = System.getenv('VERSION_QUALIFIER')
        def isReleaseBuild = System.getenv('RELEASE') == "1" || versionQualifier

        String qualifiedVersion = selectClosestInList(StackVersion.asVersion(isReleaseBuild ? version : "${version}-SNAPSHOT"), versions)
        if (qualifiedVersion == null) {
            throw new GradleException("could not find the current artifact from the artifact-api ${artifactVersionsApi} for ${version}")
        }
        qualifiedVersion
    }

    /**
     * Suppose availableVersions is sorted in such a way that the SNAPSHOT version is before the release version,
     * following the natural order of versions:
     *  7.10.1-SNAPSHOT
     *  7.10.1
     *  7.11.0-SNAPSHOT
     *  7.11.0
     *  8.0.0-SNAPSHOT
     *  8.0.0-alpha1
     *  8.0.0-alpha2
     *  8.0.0-rc1
     *  8.0.0-rc2
     *  8.0.0
     * */
    protected def selectClosestInList(StackVersion version, List<StackVersion> availableVersions) {
        for (int index = 0; index < availableVersions.size(); index++) {
            StackVersion currentVersion = availableVersions[index]
            if (currentVersion == version) {
                return currentVersion
            }
            if (index == availableVersions.size() - 1) {
                // last version
                return currentVersion
            }
            if (currentVersion < version && version < availableVersions[index + 1]) {
                // 7.14.0 < 7.15.0 < 8.0.0-SNAPSHOT and 7.15.0 is not yet released
                return currentVersion
            }
        }
        throw new IllegalStateException("Never reach this point")
    }


    static class StackVersion implements Comparable<StackVersion> {
        final String version
        final String suffix
        final def comparator = comparator()

        StackVersion(String fullVersion) {
            def splits = fullVersion.split("-")
            version = splits[0]
            if (splits.length == 2) {
                suffix = splits[1]
            }
        }

        def static asVersion(String v) {
            new StackVersion(v)
        }

        @Override
        String toString() {
            suffix != null ? "$version-$suffix" : version
        }

        static Comparator<StackVersion> comparator() {
            Comparator.comparing({sv -> sv.version})
                    .thenComparing({sv -> sv.suffix}, new SuffixComparator())
        }

        @Override
        int compareTo(StackVersion other) {
            comparator.compare(this, other)
        }
    }

    static class SuffixComparator implements Comparator<String> {

        private static final List<String> VERSION_SUFFIX_ORDER = ["SNAPSHOT", "alpha1", "alpha2", "rc1", "rc2", "<GA>"]

        @Override
        int compare(String s, String t) {
            if (s == null)
                s = "<GA>"
            if (t == null)
                t = "<GA>"

            //for example 8.0.0-SNAPSHOT vs 8.0.0-alpha1
            int sSuffixOrder = VERSION_SUFFIX_ORDER.indexOf(s)
            int tSuffixOrder = VERSION_SUFFIX_ORDER.indexOf(t)
            if (sSuffixOrder < 0)
                throw new IllegalArgumentException("Found illegal version suffix: [$s]")
            if (tSuffixOrder < 0)
                throw new IllegalArgumentException("Found illegal version suffix: [$t]")

            return sSuffixOrder <=> tSuffixOrder
        }
    }
}