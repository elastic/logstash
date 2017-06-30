package org.logstash.benchmark.cli;

import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.junit.WireMockRule;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.EnumMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.junit.Rule;
import org.junit.Test;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.openjdk.jmh.util.ListStatistics;
import org.openjdk.jmh.util.Statistics;

/**
 * Tests for {@link LsMetricsMonitor}.
 */
public final class LsMetricsMonitorTest {

    @Rule
    public WireMockRule http = new WireMockRule(0);

    @Test
    public void parsesFilteredCount() throws Exception {
        final String path = "/_node/stats/?pretty";
        http.stubFor(WireMock.get(WireMock.urlEqualTo(path)).willReturn(WireMock.okJson(
            new String(
                Files.readAllBytes(
                    Paths.get(LsMetricsMonitorTest.class.getResource("metrics.json").getPath()
                    ))
                , StandardCharsets.UTF_8)
        )));
        final ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            final LsMetricsMonitor monitor =
                new LsMetricsMonitor(String.format("http://127.0.0.1:%d/%s", http.port(), path));
            final Future<EnumMap<LsMetricStats, ListStatistics>> future = executor.submit(monitor);
            TimeUnit.SECONDS.sleep(5L);
            monitor.stop();
            final Statistics stats = future.get().get(LsMetricStats.THROUGHPUT);
            MatcherAssert.assertThat(stats.getMax(), CoreMatchers.is(21052.0D));
        } finally {
            executor.shutdownNow();
        }
    }

    @Test
    public void parsesCpuUsage() throws Exception {
        final String path = "/_node/stats/?pretty";
        http.stubFor(WireMock.get(WireMock.urlEqualTo(path)).willReturn(WireMock.okJson(
            new String(
                Files.readAllBytes(
                    Paths.get(LsMetricsMonitorTest.class.getResource("metrics.json").getPath()
                    ))
                , StandardCharsets.UTF_8)
        )));
        final ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            final LsMetricsMonitor monitor =
                new LsMetricsMonitor(String.format("http://127.0.0.1:%d/%s", http.port(), path));
            final Future<EnumMap<LsMetricStats, ListStatistics>> future = executor.submit(monitor);
            TimeUnit.SECONDS.sleep(5L);
            monitor.stop();
            final Statistics stats = future.get().get(LsMetricStats.CPU_USAGE);
            MatcherAssert.assertThat(stats.getMax(), CoreMatchers.is(63.0D));
        } finally {
            executor.shutdownNow();
        }
    }
}
