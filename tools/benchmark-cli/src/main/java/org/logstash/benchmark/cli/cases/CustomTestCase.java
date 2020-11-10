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
    private final File data;
    private final int repeats;

    public CustomTestCase(DataStore store, LogstashInstallation logstash, Path cwd, Properties settings,
            UserOutput output, BenchmarkMeta runConfig) {
        this.logstash = logstash;
        logstash.configure(runConfig);
        if (runConfig.getDataPath() != null) {
            data = runConfig.getDataPath().toFile();
        } else {
            data = null;
        }
        this.store = store;
        this.configpath = runConfig.getConfigPath();
        this.repeats = Integer.parseInt(settings.getProperty(LsBenchSettings.INPUT_DATA_REPEAT));
    }

    @Override
    public AbstractMap<LsMetricStats, ListStatistics> run() {
        try (final LsMetricsMonitor.MonitorExecution monitor = new LsMetricsMonitor.MonitorExecution(logstash.metrics(),
                store)) {
            final ByteArrayOutputStream baos = new ByteArrayOutputStream();

            try (final InputStream cfg = Files.newInputStream(configpath)) {
                IOUtils.copy(cfg, baos);
            }
            if (data != null) {
                logstash.execute(baos.toString(), data, repeats);
            } else {
                logstash.execute(baos.toString());
            }
            return monitor.stopAndGet();
        } catch (final IOException | InterruptedException | ExecutionException | TimeoutException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
