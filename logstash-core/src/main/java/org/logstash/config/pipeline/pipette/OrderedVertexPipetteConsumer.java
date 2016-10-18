package org.logstash.config.pipeline.pipette;

import org.logstash.Event;
import org.logstash.config.pipeline.PipelineRunnerObserver;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.SpecialVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.*;

/**
 * Created by andrewvc on 10/11/16.
 */
public class OrderedVertexPipetteConsumer implements IPipetteConsumer {
    private final List<Vertex> orderedVertices;
    private final Map<Edge,List<Event>> edgesToEvents;
    private final Map<Vertex, ICompiledProcessor> verticesToCompiled;
    private final ArrayList<ExecutionStep> executionSteps;
    private final SpecialVertex queueVertex;
    private final PipelineRunnerObserver observer;

    public class ExecutionStep {
        public Collection<Edge> getOutgoingEdges() {
            return outgoingEdges;
        }

        public Collection<Edge> getIncomingEdges() {
            return incomingEdges;
        }

        public ICompiledProcessor getCompiledProcessor() {
            return compiledProcessor;
        }

        public Vertex getVertex() {
            return vertex;
        }

        private final Collection<Edge> outgoingEdges;
        private final Collection<Edge> incomingEdges;
        private final ICompiledProcessor compiledProcessor;
        private final Vertex vertex;

        public ExecutionStep(Vertex vertex, ICompiledProcessor compiledProcessor,
                             Collection<Edge> incomingEdges, Collection<Edge> outgoingEdges) {
            this.vertex = vertex;
            this.compiledProcessor = compiledProcessor;
            this.incomingEdges = incomingEdges;
            this.outgoingEdges = outgoingEdges;
        }

        public String toString() {
            return "[Execution Step] Vertex: " + vertex;
        }
    }

    public OrderedVertexPipetteConsumer(List<Vertex> orderedVertices, Map<Vertex, ICompiledProcessor> processorVerticesToCompiled, SpecialVertex queueVertex, PipelineRunnerObserver observer) {
        this.orderedVertices = orderedVertices;
        this.verticesToCompiled = processorVerticesToCompiled;
        this.executionSteps = new ArrayList<>(this.orderedVertices.size());
        this.edgesToEvents = new HashMap<>();
        this.queueVertex = queueVertex;
        this.observer = observer;

        for (Vertex vertex : this.orderedVertices) {
            this.executionSteps.add(new ExecutionStep(vertex, verticesToCompiled.get(vertex), vertex.getIncomingEdges(), vertex.getOutgoingEdges()));
        }
    }

    @Override
    public void process(List<Event> events) throws PipetteExecutionException {
        // Reset this on each run, probably cheaper than reallocating
        edgesToEvents.clear();
        // The queue edges just have the input set of events

        queueVertex.getOutgoingEdges().forEach(e -> edgesToEvents.put(e, events));

        for (ExecutionStep executionStep : executionSteps) {
            List<Event> incomingEvents = new ArrayList<>();
            for (Edge edge : executionStep.incomingEdges) {
                List<Event> edgeEvents = edgesToEvents.get(edge);
                if (edgeEvents != null) incomingEvents.addAll(edgeEvents);
            }

            // If there's nothing coming in, just skip execution
            if (incomingEvents.isEmpty()) {
                continue;
            }

            Map<Edge, List<Event>> outgoingEvents = executionStep.getCompiledProcessor().process(incomingEvents);
            observer.postExecutionStep(executionStep, incomingEvents, outgoingEvents);
            edgesToEvents.putAll(outgoingEvents);
        }
    }

    @Override
    public void stop() throws PipetteExecutionException {

    }
}
