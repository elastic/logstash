package org.logstash.config.ir.graph;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Created by andrewvc on 9/15/16.
 */
public class Edge {
    public static class EdgeFactory {
        public Edge make(Vertex out, Vertex in) {
            return new Edge(out, in);
        }
    }

    private final Vertex to;
    private final Vertex from;

    public static Collection<Edge> threadVertices(Vertex... vertices) {
        return threadVertices(new EdgeFactory());
    }

    public static Collection<Edge> threadVertices(EdgeFactory edgeFactory, Vertex... vertices) {
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

    public Edge(Vertex from, Vertex to) {
        this.from = from;
        this.to = to;
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
}
