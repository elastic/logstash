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

import org.junit.Before;
import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static junit.framework.TestCase.assertEquals;

public class DepthFirstTest {
    Graph g = Graph.empty();
    final AtomicInteger visitCount = new AtomicInteger();
    final List<Vertex> visited = new ArrayList<>();

    @Before
    public void setup() throws InvalidIRException {
        g.chainVertices(
                IRHelpers.createTestVertex(),
                IRHelpers.createTestVertex(),
                IRHelpers.createTestVertex()
        );
    }

    @Test
    public void testDFSBasic() {
        DepthFirst.depthFirst(g).forEach(v -> visitCount.incrementAndGet());
        assertEquals("It should visit each node once", visitCount.get(), 3);
    }

    @Test
    public void testDFSReverse() {
        DepthFirst.reverseDepthFirst(g).forEach(v -> visitCount.incrementAndGet());
        assertEquals("It should visit each node once", visitCount.get(), 3);
    }

    @Test
    public void testDFSVertex() {
        DepthFirst.depthFirst(g.getRoots()).forEach(v -> visitCount.incrementAndGet());
        assertEquals("It should visit each node once", visitCount.get(), 3);
    }

    @Test
    public void testReverseDFSVertex() {
        DepthFirst.reverseDepthFirst(g.getLeaves()).forEach(v -> visitCount.incrementAndGet());
        assertEquals("It should visit each node once", visitCount.get(), 3);
    }
}
