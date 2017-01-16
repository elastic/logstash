package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.config.ir.IRHelpers;
import org.logstash.config.ir.InvalidIRException;

import java.util.Collection;
import java.util.Collections;
import java.util.Optional;

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
}
