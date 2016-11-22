package org.logstash.config.ir.graph;

import org.junit.Test;

/**
 * Created by andrewvc on 11/22/16.
 */
public class SpecialVertexTest {
    @Test
    public void testConstruction() {
        new SpecialVertex(SpecialVertex.Type.FILTER_OUT);
    }
}
