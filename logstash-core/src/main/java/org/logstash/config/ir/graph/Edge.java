package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Created by andrewvc on 9/15/16.
 */
public abstract class Edge implements ISourceComponent {
    public static abstract class EdgeFactory {
        public abstract Edge make(Vertex out, Vertex in) throws InvalidIRException;
    }

    private final Vertex to;
    private final Vertex from;

    public static Edge threadVertices(Vertex v1, Vertex v2) throws InvalidIRException {
        Vertex[] args = { v1, v2 };
        // Only ever returns one edge
        return threadVertices(new PlainEdge.PlainEdgeFactory(), args).stream().findFirst().get();
    }

    public static Edge threadVertices(EdgeFactory edgeFactory, Vertex v1, Vertex v2) throws InvalidIRException {
        Vertex[] args = { v1, v2 };
        // Only ever returns one edge`
        return threadVertices(edgeFactory, args).stream().findFirst().get();
    }

    public static Collection<Edge> threadVertices(Vertex... vertices) throws InvalidIRException {
        return threadVertices(new PlainEdge.PlainEdgeFactory(), vertices);
    }

    public static Collection<Edge> threadVertices(EdgeFactory edgeFactory, Vertex... vertices) throws InvalidIRException {
        Collection<Edge> edges = new ArrayList<>();

        for (int i = 0; i < vertices.length-1; i++) {
            Vertex from = vertices[i];
            Vertex to = vertices[i+1];

            Edge edge = edgeFactory.make(from, to);
            to.addInEdge(edge);
            from.addOutEdge(edge);
            edges.add(edge);
        }

        return edges;
    }

    public Edge(Vertex from, Vertex to) throws InvalidIRException {
        this.from = from;
        this.to = to;

        if (this.from == this.to) {
            throw new InvalidIRException("Cannot create a cyclic vertex! " + to);
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
    public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent.getClass() == sourceComponent.getClass()) {
            Edge otherE = (Edge) sourceComponent;

            return this.getFrom().sourceComponentEquals(otherE.getFrom()) &&
                    this.getTo().sourceComponentEquals(otherE.getTo());
        }
        return false;
    }


    @Override
    public SourceMetadata getMeta() {
        return null;
    }
}
