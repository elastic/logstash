package org.logstash.execution.queue;

import java.util.Map;

/**
 * Writes to the Queue.
 */
public interface QueueWriter {

    /**
     * Pushes a single event to the Queue, blocking indefinitely if the Queue is not ready for a
     * write.
     * @param event Logstash Event Data
     */
    void push(Map<String, Object> event);
}
