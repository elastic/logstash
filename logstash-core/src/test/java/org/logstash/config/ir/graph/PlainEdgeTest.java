package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 11/22/16.
 */
public class PlainEdgeTest {
    @Test
    public void creationDoesNotRaiseException() throws InvalidIRException {
        new PlainEdge(IRHelpers.createTestVertex(), IRHelpers.createTestVertex());
    }

    @Test
    public void testFactoryCreationDoesNotRaiseException() throws InvalidIRException {
        PlainEdge.PlainEdgeFactory factory = new PlainEdge.PlainEdgeFactory();
        factory.make(IRHelpers.createTestVertex(), IRHelpers.createTestVertex());
    }
}
