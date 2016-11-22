package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static junit.framework.TestCase.assertEquals;

/**
 * Created by andrewvc on 1/5/17.
 */
public class DepthFirstTest {
    @Test
    public void testDFSBasic() throws InvalidIRException {
        Graph g = Graph.empty();
        g.chainVertices(IRHelpers.createTestVertex(), IRHelpers.createTestVertex(), IRHelpers.createTestVertex());
        final AtomicInteger visitCount = new AtomicInteger();
        final List<Vertex> visited = new ArrayList<>();
        DepthFirst.depthFirst(g).forEach(v -> visitCount.incrementAndGet());
        assertEquals("It should visit each node once", visitCount.get(), 3);
    }
}
