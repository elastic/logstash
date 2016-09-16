package org.logstash.config.ir.imperative;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.*;

import java.util.Collection;
import java.util.List;
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

    public IfStatement(SourceMetadata meta,
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
        Graph graph = new Graph();
        Vertex ifVertex = new IfVertex(this.booleanExpression);

        if (!(getTrueStatement() instanceof NoopStatement)) {
            graph.addByThreading(
                    new BooleanEdge.BooleanEdgeFactory(true),
                    ifVertex,
                    this.getTrueStatement().toGraph().root().get()
            );
        }

        if (!(getFalseStatement() instanceof NoopStatement)) {
            Graph fStatement = getFalseStatement().toGraph();
            List<Vertex> fStatementRoots = fStatement.roots().collect(Collectors.toList());
            Vertex fStatementRoot = fStatement.root().get();
            System.out.println(fStatementRoot + fStatementRoots.toString());
            graph.addByThreading(
                    new BooleanEdge.BooleanEdgeFactory(false),
                    ifVertex,
                    this.getFalseStatement().toGraph().root().get()
            );
        }
        return graph;
    }
}
