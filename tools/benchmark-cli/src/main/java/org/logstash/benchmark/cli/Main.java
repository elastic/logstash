package org.logstash.benchmark.cli;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
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
        execute(
            new UserOutput(System.out), loadSettings(), options.valueOf(testcase),
            options.valueOf(pwd).toPath(), version, type
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
     * @throws Exception On Failure
     */
    public static void execute(final UserOutput output, final Properties settings,
        final String test, final Path cwd, final String version, final LsVersionType type)
        throws Exception {
        output.printBanner();
        output.printLine();
        output.green(String.format("Benchmarking Version: %s", version));
        output.green(String.format("Running Test Case: %s", test));
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
        final Case testcase;
        if (GeneratorToStdout.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new GeneratorToStdout(logstash);
        } else if (ApacheLogsComplex.IDENTIFIER.equalsIgnoreCase(test)) {
            testcase = new ApacheLogsComplex(logstash, cwd, settings);
        } else {
            throw new IllegalArgumentException(String.format("Unknown test case %s", test));
        }
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
        output.green(
            String.format("Num Events: %d", (long) stats.get(LsMetricStats.COUNT).getMax())
        );
        final ListStatistics throughput = stats.get(LsMetricStats.THROUGHPUT);
        output.green(String.format("Throughput Min: %.2f", throughput.getMin()));
        output.green(String.format("Throughput Max: %.2f", throughput.getMax()));
        output.green(String.format("Throughput Mean: %.2f", throughput.getMean()));
        output.green(String.format("Throughput StdDev: %.2f", throughput.getStandardDeviation()));
        output.green(String.format("Throughput Variance: %.2f", throughput.getVariance()));
        output.green(
            String.format(
                "Mean CPU Usage: %.2f%%", stats.get(LsMetricStats.CPU_USAGE).getMean()
            )
        );
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
