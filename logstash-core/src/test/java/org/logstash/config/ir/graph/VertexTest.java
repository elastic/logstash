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
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

import static org.junit.Assert.*;

public class VertexTest {
    @Test
    public void TestVertexBasics() throws InvalidIRException {
        Graph graph = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        graph.chainVertices(v1, v2);

        assertTrue("v1 has v2 as an outgoing vertex", v1.outgoingVertices().anyMatch(v2::equals));
        assertTrue("v2 has v1 as an incoming vertex", v2.incomingVertices().anyMatch(v1::equals));
    }

    @Test
    public void testIsLeafAndRoot() throws InvalidIRException {
        Graph graph = Graph.empty();

        Vertex v = IRHelpers.createTestVertex();
        graph.addVertex(v);

        // Nodes should be leaves and roots if they are isolated
        assertTrue(v.isLeaf());
        assertTrue(v.isRoot());

        Vertex otherV = IRHelpers.createTestVertex();
        graph.chainVertices(v, otherV);

        assertFalse(v.isLeaf());
        assertTrue(v.isRoot());
        assertTrue(otherV.isLeaf());
        assertFalse(otherV.isRoot());
    }

    @Test
    public void testPartialLeafOnUnconnectedVertex() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v = IRHelpers.createTestVertex();
        g.addVertex(v);
        assertEquals(v.getUnusedOutgoingEdgeFactories().size(), 1);
        assertTrue(v.isPartialLeaf());
    }

    @Test
    public void testPartialLeafOnConnectedVertex() throws InvalidIRException {
        Vertex v = IRHelpers.createTestVertex();
        Vertex otherV = IRHelpers.createTestVertex();
        Graph graph = Graph.empty();
        graph.chainVertices(v, otherV);

        assertEquals(v.getUnusedOutgoingEdgeFactories().size(), 0);
        assertFalse(v.isPartialLeaf());
    }


}
