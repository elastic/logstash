package org.logstash.execution;

import java.util.Collection;
import java.util.Map;

/**
 * Writes to the Queue.
 */
public interface QueueWriter {

    /**
     * Pushes a single event to the Queue, blocking indefinitely if the Queue is not ready for a
     * write.
     * @param event Logstash Event Data
     * @return Sequence number of the event or -1 if push failed
     */
    long push(Map<String, Object> event);

    /**
     * Pushes a single event to the Queue, blocking for the given timeout if the Queue is not ready
     * for a write.
     * @param event Logstash Event Data
     * @param millis Timeout in millis
     * @return Sequence number of the event or -1 if push failed
     */
    long push(Map<String, Object> event, long millis);

    /**
     * Pushes a multiple events to the Queue, blocking for the given timeout if the Queue is not
     * ready for a write.
     * Guarantees that a return {@code != -1} means that all events were pushed to the Queue
     * successfully and no partial writes of only a subset of the input events will ever occur.
     * @param events Logstash Events Data
     * @return Sequence number of the first event or -1 if push failed
     */
    long push(Collection<Map<String, Object>> events);

    /**
     * Pushes a multiple events to the Queue, blocking for the given timeout if the Queue is not
     * ready for a write.
     * Guarantees that a return {@code != -1} means that all events were pushed to the Queue
     * successfully and no partial writes of only a subset of the input events will ever occur.
     * @param events Logstash Events Data
     * @param millis Timeout in millis
     * @return Sequence number of the first event or -1 if push failed
     */
    long push(Collection<Map<String, Object>> events, long millis);

    /**
     * Returns the upper bound for acknowledged sequence numbers.
     * @return upper bound for acknowledged sequence numbers
     */
    long watermark();

    /**
     * Returns the upper bound for unacknowledged sequence numbers.
     * @return upper bound for unacknowledged sequence numbers
     */
    long highWatermark();
}
