package org.logstash.plugin;

import org.logstash.Event;

import java.util.NoSuchElementException;

public interface ProcessorBatch extends Batch {
    /**
     * Remove the given event from the batch. This drops the event and no further processing will occur on it..
     * <p>
     * This replaces the org.logstash.Event#cancel() method
     *
     * @param entry The event to be cancelled. This event must exist in the batch.
     * @throws NoSuchElementException if an event does not exist in the batch
     */
    void remove(Event event) throws NoSuchElementException;

    void add(Event event);
}
