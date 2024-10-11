/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.logstash.instrument.metrics.MetricKeys;

import java.io.IOException;
import java.util.Map;
import java.util.Objects;
import java.util.OptionalDouble;
import java.util.stream.Collectors;

import static org.logstash.health.Status.*;

/**
 * A {@code PipelineIndicator} is a specialized {@link ProbeIndicator} that is meant for assessing the health of
 * an individual pipeline.
 */
public class PipelineIndicator extends ProbeIndicator<PipelineIndicator.Details> {

    public static PipelineIndicator forPipeline(final String pipelineId,
                                                final PipelineDetailsProvider pipelineDetailsProvider) {
        PipelineIndicator pipelineIndicator = new PipelineIndicator(new DetailsSupplier(pipelineId, pipelineDetailsProvider));
        pipelineIndicator.attachProbe("status", new StatusProbe());
        pipelineIndicator.attachProbe("flow:worker_utilization", new FlowWorkerUtilizationProbe());
        return pipelineIndicator;
    }

    private PipelineIndicator(final DetailsSupplier detailsSupplier) {
        super("pipeline", detailsSupplier::get);
    }

    @JsonSerialize(using = Status.JsonSerializer.class)
    public static class Status {
        public enum State {
            UNKNOWN,
            LOADING,
            RUNNING,
            FINISHED,
            TERMINATED,
        }

        public static final Status UNKNOWN = new Status(State.UNKNOWN);
        public static final Status LOADING = new Status(State.LOADING);
        public static final Status RUNNING = new Status(State.RUNNING);
        public static final Status FINISHED = new Status(State.FINISHED);
        public static final Status TERMINATED = new Status(State.TERMINATED);

        private final State state;
        public Status(final State state) {
            this.state = state;
        }
        public State getState() {
            return state;
        }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Status> {
            @Override
            public void serialize(Status value, JsonGenerator gen, SerializerProvider serializers) throws IOException {
                gen.writeStartObject();
                gen.writeStringField("state", value.getState().toString());
                gen.writeEndObject();
            }
        }
    }

    @JsonSerialize(using = Details.JsonSerializer.class)
    public static class Details implements Observation {
        private final Status status;
        private final FlowObservation flow;

        public Details(Status status, FlowObservation flow) {
            this.status = Objects.requireNonNull(status, "status cannot be null");
            this.flow = Objects.requireNonNullElse(flow, FlowObservation.EMPTY);
        }

        public Details(final Status status) {
            this(status, null);
        }

        public Status getStatus() {
            return this.status;
        }
        public FlowObservation getFlow() { return this.flow; }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Details> {
            @Override
            public void serialize(final Details details,
                                  final JsonGenerator jsonGenerator,
                                  final SerializerProvider serializerProvider) throws IOException {
                jsonGenerator.writeStartObject();
                jsonGenerator.writeObjectField("status", details.getStatus());
                FlowObservation flow = details.getFlow();
                if (flow != null && !flow.isEmpty()) {
                    jsonGenerator.writeObjectField("flow", flow);
                }
                jsonGenerator.writeEndObject();
            }
        }
    }

    @JsonSerialize(using = FlowObservation.JsonSerializer.class)
    public static class FlowObservation {
        private static FlowObservation EMPTY = new FlowObservation(Map.of());
        final Map<String, Map<String,Double>> capture;

        public FlowObservation(final Map<String, Map<String,Double>> capture) {
            this.capture = Objects.requireNonNull(capture, "capture cannot be null").entrySet()
                                    .stream()
                                    .collect(Collectors.toUnmodifiableMap(Map.Entry::getKey, (e) -> Map.copyOf(e.getValue())));
        }

        public OptionalDouble getRate(final String flowMetricName, final String flowMetricWindow) {
            final Map<String, Double> flowMetrics = capture.get(flowMetricName);
            if (flowMetrics == null) {
                return OptionalDouble.empty();
            }
            final Double rate = flowMetrics.get(flowMetricWindow);
            if (rate == null) {
                return OptionalDouble.empty();
            } else {
                return OptionalDouble.of(rate);
            }
        }

