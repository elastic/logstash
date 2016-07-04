package org.logstash.ackedqueue;

import java.io.Closeable;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

public class Batch implements Closeable {

    private final List<Queueable> elements;

    private final List<Long> ackableSeqNums; // from initial read events seqNum
    private final Queue queue;
    private final AtomicBoolean closed;

    public Batch(List<Queueable> elements, Queue q) {
        this.elements = elements;
        this.queue = q;
        this.closed = new AtomicBoolean(false);
        this.ackableSeqNums = elements.stream().map(e -> e.getSeqNum()).collect(Collectors.toList());
    }

    // close acks the batch ackable events
    public void close() {
        if (closed.getAndSet(true) == false) {
//            Long[] seqNums = new Long[this.ackableSeqNums.size()];
//            seqNums = this.ackableSeqNums.toArray(seqNums);
//            this.queue.ack(seqNums);
        } else {
            // TODO: double close hnalding
            // throw?
        }
    }

    public List<Queueable> getElements() {
        return elements;
    }

    public Queue getQueue() {
        return queue;
    }
}
