package org.logstash.ackedqueue;

import com.logstash.Event;

import java.io.Closeable;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class Batch implements Closeable {

    private List<Event> liveEvents;
    // TBD private List<Event> canceledEvents
    // TBD private List<Event> newEvents
    private long[] ackableEvents; // from initial read events seqNum
    private Queue queue;
    private AtomicBoolean closed;

    Batch(List<Event> events, Queue q) {
        this.liveEvents = events;
        this.queue = q;
        // TBD
        // ackEvents = build array of seqNum from events
    }

    // close acks the batch ackable events
    public void close() {
        if (closed.getAndSet(true) == false) {
            this.queue.ack(this.ackableEvents);
        } else {
            // TBD on double close
            // throw?
        }
    }
}
