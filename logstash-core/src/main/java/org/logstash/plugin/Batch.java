package org.logstash.plugin;

import org.logstash.Event;

import java.util.NoSuchElementException;

/*
 * A batch is a container for events as it travels through the pipeline.
 *
 * Basically, a batch is a unit of work that travels along a Logstash pipeline.
 *
 */

public interface Batch extends Iterable<Event> {
    /**
     * Mark an event as having failed.
     * <p>
     * XXX: Can we categorize failures? Use something like types
     *
     * @param entry The element to fail.
     * @throws NoSuchElementException if an event does not exist in the batch
     */
    void fail(Event entry, FailureContext context);

    int size();
}
