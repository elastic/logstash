package org.logstash.config.ir.graph;

import org.logstash.common.Util;
import org.logstash.config.ir.Hashable;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.algorithms.DepthFirst;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Collection;
import java.util.Collections;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/15/16.
 */
public abstract class Vertex implements SourceComponent, Hashable {
    private final SourceMetadata sourceMetadata;
    private Graph graph = this.getGraph();

    public Vertex() {
        this.sourceMetadata = null;
    }

    public Vertex(SourceMetadata sourceMetadata) {
        this.sourceMetadata = sourceMetadata;
    }

    public abstract Vertex copy();

    public static class InvalidEdgeTypeException extends InvalidIRException {
        public InvalidEdgeTypeException(String s) {
            super(s);
        }
    }

    public Graph getGraph() {
        return this.graph;
    }

    public void setGraph(Graph graph) {
        if (this.graph == graph) {
            return;
        } else if (this.graph == null) {
            this.graph = graph;
        } else {
            throw new IllegalArgumentException("Cannot set graph property on Vertex that is already assigned to an existing graph!");
        }
    }

    public boolean isRoot() {
        return getIncomingEdges().isEmpty();
    }

    public boolean isLeaf() {
        return getOutgoingEdges().isEmpty();
    }

    public boolean hasIncomingEdges() {
        return !getIncomingEdges().isEmpty();
    }

    public boolean hasOutgoingEdges() {
        return !getOutgoingEdges().isEmpty();
    }

    public Collection<Edge> getIncomingEdges() {
        return incomingEdges().collect(Collectors.toSet());
    }

    public Collection<Edge> getOutgoingEdges() {
        return outgoingEdges().collect(Collectors.toSet());
    }

    public Collection<Vertex> getOutgoingVertices() {
        return outgoingVertices().collect(Collectors.toList());
    }

    public Stream<Vertex> outgoingVertices() {
        return outgoingEdges().map(Edge::getTo);
    }

    public Collection<Vertex> getIncomingVertices() {
        return incomingVertices().collect(Collectors.toList());
    }

    public Stream<Vertex> incomingVertices() {
        return incomingEdges().map(Edge::getFrom);
    }

    public Stream<Edge> incomingEdges() {
        return this.getGraph().getIncomingEdges(this).stream();
    }

    public Stream<Edge> outgoingEdges() {
        return this.getGraph().getOutgoingEdges(this).stream();
    }

    public Stream<Vertex> ancestors() {
        return DepthFirst.reverseDepthFirst(this).filter(v -> v != this);
    }

    public Stream<Vertex> roots() {
        return ancestors().filter(Vertex::isRoot);
    }

    public Stream<Vertex> descendants() {
        return DepthFirst.depthFirst(this).filter(v -> v != this);
    }

    public Stream<Vertex> lineage() {
        return Stream.concat(Stream.concat(ancestors(), Stream.of(this)), descendants());
    }

    // Rank is the shortest distance to a root for this vertex
    public int rank() {
        return this.graph.rank(this);
    }

    @Override
    public String uniqueHash() {
        // Sort the lineage to ensure consistency. We prepend each item with a lexicographically sortable
        // encoding of its rank (using hex notation) so that the sort order is identical to the traversal order.
        // This is a required since there may be individually identical components in different locations in the graph.
        // It is, however, illegal to have functionally identical vertices, that is to say two vertices with the same
        // contents that have the same lineage.

        MessageDigest lineageDigest = Util.defaultMessageDigest();

        lineageDigest.update(hashPrefix().getBytes());

        // The lineage can be quite long and we want to avoid the quadratic complexity of string concatenation
        // Thus, in this case there's no real way to get the hash source, we just hash as we go.
        lineage().
                map(Vertex::contextualHashSource).
                sorted().
                forEachOrdered(v -> {
                    byte[] bytes = v.getBytes(StandardCharsets.UTF_8);
                    lineageDigest.update(bytes);
                });

        String digest = Util.bytesToHexString(lineageDigest.digest());

        return digest;
    }

    @Override
    public String hashSource() {
        // In this case the source can be quite large, so we never actually use this function.
        return this.uniqueHash();
    }

    public String hashPrefix() {
        return String.format("Vertex[%08x]=", this.rank()) + this.individualHashSource() + "|";
    }

    public String contextualHashSource() {
        // This string must be lexicographically sortable hence the ID at the front. It also must have the individualHashSource
        // repeated at the front for the case of a graph with two nodes at the same rank, same contents, but different lineages
        StringBuilder result = new StringBuilder();
        result.append(hashPrefix());
        result.append(individualHashSource());

        result.append("I:");
        this.incomingEdges().map(Edge::individualHashSource).sorted().forEachOrdered(result::append);
        result.append("O:");
        this.outgoingEdges().map(Edge::individualHashSource).sorted().forEachOrdered(result::append);

        return result.toString();
    }

    public abstract String individualHashSource();

    // Can be overriden in subclasses to define multiple
    // expected Edge classes this Vertex can take.
    // If any EdgeFactory instances are returned this Vertex is considered
    // a partial leaf.
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

    public abstract String getId();
}
