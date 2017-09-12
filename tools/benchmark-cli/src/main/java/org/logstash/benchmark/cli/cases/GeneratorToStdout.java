package org.logstash.benchmark.cli.cases;

import java.io.IOException;
import java.util.EnumMap;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeoutException;
import org.logstash.benchmark.cli.BenchmarkMeta;
import org.logstash.benchmark.cli.DataStore;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.LsBenchSettings;
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

    private final String configuration;

    private final LogstashInstallation logstash;

    private final DataStore store;

    public GeneratorToStdout(final DataStore store, final LogstashInstallation logstash,
        final Properties settings, final BenchmarkMeta lsSettings) {
        this.logstash = logstash;
        logstash.configure(lsSettings);
        this.store = store;
        configuration =
            String.format(
                "input { generator { threads => 1 count => %d }  } output { stdout { } }",
                Long.parseLong(
                    settings.getProperty(LsBenchSettings.INPUT_DATA_REPEAT)
                ) * 1_000_000L
            );
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> run() {
        try (final LsMetricsMonitor.MonitorExecution monitor =
                 new LsMetricsMonitor.MonitorExecution(logstash.metrics(), store)) {
            logstash.execute(configuration);
            return monitor.stopAndGet();
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
