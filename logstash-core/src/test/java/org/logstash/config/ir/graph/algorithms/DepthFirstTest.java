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

/**
 * Created by andrewvc on 1/5/17.
 */
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
