package org.logstash.execution.queue;

import java.util.Map;

/**
 * Writes to the queue.
 */
public interface QueueWriter {

    /**
     * Pushes a single event to the Queue, blocking indefinitely if the Queue is not ready for a
     * write. Implementations of this interface must produce events from a deep copy of the supplied
     * map because upstream clients of this interface may reuse map instances between calls to push.
     *
     * @param event Logstash event data
     */
    void push(Map<String, Object> event);
}
