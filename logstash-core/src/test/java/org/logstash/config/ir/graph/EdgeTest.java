package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

import static org.junit.Assert.*;
import static org.hamcrest.CoreMatchers.*;

public class EdgeTest {
    @Test
    public void testBasicEdge() throws InvalidIRException {
        Edge e = IRHelpers.createTestEdge();
        assertThat("From is edge", e.getFrom(), notNullValue());
        assertThat("To is edge", e.getTo(), notNullValue());
    }
}
