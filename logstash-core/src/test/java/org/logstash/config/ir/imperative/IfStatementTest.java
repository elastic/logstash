package org.logstash.config.ir.imperative;

import org.junit.Test;
import static org.junit.Assert.assertTrue;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;

import static org.logstash.config.ir.IRHelpers.*;

public class IfStatementTest {

    @Test
    public void testEmptyIfStatement() throws InvalidIRException {
        IfStatement ifStatement = new IfStatement(
            randMeta(),
            createTestExpression(),
            new NoopStatement(randMeta()),
            new NoopStatement(randMeta())
        );

        Graph ifStatementGraph = ifStatement.toGraph();
        assertTrue(ifStatementGraph.isEmpty());
    }
}
