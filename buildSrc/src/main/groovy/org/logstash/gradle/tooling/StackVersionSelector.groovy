package org.logstash.gradle.tooling

import org.gradle.api.GradleException
import groovy.json.JsonSlurper

class StackVersionSelector {

    private final String artifactVersionsApi
    private final def versionComparator = new VersionComparator()

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
    protected def selectClosestInList(String version, List<String> availableVersions) {
        for (int index = 0; index < availableVersions.size(); index++) {
            String currentVersion = availableVersions[index]
            if (currentVersion == version) {
                return currentVersion
            }
            if (index == availableVersions.size() - 1) {
                // last version
                return currentVersion
            }
            if (versionComparator.compare(currentVersion, version) == -1 &&
                    versionComparator.compare(availableVersions[index + 1], version) == 1) {
                // 7.14.0 < 7.15.0 < 8.0.0-SNAPSHOT and 7.15.0 is not yet released
                return currentVersion
            }
        }
        throw new IllegalStateException("Never reach this point")
    }

    static class VersionComparator implements Comparator<String> {
        private static final List<String> VERSION_SUFFIX_ORDER = ["SNAPSHOT", "alpha1", "alpha2", "rc1", "rc2"]

        /**
         * @return  1 s > t,
         *          0 s == t,
         *         -1 s < t
         * */
        @Override
        int compare(String s, String t) {
            if (!s.contains("-") && !t.contains("-"))
                // no SNAPSHOT version, compare directly
                return s <=> t
            if (s.contains("-") && t.contains("-")) {
                //both have a -SNAPSHOT or -alpha1 etc
                String swd = s.split("-")[0]
                String twd = t.split("-")[0]
                if (swd == twd) {
                    //for example 8.0.0-SNAPSHOT vs 8.0.0-alpha1
                    String sSuffix = s.split("-")[1]
                    String tSuffix = t.split("-")[1]
                    int sSuffixOrder = VERSION_SUFFIX_ORDER.indexOf(sSuffix)
                    int tSuffixOrder = VERSION_SUFFIX_ORDER.indexOf(tSuffix)
                    if (sSuffixOrder < 0)
                        throw new IllegalArgumentException("Found illegal version suffix for $s: [$sSuffix]")
                    if (tSuffixOrder < 0)
                        throw new IllegalArgumentException("Found illegal version suffix for $t: [$tSuffix]")

                    return sSuffixOrder <=> tSuffixOrder
                }
                // different -SNAPSHOT versions, compare jus the version part
                return swd <=> twd
            }
            // one between s and t has -SNAPSHOT
            String swd = s.split("-")[0]
            String twd = t.split("-")[0]
            if (swd == twd) {
                //both are same version
                if (s.contains("-"))
                    // the one with -SNAPSHOT has lower priority
                    return -1
                else
                    return 1
            }

            return swd <=> twd
        }
    }
}