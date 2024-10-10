package org.logstash.health;

import org.junit.Test;

import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;


public class PipelineIndicatorTest {
    private static final String WORKER_UTILIZATION = "worker_utilization";
    private static final PipelineIndicator.FlowWorkerUtilizationProbe flowWorkerUtilizationProbe = new PipelineIndicator.FlowWorkerUtilizationProbe();

    @Test
    public void testFlowWorkerUtilizationNew() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.GREEN));
    }

    @Test
    public void testFlowWorkerUtilizationOK() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 38.4, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.GREEN));
    }

    @Test
    public void testFlowWorkerUtilizationNearlyBlockedOneMinute() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 97.1, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.YELLOW));
        assertThat(analysis.diagnosis.cause, containsString("nearly blocked"));
        assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-flow-worker-utilization.html#nearly-blocked-1m"));
    }

    @Test
    public void testFlowWorkerUtilizationCompletelyBlockedOneMinute() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 100, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.YELLOW));
        assertThat(analysis.diagnosis.cause, containsString("completely blocked"));
        assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-flow-worker-utilization.html#blocked-1m"));
    }

    @Test
    public void testFlowWorkerUtilizationNearlyBlockedFiveMinutes() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 97.1, 96.1, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.YELLOW));
        assertThat(analysis.diagnosis.cause, containsString("nearly blocked"));
        assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-flow-worker-utilization.html#nearly-blocked-5m"));
    }

    @Test
    public void testFlowWorkerUtilizationCompletelyBlockedFiveMinutes() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 100, 100, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.RED));
        assertThat(analysis.diagnosis.cause, containsString("completely blocked"));
        assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-flow-worker-utilization.html#blocked-5m"));
    }

    @Test
    public void testFlowWorkerUtilizationNearlyBlockedFiveMinutesRecovering() throws Exception {
        final PipelineIndicator.Details details = detailsForFlow(Map.of(WORKER_UTILIZATION, flowAnalysis(30.2, 79, 97, 87.0)));

        Probe.Analysis analysis = flowWorkerUtilizationProbe.analyze(details);
        assertThat(analysis.status, is(Status.YELLOW));
        assertThat(analysis.diagnosis.cause, both(containsString("nearly blocked")).and(containsString("recovering")));
        assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-flow-worker-utilization.html#nearly-blocked-5m"));
    }

    private PipelineIndicator.Details detailsForFlow(final Map<String, Map<String,Double>> flow) {
        return detailsForFlow(PipelineIndicator.Status.RUNNING, flow);
    }

    private PipelineIndicator.Details detailsForFlow(final PipelineIndicator.Status status, final Map<String, Map<String,Double>> flow) {
        return new PipelineIndicator.Details(status, new PipelineIndicator.FlowObservation(flow));
    }

    private Map<String, Double> flowAnalysis(final double current, final double lifetime) {
        return Map.of("current", current, "lifetime", lifetime);
    }
    private Map<String, Double> flowAnalysis(final double current, final double lastOneMinute, final double lifetime) {
        return Map.of("current", current, "last_1_minute", lastOneMinute, "lifetime", lifetime);
    }
    private Map<String, Double> flowAnalysis(final double current, final double lastOneMinute, final double lastFiveMinutes, final double lifetime) {
        return Map.of("current", current, "last_1_minute", lastOneMinute, "last_5_minutes", lastFiveMinutes, "lifetime", lifetime);
    }
}