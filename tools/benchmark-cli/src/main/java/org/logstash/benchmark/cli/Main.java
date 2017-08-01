package org.logstash.benchmark.cli;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.NoSuchAlgorithmException;
import java.util.AbstractMap;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.TimeUnit;
import joptsimple.OptionException;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import joptsimple.OptionSpec;
import joptsimple.OptionSpecBuilder;
import org.apache.commons.lang3.SystemUtils;
import org.logstash.benchmark.cli.cases.ApacheLogsComplex;
import org.logstash.benchmark.cli.cases.Case;
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
    public static void main(final String... args) throws Exception {
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
        execute(
            new UserOutput(System.out), settings, options.valueOf(testcase),
            options.valueOf(pwd).toPath(), version, type, options.valueOf(esout)
        );
    }

    /**
     * Programmatic Entrypoint.
     * @param output Output Printer
     * @param settings Properties
     * @param test String identifier of the testcase to run
     * @param cwd Working Directory to run in and write cache files to
     * @param version Version of Logstash to benchmark
     * @param type Type of Logstash version to benchmark
     * @param esout Elastic Search URL (empty string is interpreted as not using ES output)
     * @throws Exception On Failure
     */
    public static void execute(final UserOutput output, final Properties settings,
        final String test, final Path cwd, final String version, final LsVersionType type,
        final String esout)
        throws Exception {
        output.printBanner();
        output.printLine();
        output.green(String.format("Benchmarking Version: %s", version));
        output.green(
            String.format(
                "Running Test Case: %s (x%d)", test,
                Integer.parseInt(settings.getProperty(LsBenchSettings.INPUT_DATA_REPEAT))
            )
        );
        output.printLine();
        Files.createDirectories(cwd);
        final LogstashInstallation logstash;
        if (type == LsVersionType.GIT) {
            logstash = LsBenchLsSetup.logstashFromGit(
                cwd.toAbsolutePath().toString(), version, JRubyInstallation.bootstrapJruby(cwd)
            );
        } else {
            logstash = LsBenchLsSetup.setupLS(cwd.toAbsolutePath().toString(), version, type);
        }
        try (final DataStore store = setupDataStore(esout, test, version, type)) {
            final Case testcase = setupTestCase(store, logstash, cwd, settings, test);
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
        final Path cwd, final Properties settings, final String test)
        throws IOException, NoSuchAlgorithmException {
        final Case testcase;
        if (GeneratorToStdout.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new GeneratorToStdout(store, logstash, settings);
        } else if (ApacheLogsComplex.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new ApacheLogsComplex(store, logstash, cwd, settings);
        } else {
            throw new IllegalArgumentException(String.format("Unknown test case %s", test));
        }
        return testcase;
    }

    private static DataStore setupDataStore(final String elastic, final String test,
        final String version, final LsVersionType vtype) throws UnknownHostException {
        if (elastic.isEmpty()) {
            return DataStore.NONE;
        } else {
            final URI elasticsearch = URI.create(elastic);
            return new DataStore.ElasticSearch(
                elasticsearch.getHost(), elasticsearch.getPort(), elasticsearch.getScheme(),
                meta(test, version, vtype)
            );
        }
    }

    private static Map<String, Object> meta(final String testcase, final String version,
        final LsVersionType vtype) throws UnknownHostException {
        final Map<String, Object> result = new HashMap<>();
        result.put("test_name", testcase);
        result.put("os_name", SystemUtils.OS_NAME);
        result.put("os_version", SystemUtils.OS_VERSION);
        result.put("host_name", InetAddress.getLocalHost().getHostName());
        result.put("cpu_cores", Runtime.getRuntime().availableProcessors());
        result.put("version_type", vtype);
        result.put("version", version);
        return result;
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
