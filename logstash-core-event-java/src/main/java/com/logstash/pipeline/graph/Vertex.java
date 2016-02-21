package com.logstash.pipeline.graph;

import com.logstash.pipeline.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 2/20/16.
 */
public class Vertex {
    private final List<Edge> outEdges;
    private final Component component;

    Vertex(String id, Component component) {
        this.component = component;
        this.outEdges = new ArrayList<>();
    }

    public Component getComponent() {
        return component;
    }

    public Stream<Vertex> getOutVertices() {
        return this.outEdges.stream().map(Edge::getTo);
    }

    public boolean hasOutVertex(Vertex v) {
        return this.getOutVertices().anyMatch(ov -> v == ov);
    }

    public Edge addOutEdge(Vertex to) {
        return addOutEdge(to, null);
    }

    public Edge addOutEdge(Vertex to, Condition c) {
        if (this.hasOutVertex(to)) return null;

        Edge e = new Edge(this, to, c);
        this.outEdges.add(e);
        return e;
    }

    public List<Edge> getOutEdges() {
        return this.outEdges;
    }

    public boolean isTerminal() {
        return this.outEdges.size() == 0;
    }

    public String toString() {
       return  String.format("<Vertex (%s)>", this.component);
    }
}
