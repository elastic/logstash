package org.logstash.execution;

import org.logstash.common.io.DeadLetterQueueWriter;

/**
 * Holds Logstash Environment.
 */
public final class LsContext {

    // TODO: Add getters for metrics, logger etc.

    public DeadLetterQueueWriter dlqWriter() {
        return null;
    }
}
