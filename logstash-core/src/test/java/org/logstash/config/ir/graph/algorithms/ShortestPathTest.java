package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.Arrays;
import java.util.List;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.config.ir.IRHelpers.createTestVertex;

/**
 * Created by andrewvc on 1/5/17.
 */
public class ShortestPathTest {
    @Test
    public void testShortestPathBasic() throws InvalidIRException, ShortestPath.InvalidShortestPathArguments {
        Graph g = Graph.empty();
        Vertex v1 = createTestVertex("v1");
        g.addVertex(v1);
        Vertex v2 = createTestVertex("v2");
        g.addVertex(v2);
        Vertex v3 = createTestVertex("v3");
        g.addVertex(v3);
        Vertex v4 = createTestVertex("v4");
        g.addVertex(v4);

        g.chainVertices(v1, v2, v3, v4);
        g.chainVertices(v2, v4);

        List<Vertex> path = ShortestPath.shortestPath(v1, v4);
        List<Vertex> expected = Arrays.asList(v1,v2,v4);
        assertThat(path, is(expected));
    }
}
