package org.logstash.execution;

import org.logstash.common.io.DeadLetterQueueWriter;

/**
 * Holds Logstash Environment.
 */
public final class LsContext {

    public DeadLetterQueueWriter dlqWriter() {
        return null;
    }
}
