package org.logstash.benchmark.cli.cases;

import org.apache.commons.io.IOUtils;
import org.logstash.benchmark.cli.*;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.ui.UserOutput;
import org.openjdk.jmh.util.ListStatistics;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.AbstractMap;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeoutException;

public class CustomTestCase implements Case {
    public static final String IDENTIFIER = "custom";

    private final LogstashInstallation logstash;
    private final DataStore store;
    private final Path configpath;

    public CustomTestCase(DataStore store, LogstashInstallation logstash, Path cwd, Properties settings, UserOutput output, BenchmarkMeta runConfig) {
        this.logstash = logstash;
        logstash.configure(runConfig);
        this.store = store;
        this.configpath = runConfig.getConfigPath();
    }

    @Override
    public AbstractMap<LsMetricStats, ListStatistics> run() {
        try (final LsMetricsMonitor.MonitorExecution monitor =
                     new LsMetricsMonitor.MonitorExecution(logstash.metrics(), store)) {
            final ByteArrayOutputStream baos = new ByteArrayOutputStream();

            try (final InputStream cfg = Files.newInputStream(configpath)){
                IOUtils.copy(cfg, baos);
            }
            logstash.execute(baos.toString());
            return monitor.stopAndGet();
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
