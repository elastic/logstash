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


package org.logstash.benchmark.cli;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.NoSuchAlgorithmException;
import java.util.AbstractMap;
import java.util.Properties;
import java.util.concurrent.TimeUnit;
import joptsimple.OptionException;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import joptsimple.OptionSpec;
import joptsimple.OptionSpecBuilder;
import org.logstash.benchmark.cli.cases.ApacheLogsComplex;
import org.logstash.benchmark.cli.cases.Case;
import org.logstash.benchmark.cli.cases.CustomTestCase;
import org.logstash.benchmark.cli.cases.GeneratorToStdout;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.ui.LsVersionType;
import org.logstash.benchmark.cli.ui.UserInput;
import org.logstash.benchmark.cli.ui.UserOutput;
import org.logstash.benchmark.cli.util.LsBenchLsSetup;
import org.openjdk.jmh.util.ListStatistics;

/**
 * Benchmark CLI Main Entry Point.
 */
public final class Main {

    /**
     * Ctor.
     */
    private Main() {
        // Utility Class.
    }

    /**
     * CLI Entrypoint.
     * @param args Cli Args
     */
    public static void main(final String... args) throws IOException, NoSuchAlgorithmException {
        final OptionParser parser = new OptionParser();
        final OptionSpecBuilder gitbuilder =
            parser.accepts(UserInput.GIT_VERSION_PARAM, UserInput.GIT_VERSION_HELP);
        final OptionSpecBuilder localbuilder =
            parser.accepts(UserInput.LOCAL_VERSION_PARAM, UserInput.LOCAL_VERSION_HELP);
        final OptionSpecBuilder distributionbuilder =
            parser.accepts(
                UserInput.DISTRIBUTION_VERSION_PARAM, UserInput.DISTRIBUTION_VERSION_HELP
            );
        final OptionSpec<String> git = gitbuilder.requiredUnless(
            UserInput.DISTRIBUTION_VERSION_PARAM, UserInput.LOCAL_VERSION_PARAM
        ).availableUnless(UserInput.DISTRIBUTION_VERSION_PARAM, UserInput.LOCAL_VERSION_PARAM)
            .withRequiredArg().ofType(String.class).forHelp();
        final OptionSpec<String> distribution = distributionbuilder
            .requiredUnless(UserInput.LOCAL_VERSION_PARAM, UserInput.GIT_VERSION_PARAM)
            .availableUnless(
                UserInput.LOCAL_VERSION_PARAM, UserInput.GIT_VERSION_PARAM
            ).withRequiredArg().ofType(String.class).forHelp();
        final OptionSpec<String> local = localbuilder.requiredUnless(
            UserInput.DISTRIBUTION_VERSION_PARAM, UserInput.GIT_VERSION_PARAM)
            .availableUnless(UserInput.DISTRIBUTION_VERSION_PARAM, UserInput.GIT_VERSION_PARAM)
            .withRequiredArg().ofType(String.class).forHelp();
        final OptionSpec<String> testcase = parser.accepts(
            UserInput.TEST_CASE_PARAM, UserInput.TEST_CASE_HELP
        ).withRequiredArg().ofType(String.class).defaultsTo(GeneratorToStdout.IDENTIFIER).forHelp();
        final OptionSpec<File> testcaseconfig = parser.accepts(
                UserInput.TEST_CASE_CONFIG_PARAM, UserInput.TEST_CASE_CONFIG_HELP
        ).withRequiredArg().ofType(File.class).forHelp();
        final OptionSpec<File> testcasedata = parser.accepts(
            UserInput.TEST_CASE_DATA_PARAM, UserInput.TEST_CASE_DATA_HELP
            ).withRequiredArg().ofType(File.class).forHelp();
        final OptionSpec<File> pwd = parser.accepts(
            UserInput.WORKING_DIRECTORY_PARAM, UserInput.WORKING_DIRECTORY_HELP
        ).withRequiredArg().ofType(File.class).defaultsTo(UserInput.WORKING_DIRECTORY_DEFAULT)
            .forHelp();
        final OptionSpec<String> esout = parser.accepts(
            UserInput.ES_OUTPUT_PARAM, UserInput.ES_OUTPUT_HELP
        ).withRequiredArg().ofType(String.class).defaultsTo(UserInput.ES_OUTPUT_DEFAULT).forHelp();
        final OptionSpec<Integer> repeats = parser.accepts(
            UserInput.REPEAT_PARAM, UserInput.REPEAT_PARAM_HELP
        ).withRequiredArg().ofType(Integer.class).defaultsTo(1).forHelp();
        final OptionSpec<Integer> workers = parser.accepts(
            UserInput.LS_WORKER_THREADS, UserInput.LS_WORKER_THREADS_HELP
        ).withRequiredArg().ofType(Integer.class)
            .defaultsTo(UserInput.LS_WORKER_THREADS_DEFAULT).forHelp();
        final OptionSpec<Integer> batchsize = parser.accepts(
            UserInput.LS_BATCH_SIZE, UserInput.LS_BATCH_SIZE_HELP
        ).withRequiredArg().ofType(Integer.class)
            .defaultsTo(UserInput.LS_BATCHSIZE_DEFAULT).forHelp();
        final OptionSet options;
        try {
            options = parser.parse(args);
        } catch (final OptionException ex) {
            parser.printHelpOn(System.out);
            throw ex;
        }
        final LsVersionType type;
        final String version;
        if (options.has(distribution)) {
            type = LsVersionType.DISTRIBUTION;
            version = options.valueOf(distribution);
        } else if (options.has(git)) {
            type = LsVersionType.GIT;
            version = options.valueOf(git);
        } else {
            type = LsVersionType.LOCAL;
            version = options.valueOf(local);
        }
        final Properties settings = loadSettings();
        settings.setProperty(
            LsBenchSettings.INPUT_DATA_REPEAT, String.valueOf(options.valueOf(repeats))
        );

        Path testCaseConfigPath = null;
        Path testCaseDataPath = null;
        if (options.valueOf(testcase).equals("custom")) {
            if (options.has(testcaseconfig)) {
                testCaseConfigPath = options.valueOf(testcaseconfig).toPath();
            }
            else {
                throw new IllegalArgumentException("Path to Test Case Config must be provided");
            }
            if (options.has(testcasedata)) {
                testCaseDataPath = options.valueOf(testcasedata).toPath();
            }
        } else {
            if (options.has(testcaseconfig) || options.has(testcasedata)) {
                throw new IllegalArgumentException("Path to Test Case Config or Data can only be used with Custom Test Case");
        }
    }

        final BenchmarkMeta runConfig = new BenchmarkMeta(
            options.valueOf(testcase), testCaseConfigPath, testCaseDataPath, version, type, options.valueOf(workers),
            options.valueOf(batchsize)
        );
        execute(
            new UserOutput(System.out), settings, options.valueOf(pwd).toPath(), runConfig,
            options.valueOf(esout)
        );
    }

