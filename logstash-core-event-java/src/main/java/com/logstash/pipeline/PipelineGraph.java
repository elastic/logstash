package com.logstash.pipeline;


import com.logstash.Event;
import com.logstash.pipeline.graph.Condition;
import com.logstash.pipeline.graph.Edge;
import com.logstash.pipeline.graph.Vertex;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 2/20/16.
 */
public class PipelineGraph {
    private final Set<Vertex> sources;
    private final List<Vertex> sortedVertices;
    private final List<Vertex> postQueueVertices;
    private Set<Edge> edges;
    private final Map<String, Vertex> vertices;
    private final ComponentProcessor componentProcessor;

    public static class InvalidGraphError extends Throwable {
        InvalidGraphError(String message) {
            super(message);
        }
    }

    public PipelineGraph(Map<String, Vertex> vertices, ComponentProcessor componentProcessor) throws InvalidGraphError {
        this.vertices = vertices;
        this.componentProcessor = componentProcessor;
        this.edges = getVertices().stream().flatMap(v -> v.getOutEdges().stream()).collect(Collectors.toSet());
        // Precalculate source elements (those with no incoming edges)
        this.sources = getVertices().stream().filter(Vertex::isSource).collect(Collectors.toSet());

        // Setup each vertex with the component processor
        Arrays.stream(this.getComponents()).forEach(componentProcessor::setup);

        this.sortedVertices = topologicalSort();
        int queueIndex = this.sortedVertices.indexOf(this.queueVertex());
        // Workers only process stuff after the queue, so this list becomes valuable
        this.postQueueVertices = this.sortedVertices.subList(queueIndex+1,this.sortedVertices.size());
    }

    // Uses Kahn's algorithm to do a topological sort and detect cycles
    public List<Vertex> topologicalSort() throws InvalidGraphError {
        List<Vertex> sorted = new ArrayList<>(this.vertices.size());

        Deque<Vertex> pending = new LinkedList<>();
        pending.addAll(sources);

        Set<Edge> traversedEdges = new HashSet<>();

        while (!pending.isEmpty()) {
            Vertex currentVertex = pending.removeFirst();
            sorted.add(currentVertex);
            currentVertex.getOutEdges().forEach(edge -> {
                traversedEdges.add(edge);
                Vertex toVertex = edge.getTo();
                if (toVertex.getInEdges().stream().allMatch(traversedEdges::contains)) {
                    pending.add(toVertex);
                }
            });
        }

        // Check for cycles
        if (this.edges.stream().noneMatch(traversedEdges::contains)) {
            throw new InvalidGraphError("Graph has cycles, is not a DAG!");
        }

        return sorted;
    }

    public void processWorker(Batch batch) {
        Map<Edge, List<Event>> edgePayloads = new HashMap<>(edges.size());

        Set<Vertex> workerRootVertices = this.queueVertex().getOutVertices().collect(Collectors.toSet());

        for (Vertex vertex : postQueueVertices) {
            // Root elements get the input batch directly
            // We should probably consider cloning these at some point
            // because if we truly have multiple roots that would be problematic
            List<Event> incoming;
            if (workerRootVertices.contains(vertex)) {
                incoming = batch.getEvents();
            } else {
                incoming = vertex.getInEdges().stream().
                        flatMap(e -> edgePayloads.get(e).stream()).
                        collect(Collectors.toList());
            }

            // Sort incoming events if we're sending to an output, this gives us strict ordering
            // if a single worker is used and there is only one path through the pipeline
            if (vertex.getComponent().getType() == Component.Type.OUTPUT) {
                incoming.sort((e1, e2) -> {
                    // Nulls go last!
                    if (e1 == null && e2 == null) return 0;
                    else if (e1 == null) return 1;
                    else if (e2 == null) return -1;
                    else return Integer.compare(e1.getBatchSequence(), e2.getBatchSequence());
                });
            }

            edgePayloads.putAll(processVertex(vertex, incoming));
        }
    }

    public LinkedHashMap<Edge, List<Event>> processVertex(Vertex v, List<Event> inEvents) {
        Component component = v.getComponent();

        LinkedHashMap<Edge, List<Event>> vMapping = new LinkedHashMap<>();
        if (component.getType() == Component.Type.PREDICATE) {
            // Edges are in order of branching
            List<Event> remainingEvents = inEvents;
            for (Edge edge : v.getOutEdges()) {
                Condition condition = edge.getCondition();

                BooleanEventsResult results;
                if (condition != Condition.elseCondition) {
                    results = componentProcessor.processCondition(condition, remainingEvents);
                } else {
                    results = new BooleanEventsResult(remainingEvents, new LinkedList<>());
                }
                remainingEvents = results.getFalseEvents();

                vMapping.put(edge, results.getTrueEvents());
            }
        } else {
            List<Event> outEvents = componentProcessor.process(component, inEvents);
            v.getOutEdges().forEach(outE -> vMapping.put(outE, outEvents));
        }

        return vMapping;
    }

    // Vertices that occur after the queue
    // This is a bit hacky and only supports one queue at the moment
    // for our current pipeline
    public Stream<Vertex> workerVertices() {
        return queueVertex().getOutVertices();
    }

    public Vertex queueVertex() {
        return this.vertices.get("main-queue");
    }

    public Component[] getComponents() {
        return this.vertices.values().stream().map(Vertex::getComponent).toArray(Component[]::new);
    }

    public Stream<Component> componentStream() {
        return this.vertices.values().stream().map(Vertex::getComponent);
    }

    public Map<String, Vertex> getVertexMapping() {
        return this.vertices;
    }

    public Collection<Vertex> getVertices() {
        return this.vertices.values();
    }

    public void flush(boolean shutdown) {
        this.componentStream().forEach(c -> componentProcessor.flush(c, shutdown));
    }
}
