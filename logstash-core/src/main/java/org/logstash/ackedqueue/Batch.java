package org.logstash.ackedqueue;

import java.io.Closeable;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class Batch implements Closeable {

    private List<Queueable> elements;

    private long[] ackableSeqNums; // from initial read events seqNum
    private Queue queue;
    private AtomicBoolean closed;

    public Batch(List<Queueable> elements, Queue q) {
        this.elements = elements;
        this.queue = q;
        this.closed = new AtomicBoolean(false);
        // TODO: ackableSeqNums = build array of seqNum from elements
    }

    // close acks the batch ackable events
    public void close() {
        if (closed.getAndSet(true) == false) {
            this.queue.ack(this.ackableSeqNums);
        } else {
            // TODO: double close hnalding
            // throw?
        }
    }
}
