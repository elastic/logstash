package org.logstash.instrument.metrics.namespaces;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.logstash.Timestamp;
import org.logstash.instrument.metrics.Counter;
import org.logstash.instrument.metrics.Gauge;
import org.logstash.instrument.metrics.MetricFactory;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 5/30/17.
 */
public class PipelineMetrics {
    private final String pipelineId;
    private final MetricFactory metricFactory;
    private final List<String> namespaceRoot;
    private final List<String> reloadsNamespace;
    private final Counter reloadSuccesses;
    private final Counter reloadFailures;
    private final Gauge<Timestamp> lastReloadSuccessTimestamp;
    private final Gauge<Timestamp> lastReloadFailureTimestamp;
    private final AgentMetrics agentMetrics;
    private volatile Gauge<ReloadFailure> lastReloadFailure;

    public PipelineMetrics(String pipelineId, MetricFactory metricFactory, AgentMetrics agentMetrics) {
        this.pipelineId = pipelineId;
        this.metricFactory = metricFactory;
        this.agentMetrics = agentMetrics;
        this.namespaceRoot = Arrays.asList("stats", "pipelines", pipelineId);

        this.reloadsNamespace = Stream.concat(namespaceRoot.stream(), Stream.of("reloads")).collect(Collectors.toList());
        this.reloadSuccesses = metricFactory.makeCounter(reloadsNamespace, "successes", 0);
        this.reloadFailures = metricFactory.makeCounter(reloadsNamespace, "failures", 0);

        this.lastReloadSuccessTimestamp = metricFactory.makeGauge(reloadsNamespace, "last_success_timestamp", null);
        this.lastReloadFailureTimestamp = metricFactory.makeGauge(reloadsNamespace, "last_failure_timestamp", null);
        this.lastReloadFailure = metricFactory.makeGauge(reloadsNamespace, "last_error", null);
    }

    public void reloadSuccess() {
        this.agentMetrics.reloadSuccess();

        this.reloadSuccesses.increment();
        this.lastReloadSuccessTimestamp.set(Timestamp.now());
    }

    public long getReloadSuccesses() {
        return this.reloadSuccesses.get();
    }

    public Timestamp getLastReloadSuccessTimestamp() {
        return this.lastReloadSuccessTimestamp.get();
    }

    class ReloadFailure {
        @JsonSerialize
        private final String message;
        @JsonSerialize
        private final List<String> backtrace;

        ReloadFailure(String message, List<String> backtrace) {
            this.message = message;
            this.backtrace = backtrace;
        }

        public String getMessage() {
            return message;
        }

        public List<String> getBacktrace() {
            return backtrace;
        }
    }

    public void reloadFailure(String message, List<String> backtrace) {
        this.agentMetrics.reloadFailure();

        this.reloadFailures.increment();
        this.lastReloadFailureTimestamp.set(Timestamp.now());

        this.lastReloadFailure.set(new ReloadFailure(message, backtrace));
    }

    public Timestamp getLastReloadFailureTimestamp() {
        return this.lastReloadFailureTimestamp.get();
    }

    public ReloadFailure getLastReloadFailure() {
        return this.lastReloadFailure.get();
    }

    public long getReloadFailures() {
        return this.reloadFailures.get();
    }
}
