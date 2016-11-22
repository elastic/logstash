package org.logstash.config.ir.graph;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/15/16.
 */
public abstract class Edge implements SourceComponent {
    private Graph graph;

    public void setGraph(Graph graph) {
        if (this.graph == graph) {
            return;
        } else if (this.graph == null) {
            this.graph = graph;
        } else {
            throw new IllegalArgumentException("Attempted to set graph for edge that already has one!" + this);
        }
    }

    public abstract Edge copy(Vertex from, Vertex to) throws InvalidIRException;

    public static abstract class EdgeFactory {
        public abstract Edge make(Vertex from, Vertex to) throws InvalidIRException;
    }

    private final Vertex from;
    private final Vertex to;

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

    public Edge(Vertex from, Vertex to) throws InvalidIRException {
        this.from = from;
        this.to = to;

        if (this.from == this.to) {
            throw new InvalidIRException("Cannot create a cyclic vertex! " + to);
        }

        if (!this.from.acceptsOutgoingEdge(this)) {
            throw new Vertex.InvalidEdgeTypeException(String.format("Invalid outgoing edge %s for edge %s", this.from, this));
        }

        if (!this.to.acceptsIncomingEdge(this)) {
            throw new Vertex.InvalidEdgeTypeException(String.format("Invalid incoming edge %s for edge %s", this.from, this));
        }
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
    public SourceMetadata getMeta() {
        return null;
    }
}
