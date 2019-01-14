package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;

/**
 * Created by andrewvc on 11/22/16.
 */
public class QueueVertexTest {
    @Test
    public void testConstruction() {
        try {
            new QueueVertex();
        } catch (IncompleteSourceWithMetadataException e) {
            // never happens
            throw new RuntimeException(e);
        }
    }
}
