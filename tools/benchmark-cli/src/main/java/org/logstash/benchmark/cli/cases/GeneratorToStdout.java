package org.logstash.benchmark.cli.cases;

import java.io.IOException;
import java.util.EnumMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.LsMetricsMonitor;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.openjdk.jmh.util.ListStatistics;

/**
 * Runs Generator Input and Outputs to StdOut.
 */
public final class GeneratorToStdout implements Case {

    /**
     * Identifier used by the CLI interface.
     */
    public static final String IDENTIFIER = "baseline";

    private static final String CONFIGURATION =
        "input { generator { threads => 1 count => 1000000 }  } output { stdout { } }";

    private final LogstashInstallation logstash;

    public GeneratorToStdout(final LogstashInstallation logstash) {
        this.logstash = logstash;
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> run() {
        final LsMetricsMonitor monitor = new LsMetricsMonitor(logstash.metrics());
        final ExecutorService exec = Executors.newSingleThreadExecutor();
        final Future<EnumMap<LsMetricStats, ListStatistics>> future = exec.submit(monitor);
        try {
            logstash.execute(GeneratorToStdout.CONFIGURATION);
            monitor.stop();
            return future.get(20L, TimeUnit.SECONDS);
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        } finally {
            exec.shutdownNow();
        }
    }
}
