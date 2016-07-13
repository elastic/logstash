package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
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
    public void close() throws IOException {
        if (closed.getAndSet(true) == false) {
              this.queue.ack(this.ackableSeqNums);
        } else {
            // TODO: how should we handle double-closing?
            throw new IOException("double closing batch");
        }
    }

    public List<? extends Queueable> getElements() {
        return elements;
    }

    public Queue getQueue() {
        return queue;
    }
}
