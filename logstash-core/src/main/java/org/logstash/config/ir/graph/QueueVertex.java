package org.logstash.config.ir.graph;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/15/16.
 */
public class QueueVertex extends Vertex {
    public QueueVertex() {
        super(null);
    }

    @Override
    public String getId() {
        return "__QUEUE__";
    }

    @Override
    public String individualHashSource() {
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
        if (other == null) return false;
        return other instanceof QueueVertex;
    }

    // Special vertices really have no metadata
    @Override
    public SourceMetadata getMeta() {
        return null;
    }
}
