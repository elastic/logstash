package org.logstash.config.ir.graph;

import org.junit.experimental.theories.DataPoint;
import org.junit.experimental.theories.Theories;
import org.junit.experimental.theories.Theory;
import org.junit.runner.RunWith;
import org.logstash.config.ir.InvalidIRException;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

/**
 * Created by andrewvc on 11/21/16.
 */
@RunWith(Theories.class)
public class BooleanEdgeTest {
    @DataPoint
    public static Boolean TRUE = true;
    @DataPoint
    public static Boolean FALSE = false;

    @Theory
    public void testBasicBooleanEdgeProperties(Boolean edgeType) throws InvalidIRException {
        BooleanEdge be = new BooleanEdge(edgeType, createTestVertex(), createTestVertex());
        assertThat(be.getEdgeType(), is(edgeType));
    }

    @Theory
    public void testFactoryCreation(Boolean edgeType) throws InvalidIRException {
        BooleanEdge.BooleanEdgeFactory factory = new BooleanEdge.BooleanEdgeFactory(edgeType);
        BooleanEdge be = factory.make(createTestVertex(), createTestVertex());
        assertThat(be.getEdgeType(), is(edgeType));
    }
}
