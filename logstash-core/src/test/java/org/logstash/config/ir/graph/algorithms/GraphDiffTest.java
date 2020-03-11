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
