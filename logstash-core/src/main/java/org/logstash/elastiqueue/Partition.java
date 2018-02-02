package org.logstash.elastiqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicLong;

public class Partition implements Closeable {
    private final Elastiqueue elastiqueue;
    private final Topic topic;
    private final int partitionId;
    private final String indexName;
    private volatile long seq = -1;
    private static String PARTITION_PREFIX = "esqueue-partition-";

    public Partition(Elastiqueue elastiqueue, Topic topic, int partitionId) {
        this.elastiqueue = elastiqueue;
        this.topic = topic;
        this.partitionId = partitionId;
        this.indexName = PARTITION_PREFIX + topic.getName() + "-" + Integer.toString(partitionId);
    }

    @Override
    public void close() throws IOException {
        try {
            this.topic.returnPartitionToWritePool(this);
        } catch (InterruptedException e) {
            throw new IOException("Could not return partition to write pool", e);
        }
    }

    public String getIndexName() {
        return indexName;
    }

    public long getSeq() {
        return seq;
    }

    public void setSeq(long num) {
        seq = num;
    }
}
