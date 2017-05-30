package org.logstash.instrument.metrics.namespaces;

import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.MetricFactory;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.*;
import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsNull.notNullValue;

/**
 * Created by andrewvc on 6/1/17.
 */
public class PipelineMetricsTest {
    AgentMetrics agentMetrics;
    PipelineMetrics pipelineMetrics;
    @Before
    public void init() {
        MetricFactory metricFactory = new TestMetricFactory();
        agentMetrics = new AgentMetrics(metricFactory);
        pipelineMetrics = new PipelineMetrics("foo", metricFactory, agentMetrics);
    }

    @Test
    public void testInitialState() {
        assertThat(pipelineMetrics.getReloadFailures(), is(0L));
        assertThat(pipelineMetrics.getReloadSuccesses(), is(0L));
    }

    @Test
    public void testReloadSuccess() {
        pipelineMetrics.reloadSuccess();
        assertThat(agentMetrics.getReloadSuccesses(), is(1L));
        assertThat(pipelineMetrics.getReloadSuccesses(), is(1L));
        assertThat(pipelineMetrics.getLastReloadSuccessTimestamp(), is(notNullValue()));
    }

    @Test
    public void testReloadFailure() {
        String message = "myMessage";
        List<String> backtrace = Arrays.asList("foo", "bar");

        pipelineMetrics.reloadFailure(message, backtrace);
        assertThat(agentMetrics.getReloadFailures(), is(1L));
        assertThat(pipelineMetrics.getReloadFailures(), is(1L));
        assertThat(pipelineMetrics.getLastReloadFailureTimestamp(), is(notNullValue()));
        assertThat(pipelineMetrics.getLastReloadFailure().getMessage(), is(message));
        assertThat(pipelineMetrics.getLastReloadFailure().getBacktrace(), is(backtrace));
    }
}