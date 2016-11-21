package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.unary.Truthy;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;

import static org.junit.Assert.*;
import static org.hamcrest.CoreMatchers.*;
import static org.logstash.config.ir.IRHelpers.makeTestEdge;
import static org.logstash.config.ir.IRHelpers.makeTestExpression;
import static org.logstash.config.ir.IRHelpers.makeTestVertex;


/**
 * Created by andrewvc on 11/21/16.
 */
public class EdgeTest {
    @Test
    public void testBasicEdge() throws InvalidIRException {
        Edge e = makeTestEdge();
        assertThat("From is edge", e.getFrom(), notNullValue());
        assertThat("To is edge", e.getTo(), notNullValue());
    }

    @Test
    public void testThreading() throws InvalidIRException {
        Vertex v1 = makeTestVertex();
        Vertex v2 = makeTestVertex();
        Edge e = Edge.threadVertices(v1, v2);
        assertThat(v1.getOutgoingEdges().stream().findFirst().get(), is(e));
        assertThat(v2.getIncomingEdges().stream().findFirst().get(), is(e));
        assertThat(e, instanceOf(PlainEdge.class));
    }

    @Test
    public void testThreadingMulti() throws InvalidIRException {
        Vertex v1 = makeTestVertex();
        Vertex v2 = makeTestVertex();
        Vertex v3 = makeTestVertex();
        Collection<Edge> multiEdges = Edge.threadVertices(v1, v2, v3);

        assertThat(multiEdges.size(), is(2));
        assertThat(v1.getOutgoingVertices(), is(Collections.singletonList(v2)));
        assertThat(v2.getIncomingVertices(), is(Collections.singletonList(v1)));
        assertThat(v2.getOutgoingVertices(), is(Collections.singletonList(v3)));
        assertThat(v3.getIncomingVertices(), is(Collections.singletonList(v2)));
    }

    @Test
    public void testThreadingTyped() throws InvalidIRException {
        Vertex if1 = new IfVertex(null, makeTestExpression());
        Vertex condT = makeTestVertex();
        Edge tEdge = Edge.threadVertices(new BooleanEdge.BooleanEdgeFactory(true), if1, condT);
        assertThat(tEdge, instanceOf(BooleanEdge.class));
        BooleanEdge tBooleanEdge = (BooleanEdge) tEdge;
        assertThat(tBooleanEdge.getEdgeType(), is(true));
    }
}
