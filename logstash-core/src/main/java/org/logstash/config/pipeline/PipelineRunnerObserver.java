package org.logstash.config.pipeline;

import org.logstash.Event;
import org.logstash.config.pipeline.pipette.OrderedVertexPipetteProcessor;
import org.logstash.config.ir.graph.Edge;

import java.util.List;
import java.util.Map;

/**
 * Created by andrewvc on 10/14/16.
 *
 * By default this class is a noop, override any methods you want to implement
 */
public class PipelineRunnerObserver {
    public void postExecutionStep(OrderedVertexPipetteProcessor.ExecutionStep executionStep, List<Event> incomingEvents, Map<Edge, List<Event>> outgoingEvents) {

    }

    public void initialize(PipelineRunner pipelineRunner) {
        
    }

    public void beforeStart(PipelineRunner pipelineRunner) {
    }

    public void afterStart(PipelineRunner pipelineRunner) {
    }

    public void beforeStop(PipelineRunner pipelineRunner) {
        
    }

    public void inputsStopped(PipelineRunner pipelineRunner) {
    }

    public void afterStop(PipelineRunner pipelineRunner) {
    }

    public void beforeInputsStart(PipelineRunner pipelineRunner) {

    }

    public void afterInputsStart(PipelineRunner pipelineRunner) {
        
    }

    public void beforeProcessorsStart(PipelineRunner pipelineRunner) {
    }

    public void afterProcessorsStart(PipelineRunner pipelineRunner) {
    }
}
