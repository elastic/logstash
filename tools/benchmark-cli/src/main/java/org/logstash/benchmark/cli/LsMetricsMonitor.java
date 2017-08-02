package org.logstash.benchmark.cli;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.EnumMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.util.LsBenchJsonUtil;
import org.openjdk.jmh.util.ListStatistics;

public final class LsMetricsMonitor implements Callable<EnumMap<LsMetricStats, ListStatistics>> {

    private final ByteArrayOutputStream baos = new ByteArrayOutputStream();

    private final DataStore store;
    
    private final String metrics;

    private volatile boolean running = true;

    private LsMetricsMonitor(final String metrics, final DataStore store) {
        this.metrics = metrics;
        this.store = store;
    }

    @Override
    public EnumMap<LsMetricStats, ListStatistics> call() throws IOException {
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
        store.store(result);
        return result;
    }

    public void stop() {
        running = false;
    }

    private long[] getCounts() {
        try (final CloseableHttpClient client = HttpClientBuilder.create().build()) {
            baos.reset();
            try (final CloseableHttpResponse response = client
                .execute(new HttpGet(metrics))) {
                response.getEntity().writeTo(baos);
            } catch (final IOException ex) {
                return new long[]{-1L, -1L};
            }
            final Map<String, Object> data = LsBenchJsonUtil.deserializeMetrics(baos.toByteArray());
            final long count;
            if (data.containsKey("pipeline")) {
                count = readNestedLong(data, "pipeline", "events", "filtered");

            } else if (data.containsKey("events")) {
                count = readNestedLong(data, "events", "filtered");
            } else {
                count = -1L;
            }
            final long cpu;
            if (count == -1L) {
                cpu = -1L;
            } else {
                cpu = readNestedLong(data, "process", "cpu", "percent");
            }
            return new long[]{count, cpu};
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
    }

    @SuppressWarnings("unchecked")
    private static long readNestedLong(final Map<String, Object> map, final String ... path) {
        Map<String, Object> nested = map;
        for (int i = 0; i < path.length - 1; ++i) {
            nested = (Map<String, Object>) nested.get(path[i]);
        }
        return ((Number) nested.get(path[path.length - 1])).longValue();
    }

    /**
     * Runs a {@link LsMetricsMonitor} instance in a background thread.
     */
    public static final class MonitorExecution implements AutoCloseable {

        private final Future<EnumMap<LsMetricStats, ListStatistics>> future;

        private final ExecutorService exec;

        private final LsMetricsMonitor monitor;

        /**
         * Ctor.
         * @param metrics Logstash Metrics URL
         * @param store {@link DataStore} to persist benchmark results
         */
        public MonitorExecution(final String metrics, final DataStore store) {
            monitor = new LsMetricsMonitor(metrics, store);
            exec = Executors.newSingleThreadExecutor();
            future = exec.submit(monitor);
        }

        /**
         * Stops metric collection and returns the collected results.
         * @return Statistical results from metric collection
         * @throws InterruptedException On Failure
         * @throws ExecutionException On Failure
         * @throws TimeoutException On Failure
         */
        public EnumMap<LsMetricStats, ListStatistics> stopAndGet()
            throws InterruptedException, ExecutionException, TimeoutException {
            monitor.stop();
            return future.get(20L, TimeUnit.SECONDS);
        }

        @Override
        public void close() {
            exec.shutdownNow();
        }
    }

}
