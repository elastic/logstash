package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

/**
 * Created by andrewvc on 11/22/16.
 */
public class IfVertexTest {
    @Test
    public void testIfVertexCreation() throws InvalidIRException {
        testIfVertex();
    }

    @Test(expected = Vertex.InvalidEdgeTypeException.class)
    public void testDoesNotAcceptNonBooleanEdges() throws InvalidIRException {
        Graph graph = Graph.empty();
        IfVertex ifV = testIfVertex();
        Vertex otherV = createTestVertex();
        graph.chainVertices(PlainEdge.factory, ifV, otherV);
    }

    @Test
    public void testEdgeTypeHandling() throws InvalidIRException {
        Graph graph = Graph.empty();
        IfVertex ifV = testIfVertex();
        graph.addVertex(ifV);
        Vertex trueV = createTestVertex();
        graph.addVertex(trueV);

        assertThat(ifV.hasEdgeType(true), is(false));
        assertThat(ifV.hasEdgeType(false), is(false));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().size(), is(2));

        graph.chainVertices(BooleanEdge.trueFactory, ifV, trueV);

        assertThat(ifV.hasEdgeType(true), is(true));
        assertThat(ifV.hasEdgeType(false), is(false));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().size(), is(1));
        assertThat(
                ifV.getUnusedOutgoingEdgeFactories().stream().findFirst().get(),
                is(BooleanEdge.falseFactory)
        );

        Vertex falseV = createTestVertex();
        graph.chainVertices(BooleanEdge.falseFactory, ifV, falseV);

        assertThat(ifV.hasEdgeType(false), is(true));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().isEmpty(), is(true));


        BooleanEdge trueEdge = ifV.outgoingBooleanEdgesByType(true).findAny().get();
        BooleanEdge falseEdge = ifV.outgoingBooleanEdgesByType(false).findAny().get();
        assertThat(trueEdge.getEdgeType(), is(true));
        assertThat(falseEdge.getEdgeType(), is(false));
    }

    public IfVertex testIfVertex() throws InvalidIRException {
        return new IfVertex(randMeta(), createTestExpression());
    }

}
