package org.logstash.elastiqueue;

import java.util.*;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

public class Topic {
    private final Elastiqueue elastiqueue;
    private final String name;
    private final List<Partition> partitions = new ArrayList<>();
    private final BlockingQueue<Partition> writablePartitions;
    private int numPartitions;

    public Topic(final Elastiqueue elastiqueue, String name, int numPartitions) {
        this.elastiqueue = elastiqueue;
        this.name = name;
        this.numPartitions = numPartitions;
        writablePartitions = new ArrayBlockingQueue<>(this.numPartitions);
        for (int i = 0; i < numPartitions; i++) {
            Partition p = new Partition(elastiqueue, this, i);
            partitions.add(p);
            try {
                writablePartitions.put(p);
            } catch (InterruptedException e) {
                // Should never happen
                throw new RuntimeException(e);
            }
        }
    }

    public Producer makeProducer(String producerId) {
        return new Producer(elastiqueue, this, producerId);
    }

    public Collection<Partition> getPartitions() {
        return partitions;
    }

    public Partition getWritablePartition() throws InterruptedException {
        return writablePartitions.take();
    }

    public void returnPartitionToWritePool(Partition partition) throws InterruptedException {
        writablePartitions.put(partition);
    }

    public String getName() {
        return name;
    }

    public int getNumPartitions() {
        return numPartitions;
    }

    public Consumer makeConsumer(String consumerId) {
        return new Consumer(elastiqueue, this, consumerId);
    }
}
