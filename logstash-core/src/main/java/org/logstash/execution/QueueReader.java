package org.logstash.execution;

import org.logstash.Event;

/**
 * Reads from the Queue.
 */
public interface QueueReader {

    /**
     * Polls for the next event without timeout.
     * @param event Event Pointer to write next Event to
     * @return Sequence Number of the event, -1 on failure to poll an event
     */
    long poll(Event event);

    /**
     * Polls for the next event with a timeout.
     * @param event Event Pointer to write next event to
     * @param millis Timeout for polling the next even in ms
     * @return Sequence Number of the event, -1 on failure to poll an event
     */
    long poll(Event event, long millis);

    /**
     * Acknowledges that an Event has passed through the pipeline and can be acknowledged to the
     * input.
     * @param sequenceNum Sequence number of the acknowledged event
     */
    void acknowledge(long sequenceNum);
}
