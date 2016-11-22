package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.logstash.config.ir.IRHelpers.createTestVertex;

/**
 * Created by andrewvc on 1/5/17.
 */
public class GraphDiffTest {
    @Test
    public void testIdenticalGraphs() throws InvalidIRException {
        Graph left = simpleGraph();
        Graph right = simpleGraph();
        GraphDiff.DiffResult result = GraphDiff.diff(left, right);

        assertTrue(result.isIdentical());

        assertTrue(result.getAddedEdges().isEmpty());
        assertTrue(result.getRemovedEdges().isEmpty());
        assertTrue(result.getAddedVertices().isEmpty());
        assertTrue(result.getRemovedVertices().isEmpty());
    }

    @Test
    public void testDifferentSimpleGraphs() throws InvalidIRException {
        Graph left = simpleGraph();

        Graph right = left.copy();
        Vertex new1 = createTestVertex("new1");
        right.addVertex(new1);
        right.chainVerticesById("t3", "new1");

        GraphDiff.DiffResult result = GraphDiff.diff(left, right);

        assertFalse(result.isIdentical());

        assertThat(result.getAddedVertices().size(), is(1));
        assertThat(result.getAddedVertices().stream().findAny().get().getId(), is("new1"));

        assertThat(result.getAddedEdges().size(), is(1));
        Edge expectedEdge = new1.incomingEdges().findAny().get();
        assertTrue(result.getAddedEdges().stream().findAny().get().sourceComponentEquals(expectedEdge));

        assertTrue(result.getRemovedVertices().isEmpty());
        assertTrue(result.getRemovedEdges().isEmpty());
    }

    public Graph simpleGraph() throws InvalidIRException {
        Graph graph = Graph.empty();
        graph.addVertex(createTestVertex("t1"));
        graph.addVertex(createTestVertex("t2"));
        graph.addVertex(createTestVertex("t3"));
        graph.chainVerticesById("t1", "t2", "t3");
        graph.chainVerticesById("t1", "t3");
        return graph;
    }
}
