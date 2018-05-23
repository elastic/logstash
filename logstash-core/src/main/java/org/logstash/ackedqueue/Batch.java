package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class Batch implements Closeable {

    private final List<Queueable> elements;

    private final long firstSeqNum;

    private final Queue queue;
    private final AtomicBoolean closed;

    public Batch(SequencedList<byte[]> serialized, Queue q) {
        this(
            serialized.getElements(),
            serialized.getSeqNums().size() == 0 ? -1L : serialized.getSeqNums().get(0), q
        );
    }

    public Batch(List<byte[]> elements, long firstSeqNum, Queue q) {
        this.elements = deserializeElements(elements, q);
        this.firstSeqNum = elements.isEmpty() ? -1L : firstSeqNum;
        this.queue = q;
        this.closed = new AtomicBoolean(false);
    }

    // close acks the batch ackable events
    @Override
    public void close() throws IOException {
        if (closed.getAndSet(true) == false) {
            if (firstSeqNum >= 0L) {
                this.queue.ack(firstSeqNum, elements.size());
            }
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

    public Queue getQueue() {
        return queue;
    }

    /**
     *
     * @param serialized Collection of serialized elements
     * @param q {@link Queue} instance
     * @return Collection of deserialized {@link Queueable} elements
     */
    private static List<Queueable> deserializeElements(List<byte[]> serialized, Queue q) {
        final List<Queueable> deserialized = new ArrayList<>(serialized.size());
        for (final byte[] element : serialized) {
            deserialized.add(q.deserialize(element));
        }
        return deserialized;
    }
}
