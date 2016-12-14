package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;

import static org.junit.Assert.*;
import static org.logstash.config.ir.IRHelpers.testVertex;

/**
 * Created by andrewvc on 11/21/16.
 */
public class VertexTest {
    @Test
    public void TestVertexBasics() throws InvalidIRException {
        Graph graph = Graph.empty();
        Vertex v1 = testVertex();
        Vertex v2 = testVertex();
        graph.threadVertices(v1, v2);

        assertTrue("v1 has v2 as an outgoing vertex", v1.outgoingVertices().anyMatch(v2::equals));
        assertTrue("v2 has v1 as an incoming vertex", v2.incomingVertices().anyMatch(v1::equals));
    }

    @Test
    public void testIsLeafAndRoot() throws InvalidIRException {
        Graph graph = Graph.empty();

        Vertex v = testVertex();
        graph.addVertex(v);

        // Nodes should be leaves and roots if they are isolated
        assertTrue(v.isLeaf());
        assertTrue(v.isRoot());

        Vertex otherV = testVertex();
        graph.threadVertices(v, otherV);

        assertFalse(v.isLeaf());
        assertTrue(v.isRoot());
        assertTrue(otherV.isLeaf());
        assertFalse(otherV.isRoot());
    }

    @Test
    public void testPartialLeafOnUnconnectedVertex() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v = testVertex();
        g.addVertex(v);
        assertEquals(v.getUnusedOutgoingEdgeFactories().size(), 1);
        assertTrue(v.isPartialLeaf());
    }

    @Test
    public void testPartialLeafOnConnectedVertex() throws InvalidIRException {
        Vertex v = testVertex();
        Vertex otherV = testVertex();
        Graph graph = Graph.empty();
        graph.threadVertices(v, otherV);

        assertEquals(v.getUnusedOutgoingEdgeFactories().size(), 0);
        assertFalse(v.isPartialLeaf());
    }


}
