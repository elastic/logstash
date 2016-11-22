package org.logstash.config.ir.graph;

import org.logstash.common.Util;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 9/15/16.
 */
public class BooleanEdge extends Edge {
    public static class BooleanEdgeFactory extends EdgeFactory {
        public Boolean getEdgeType() {
            return edgeType;
        }

        private final Boolean edgeType;

        public BooleanEdgeFactory(Boolean edgeType) {
            this.edgeType = edgeType;
        }

        public BooleanEdge make(Vertex in, Vertex out) throws InvalidIRException {
            return new BooleanEdge(edgeType, in, out);
        }

        public boolean equals(Object other) {
            if (other == null) return false;
            if (other instanceof BooleanEdgeFactory) {
               return ((BooleanEdgeFactory) other).getEdgeType().equals(edgeType);
            }
            return false;
        }

        public String toString() {
            return "BooleanEdge.BooleanEdgeFactory[" + edgeType + "]";
        }
    }
    public static BooleanEdge.BooleanEdgeFactory trueFactory = new BooleanEdge.BooleanEdgeFactory(true);
    public static BooleanEdge.BooleanEdgeFactory falseFactory = new BooleanEdge.BooleanEdgeFactory(false);

    private final Boolean edgeType;

    public Boolean getEdgeType() {
        return edgeType;
    }

    public BooleanEdge(Boolean edgeType, Vertex outVertex, Vertex inVertex) throws InvalidIRException {
        super(outVertex, inVertex);
        this.edgeType = edgeType;
    }

    @Override
    public String individualHashSource() {
        return this.getClass().getCanonicalName() + "|" + this.getEdgeType() + "|";
    }

    @Override
    public String getId() {
        return Util.digest(this.getFrom().getId() + "[" + this.getEdgeType() + "]->" + this.getTo().getId());
    }

    public String toString() {
        return getFrom() + " -|" + this.edgeType + "|-> " + getTo();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
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

    @Override
    public BooleanEdge copy(Vertex from, Vertex to) throws InvalidIRException {
        return new BooleanEdge(this.edgeType, from, to);
    }

}
