package org.logstash.config.ir.graph;

import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Stream;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.expression.BooleanExpression;

/**
 * Created by andrewvc on 9/15/16.
 */
public class IfVertex extends Vertex {

    public BooleanExpression getBooleanExpression() {
        return booleanExpression;
    }

    private final BooleanExpression booleanExpression;

    public IfVertex(SourceWithMetadata meta, BooleanExpression booleanExpression) {
        super(meta);
        this.booleanExpression = booleanExpression;
    }

    public String toString() {
        return "[if " + booleanExpression.toString(0) + "]";
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        if (other == null) return false;
        if (other == this) return true;
        if (other instanceof IfVertex) {
            IfVertex otherV = (IfVertex) other;
            // We don't check the id because we're comparing functional equality, not
            // identity
            return otherV.booleanExpression.sourceComponentEquals(this.booleanExpression);
        }
        return false;
    }

    public boolean hasEdgeType(boolean type) {
        for (Edge e : getOutgoingEdges()) {
            BooleanEdge bEdge = (BooleanEdge) e; // There should only  be boolean edges here!
            if (bEdge.getEdgeType() == type) return true;
        }
        return false;
    }

    public Collection<Edge.EdgeFactory> getUnusedOutgoingEdgeFactories() {
        List<Edge.EdgeFactory> l = new LinkedList<>();
        if (!hasEdgeType(true)) l.add(BooleanEdge.trueFactory);
        if (!hasEdgeType(false)) l.add(BooleanEdge.falseFactory);
        return l;
    }

    public boolean acceptsOutgoingEdge(Edge e) {
        return (e instanceof BooleanEdge);
    }

    public Stream<BooleanEdge> outgoingBooleanEdgesByType(boolean edgeType) {
        return outgoingEdges().map(e -> (BooleanEdge) e).filter(e -> e.getEdgeType() == edgeType);
    }

    // The easiest readable version of this for a human.
    // If the original source is available we use that, otherwise we serialize the expression
    public String humanReadableExpression() {
        String sourceText = this.booleanExpression.getSourceWithMetadata() != null ? this.booleanExpression.getSourceWithMetadata().getText() : null;
        if (sourceText != null) {
            return sourceText;
        } else {
            return this.getBooleanExpression().toRubyString();
        }
    }

    @Override
    public IfVertex copy() {
        return new IfVertex(this.getSourceWithMetadata(), booleanExpression);
    }
}
