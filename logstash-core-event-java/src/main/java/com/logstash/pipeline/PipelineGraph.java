package com.logstash.pipeline;


import com.logstash.Event;
import com.logstash.pipeline.graph.Condition;
import com.logstash.pipeline.graph.Edge;
import com.logstash.pipeline.graph.Vertex;

import java.util.*;
import java.util.function.BiConsumer;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 2/20/16.
 */
public class PipelineGraph {
    private final Map<String, Vertex> vertices;
    private final ComponentProcessor componentProcessor;

    public PipelineGraph(Map<String, Vertex> vertices, ComponentProcessor componentProcessor) {
        this.vertices = vertices;
        this.componentProcessor = componentProcessor;

        //TODO: Make this streamy
        Component[] components = this.getComponents();
        for (int i=0; i < components.length; i++) {
            Component component = components[i];
            componentProcessor.setup(component);
        }
    }

    public void processWorker(Batch batch) {
        // Perform a breadth-first traversal, using the queue to track what's next
        Deque<Map.Entry<Vertex,List<Event>>> queue = new LinkedList<>();
        workerVertices().forEach(wv -> {
            Map.Entry<Vertex, List<Event>> rootEntry = new AbstractMap.SimpleEntry<>(wv, batch.getEvents());
            queue.addLast(rootEntry);
        });

        // We want to accumulate as many events as possible and process all
        // outputs last
        Map<Vertex, List<Event>> terminalVerticesToEvents = new HashMap<>();

        Map.Entry<Vertex, List<Event>> current;
        for(current = queue.pollFirst(); current != null; current = queue.pollFirst()) {
            Vertex currentVertex = current.getKey();
            List<Event> currentEvents = current.getValue();

            LinkedHashMap<Vertex, List<Event>> vMapping = processVertex(currentVertex, currentEvents);

            vMapping.forEach((mappingVertex, mappingEvents) -> {
                if (mappingVertex.isTerminal()) {
                    terminalVerticesToEvents.putIfAbsent(mappingVertex, new ArrayList<>());
                    List<Event> terminalEvents = terminalVerticesToEvents.get(mappingVertex);
                    terminalEvents.addAll(mappingEvents);
                } else if (mappingEvents.size() > 0){
                    queue.addLast(new AbstractMap.SimpleEntry<>(mappingVertex, mappingEvents));
                }
            });
        }

        // Finally process our terminal (usually output) vertices
        terminalVerticesToEvents.forEach((v, events) -> {
            // Sort stuff so that batches come out in order
            // People might want -w1 to maintain order, this helps that
            events.sort(new Comparator<Event>() {
                @Override
                public int compare(Event e1, Event e2) {
                    // Nulls go last!
                    if (e1 == null && e2 == null) return 0;
                    else if (e1 == null) return 1;
                    else if (e2 == null) return -1;
                    else return Integer.compare(e1.getBatchSequence(), e2.getBatchSequence());
                }
            });
            processVertex(v, events);
        });
    }

    public LinkedHashMap<Vertex, List<Event>> processVertex(Vertex v, List<Event> inEvents) {
        Component component = v.getComponent();

        LinkedHashMap<Vertex, List<Event>> vMapping = new LinkedHashMap<>();
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

                vMapping.put(edge.getTo(), results.getTrueEvents());
            }
        } else {
            List<Event> outEvents = componentProcessor.process(component, inEvents);
            v.getOutVertices().forEach(outV -> vMapping.put(outV, outEvents));
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
