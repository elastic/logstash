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
