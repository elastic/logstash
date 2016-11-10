package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;

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

        public BooleanEdge make(Vertex in, Vertex out) throws InvalidIRException {
            return new BooleanEdge(edgeType, in, out);
        }
    }
    public static BooleanEdge.BooleanEdgeFactory trueFactory = new BooleanEdge.BooleanEdgeFactory(true);
    public static BooleanEdge.BooleanEdgeFactory falseFactory = new BooleanEdge.BooleanEdgeFactory(false);

    public static Collection<Edge> trueThreadVertices(Vertex... vertices) throws InvalidIRException {
        return threadVertices(new BooleanEdgeFactory(true), vertices);
    }

    public static Collection<Edge> falseThreadVertices(Vertex... vertices) throws InvalidIRException {
        return threadVertices(new BooleanEdgeFactory(false), vertices);
    }

    private final Boolean edgeType;

    public Boolean getEdgeType() {
        return edgeType;
    }

    public BooleanEdge(Boolean edgeType, Vertex outVertex, Vertex inVertex) throws InvalidIRException {
        super(outVertex, inVertex);
        this.edgeType = edgeType;
    }

    public String toString() {
        return getFrom() + " -|" + this.edgeType + "|-> " + getTo();
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof BooleanEdge) {
            BooleanEdge otherE = (BooleanEdge) sourceComponent;

            return this.getFrom().sourceComponentEquals(otherE.getFrom()) &&
                    this.getTo().sourceComponentEquals(otherE.getTo()) &&
                    this.getEdgeType().equals(otherE.getEdgeType());
        }
        return false;
    }

}
