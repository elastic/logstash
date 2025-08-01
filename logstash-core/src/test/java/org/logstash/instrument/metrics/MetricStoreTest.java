package org.logstash.instrument.metrics;

import org.junit.Test;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.Arrays;
import java.util.List;

import static org.junit.Assert.*;

public class MetricStoreTest {

    @Test
    public void testHasMetricWhenItContains() {
        //setup
        List<String> path = Arrays.asList("node", "sashimi", "pipelines", "pipeline01", "plugins", "logstash-output-elasticsearch", "event_in");

        String metricKey = "event_in";
        List<String> namespaces = Arrays.asList("node", "sashimi", "pipelines", "pipeline01", "plugins", "logstash-output-elasticsearch");

        MetricStore sut = new MetricStore();
        LongCounter metric = (LongCounter) sut.fetchOrStore(namespaces, metricKey, () -> new LongCounter(metricKey));
        metric.increment();

        // Exercise
        assertTrue(sut.hasMetric(path));
    }

}