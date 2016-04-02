package com.logstash.pipeline.graph;

import com.logstash.pipeline.Component;

import java.util.*;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 2/20/16.
 */
public class Vertex {
    private final List<Edge> outEdges;
    private final Component component;
    private final List<Edge> inEdges;
    private final String id;

    Vertex(String id, Component component) {
        this.id = id;
        this.component = component;
        this.inEdges = new ArrayList<>();
        this.outEdges = new ArrayList<>();
    }

    public static Edge linkVertices(Vertex from, Vertex to) {
        return linkVertices(from, to, null);
    }

    public static Edge linkVertices(Vertex from, Vertex to, Condition condition) {
        Optional<Edge> existingEdge = getVertexLinkingEdge(from, to, condition);

        if (existingEdge.isPresent()) {
            return existingEdge.get();
        } else {
            Edge edge = new Edge(from, to, condition);
            from.addOutEdge(edge);
            to.addInEdge(edge);

            return edge;
        }
    }

    public static Optional<Edge> getVertexLinkingEdge(Vertex from, Vertex to, Condition condition) {
        return from.getOutEdges().stream().filter(edge -> {
            Condition edgeCondition = edge.getCondition();
            if (edgeCondition == null) {
                return condition == null;
            } else {
                return edgeCondition.equals(condition);
            }
        }).findFirst();
    }

    public Component getComponent() {
        return component;
    }

    public Stream<Vertex> getOutVertices() {
        return this.outEdges.stream().map(Edge::getTo);
    }

    public Stream<Vertex> getInVertices() { return this.inEdges.stream().map(Edge::getTo); }

    public boolean hasOutVertex(Vertex v) {
        return this.getOutVertices().anyMatch(ov -> v == ov);
    }

    public boolean hasInVertex(Vertex v) { return this.getInVertices().anyMatch(iv -> v == iv ); }


    protected void addOutEdge(Edge e) {
        if (!this.outEdges.contains(e)) {
            this.outEdges.add(e);
        }
    }

    protected void addInEdge(Edge e) {
        if (!this.inEdges.contains(e)) {
            this.inEdges.add(e);
        }
    }

    public List<Edge> getOutEdges() {
        return this.outEdges;
    }

    public List<Edge> getInEdges() {
        return this.inEdges;
    }

    public boolean isSource() { return this.inEdges.size() == 0; }

    public boolean isTerminal() {
        return this.outEdges.size() == 0;
    }

    public String toString() {
       return  String.format("<Vertex (%s)>", this.component);
    }

    public String getId() {
        return id;
    }
}
