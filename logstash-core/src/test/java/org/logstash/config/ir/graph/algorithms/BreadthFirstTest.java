package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static junit.framework.TestCase.assertEquals;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.config.ir.IRHelpers.testVertex;

/**
 * Created by andrewvc on 1/5/17.
 */
public class BreadthFirstTest {
    @Test
    public void testBFSBasic() throws InvalidIRException {
        Graph g = Graph.empty();
        g.threadVertices(testVertex(), testVertex(), testVertex());

        // We don't *really* need threadsafety for the count,
        // but since we're using a lambda we need something that's final
        final AtomicInteger visitCount = new AtomicInteger();
        BreadthFirst.BfsResult res = BreadthFirst.breadthFirst(g.getRoots(), false, (v -> visitCount.incrementAndGet()));

        assertEquals("It should visit each node once", visitCount.get(), 3);
        assertThat(res.getVertices(), is(g.getVertices()));
    }

}
