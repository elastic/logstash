/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.graph;

import java.util.concurrent.atomic.AtomicInteger;

import org.logstash.common.SourceWithMetadata;
import org.logstash.common.Util;
import org.logstash.config.ir.HashableWithSource;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.algorithms.DepthFirst;

import java.util.Collection;
import java.util.Collections;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public abstract class Vertex implements SourceComponent, HashableWithSource {

    private static final AtomicInteger SEQUENCE = new AtomicInteger();

    private final int hashCode = SEQUENCE.incrementAndGet();

    private final String explicitId;

    private final SourceWithMetadata meta;

    private Graph graph;

    private volatile String contextualHashCache;
    private volatile String hashCache;
    private volatile String individualHashSourceCache;
    private volatile String generatedId;

    protected Vertex(SourceWithMetadata meta) {
        this(meta,null);
    }

    protected Vertex(SourceWithMetadata meta, String explicitId) {
        if (meta == null) {
            throw new IllegalArgumentException(
                        "No source with metadata declared for " +
                        this.getClass().getName()
            );
        }
        this.meta = meta;
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

        if (this.getSourceWithMetadata() != null) {
            return this.getSourceWithMetadata().uniqueHash();
        } else {
            // This should never happen outside of the test suite where we construct pipelines
            // without source metadata
            throw new RuntimeException("Attempted to compute unique hash on a vertex with no source metadata!");
        }
    }

    @Override
    public String hashSource() {
        return this.uniqueHash();
    }

    // Can be overridden in subclasses to define multiple
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

    @Override
    public SourceWithMetadata getSourceWithMetadata() {
        return meta;
    }
}
