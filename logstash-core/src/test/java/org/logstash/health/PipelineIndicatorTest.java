package org.logstash.health;

import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;

import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.both;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;

@RunWith(Enclosed.class)
public class PipelineIndicatorTest {
    public static class StatusProbeTest {
        private static final PipelineIndicator.StatusProbe statusProbe = new PipelineIndicator.StatusProbe();

        @Test
        public void testRunning() {
            final PipelineIndicator.Details details = detailsForStatus(PipelineIndicator.Status.RUNNING);

            final Probe.Analysis analysis = statusProbe.analyze(details);
            assertThat(analysis.status, is(Status.GREEN));
            assertThat(analysis.diagnosis, is(nullValue()));
            assertThat(analysis.impact, is(nullValue()));
        }

        @Test
        public void testLoading() {
            final PipelineIndicator.Details details = detailsForStatus(PipelineIndicator.Status.LOADING);

            final Probe.Analysis analysis = statusProbe.analyze(details);
            assertThat(analysis.status, is(Status.YELLOW));
            assertThat(analysis.diagnosis, is(notNullValue()));
            assertThat(analysis.diagnosis.cause, containsString("loading"));
            assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-status.html#loading"));
            assertThat(analysis.impact, is(notNullValue()));
            assertThat(analysis.impact.id, containsString("not_processing"));
            assertThat(analysis.impact.impactAreas, contains(ImpactArea.PIPELINE_EXECUTION));
        }

        @Test
        public void testFinished() {
            final PipelineIndicator.Details details = detailsForStatus(PipelineIndicator.Status.FINISHED);

            final Probe.Analysis analysis = statusProbe.analyze(details);
            assertThat(analysis.status, is(Status.YELLOW));
            assertThat(analysis.diagnosis, is(notNullValue()));
            assertThat(analysis.diagnosis.cause, containsString("finished"));
            assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-status.html#finished"));
            assertThat(analysis.impact, is(notNullValue()));
            assertThat(analysis.impact.id, containsString("not_processing"));
            assertThat(analysis.impact.impactAreas, contains(ImpactArea.PIPELINE_EXECUTION));
        }

        @Test
        public void testTerminated() {
            final PipelineIndicator.Details details = detailsForStatus(PipelineIndicator.Status.TERMINATED);

            final Probe.Analysis analysis = statusProbe.analyze(details);
            assertThat(analysis.status, is(Status.RED));
            assertThat(analysis.diagnosis, is(notNullValue()));
            assertThat(analysis.diagnosis.cause, containsString("error"));
            assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-status.html#terminated"));
            assertThat(analysis.impact, is(notNullValue()));
            assertThat(analysis.impact.id, containsString("not_processing"));
            assertThat(analysis.impact.impactAreas, contains(ImpactArea.PIPELINE_EXECUTION));
        }

        @Test
        public void testUnknown() {
            final PipelineIndicator.Details details = detailsForStatus(PipelineIndicator.Status.UNKNOWN);

            final Probe.Analysis analysis = statusProbe.analyze(details);
            assertThat(analysis.status, is(Status.UNKNOWN));
            assertThat(analysis.diagnosis, is(notNullValue()));
            assertThat(analysis.diagnosis.cause, containsString("not known"));
            assertThat(analysis.diagnosis.helpUrl, containsString("/health-report-pipeline-status.html#unknown"));
            assertThat(analysis.impact, is(notNullValue()));
            assertThat(analysis.impact.id, containsString("not_processing"));
            assertThat(analysis.impact.impactAreas, contains(ImpactArea.PIPELINE_EXECUTION));
        }

        static PipelineIndicator.Details detailsForStatus(PipelineIndicator.Status status) {
            return new PipelineIndicator.Details(status);
        }
    }

    public static class FlowWorkerUtilizationProbeTest {

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

        private static PipelineIndicator.Details detailsForFlow(final Map<String, Map<String,Double>> flow) {
            return detailsForFlow(PipelineIndicator.Status.RUNNING, flow);
        }

        private static PipelineIndicator.Details detailsForFlow(final PipelineIndicator.Status status, final Map<String, Map<String,Double>> flow) {
            return new PipelineIndicator.Details(status, new PipelineIndicator.FlowObservation(flow));
        }

        private static Map<String, Double> flowAnalysis(final double current, final double lifetime) {
            return Map.of("current", current, "lifetime", lifetime);
        }
        private static Map<String, Double> flowAnalysis(final double current, final double lastOneMinute, final double lifetime) {
            return Map.of("current", current, "last_1_minute", lastOneMinute, "lifetime", lifetime);
        }
        private static Map<String, Double> flowAnalysis(final double current, final double lastOneMinute, final double lastFiveMinutes, final double lifetime) {
            return Map.of("current", current, "last_1_minute", lastOneMinute, "last_5_minutes", lastFiveMinutes, "lifetime", lifetime);
        }
    }
}