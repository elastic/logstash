package org.logstash.config.ir.graph;

import org.logstash.config.ir.SourceComponent;
import org.logstash.common.SourceWithMetadata;

/**
 * Created by andrewvc on 9/15/16.
 */
public final class QueueVertex extends Vertex {

    @Override
    public String getId() {
        return "__QUEUE__";
    }

    @Override
    public String calculateIndividualHashSource() {
        return this.getClass().getCanonicalName();
    }

    public String toString() {
        return this.getId();
    }

    @Override
    public QueueVertex copy() {
        return new QueueVertex();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        return other instanceof QueueVertex;
    }

    // Special vertices really have no metadata
    @Override
    public SourceWithMetadata getSourceWithMetadata() {
        return null;
    }
}
