package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/15/16.
 */
public abstract class Vertex implements ISourceComponent {
    private final Collection<Edge> incomingEdges = new HashSet<Edge>();
    private final Collection<Edge> outgoingEdges = new HashSet<Edge>();
    private final SourceMetadata sourceMetadata;

    public Vertex() {
        this.sourceMetadata = null;
    }

    public Vertex(SourceMetadata sourceMetadata) {
        this.sourceMetadata = sourceMetadata;
    }

    public Vertex(Collection<Edge> incoming, Collection<Edge> outgoingEdges, SourceMetadata sourceMetadata) {
        this.sourceMetadata = sourceMetadata;
        this.incomingEdges.addAll(incoming);
        this.outgoingEdges.addAll(outgoingEdges);
    }

    public Vertex addInEdge(Edge e) throws InvalidIRException {
        if (!this.acceptsIncomingEdge(e)) throw new InvalidIRException("Invalid incomingEdges edge!" + e + " for " + this);
        this.incomingEdges.add(e);
        return this;
    }

    public Vertex addOutEdge(Edge e) throws InvalidIRException {
        if (!this.acceptsOutgoingEdge(e)) {
            throw new InvalidIRException(
                "Invalid outgoing edge!" +
                e + " for " + this +
                " existing outgoing edges: " + this.getOutgoingEdges());
        }
        this.outgoingEdges.add(e);
        return this;
    }

    public boolean isRoot() {
        return incomingEdges.size() == 0;
    }

    public boolean isLeaf() {
        return outgoingEdges.size() == 0;
    }

    public boolean hasIncomingEdges() {
        return incomingEdges.size() > 0;
    }

    public boolean hasOutgoingEdges() {
        return outgoingEdges.size() > 0;
    }

    public Collection<Edge> getIncomingEdges() {
        return incomingEdges;
    }

    public Collection<Edge> getOutgoingEdges() {
        return outgoingEdges;
    }

    public Collection<Vertex> getOutgoingVertices() {
        return outgoingEdges().map(Edge::getTo).collect(Collectors.toList());
    }

    public Collection<Vertex> getIncomingVertices() {
        return incomingEdges().map(Edge::getFrom).collect(Collectors.toList());
    }

    public Stream<Edge> incomingEdges() {
        return getIncomingEdges().stream();
    }

    public Stream<Edge> outgoingEdges() {
        return outgoingEdges.stream();
    }

    @Override
    public SourceMetadata getMeta() {
        return null;
    }

    public Collection<Edge.EdgeFactory> getUnusedOutgoingEdgeFactories() {
       if (!this.hasOutgoingEdges()) {
           return Collections.singletonList(new PlainEdge.PlainEdgeFactory());
       }
       return Collections.emptyList();
    }

    public boolean isPartialLeaf() {
       return getUnusedOutgoingEdgeFactories().size() > 0;
    }

    public boolean acceptsIncomingEdge(Edge e) {
        return true;
    }

    public boolean acceptsOutgoingEdge(Edge e) {
        return true;
    }
}
