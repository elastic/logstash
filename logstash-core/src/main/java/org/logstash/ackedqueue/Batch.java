package org.logstash.ackedqueue;

import com.logstash.Event;

import java.io.Closeable;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class Batch implements Closeable {

    private List<Event> liveEvents;

    // TODO: figure cancelled & new events structure & handling
    // private List<Event> canceledEvents
    // private List<Event> newEvents
    private long[] ackableEvents; // from initial read events seqNum
    private Queue queue;
    private AtomicBoolean closed;

    Batch(List<Event> events, Queue q) {
        this.liveEvents = events;
        this.queue = q;
        // TODO: ackableEvents = build array of seqNum from events
    }

    // close acks the batch ackable events
    public void close() {
        if (closed.getAndSet(true) == false) {
            this.queue.ack(this.ackableEvents);
        } else {
            // TODO: double close hnalding
            // throw?
        }
    }
}
