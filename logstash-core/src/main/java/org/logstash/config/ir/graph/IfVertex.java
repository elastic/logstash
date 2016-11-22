package org.logstash.config.ir.graph;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.expression.BooleanExpression;

import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Created by andrewvc on 9/15/16.
 */
public class IfVertex extends Vertex {
    public BooleanExpression getBooleanExpression() {
        return booleanExpression;
    }

    private final BooleanExpression booleanExpression;

    public IfVertex(SourceMetadata meta, BooleanExpression booleanExpression) {
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

    // An IfVertex has no real metadata in and of itself, but its expression does!
    @Override
    public SourceMetadata getMeta() {
        return null;
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

    @Override
    public String getId() {
        return this.uniqueHash();
    }

    public Collection<BooleanEdge> getOutgoingBooleanEdges() {
        // Wish there was a way to do this as a java a cast without an operation
        return getOutgoingEdges().stream().map(e -> (BooleanEdge) e).collect(Collectors.toList());
    }

    public Collection<BooleanEdge> getOutgoingBooleanEdgesByType(Boolean edgeType) {
        return getOutgoingBooleanEdges().stream().filter(e -> e.getEdgeType().equals(edgeType)).collect(Collectors.toList());
    }

    // The easiest readable version of this for a human.
    // If the original source is available we use that, otherwise we serialize the expression
    public String humanReadableExpression() {
        String sourceText = this.booleanExpression.getMeta() != null ? this.booleanExpression.getMeta().getSourceText() : null;
        if (sourceText != null) {
            return sourceText;
        } else {
            return this.getBooleanExpression().toRubyString();
        }
    }

    @Override
    public IfVertex copy() {
        return new IfVertex(getMeta(),getBooleanExpression());
    }

    @Override
    public String individualHashSource() {
        return this.getClass().getCanonicalName() + "{" + this.booleanExpression.hashSource() + "}";
    }
}
