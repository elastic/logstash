package org.logstash.execution;

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
