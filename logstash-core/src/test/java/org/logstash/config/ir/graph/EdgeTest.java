package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

import java.util.Collection;
import java.util.Collections;

import static org.junit.Assert.*;
import static org.hamcrest.CoreMatchers.*;
import static org.logstash.config.ir.IRHelpers.testExpression;
import static org.logstash.config.ir.IRHelpers.testVertex;


/**
 * Created by andrewvc on 11/21/16.
 */
public class EdgeTest {
    @Test
    public void testBasicEdge() throws InvalidIRException {
        Edge e = IRHelpers.testEdge();
        assertThat("From is edge", e.getFrom(), notNullValue());
        assertThat("To is edge", e.getTo(), notNullValue());
    }

    @Test
    public void testThreading() throws InvalidIRException {
        Vertex v1 = testVertex();
        Vertex v2 = testVertex();
        Edge e = Edge.threadVertices(v1, v2);
        assertThat(v1.getOutgoingEdges().stream().findFirst().get(), is(e));
        assertThat(v2.getIncomingEdges().stream().findFirst().get(), is(e));
        assertThat(e, instanceOf(PlainEdge.class));
    }

    @Test
    public void testThreadingMulti() throws InvalidIRException {
        Vertex v1 = testVertex();
        Vertex v2 = testVertex();
        Vertex v3 = testVertex();
        Collection<Edge> multiEdges = Edge.threadVertices(v1, v2, v3);

        assertThat(multiEdges.size(), is(2));
        assertThat(v1.getOutgoingVertices(), is(Collections.singletonList(v2)));
        assertThat(v2.getIncomingVertices(), is(Collections.singletonList(v1)));
        assertThat(v2.getOutgoingVertices(), is(Collections.singletonList(v3)));
        assertThat(v3.getIncomingVertices(), is(Collections.singletonList(v2)));
    }

    @Test
    public void testThreadingTyped() throws InvalidIRException {
        Vertex if1 = new IfVertex(null, testExpression());
        Vertex condT = testVertex();
        Edge tEdge = Edge.threadVertices(BooleanEdge.trueFactory, if1, condT);
        assertThat(tEdge, instanceOf(BooleanEdge.class));
        BooleanEdge tBooleanEdge = (BooleanEdge) tEdge;
        assertThat(tBooleanEdge.getEdgeType(), is(true));
    }
}
