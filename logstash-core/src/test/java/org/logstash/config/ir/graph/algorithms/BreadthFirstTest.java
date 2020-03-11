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
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;

import java.util.concurrent.atomic.AtomicInteger;

import static junit.framework.TestCase.assertEquals;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class BreadthFirstTest {
    @Test
    public void testBFSBasic() throws InvalidIRException {
        Graph g = Graph.empty();
        g.chainVertices(IRHelpers.createTestVertex(), IRHelpers.createTestVertex(), IRHelpers.createTestVertex());

        // We don't *really* need threadsafety for the count,
        // but since we're using a lambda we need something that's final
        final AtomicInteger visitCount = new AtomicInteger();
        BreadthFirst.BfsResult res = BreadthFirst.breadthFirst(g.getRoots(), false, (v -> visitCount.incrementAndGet()));

        assertEquals("It should visit each node once", visitCount.get(), 3);
        assertThat(res.getVertices(), is(g.getVertices()));
    }

}
