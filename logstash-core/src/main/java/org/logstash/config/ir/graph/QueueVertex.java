package org.logstash.config.ir.graph;

import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.Util;
import org.logstash.config.ir.SourceComponent;
import org.logstash.common.SourceWithMetadata;

/**
 * Created by andrewvc on 9/15/16.
 */
public final class QueueVertex extends Vertex {
    public QueueVertex() throws IncompleteSourceWithMetadataException {
        super(new SourceWithMetadata("internal", "queue", 0,0,"queue"));
    }

    @Override
    public String getId() {
        return "__QUEUE__";
    }

    @Override
    public String toString() {
        return this.getId();
    }

    @Override
    public QueueVertex copy() {
        try {
            return new QueueVertex();
        } catch (IncompleteSourceWithMetadataException e) {
            // Never happens
            throw new RuntimeException(e);
        }
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

    @Override
    public String uniqueHash() {
        return Util.digest("QUEUE");
    }
}
