package org.logstash.instrument.metrics.namespaces;

import org.logstash.instrument.metrics.Counter;
import org.logstash.instrument.metrics.MetricFactory;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by andrewvc on 5/30/17.
 */
public class AgentMetrics {
    private final MetricFactory metricFactory;
    private final Counter reloadSuccesses;
    private final Counter reloadFailures;
    private final Map<String, PipelineMetrics> pipelineMetrics;

    public AgentMetrics(MetricFactory metricFactory) {
        this.metricFactory = metricFactory;

        List<String> reloadsNamespace = Arrays.asList("stats", "reloads");
        reloadSuccesses = metricFactory.makeCounter(reloadsNamespace, "successes", 0);
        reloadFailures = metricFactory.makeCounter(reloadsNamespace, "failures", 0);

        this.pipelineMetrics = new ConcurrentHashMap<>();
    }

    protected void reloadSuccess() {
        this.reloadSuccesses.increment();
    }

    public long getReloadSuccesses() {
        return reloadSuccesses.get();
    }

    protected void reloadFailure() {
        this.reloadFailures.increment();
    }

    public long getReloadFailures() {
        return this.reloadFailures.get();
    }

    public PipelineMetrics addPipeline(String pipelineId) {
        PipelineMetrics metrics = new PipelineMetrics(pipelineId, metricFactory, this);
        pipelineMetrics.put(pipelineId, metrics);
        return metrics;
    }

    public void removePipeline(String pipelineId) {
        pipelineMetrics.remove(pipelineId);
    }

    public PipelineMetrics getPipelineMetrics(String pipelineId) {
        return pipelineMetrics.get(pipelineId);
    }
}
