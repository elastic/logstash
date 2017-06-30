package org.logstash.benchmark.cli.ui;

import java.io.File;
import java.nio.file.Paths;

/**
 * User Input Definitions and Utility Methods.
 */
public final class UserInput {

    /**
     * The Default Cache/Working-Directory.
     */
    public static final File WORKING_DIRECTORY_DEFAULT = Paths.get(
        System.getProperty("user.home"), ".logstash-benchmarks"
    ).toFile();

    /**
     * Name of the testcase to run.
     */
    public static final String TEST_CASE_PARAM = "testcase";

    public static final String TEST_CASE_HELP =
        "Currently available test cases are 'baseline' and 'apache'.";

    /**
     * Version parameter to use for Logstash build downloaded from elastic.co.
     */
    public static final String DISTRIBUTION_VERSION_PARAM = "distribution-version";

    public static final String DISTRIBUTION_VERSION_HELP =
        "The version of a Logstash build to download from elastic.co.";

    /**
     * Version parameter to use for Logstash build form a Git has.
     */
    public static final String GIT_VERSION_PARAM = "git-hash";

    public static final String GIT_VERSION_HELP = String.join(
        "\n",
        "Either a git tree (tag/branch or commit hash), optionally prefixed by a Github username,",
        "if ran against forks.",
        "E.g. 'ab1cfe8cf7e20114df58bcc6c996abcb2b0650d7',",
        "'user-name#ab1cfe8cf7e20114df58bcc6c996abcb2b0650d7' or 'master'"
    );

    public static final String LOCAL_VERSION_PARAM = "local-path";

    public static final String LOCAL_VERSION_HELP =
        "Path to the root of a local Logstash distribution.\n E.g. `/opt/logstash`";

    public static final String WORKING_DIRECTORY_PARAM = "workdir";

    public static final String WORKING_DIRECTORY_HELP =
            "Working directory to store cached files in.";

    /**
     * Constructor.
     */
    private UserInput() {
        // Utility Class
    }
}
