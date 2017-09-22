package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;
import org.logstash.ackedqueue.io.LongVector;

public class Batch implements Closeable {

    private final List<Queueable> elements;

    private final LongVector seqNums;
    private final Queue queue;
    private final AtomicBoolean closed;

    public Batch(List<Queueable> elements, LongVector seqNums, Queue q) {
        this.elements = elements;
        this.seqNums = seqNums;
        this.queue = q;
        this.closed = new AtomicBoolean(false);
    }

    // close acks the batch ackable events
    public void close() throws IOException {
        if (closed.getAndSet(true) == false) {
              this.queue.ack(this.seqNums);
        } else {
            // TODO: how should we handle double-closing?
            throw new IOException("double closing batch");
        }
    }

    public int size() {
        return elements.size();
    }

    public List<? extends Queueable> getElements() {
        return elements;
    }

    public LongVector getSeqNums() { return this.seqNums; }

    public Queue getQueue() {
        return queue;
    }
}
