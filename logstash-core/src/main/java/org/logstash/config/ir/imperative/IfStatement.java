package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.graph.BooleanEdge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.Collection;
import java.util.stream.Collectors;

/**
 * Created by andrewvc on 9/6/16.
 * if 5 {
 *
 * }
 */

public class IfStatement extends Statement {
    private final BooleanExpression booleanExpression;
    private final Statement trueStatement;
    private final Statement falseStatement;

    public BooleanExpression getBooleanExpression() {
        return booleanExpression;
    }

    public Statement getTrueStatement() {
        return trueStatement;
    }

    public Statement getFalseStatement() {
        return falseStatement;
    }

    public IfStatement(SourceWithMetadata meta,
                       BooleanExpression booleanExpression,
                       Statement trueStatement,
                       Statement falseStatement
    ) throws InvalidIRException {
        super(meta);

        if (booleanExpression == null) throw new InvalidIRException("Boolean expr must eNot be null!");
        if (trueStatement == null) throw new InvalidIRException("If Statement needs true statement!");
        if (falseStatement == null) throw new InvalidIRException("If Statement needs false statement!");

        this.booleanExpression = booleanExpression;
        this.trueStatement = trueStatement;
        this.falseStatement = falseStatement;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof IfStatement) {
            IfStatement other = (IfStatement) sourceComponent;


            return (this.booleanExpression.sourceComponentEquals(other.getBooleanExpression()) &&
                    this.trueStatement.sourceComponentEquals(other.trueStatement) &&
                    this.falseStatement.sourceComponentEquals(other.falseStatement));
        }
        return false;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) +
                    "(if " + booleanExpression.toString(0) +
                    "\n" +
                    this.trueStatement +
                    "\n" +
                    this.falseStatement +
                    ")";
    }


    @Override
    public Graph toGraph() throws InvalidIRException {
        Graph trueGraph = getTrueStatement().toGraph();
        Graph falseGraph = getFalseStatement().toGraph();

        // If there is nothing in the true or false sections of this if statement,
        // we can omit the if statement altogether!
        if (trueGraph.isEmpty() && falseGraph.isEmpty()) {
            return new Graph();
        }

        Graph.GraphCombinationResult combination = Graph.combine(trueGraph, falseGraph);
        Graph newGraph = combination.graph;
        Collection<Vertex> trueRoots = trueGraph.roots().map(combination.oldToNewVertices::get).collect(Collectors.toList());
        Collection<Vertex> falseRoots = falseGraph.roots().map(combination.oldToNewVertices::get).collect(Collectors.toList());

        IfVertex ifVertex = new IfVertex(this.getSourceWithMetadata(), this.booleanExpression);
        newGraph.addVertex(ifVertex);

        for (Vertex v : trueRoots) {
            newGraph.chainVerticesUnsafe(BooleanEdge.trueFactory, ifVertex, v);
        }

        for (Vertex v : falseRoots) {
            newGraph.chainVerticesUnsafe(BooleanEdge.falseFactory, ifVertex, v);
        }

        return newGraph;
    }
}
