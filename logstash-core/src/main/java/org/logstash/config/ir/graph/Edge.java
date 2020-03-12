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

import java.util.stream.Stream;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;

public abstract class Edge implements SourceComponent {

    private final Vertex from;

    private final Vertex to;

    private Graph graph;

    protected Edge(Vertex from, Vertex to) throws InvalidIRException {
        this.from = from;
        this.to = to;

        if (this.from == this.to) {
            throw new InvalidIRException("Cannot create a cyclic vertex! " + to);
        }

        if (!this.from.acceptsOutgoingEdge(this)) {
            throw new Vertex.InvalidEdgeTypeException(String.format("Invalid outgoing edge %s for edge %s", this.from, this));
        }
    }

    public void setGraph(Graph graph) {
        if (this.graph == graph) {
            return;
        } else if (this.graph == null) {
            this.graph = graph;
        } else {
            throw new IllegalArgumentException("Attempted to set graph for edge that already has one!" + this);
        }
    }

    @Override
    public final int hashCode() {
        return 37 * from.hashCode() + to.hashCode();
    }

    @Override
    public final boolean equals(final Object other) {
        if (this == other) {
            return true;
        }
        if (this.getClass() != other.getClass()) {
            return false;
        }
        final Edge that = (Edge) other;
        return this.from.equals(that.from) && this.to.equals(that.to);
    }

    public abstract Edge copy(Vertex from, Vertex to) throws InvalidIRException;

    public abstract static class EdgeFactory {
        public abstract Edge make(Vertex from, Vertex to) throws InvalidIRException;
    }

    public Stream<Edge> ancestors() {
       // Without all the distinct calls this can be slow
       return Stream.concat(this.from.incomingEdges(), this.from.incomingEdges().flatMap(Edge::ancestors).distinct()).distinct();
    }

    public Stream<Edge> descendants() {
       // Without all the distinct calls this can be slow
       return Stream.concat(this.to.outgoingEdges(), this.to.outgoingEdges().flatMap(Edge::ancestors).distinct()).distinct();
    }

    public Stream<Edge> lineage() {
        return Stream.concat(Stream.concat(ancestors(), Stream.of(this)), descendants());
    }

    public Vertex getTo() {
        return to;
    }

    public Vertex getFrom() {
        return from;
    }

    public String toString() {
        return getFrom() + " -> " + getTo();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent.getClass() == this.getClass()) {
            Edge otherE = (Edge) sourceComponent;

            return this.getFrom().sourceComponentEquals(otherE.getFrom()) &&
                    this.getTo().sourceComponentEquals(otherE.getTo());
        }
        return false;
    }

    public abstract String individualHashSource();


    public abstract String getId();

    @Override
    public SourceWithMetadata getSourceWithMetadata() {
        return null;
    }
}
