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
        return new PipelineIndicator(new DetailsSupplier(pipelineId, pipelineDetailsProvider));
    }

    public PipelineIndicator(final DetailsSupplier detailsSupplier) {
        super("pipeline", detailsSupplier::get);

        this.attachProbe("up", new UpProbe());
    }

    public enum RunState {
        UNKNOWN,
        LOADING,
        RUNNING,
        FINISHED,
        TERMINATED,
    }

    @JsonSerialize(using = Details.JsonSerializer.class)
    public static class Details implements Observation {
        private final RunState runState;

        public Details(final RunState runState) {
            this.runState = Objects.requireNonNull(runState, "runState cannot be null");
        }
        public RunState getRunState() {
            return this.runState;
        }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Details> {
            @Override
            public void serialize(final Details details,
                                  final JsonGenerator jsonGenerator,
                                  final SerializerProvider serializerProvider) throws IOException {
                jsonGenerator.writeStartObject();
                jsonGenerator.writeStringField("run_state", details.getRunState().name());
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

    static class UpProbe implements Probe<Details> {
        @Override
        public Analysis analyze(final Details details) {
            switch (details.getRunState()) {
                case LOADING:
                    return Analysis.builder()
                            .setStatus(YELLOW)
                            .setDiagnosis(db -> db.setCause("pipeline is loading").setAction("check logs"))
                            .setImpact(ib -> ib.setSeverity(1).setDescription("pipeline is loading").addImpactArea(ImpactArea.PIPELINE_EXECUTION))
                            .build();
                case RUNNING:
                    return Analysis.builder()
                            .setStatus(GREEN)
                            .build();
                case FINISHED:
                    return Analysis.builder()
                            .setStatus(YELLOW)
                            .setDiagnosis(db -> db
                                    .setCause("pipeline has finished running because its inputs have been closed and events have been processed")
                                    .setAction("if you expect this pipeline to run indefinitely, you will need to configure its inputs to continue receiving or fetching events"))
                            .setImpact(ib -> ib.setSeverity(10).setDescription("pipeline has finished running").addImpactArea(ImpactArea.PIPELINE_EXECUTION))
                            .build();
                case TERMINATED:
                    return Analysis.builder()
                            .setStatus(RED)
                            .setDiagnosis(db -> db.setCause("pipeline is not running, likely because it has encountered an error").setAction("check logs"))
                            .setImpact(ib -> ib.setDescription("pipeline is not running").addImpactArea(ImpactArea.PIPELINE_EXECUTION))
                            .build();
                case UNKNOWN:
                default:
                    return Analysis.builder()
                            .setStatus(UNKNOWN)
                            .setDiagnosis(db -> db.setCause("pipeline is not known; it may have been recently deleted").setAction("check logs"))
                            .setImpact(ib -> ib.setDescription("pipeline is not known").addImpactArea(ImpactArea.PIPELINE_EXECUTION))
                            .build();
            }
        }

    }
}