    /**
     * Programmatic Entrypoint.
     * @param output Output Printer
     * @param settings Properties
     * @param cwd Working Directory to run in and write cache files to
     * @param runConfig Logstash Settings
     * @param esout Elastic Search URL (empty string is interpreted as not using ES output)
     * @throws IOException On Failure
     * @throws NoSuchAlgorithmException On Failure
     */
    public static void execute(final UserOutput output, final Properties settings,
        final Path cwd, final BenchmarkMeta runConfig, final String esout)
        throws IOException, NoSuchAlgorithmException {
        output.printBanner();
        output.printLine();
        final String version = runConfig.getVersion();
        output.green(String.format("Benchmarking Version: %s", version));
        output.green(
            String.format(
                "Logstash Parameters: -w %d -b %d", runConfig.getWorkers(),
                runConfig.getBatchsize()
            )
        );
        final String test = runConfig.getTestcase();
        output.green(
            String.format(
                "Running Test Case: %s (x%d)", test,
                Integer.parseInt(settings.getProperty(LsBenchSettings.INPUT_DATA_REPEAT))
            )
        );
        if (runConfig.getTestcase().equals("custom")) {
            output.green(
                    String.format("Test Case Config: %s", runConfig.getConfigPath())
            );
        }

        output.printLine();
        Files.createDirectories(cwd);
        final LogstashInstallation logstash;
        final LsVersionType type = runConfig.getVtype();
        if (type == LsVersionType.GIT) {
            logstash = LsBenchLsSetup.logstashFromGit(
                cwd.toAbsolutePath().toString(), version, JRubyInstallation.bootstrapJruby(cwd)
            );
        } else {
            logstash =
                LsBenchLsSetup.setupLS(cwd.toAbsolutePath().toString(), version, type, output);
        }
        try (final DataStore store = setupDataStore(esout, runConfig)) {
            final Case testcase = setupTestCase(store, logstash, cwd, settings, runConfig, output);
            output.printStartTime();
            final long start = System.currentTimeMillis();
            final AbstractMap<LsMetricStats, ListStatistics> stats = testcase.run();
            output.green("Statistical Summary:\n");
            output.green(String.format(
                "Elapsed Time: %ds",
                TimeUnit.SECONDS.convert(
                    System.currentTimeMillis() - start, TimeUnit.MILLISECONDS
                )
            ));
            output.printStatistics(stats);
        }
    }

    private static Case setupTestCase(final DataStore store, final LogstashInstallation logstash,
        final Path cwd, final Properties settings, final BenchmarkMeta runConfig, final UserOutput output)
        throws IOException, NoSuchAlgorithmException {
        final Case testcase;
        final String test = runConfig.getTestcase();
        if (GeneratorToStdout.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new GeneratorToStdout(store, logstash, settings, runConfig);
        } else if (ApacheLogsComplex.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new ApacheLogsComplex(store, logstash, cwd, settings, output, runConfig);
        } else if (CustomTestCase.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new CustomTestCase(store, logstash, cwd, settings, output, runConfig);
        }
        else {
            throw new IllegalArgumentException(String.format("Unknown test case %s", test));
        }
        return testcase;
    }

    private static DataStore setupDataStore(final String elastic, final BenchmarkMeta config) {
        if (elastic.isEmpty()) {
            return DataStore.NONE;
        } else {
            final URI elasticsearch = URI.create(elastic);
            return new DataStore.ElasticSearch(
                elasticsearch.getHost(), elasticsearch.getPort(), elasticsearch.getScheme(),
                config.asMap()
            );
        }
    }

    private static Properties loadSettings() throws IOException {
        final Properties props = new Properties();
        try (final InputStream settings =
                 Main.class.getResource("ls-benchmark.properties").openStream()) {
            props.load(settings);
        }
        return props;
    }
}
