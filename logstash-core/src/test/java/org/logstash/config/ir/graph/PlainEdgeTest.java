package org.logstash.config.ir.graph;

import org.junit.Test;
import org.junit.experimental.theories.Theories;
import org.junit.experimental.theories.Theory;
import org.junit.runner.RunWith;
import org.logstash.config.ir.InvalidIRException;

import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.testVertex;

/**
 * Created by andrewvc on 11/22/16.
 */
public class PlainEdgeTest {
    @Test
    public void creationDoesNotRaiseException() throws InvalidIRException {
        PlainEdge e = new PlainEdge(testVertex(), testVertex());
    }

    @Test
    public void testFactoryCreationDoesNotRaiseException(Boolean edgeType) throws InvalidIRException {
        PlainEdge.PlainEdgeFactory factory = new PlainEdge.PlainEdgeFactory();
        PlainEdge e = factory.make(testVertex(), testVertex());
    }
}
