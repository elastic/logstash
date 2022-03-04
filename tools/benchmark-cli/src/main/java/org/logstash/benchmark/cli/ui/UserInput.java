/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.benchmark.cli.ui;

import java.io.File;
import java.nio.file.Paths;

/**
 * User Input Definitions and Utility Methods.
 */
public final class UserInput {

    public static final String REPEAT_PARAM = "repeat-data";

    public static final String REPEAT_PARAM_HELP =
        "Sets how often the test's dataset should be run.";

    public static final String ES_OUTPUT_PARAM = "elasticsearch-export";

    public static final String ES_OUTPUT_HELP = "Optional Elasticsearch host URL to store detailed results at.";

    public static final String ES_OUTPUT_DEFAULT = "";

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
        "Currently available test cases are 'baseline', 'apache' and 'custom'.";

    public static final String LS_WORKER_THREADS = "ls-workers";

    public static final String LS_BATCH_SIZE = "ls-batch-size";

    public static final int LS_BATCHSIZE_DEFAULT = 128;

    public static final String LS_BATCH_SIZE_HELP =
        "Logstash batch size (-b argument) to configure.";

    public static final int LS_WORKER_THREADS_DEFAULT = 2;

    public static final String LS_WORKER_THREADS_HELP =
        "Number of Logstash worker threads (-w argument) to configure.";

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
        "'user-name#ab1cfe8cf7e20114df58bcc6c996abcb2b0650d7' or 'main'"
    );

    public static final String LOCAL_VERSION_PARAM = "local-path";

    public static final String LOCAL_VERSION_HELP =
        "Path to the root of a local Logstash distribution.\n E.g. `/opt/logstash`";

    public static final String WORKING_DIRECTORY_PARAM = "workdir";

    public static final String WORKING_DIRECTORY_HELP =
            "Working directory to store cached files in.";

    public static final String TEST_CASE_CONFIG_PARAM = "config";
    public static final String TEST_CASE_CONFIG_HELP =
            "Path to custom logstash config. Required if testcase is set to 'custom'";

    public static final String TEST_CASE_DATA_PARAM = "data";
    public static final String TEST_CASE_DATA_HELP =
            "Path to custom logstash data. Only if testcase is set to 'custom'";

    /**
     * Constructor.
     */
    private UserInput() {
        // Utility Class
    }
}
