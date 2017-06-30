package org.logstash.benchmark.cli;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.openjdk.jmh.util.ListStatistics;

public final class LsMetricsMonitor implements Callable<EnumMap<LsMetricStats, ListStatistics>> {

    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private final String metrics;

    private volatile boolean running = true;

    public LsMetricsMonitor(final String metrics) {
        this.metrics = metrics;
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> call() {
        final ListStatistics stats = new ListStatistics();
        long count = 0L;
        final ListStatistics counts = new ListStatistics();
        final ListStatistics cpu = new ListStatistics();
        long start = System.nanoTime();
        while (running) {
            try {
                TimeUnit.SECONDS.sleep(1L);
                final long[] newcounts = getCounts();
                final long newcount = newcounts[0];
                if (newcount < 0L) {
                    start = System.nanoTime();
                    continue;
                }
                final long newstrt = System.nanoTime();
                stats.addValue(
                    (double) (newcount - count) /
                        (double) TimeUnit.SECONDS.convert(newstrt - start, TimeUnit.NANOSECONDS)
                );
                start = newstrt;
                count = newcount;
                counts.addValue((double) count);
                cpu.addValue(newcounts[1]);
            } catch (final InterruptedException ex) {
                throw new IllegalStateException(ex);
            }
        }
        final EnumMap<LsMetricStats, ListStatistics> result = new EnumMap<>(LsMetricStats.class);
        result.put(LsMetricStats.THROUGHPUT, stats);
        result.put(LsMetricStats.COUNT, counts);
        result.put(LsMetricStats.CPU_USAGE, cpu);
        return result;
    }

    public void stop() {
        running = false;
    }

    private long[] getCounts() {
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (final CloseableHttpClient client = HttpClientBuilder.create().build()) {
            baos.reset();
            try (final CloseableHttpResponse response = client
                .execute(new HttpGet(metrics))) {
                response.getEntity().writeTo(baos);
            } catch (final IOException ex) {
                return new long[]{-1L, -1L};
            }
            final Map<String, Object> data =
                OBJECT_MAPPER.readValue(baos.toByteArray(), HashMap.class);
            final long count;
            if (data.containsKey("pipeline")) {
                count = getFiltered((Map<String, Object>) data.get("pipeline"));

            } else if (data.containsKey("events")) {
                count = getFiltered(data);
            } else {
                count = -1L;
            }
            final long cpu;
            if (count == -1L) {
                cpu = -1L;
            } else {
                cpu = ((Number) ((Map<String, Object>) ((Map<String, Object>) data.get("process"))
                    .get("cpu")).get("percent")).longValue();
            }
            return new long[]{count, cpu};
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    private static long getFiltered(final Map<String, Object> data) {
        return ((Number) ((Map<String, Object>) (data.get("events")))
            .get("filtered")).longValue();
    }
}
