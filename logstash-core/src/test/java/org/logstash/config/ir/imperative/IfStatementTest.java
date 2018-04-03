package org.logstash.config.ir.imperative;

import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import java.util.stream.Stream;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.DSL;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.Expression;
import org.logstash.config.ir.graph.*;

import static org.logstash.config.ir.IRHelpers.*;

public class IfStatementTest {

    @Test
    public void testEmptyIf() throws InvalidIRException {
        Statement trueStatement = new NoopStatement(randMeta());
        Statement falseStatement = new NoopStatement(randMeta());
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph();
        assertTrue(ifStatementGraph.isEmpty());
    }

    @Test
    public void testIfWithOneTrueStatement() throws InvalidIRException {
        PluginDefinition pluginDef = testPluginDefinition();
        Statement trueStatement = new PluginStatement(randMeta(), testPluginDefinition());
        Statement falseStatement = new NoopStatement(randMeta());
        BooleanExpression ifExpression = createTestExpression();
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                ifExpression,
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph();
        assertFalse(ifStatementGraph.isEmpty());
        
        Graph expected = new Graph();
        IfVertex expectedIf = DSL.gIf(randMeta(), ifExpression);
        expected.addVertex(expectedIf);
        PluginVertex expectedT = DSL.gPlugin(randMeta(), testPluginDefinition());
        expected.chainVertices(true, expectedIf, expectedT);

        assertSyntaxEquals(expected, ifStatementGraph);
    }


    @Test
    public void testIfWithOneFalseStatement() throws InvalidIRException {
        Statement trueStatement = new NoopStatement(randMeta());
        Statement falseStatement = new PluginStatement(randMeta(), testPluginDefinition());
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph();
        assertFalse(ifStatementGraph.isEmpty());

        Stream<Vertex> trueVertices = ifStatementGraph
                .edges()
                .filter(e -> e instanceof BooleanEdge)
                .map(e -> (BooleanEdge) e)
                .filter(e -> e.getEdgeType() == true)
                .map(e -> e.getTo());
        assertEquals(0, trueVertices.count());

        Stream<Vertex> falseVertices = ifStatementGraph
                .edges()
                .filter(e -> e instanceof BooleanEdge)
                .map(e -> (BooleanEdge) e)
                .filter(e -> e.getEdgeType() == false)
                .map(e -> e.getTo());
        assertEquals(1, falseVertices.count());
    }

    @Test
    public void testIfWithOneTrueOneFalseStatement() throws InvalidIRException {
        Statement trueStatement = new PluginStatement(randMeta(), testPluginDefinition());
        Statement falseStatement = new PluginStatement(randMeta(), testPluginDefinition());
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph();
        assertFalse(ifStatementGraph.isEmpty());

        Stream<Vertex> trueVertices = ifStatementGraph
                .edges()
                .filter(e -> e instanceof BooleanEdge)
                .map(e -> (BooleanEdge) e)
                .filter(e -> e.getEdgeType() == true)
                .map(e -> e.getTo());
        assertEquals(1, trueVertices.count());

        Stream<Vertex> falseVertices = ifStatementGraph
                .edges()
                .filter(e -> e instanceof BooleanEdge)
                .map(e -> (BooleanEdge) e)
                .filter(e -> e.getEdgeType() == false)
                .map(e -> e.getTo());
        assertEquals(1, falseVertices.count());
    }
}
