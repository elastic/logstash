package org.logstash.benchmark.cli.ui;

/**
 * Enum of the various types of Logstash versions.
 */
public enum LsVersionType {
    /**
     * A local version of Logstash that is assumed to have all dependencies installed and/or build.
     */
    LOCAL,

    /**
     * A release version of Logstash to be downloaded from elastic.co mirrors.
     */
    DISTRIBUTION,

    /**
     * A version build from a given GIT tree hash/identifier.
     */
    GIT
}
