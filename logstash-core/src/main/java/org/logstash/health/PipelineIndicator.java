package org.logstash.health;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.io.IOException;
import java.util.Objects;

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

        public Details(final Status status) {
            this.status = Objects.requireNonNull(status, "status cannot be null");
        }
        public Status getStatus() {
            return this.status;
        }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Details> {
            @Override
            public void serialize(final Details details,
                                  final JsonGenerator jsonGenerator,
                                  final SerializerProvider serializerProvider) throws IOException {
                jsonGenerator.writeStartObject();
                jsonGenerator.writeObjectField("status", details.getStatus());
                jsonGenerator.writeEndObject();
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

        @Override
        public Analysis analyze(final Details details) {
            switch (details.getStatus().getState()) {
                case LOADING:
                    return Analysis.builder()
                            .withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("loading"))
                                    .withCause("pipeline is loading")
                                    .withAction("if pipeline does not come up quickly, you may need to check the logs to see if it is stalled"))
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
                                    .withAction("if you expect this pipeline to run indefinitely, you will need to configure its inputs to continue receiving or fetching events"))
                            .withImpact(NOT_PROCESSING.withSeverity(10).withDescription("pipeline has finished running").build())
                            .build();
                case TERMINATED:
                    return Analysis.builder()
                            .withStatus(RED)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("terminated"))
                                    .withCause("pipeline is not running, likely because it has encountered an error")
                                    .withAction("view logs to determine the cause of abnormal pipeline shutdown"))
                            .withImpact(NOT_PROCESSING.withSeverity(1).build())
                            .build();
                case UNKNOWN:
                default:
                    return Analysis.builder()
                            .withStatus(YELLOW)
                            .withDiagnosis(db -> db
                                    .withId(diagnosisId("unknown"))
                                    .withCause("pipeline is not known; it may have been recently deleted")
                                    .withAction("check logs"))
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
}
