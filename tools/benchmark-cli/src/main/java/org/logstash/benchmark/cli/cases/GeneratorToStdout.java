package org.logstash.benchmark.cli.cases;

import java.io.IOException;
import java.util.EnumMap;
import java.util.concurrent.ExecutionException;
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
        try (final LsMetricsMonitor.MonitorExecution monitor =
                 new LsMetricsMonitor.MonitorExecution(logstash.metrics())) {
            logstash.execute(GeneratorToStdout.CONFIGURATION);
            return monitor.stopAndGet();
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
