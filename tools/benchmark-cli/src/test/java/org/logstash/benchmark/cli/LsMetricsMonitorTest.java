package org.logstash.benchmark.cli;

import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.junit.WireMockRule;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;
import org.apache.commons.io.IOUtils;
import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.junit.Rule;
import org.junit.Test;
import org.logstash.benchmark.cli.ui.LsMetricStats;
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
            metricsFixture()
        )));
        try (final LsMetricsMonitor.MonitorExecution monitor =
                 new LsMetricsMonitor.MonitorExecution(
                     String.format("http://127.0.0.1:%d/%s", http.port(), path),
                     DataStore.NONE
                 )
        ) {
            TimeUnit.SECONDS.sleep(5L);
            final Statistics stats = monitor.stopAndGet().get(LsMetricStats.THROUGHPUT);
            MatcherAssert.assertThat(stats.getMax(), CoreMatchers.is(21052.0D));
        }
    }

    @Test
    public void parsesCpuUsage() throws Exception {
        final String path = "/_node/stats/?pretty";
        http.stubFor(WireMock.get(WireMock.urlEqualTo(path)).willReturn(WireMock.okJson(
            metricsFixture()
        )));
        try (final LsMetricsMonitor.MonitorExecution monitor =
                 new LsMetricsMonitor.MonitorExecution(
                     String.format("http://127.0.0.1:%d/%s", http.port(), path),
                     DataStore.NONE
                 )
        ) {
            TimeUnit.SECONDS.sleep(5L);
            final Statistics stats = monitor.stopAndGet().get(LsMetricStats.CPU_USAGE);
            MatcherAssert.assertThat(stats.getMax(), CoreMatchers.is(63.0D));
        }
    }

    private static String metricsFixture() throws IOException {
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (final InputStream input = LsMetricsMonitorTest.class
            .getResourceAsStream("metrics.json")) {
            IOUtils.copy(input, baos);
        }
        return baos.toString(StandardCharsets.UTF_8.name());
    }
}
