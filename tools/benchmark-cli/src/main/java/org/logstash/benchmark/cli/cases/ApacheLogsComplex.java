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
import java.util.concurrent.TimeoutException;
import org.apache.commons.io.IOUtils;
import org.logstash.benchmark.cli.BenchmarkMeta;
import org.logstash.benchmark.cli.DataStore;
import org.logstash.benchmark.cli.LogstashInstallation;
import org.logstash.benchmark.cli.LsBenchSettings;
import org.logstash.benchmark.cli.LsMetricsMonitor;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.ui.UserOutput;
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

    /**
     * File containing example Apache web-server logs.
     */
    private final File data;

    /**
     * {@link DataStore} to save benchmark run results to.
     */
    private final DataStore store;

    private final int repeats;

    public ApacheLogsComplex(final DataStore store, final LogstashInstallation logstash,
        final Path cwd, final Properties settings, final UserOutput output,
        final BenchmarkMeta runConfig) throws IOException, NoSuchAlgorithmException {
        data = cwd.resolve("data_apache").resolve("apache_access_logs").toFile();
        ensureDatafile(
            data.toPath().getParent().toFile(),
            settings.getProperty(LsBenchSettings.APACHE_DATASET_URL), output
        );
        this.logstash = logstash;
        logstash.configure(runConfig);
        this.store = store;
        repeats = Integer.parseInt(settings.getProperty(LsBenchSettings.INPUT_DATA_REPEAT));
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> run() {
        try (final LsMetricsMonitor.MonitorExecution monitor =
                 new LsMetricsMonitor.MonitorExecution(logstash.metrics(), store)) {
            final ByteArrayOutputStream baos = new ByteArrayOutputStream();
            try (final InputStream cfg = ApacheLogsComplex.class
                .getResourceAsStream("apache.cfg")) {
                IOUtils.copy(cfg, baos);
            }
            logstash.execute(baos.toString(), data, repeats);
            return monitor.stopAndGet();
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static void ensureDatafile(final File file, final String url, final UserOutput output)
        throws IOException, NoSuchAlgorithmException {
        if (file.exists()) {
            output.blue("Using example Apache web-server logs from cache.");
        } else {
            output.blue("Downloading example Apache web-server logs.");
            LsBenchDownloader.downloadDecompress(file, url);
            output.blue("Finished downloading example Apache web-server logs.");
        }
    }
}