        public boolean isEmpty() {
            return capture.isEmpty() || capture.values().stream().allMatch(Map::isEmpty);
        }

        static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<FlowObservation> {
            @Override
            public void serialize(FlowObservation value, JsonGenerator gen, SerializerProvider serializers) throws IOException {
                gen.writeObject(value.capture);
            }
        }
    }


    /**
     * This interface is implemented by the ruby-Agent
     */
    @FunctionalInterface
    public interface PipelineDetailsProvider {
        Details pipelineDetails(final String pipelineId);
    }

    public static class DetailsSupplier {
        private final String pipelineId;
        private final PipelineDetailsProvider pipelineDetailsProvider;
        DetailsSupplier(final String pipelineId,
                        final PipelineDetailsProvider pipelineDetailsProvider) {
            this.pipelineId = pipelineId;
            this.pipelineDetailsProvider = pipelineDetailsProvider;
        }

        public Details get() {
            return this.pipelineDetailsProvider.pipelineDetails(pipelineId);
        }
    }

    static class StatusProbe implements Probe<Details> {
        static final Impact.Builder NOT_PROCESSING = Impact.builder()
                .withId(impactId("not_processing"))
                .withDescription("the pipeline is not currently processing")
                .withAdditionalImpactArea(ImpactArea.PIPELINE_EXECUTION);

        static final HelpUrl HELP_URL = new HelpUrl("health-report-pipeline-status");

