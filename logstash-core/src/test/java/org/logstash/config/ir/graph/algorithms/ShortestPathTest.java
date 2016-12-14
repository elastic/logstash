package org.logstash.config.ir.graph.algorithms;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.Arrays;
import java.util.List;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.config.ir.IRHelpers.testVertex;

/**
 * Created by andrewvc on 1/5/17.
 */
public class ShortestPathTest {
    @Test
    public void testShortestPathBasic() throws InvalidIRException {
        Graph g = Graph.empty();
        Vertex v1 = testVertex("v1");
        g.addVertex(v1);
        Vertex v2 = testVertex("v2");
        g.addVertex(v2);
        Vertex v3 = testVertex("v3");
        g.addVertex(v3);
        Vertex v4 = testVertex("v4");
        g.addVertex(v4);

        g.threadVertices(v1, v2, v3, v4);
        g.threadVertices(v2, v4);

        List<Vertex> path = ShortestPath.shortestPath(v1, v4);
        List<Vertex> expected = Arrays.asList(v1,v2,v4);
        assertThat(path, is(expected));
    }
}
