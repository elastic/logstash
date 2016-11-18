package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.hamcrest.CoreMatchers.hasItem;
import static org.hamcrest.CoreMatchers.hasItems;
import static org.junit.Assert.*;

/**
 * Created by andrewvc on 11/18/16.
 */
public class GraphTest {
    @Test
    public void testGraphBasics() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v1 = testVertex();
        Vertex v2 = testVertex();
        g.threadVertices(v1, v2);
        Edge e = v1.outgoingEdges().findFirst().get();
        assertEquals("Connects vertex edges correctly", v1.getOutgoingEdges(), v2.getIncomingEdges());
        assertEquals("Has one edge", g.getEdges(), Collections.singleton(e));
        assertTrue("Has v1", g.getVertices().contains(v1));
        assertTrue("Has v2", g.getVertices().contains(v2));
    }

    // Expect an Invalid IR Exception from the cycle
    @Test(expected = org.logstash.config.ir.InvalidIRException.class)
    public void testGraphCycleDetection() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v1 = testVertex();
        Vertex v2 = testVertex();
        g.threadVertices(v1, v2);
        g.threadVertices(v2, v1);
    }

    @Test
    public void extendingLeavesIntoRoots() throws InvalidIRException {
        Vertex fromV1 = testVertex();
        Vertex fromV2 = testVertex();
        Graph fromGraph = Graph.empty().threadVertices(fromV1, fromV2);

        Vertex toV1 = testVertex();
        Vertex toV2 = testVertex();
        Graph toGraph = Graph.empty().threadVertices(toV1, toV2);

        fromGraph.threadLeavesInto(toGraph);
        assertEquals(fromGraph.getEdges().size(), 3);
        assertVerticesConnected(fromV2, toV1);
        assertEquals(fromV2.getOutgoingEdges(), toV1.getIncomingEdges());
    }

    @Test
    public void extendingLeavesIntoRootsMultiRoot() throws InvalidIRException {
        Vertex fromV1 = testVertex("fromV1");
        Vertex fromV2 = testVertex("fromV2");
        Graph fromGraph = Graph.empty().threadVertices(fromV1, fromV2);

        Vertex toV1 = testVertex("toV1");
        Vertex toV2 = testVertex("toV2");
        Vertex toV3 = testVertex("toV3");
        Graph toGraph = Graph.empty().threadVertices(toV1, toV2).addVertex(toV3);

        fromGraph.threadLeavesInto(toGraph);
        assertEquals(fromGraph.getEdges().size(), 4);
        assertVerticesConnected(fromV2, toV1);
        assertVerticesConnected(fromV2, toV3);
    }

    @Test
    public void testWalk() throws InvalidIRException {
        Graph g = Graph.empty().
                threadVertices(testVertex(), testVertex(), testVertex());
        final AtomicInteger visitCount = new AtomicInteger();
        final List<Vertex> visited = new ArrayList<>();
        g.walkEdges(v -> {
            visitCount.incrementAndGet();
        });
        assertEquals("It should visit each node once", visitCount.get(), 2);
    }

    public void assertVerticesConnected(Vertex from, Vertex to) {
        assertTrue(from.getOutgoingVertices().contains(to));
        assertTrue(to.getIncomingVertices().contains(from));
    }

    public Vertex testVertex() {
        return testVertex(UUID.randomUUID().toString());
    }

    public Vertex testVertex(String name) {
        return new Vertex() {
            public String toString() {
                return "TestVertex-" + name;
            }

            @Override
            public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
                // For testing purposes only object identity counts
                return this == sourceComponent;
            }
        };
    }
}