        @Override
        public Analysis analyze(final Details details) {
            switch (details.getStatus().getState()) {
                case LOADING:
                    return Analysis.builder()
                            .withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("loading"))
                                    .withCause("pipeline is loading")
                                    .withAction("if pipeline does not come up quickly, you may need to check the logs to see if it is stalled")
                                    .withHelpUrl(HELP_URL.withAnchor("loading").toString()))
                            .withImpact(NOT_PROCESSING.withSeverity(1).withDescription("pipeline is loading").build())
                            .build();
                case RUNNING:
                    return Analysis.builder()
                            .withStatus(GREEN)
                            .build();
                case FINISHED:
                    return Analysis.builder()
                            .withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("finished"))
                                    .withCause("pipeline has finished running because its inputs have been closed and events have been processed")
                                    .withAction("if you expect this pipeline to run indefinitely, you will need to configure its inputs to continue receiving or fetching events")
                                    .withHelpUrl(HELP_URL.withAnchor("finished").toString()))
                            .withImpact(NOT_PROCESSING.withSeverity(10).withDescription("pipeline has finished running").build())
                            .build();
                case TERMINATED:
                    return Analysis.builder()
                            .withStatus(RED)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("terminated"))
                                    .withCause("pipeline is not running, likely because it has encountered an error")
                                    .withAction("view logs to determine the cause of abnormal pipeline shutdown")
                                    .withHelpUrl(HELP_URL.withAnchor("terminated").toString()))
                            .withImpact(NOT_PROCESSING.withSeverity(1).build())
                            .build();
                case UNKNOWN:
                default:
                    return Analysis.builder()
                            .withStatus(UNKNOWN)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("unknown"))
                                    .withCause("pipeline is not known; it may have been recently deleted or failed to start")
                                    .withAction("view logs to determine if the pipeline failed to start")
                                    .withHelpUrl(HELP_URL.withAnchor("unknown").toString()))
                            .withImpact(NOT_PROCESSING.withSeverity(2).build())
                            .build();
            }
        }

        static String diagnosisId(final String state) {
            return String.format("logstash:health:pipeline:status:diagnosis:%s", state);
        }

        static String impactId(final String state) {
            return String.format("logstash:health:pipeline:status:impact:%s", state);
        }


    }

    static class FlowWorkerUtilizationProbe implements Probe<Details> {
        static final String LAST_1_MINUTE = "last_1_minute";
        static final String LAST_5_MINUTES = "last_5_minutes";

        static final String WORKER_UTILIZATION = MetricKeys.WORKER_UTILIZATION_KEY.asJavaString();

        static final Impact.Builder BLOCKED_PROCESSING = Impact.builder()
                .withId(impactId("blocked_processing"))
                .withDescription("the pipeline is blocked")
                .withAdditionalImpactArea(ImpactArea.PIPELINE_EXECUTION);

        static final HelpUrl HELP_URL = new HelpUrl("health-report-pipeline-flow-worker-utilization");

        @Override
        public Analysis analyze(Details observation) {

            final OptionalDouble lastFiveMinutes = observation.flow.getRate(WORKER_UTILIZATION, LAST_5_MINUTES);
            final OptionalDouble lastOneMinute = observation.flow.getRate(WORKER_UTILIZATION, LAST_1_MINUTE);

            if (lastFiveMinutes.isPresent()) {
                if (lastFiveMinutes.getAsDouble() > 99.999) {
                    return Analysis.builder()
                            .withStatus(RED)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("5m-blocked"))
                                    .withCause(diagnosisCause("completely blocked", "five minutes", false))
                                    .withAction("address bottleneck or add resources")
                                    .withHelpUrl(HELP_URL.withAnchor("blocked-5m").toString()))
                            .withImpact(BLOCKED_PROCESSING.withSeverity(1).build())
                            .build();
                } else if (lastFiveMinutes.getAsDouble() >= 95.00) {
                    final boolean isRecovering = lastOneMinute.isPresent() && lastOneMinute.getAsDouble() <= 80.00;
                    return Analysis.builder()
                            .withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("5m-nearly-blocked"))
                                    .withCause(diagnosisCause("nearly blocked", "five minutes", isRecovering))
                                    .withAction(isRecovering ? "continue to monitor" : "address bottleneck or add resources")
                                    .withHelpUrl(HELP_URL.withAnchor("nearly-blocked-5m").toString()))
                            .withImpact(BLOCKED_PROCESSING.withSeverity(1).build())
                            .build();
                }
            }

            if (lastOneMinute.isPresent()) {
                if (lastOneMinute.getAsDouble() > 99.999) {
                    return Analysis.builder().withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("1m-blocked"))
                                    .withCause(diagnosisCause("completely blocked", "one minute", false))
                                    .withAction("address bottleneck or add resources")
                                    .withHelpUrl(HELP_URL.withAnchor("blocked-1m").toString()))
                            .withImpact(BLOCKED_PROCESSING.withSeverity(2).build())
                            .build();
                } else if (lastOneMinute.getAsDouble() >= 95.00) {
                        return Analysis.builder().withStatus(YELLOW)
                                .withDiagnosis(db -> db
                                        .withId(diagnosisId("1m-nearly-blocked"))
                                        .withCause(diagnosisCause("nearly blocked", "one minute", false))
                                        .withAction("address bottleneck or add resources")
                                        .withHelpUrl(HELP_URL.withAnchor("nearly-blocked-1m").toString()))
                                .withImpact(BLOCKED_PROCESSING.withSeverity(2).build())
                                .build();
                }
            }


            return Analysis.builder().build();
        }

        static String diagnosisCause(String condition, String period, boolean isRecovering) {
            final StringBuilder cause = new StringBuilder("pipeline workers have been ").append(condition).append(" for at least ").append(period);
            if (isRecovering) {
                cause.append(", but they appear to be recovering");
            }
            return cause.toString();
        }

        static String diagnosisId(final String state) {
            return String.format("logstash:health:pipeline:flow:worker_utilization:diagnosis:%s", state);
        }

        static String impactId(final String state) {
            return String.format("logstash:health:pipeline:flow:impact:%s", state);
        }
    }
}
