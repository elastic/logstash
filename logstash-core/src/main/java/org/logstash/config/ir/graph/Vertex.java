package org.logstash.config.ir.graph;

import java.util.Collection;
import java.util.HashSet;

/**
 * Created by andrewvc on 9/15/16.
 */
public class Vertex {
    private final Collection<Edge> incoming = new HashSet<Edge>();
    private final Collection<Edge> outgoingEdges = new HashSet<Edge>();

    public Vertex() {
    }

    public Vertex(Collection<Edge> incoming, Collection<Edge> outgoingEdges) {
        this.incoming.addAll(incoming);
        this.outgoingEdges.addAll(outgoingEdges);
    }

    public Vertex addInEdge(Edge e) {
        this.incoming.add(e);
        return this;
    }

    public Vertex addOutEdge(Edge e) {
        this.outgoingEdges.add(e);
        return this;
    }

    public boolean isRoot() {
        return incoming.size() == 0;
    }

    public boolean isLeaf() {
        return outgoingEdges.size() == 0;
    }

    public boolean hasOutEdges() {
        return incoming.size() > 0;
    }

    public Collection<Edge> getIncoming() {
        return incoming;
    }

    public Collection<Edge> getOutgoingEdges() {
        return outgoingEdges;
    }
}
