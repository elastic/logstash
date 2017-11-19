package org.logstash.config.ir.graph;

import java.util.concurrent.atomic.AtomicInteger;
import org.logstash.common.Util;
import org.logstash.config.ir.HashableWithSource;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
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
public abstract class Vertex implements SourceComponent, HashableWithSource {

    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    private final int hashCode = SEQUENCE.incrementAndGet();

    private final String explicitId;

    private Graph graph;

    private volatile String contextualHashCache;
    private volatile String hashCache;
    private volatile String individualHashSourceCache;
    private volatile String generatedId;

    protected Vertex() {
        this(null);
    }

    protected Vertex(String explicitId) {
        this.explicitId = explicitId;
    }

    public abstract Vertex copy();

    public static class InvalidEdgeTypeException extends InvalidIRException {
        private static final long serialVersionUID = -2707379453144995223L;

        public InvalidEdgeTypeException(String s) {
            super(s);
        }
    }

    @Override
    public final int hashCode() {
        return hashCode;
    }

    public final boolean equals(final Object other) {
        return this == other;
    }

    public final Graph getGraph() {
        return this.graph;
    }

    public final void setGraph(Graph graph) {
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
        return this.graph.getIncomingEdges(this).stream();
    }

    public Stream<Edge> outgoingEdges() {
        return this.graph.getOutgoingEdges(this).stream();
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
        if (this.hashCache != null) {
            return this.hashCache;
        }

        // Sort the lineage to ensure consistency. We prepend each item with a lexicographically sortable
        // encoding of its rank (using hex notation) so that the sort order is identical to the traversal order.
        // This is a required since there may be individually identical components in different locations in the graph.
        // It is, however, illegal to have functionally identical vertices, that is to say two vertices with the same
        // contents that have the same lineage.

        MessageDigest lineageDigest = Util.defaultMessageDigest();

        lineageDigest.update(hashPrefix().getBytes(StandardCharsets.UTF_8));

        // The lineage can be quite long and we want to avoid the quadratic complexity of string concatenation
        // Thus, in this case there's no real way to get the hash source, we just hash as we go.
        lineage().map(Vertex::contextualHashSource).forEachOrdered(v -> {
                    byte[] bytes = v.getBytes(StandardCharsets.UTF_8);
                    lineageDigest.update(bytes);
                });

        this.hashCache = Util.bytesToHexString(lineageDigest.digest());
        return hashCache;
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
        if (this.contextualHashCache != null) {
            return this.contextualHashCache;
        }

        // This string must be lexicographically sortable hence the ID at the front. It also must have the calculateIndividualHashSource
        // repeated at the front for the case of a graph with two nodes at the same rank, same contents, but different lineages
        StringBuilder result = new StringBuilder();
        result.append(hashPrefix());
        result.append(individualHashSource());

        result.append("I:");
        this.incomingEdges().map(Edge::individualHashSource).sorted().forEachOrdered(result::append);
        result.append("O:");
        this.outgoingEdges().map(Edge::individualHashSource).sorted().forEachOrdered(result::append);

        this.contextualHashCache = result.toString();
        return this.contextualHashCache;
    }

    public final String individualHashSource() {
        if (this.individualHashSourceCache != null) {
            return this.individualHashSourceCache;
        }

        this.individualHashSourceCache = calculateIndividualHashSource();
        return this.individualHashSourceCache;
    }

    public abstract String calculateIndividualHashSource();

    // Can be overriden in subclasses to define multiple
    // expected Edge classes this Vertex can take.
    // If any EdgeFactory instances are returned this Vertex is considered
    // a partial leaf.
    public Collection<Edge.EdgeFactory> getUnusedOutgoingEdgeFactories() {
       if (!this.hasOutgoingEdges()) {
           return Collections.singletonList(PlainEdge.factory);
       }
       return Collections.emptyList();
    }

    public boolean isPartialLeaf() {
       return getUnusedOutgoingEdgeFactories().size() > 0;
    }

    public boolean acceptsOutgoingEdge(Edge e) {
        return true;
    }

    public String getExplicitId() {
        return this.explicitId;
    }

    public String getId() {
        if (explicitId != null) return explicitId;
        if (generatedId != null) return generatedId;

        if (this.getGraph() == null) {
            throw new RuntimeException("Attempted to get ID from PluginVertex before attaching it to a graph!");
        }

        // Generating unique hashes for vertices is very slow!
        // We try to avoid this where possible, which means that generally only tests hit the path with hashes, since
        // they have no source metadata. This might also be used in the future by alternate config languages which are
        // willing to take the hit.
        if (this.getSourceWithMetadata() != null) {
            generatedId = Util.digest(this.graph.uniqueHash() + "|" + this.getSourceWithMetadata().uniqueHash());
        } else {
            generatedId = this.uniqueHash();
        }

        return generatedId;
    }

    public void clearCache() {
        this.hashCache = null;
        this.contextualHashCache = null;
        this.individualHashSourceCache = null;
    }

}
