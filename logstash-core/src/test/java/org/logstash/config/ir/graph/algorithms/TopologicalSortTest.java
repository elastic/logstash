package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.Arrays;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.AnyOf.anyOf;
import static org.hamcrest.core.Is.is;

/**
 * Created by andrewvc on 1/7/17.
 */
public class TopologicalSortTest {
    @Test(expected = InvalidIRException.class)
    public void testGraphCycleDetection() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        Vertex v3 = IRHelpers.createTestVertex();
        g.chainVertices(v1, v2);
        g.chainVertices(v2, v3);
        g.chainVertices(v2, v1);
    }

    @Test
    public void testSortOrder() throws InvalidIRException, TopologicalSort.UnexpectedGraphCycleError {
        Graph g = Graph.empty();
        Vertex v1 = IRHelpers.createTestVertex();
        Vertex v2 = IRHelpers.createTestVertex();
        Vertex v3 = IRHelpers.createTestVertex();
        Vertex v4 = IRHelpers.createTestVertex();
        g.chainVertices(v3, v1, v2);
        g.chainVertices(v4, v1, v2);
        assertThat(TopologicalSort.sortVertices(g),
                anyOf(
                        is(Arrays.asList(v3,v4,v1,v2)),
                        is(Arrays.asList(v4,v3,v1,v2))
                ));
    }

}
