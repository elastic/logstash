package org.logstash.ackedqueue;

import java.util.List;

public class DeserializedBatch {
    private final List<byte[]> elements;
    private final long firstSeqNum;
    private final Queue queue;

    public DeserializedBatch(List<byte[]> elements, long firstSeqNum, Queue queue) {
        this.elements = elements;
        this.firstSeqNum = firstSeqNum;
        this.queue = queue;
    }

    public Batch deserialize() {
        return new Batch(elements, firstSeqNum, queue);
    }
}
