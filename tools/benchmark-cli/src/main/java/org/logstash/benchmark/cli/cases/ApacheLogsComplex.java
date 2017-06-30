package org.logstash.benchmark.cli.cases;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Path;
import java.security.NoSuchAlgorithmException;
import java.util.EnumMap;
import java.util.Properties;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.apache.commons.io.IOUtils;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.LsMetricsMonitor;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.util.LsBenchDownloader;
import org.openjdk.jmh.util.ListStatistics;

/**
 * Test case running a set of Apache web-server logs, read from standard input, through the
 * GeoIP and UserAgent filters and printing the result to standard out using the dots codec.
 */
public final class ApacheLogsComplex implements Case {

    /**
     * Identifier used by the CLI interface.
     */
    public static final String IDENTIFIER = "apache";

    private final LogstashInstallation logstash;

    private final File data;

    public ApacheLogsComplex(final LogstashInstallation logstash, final Path cwd,
        final Properties settings) throws IOException, NoSuchAlgorithmException {
        this.data = cwd.resolve("data_apache").resolve("apache_access_logs").toFile();
        ensureDatafile(data.toPath().getParent().toFile(), settings);
        this.logstash = logstash;
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> run() {
        final LsMetricsMonitor monitor = new LsMetricsMonitor(logstash.metrics());
        final ExecutorService exec = Executors.newSingleThreadExecutor();
        final Future<EnumMap<LsMetricStats, ListStatistics>> future = exec.submit(monitor);
        try {
            final String config;
            try (final InputStream cfg = ApacheLogsComplex.class
                .getResourceAsStream("apache.cfg")) {
                final ByteArrayOutputStream baos = new ByteArrayOutputStream();
                IOUtils.copy(cfg, baos);
                config = baos.toString();
            }
            logstash.execute(config, data);
            monitor.stop();
            return future.get(20L, TimeUnit.SECONDS);
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        } finally {
            exec.shutdownNow();
        }
    }

    private static void ensureDatafile(final File file, final Properties settings)
        throws IOException, NoSuchAlgorithmException {
        LsBenchDownloader.downloadDecompress(
            file, settings.getProperty("org.logstash.benchmark.apache.dataset.url"), false
        );
    }
}
