package org.logstash.config.pipeline;

import org.logstash.Event;
import org.logstash.config.compiler.compiled.ICompiledProcessor;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Vertex;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by andrewvc on 9/23/16.
 */
public class PassthroughProcessor implements ICompiledProcessor {
    private final Vertex vertex;

    public PassthroughProcessor(Vertex vertex) {
        this.vertex = vertex;
    }

    @Override
    public Map<Edge, List<Event>> process(List<Event> events) {
        HashMap<Edge, List<Event>> out = new HashMap<>(vertex.getOutgoingEdges().size());
        for (Edge e : vertex.getOutgoingEdges()) {
            out.put(e, events);
        }
        return out;
    }

    @Override
    public void register() {

    }

    @Override
    public void stop() {

    }
}
