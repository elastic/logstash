/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

import java.util.Collection;
import java.util.Collections;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.*;
import static org.logstash.config.ir.IRHelpers.createTestExpression;
import static org.logstash.config.ir.IRHelpers.createTestVertex;
import static org.logstash.config.ir.IRHelpers.randMeta;

public class GraphTest {
    @Test
    public void testGraphBasics() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        g.chainVertices(v1, v2);
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
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        g.chainVertices(v1, v2);
        g.chainVertices(v2, v1);
    }

    @Test
    public void chaining() throws InvalidIRException {
        Graph fromGraph = Graph.empty();
        fromGraph.chainVertices(createTestVertex("fromV1"), createTestVertex("fromV2"));

        Graph toGraph = Graph.empty();
        toGraph.chainVertices(createTestVertex("toV1"), createTestVertex("toV2"));

        Graph result = fromGraph.chain(toGraph);
        assertEquals(3, result.getEdges().size());
        assertVerticesConnected(result, "fromV2", "toV1");
    }

    @Test
    public void chainingIntoMultipleRoots() throws InvalidIRException {
        Graph fromGraph = Graph.empty();
        fromGraph.chainVertices(createTestVertex("fromV1"), createTestVertex("fromV2"));

        Graph toGraph = Graph.empty();
        toGraph.chainVertices(createTestVertex("toV1"), createTestVertex("toV2"));
        toGraph.addVertex(createTestVertex("toV3"));

        Graph result = fromGraph.chain(toGraph);
        assertEquals(4, result.getEdges().size());
        assertVerticesConnected(result, "fromV2", "toV1");
        assertVerticesConnected(result, "fromV2", "toV3");
    }

    @Test
    public void SimpleConsistencyTest() throws InvalidIRException {
        SourceWithMetadata meta = randMeta();
        Graph g1 = Graph.empty();
        g1.addVertex(createTestVertex(meta, "a"));
        Graph g2 = Graph.empty();
        g2.addVertex(createTestVertex(meta, "a"));

        assertEquals(g1.uniqueHash(), g2.uniqueHash());
    }


    @Test
    public void complexConsistencyTest() throws Exception {
        for (int i = 0; i < 10; ++i) {
            Graph g1 = IRHelpers.samplePipeline().getGraph();
            Graph g2 = IRHelpers.samplePipeline().getGraph();
            assertEquals(g1.uniqueHash(), g2.uniqueHash());
        }
    }

    @Test
    public void testThreading() throws InvalidIRException {
        Graph graph = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        graph.chainVertices(v1, v2);
        assertVerticesConnected(v1, v2);
        Edge v1Edge = v1.outgoingEdges().findFirst().get();
        Edge v2Edge = v2.incomingEdges().findFirst().get();
        assertThat(v1Edge, is(v2Edge));
        assertThat(v1Edge, instanceOf(PlainEdge.class));
    }

    @Test
    public void testThreadingMulti() throws InvalidIRException {
        Graph graph = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        Vertex v3 = IRHelpers.createTestVertex();
        Collection<Edge> multiEdges = graph.chainVertices(v1, v2, v3);

        assertThat(v1.getOutgoingVertices(), is(Collections.singletonList(v2)));
        assertThat(v2.getIncomingVertices(), is(Collections.singletonList(v1)));
        assertThat(v2.getOutgoingVertices(), is(Collections.singletonList(v3)));
        assertThat(v3.getIncomingVertices(), is(Collections.singletonList(v2)));
    }

    @Test
    public void testThreadingTyped() throws InvalidIRException {
        Graph graph = Graph.empty();
        Vertex if1 = new IfVertex(randMeta(), createTestExpression());
        Vertex condT = IRHelpers.createTestVertex();
        Edge tEdge = graph.chainVertices(BooleanEdge.trueFactory, if1, condT).stream().findFirst().get();
        assertThat(tEdge, instanceOf(BooleanEdge.class));
        BooleanEdge tBooleanEdge = (BooleanEdge) tEdge;
        assertThat(tBooleanEdge.getEdgeType(), is(true));
    }

    @Test
    public void copyTest() throws InvalidIRException {
        Graph left = Graph.empty();
        left.addVertex(createTestVertex("t1"));
        Graph right = left.copy();

        Vertex lv = left.getVertexById("t1");
        Vertex rv = right.getVertexById("t1");
        assertTrue(lv.sourceComponentEquals(rv));
        assertTrue(rv.sourceComponentEquals(lv));
    }

    private void assertVerticesConnected(Graph graph, String fromId, String toId) {
        Vertex from = graph.getVertexById(fromId);
        assertNotNull(from);
        Vertex to = graph.getVertexById(toId);
        assertNotNull(to);
        assertVerticesConnected(from, to);
    }

    public void assertVerticesConnected(Vertex from, Vertex to) {
        assertTrue("No connection: " + from + " -> " + to, from.getOutgoingVertices().contains(to));
        assertTrue("No reverse connection: " + from + " -> " + to, to.getIncomingVertices().contains(from));
    }
}
