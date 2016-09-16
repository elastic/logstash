package org.logstash.config.ir.graph;

import java.util.Collection;

/**
 * Created by andrewvc on 9/15/16.
 */
public class BooleanEdge extends Edge {
    public static class BooleanEdgeFactory extends EdgeFactory {
        private final Boolean edgeType;

        public BooleanEdgeFactory(Boolean edgeType) {
            this.edgeType = edgeType;
        }

        public BooleanEdge make(Vertex in, Vertex out) {
            return new BooleanEdge(edgeType, in, out);
        }
    }

    public static Collection<Edge> trueThreadVertices(Vertex... vertices) {
        return threadVertices(new BooleanEdgeFactory(true), vertices);
    }

    public static Collection<Edge> falseThreadVertices(Vertex... vertices) {
        return threadVertices(new BooleanEdgeFactory(false), vertices);
    }

    private final Boolean edgeType;

    public BooleanEdge(Boolean edgeType, Vertex outVertex, Vertex inVertex) {
        super(outVertex, inVertex);
        this.edgeType = edgeType;
    }

    public String toString() {
        return getFrom() + " -|" + this.edgeType + "|-> " + getTo();
    }
}
